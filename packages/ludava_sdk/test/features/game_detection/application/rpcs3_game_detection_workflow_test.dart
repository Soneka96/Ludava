import 'dart:io';

import 'package:ludava_sdk/features/game_catalog/domain/profiles/deadlocked_ps3_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava_sdk/features/game_detection/application/rpcs3_game_detection_workflow.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/rpcs3_game_identity_log_event.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/rpcs3_game_identity_log_snapshot.entity.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

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

    test(
      'Method detect() leaves game identity ambiguous when processes share a log directory',
      () {
        var logReads = 0;
        final result = _workflow(
          processIds: const [41, 42],
          readMetadata: (_) => _metadata('selected'),
          readLogs: (_) {
            logReads++;
            return [_supportedSnapshot()];
          },
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(logReads, 0);
      },
    );

    test(
      'Method detect() leaves game identity ambiguous when another process cannot be distinguished',
      () {
        var logReads = 0;
        final result = _workflow(
          processIds: const [41, 42],
          readMetadata: (_) => throw Exception('metadata unavailable'),
          readLogs: (_) {
            logReads++;
            return [_supportedSnapshot()];
          },
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(logReads, 0);
      },
    );

    test(
      'Method detect() leaves game identity ambiguous when another process is unsupported',
      () {
        var logReads = 0;
        final result = _workflow(
          processIds: const [41, 42],
          readMetadata: (_) => throw UnsupportedError('unsupported platform'),
          readLogs: (_) {
            logReads++;
            return [_supportedSnapshot()];
          },
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(logReads, 0);
      },
    );

    test('Method detect() rejects multiple fresh log candidates', () {
      final result = _workflow(
        processIds: const [41],
        readMetadata: (_) => _metadata('other'),
        readLogs: (_) => [_supportedSnapshot(), _supportedSnapshot()],
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

    test('Method detect() invalidates identity after the game stops', () {
      final result = _workflow(
        processIds: const [41],
        readMetadata: (_) => _metadata('other'),
        readLogs:
            (_) => [
              _snapshot(
                events: const [
                  Rpcs3GameIdentityLogEvent(processFinished: true),
                ],
              ),
            ],
      ).detect(41, _metadata('selected'));

      expect(result.status, GameDetectionStatus.noActiveGame);
      expect(result.profile, isNull);
    });

    test('Method detect() does not select a game for the Collection menu', () {
      final result = _workflow(
        processIds: const [41],
        readMetadata: (_) => _metadata('other'),
        readLogs:
            (_) => [
              _snapshot(
                events: const [
                  Rpcs3GameIdentityLogEvent(
                    titleId: 'BCUS98282',
                    executable: 'EBOOT.BIN',
                    executableHash:
                        'PPU-673b1ce1b01ce7f42f1787a479f9b83854fa26f5',
                  ),
                ],
              ),
            ],
      ).detect(41, _metadata('selected'));

      expect(result.status, GameDetectionStatus.noActiveGame);
      expect(result.profile, isNull);
    });

    test(
      'Method detect() resolves Deadlocked from its observed standalone PPU event',
      () {
        final result = _workflow(
          processIds: const [41],
          readMetadata: (_) => _metadata('other'),
          readLogs: (_) => [_deadlockedSnapshot()],
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.supportedGame);
        expect(result.profile, same(DeadlockedPs3Profile.profile));
        expect(result.titleId, 'NPUA80646');
        expect(result.executable, 'EBOOT.BIN');
        expect(
          result.executableHash,
          'PPU-c44d700265e50dfe49054c1703f8fea668cc33b9',
        );
      },
    );

    test(
      'Method detect() leaves Deadlocked ambiguous while its PPU hash is pending',
      () {
        final profile = DeadlockedPs3Profile.profile;
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

    test(
      'Method detect() does not treat the Collection menu hash as Deadlocked',
      () {
        final result = _workflow(
          processIds: const [41],
          readMetadata: (_) => _metadata('other'),
          readLogs:
              (_) => [
                _snapshot(
                  events: const [
                    Rpcs3GameIdentityLogEvent(
                      titleId: 'NPUA80646',
                      executable: 'EBOOT.BIN',
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
      'Method detect() invalidates Deadlocked identity after a stop event',
      () {
        final result = _workflow(
          processIds: const [41],
          readMetadata: (_) => _metadata('other'),
          readLogs:
              (_) => [
                _snapshot(
                  events: [
                    Rpcs3GameIdentityLogEvent(
                      titleId: DeadlockedPs3Profile.profile.buildId,
                      executable: DeadlockedPs3Profile.profile.executable,
                      executableHash:
                          DeadlockedPs3Profile.profile.executableHash,
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
      'Method detect() leaves identity unresolved while the PPU hash is pending',
      () {
        final result = _workflow(
          processIds: const [41],
          readMetadata: (_) => _metadata('other'),
          readLogs:
              (_) => [
                _snapshot(
                  events: const [
                    Rpcs3GameIdentityLogEvent(
                      titleId: 'BCUS98282',
                      executable: 'RC2.ppu.self',
                    ),
                  ],
                ),
              ],
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
      },
    );

    test(
      'Method detect() resolves a supported profile from current PPU evidence',
      () {
        final result = _workflow(
          processIds: const [41],
          readMetadata: (_) => _metadata('other'),
          readLogs: (_) => [_supportedSnapshot()],
        ).detect(41, _metadata('selected'));

        expect(result.status, GameDetectionStatus.supportedGame);
        expect(result.profile, same(Rc2CollectionProfile.profile));
        expect(result.confidence, GameIdentityConfidence.confirmed);
      },
    );

    test('Method detect() selects the latest game boot after a stop event', () {
      final profile = Rc2CollectionProfile.profile;
      final result = _workflow(
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
    });
  });
}

Rpcs3GameDetectionWorkflow _workflow({
  required List<int> processIds,
  required Rpcs3ProcessMetadata Function(int processId) readMetadata,
  required List<Rpcs3GameIdentityLogSnapshot> Function(
    Rpcs3ProcessMetadata processMetadata,
  )
  readLogs,
}) => Rpcs3GameDetectionWorkflow(
  discoverProcessIds: () => processIds,
  readProcessMetadata: readMetadata,
  readIdentityLogCandidates: readLogs,
);

Rpcs3ProcessMetadata _metadata(String directory) => Rpcs3ProcessMetadata(
  executablePath:
      '${Directory.systemTemp.path}${Platform.pathSeparator}$directory${Platform.pathSeparator}RPCS3.exe',
  startedAtUtc: DateTime.utc(2026),
);

Rpcs3GameIdentityLogSnapshot _supportedSnapshot() => _snapshot(
  events: [
    Rpcs3GameIdentityLogEvent(
      titleId: Rc2CollectionProfile.profile.buildId,
      executable: Rc2CollectionProfile.profile.executable,
      executableHash: Rc2CollectionProfile.profile.executableHash,
    ),
  ],
);

Rpcs3GameIdentityLogSnapshot _deadlockedSnapshot() => _snapshot(
  events: [
    Rpcs3GameIdentityLogEvent(
      titleId: DeadlockedPs3Profile.profile.buildId,
      executable: DeadlockedPs3Profile.profile.executable,
      executableHash: DeadlockedPs3Profile.profile.executableHash,
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
