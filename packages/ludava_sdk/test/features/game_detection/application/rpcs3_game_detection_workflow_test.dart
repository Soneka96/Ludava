import 'dart:io';

import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_detection/application/rpcs3_game_detection_workflow.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/rpcs3_game_identity_log_event.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/rpcs3_game_identity_log_snapshot.entity.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

GameProfile _profile({
  String id = 'synthetic-alpha',
  String buildId = 'SYNTHETIC01',
  String gameName = 'Synthetic Alpha',
  String executable = 'ALPHA.self',
  String executableHash = 'PPU-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
}) => GameProfile(
  id: id,
  gameName: gameName,
  buildId: buildId,
  executable: executable,
  executableHash: executableHash,
  readStatus: VerificationStatus.experimental,
  fields: {
    'credits': GameField(
      id: 'credits',
      name: 'Credits',
      guestOffset: 0x1000,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      readStatus: VerificationStatus.experimental,
    ),
  },
);

List<GameProfile> _profiles() => [
  _profile(),
  _profile(
    id: 'synthetic-beta',
    gameName: 'Synthetic Beta',
    executable: 'BETA.self',
    executableHash: 'PPU-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  ),
];

Rpcs3GameDetectionWorkflow _workflow({
  Iterable<GameProfile>? profiles,
  required List<int> processIds,
  required Rpcs3ProcessMetadata Function(int processId) readMetadata,
  required List<Rpcs3GameIdentityLogSnapshot> Function(
    Rpcs3ProcessMetadata processMetadata,
  )
  readLogs,
}) => Rpcs3GameDetectionWorkflow(
  profiles: profiles ?? _profiles(),
  discoverProcessIds: () => processIds,
  readProcessMetadata: readMetadata,
  readIdentityLogCandidates: readLogs,
);

Rpcs3ProcessMetadata _metadata(String directory) => Rpcs3ProcessMetadata(
  executablePath:
      '${Directory.systemTemp.path}${Platform.pathSeparator}$directory${Platform.pathSeparator}RPCS3.exe',
  startedAtUtc: DateTime.utc(2026),
);

Rpcs3GameIdentityLogSnapshot _supportedSnapshot(GameProfile profile) =>
    _snapshot(
      events: [
        Rpcs3GameIdentityLogEvent(
          titleId: profile.buildId,
          executable: profile.executable,
          executableHash: profile.executableHash,
        ),
      ],
    );

Rpcs3GameIdentityLogSnapshot _snapshot({
  List<Rpcs3GameIdentityLogEvent> events = const [],
  List<String> titles = const [],
  List<String> serials = const [],
  List<String> bootPaths = const [],
}) => Rpcs3GameIdentityLogSnapshot(
  titles: titles,
  serials: serials,
  bootPaths: bootPaths,
  events: events,
  logPath: 'RPCS3.log',
  logModifiedAtUtc: DateTime.utc(2026),
  processStartedAtUtc: DateTime.utc(2026),
);

void main() {
  group('Method detect() behaves correctly', () {
    test('Method detect() rejects a process that is no longer running', () {
      var metadataReads = 0;
      var logReads = 0;
      final result = _workflow(
        processIds: const [],
        readMetadata: (_) {
          metadataReads++;
          return _metadata('other');
        },
        readLogs: (_) {
          logReads++;
          return [_snapshot()];
        },
      ).detect(41, _metadata('selected'));

      expect(result.status, GameDetectionStatus.rpcs3NotRunning);
      expect(metadataReads, 0);
      expect(logReads, 0);
    });

    test('Method detect() rejects processes sharing a log directory', () {
      var logReads = 0;
      final result = _workflow(
        processIds: const [41, 42],
        readMetadata: (_) => _metadata('selected'),
        readLogs: (_) {
          logReads++;
          return [_supportedSnapshot(_profiles().first)];
        },
      ).detect(41, _metadata('selected'));

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(logReads, 0);
    });

    test(
      'Method detect() leaves identity ambiguous when another process cannot be read',
      () {
        var logReads = 0;
        final result = _workflow(
          processIds: const [41, 42],
          readMetadata: (_) => throw Exception('metadata unavailable'),
          readLogs: (_) {
            logReads++;
            return [_supportedSnapshot(_profiles().first)];
          },
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(logReads, 0);
      },
    );

    test('Method detect() handles unsupported reads for another process', () {
      var logReads = 0;
      final result = _workflow(
        processIds: const [41, 42],
        readMetadata: (_) => throw UnsupportedError('unsupported platform'),
        readLogs: (_) {
          logReads++;
          return [_supportedSnapshot(_profiles().first)];
        },
      ).detect(41, _metadata('selected'));

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(logReads, 0);
    });

    test('Method detect() rejects multiple fresh log candidates', () {
      final profile = _profiles().first;
      final result = _workflow(
        processIds: const [41],
        readMetadata: (_) => _metadata('other'),
        readLogs:
            (_) => [_supportedSnapshot(profile), _supportedSnapshot(profile)],
      ).detect(41, _metadata('selected'));

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
    });

    test('Method detect() rejects a missing current-session log', () {
      final result = _workflow(
        processIds: const [41],
        readMetadata: (_) => _metadata('other'),
        readLogs: (_) => const [],
      ).detect(41, _metadata('selected'));

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.confidence, GameIdentityConfidence.uncertain);
    });

    test('Method detect() reports no active game for an empty current log', () {
      final result = _workflow(
        processIds: const [41],
        readMetadata: (_) => _metadata('other'),
        readLogs: (_) => [_snapshot()],
      ).detect(41, _metadata('selected'));

      expect(result.status, GameDetectionStatus.noActiveGame);
      expect(result.profile, isNull);
    });

    test(
      'Method detect() invalidates identity after a process-finished event',
      () {
        final profile = _profiles().first;
        final result = _workflow(
          processIds: const [41],
          readMetadata: (_) => _metadata('other'),
          readLogs:
              (_) => [
                _snapshot(
                  events: [
                    Rpcs3GameIdentityLogEvent(
                      titleId: profile.buildId,
                      executable: profile.executable,
                      executableHash: profile.executableHash,
                    ),
                    const Rpcs3GameIdentityLogEvent(processFinished: true),
                  ],
                ),
              ],
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.noActiveGame);
        expect(result.profile, isNull);
      },
    );

    test(
      'Method detect() does not select the Collection menu executable hash',
      () {
        final result = _workflow(
          processIds: const [41],
          readMetadata: (_) => _metadata('other'),
          readLogs:
              (_) => [
                _snapshot(
                  events: const [
                    Rpcs3GameIdentityLogEvent(
                      titleId: 'SYNTHETIC01',
                      executable: 'ALPHA.self',
                      executableHash:
                          'PPU-673b1ce1b01ce7f42f1787a479f9b83854fa26f5',
                    ),
                  ],
                ),
              ],
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.noActiveGame);
        expect(result.profile, isNull);
      },
    );

    test(
      'Method detect() leaves identity ambiguous while the hash is pending',
      () {
        final profile = _profiles().first;
        final result = _workflow(
          processIds: const [41],
          readMetadata: (_) => _metadata('other'),
          readLogs:
              (_) => [
                _snapshot(
                  events: [
                    Rpcs3GameIdentityLogEvent(
                      titleId: profile.buildId,
                      executable: profile.executable,
                    ),
                  ],
                ),
              ],
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
      },
    );

    test('Method detect() resolves an injected synthetic profile', () {
      final profiles = _profiles();
      final result = _workflow(
        profiles: profiles,
        processIds: const [41],
        readMetadata: (_) => _metadata('other'),
        readLogs: (_) => [_supportedSnapshot(profiles.first)],
      ).detect(41, _metadata('selected'));

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.profile, same(profiles.first));
      expect(result.confidence, GameIdentityConfidence.confirmed);
    });

    test(
      'Method detect() uses executable and hash to select a shared title id',
      () {
        final profiles = _profiles();
        final result = _workflow(
          profiles: profiles,
          processIds: const [41],
          readMetadata: (_) => _metadata('other'),
          readLogs: (_) => [_supportedSnapshot(profiles.last)],
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.supportedGame);
        expect(result.profile, same(profiles.last));
      },
    );

    test(
      'Method detect() selects the latest supported boot after a stop event',
      () {
        final profiles = _profiles();
        final profile = profiles.last;
        final result = _workflow(
          profiles: profiles,
          processIds: const [41],
          readMetadata: (_) => _metadata('other'),
          readLogs:
              (_) => [
                _snapshot(
                  events: [
                    const Rpcs3GameIdentityLogEvent(processFinished: true),
                    Rpcs3GameIdentityLogEvent(
                      titleId: profile.buildId,
                      executable: profile.executable,
                      executableHash: profile.executableHash,
                    ),
                  ],
                ),
              ],
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.supportedGame);
        expect(result.profile, same(profile));
      },
    );
  });
}
