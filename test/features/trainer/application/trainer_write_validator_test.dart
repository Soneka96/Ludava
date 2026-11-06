import 'package:ludava/features/game_catalog/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/trainer/application/trainer_write_validator.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

const _processId = 41;
const _memoryBase = 0x300000000;
final _startedAtUtc = DateTime.utc(2026, 11, 6);
final _profile = Rc2CollectionProfile.profile;

void main() {
  group('Method validate() behaves correctly', () {
    test('Method validate() rejects a process that is no longer running', () {
      var metadataReads = 0;
      var detectionCalls = 0;
      var baseReads = 0;
      final result = _validator(
        discover: () => const [],
        readMetadata: (_) {
          metadataReads++;
          return _metadata();
        },
        detectGame: (_, _) {
          detectionCalls++;
          return _detection();
        },
        resolveBase: (_) {
          baseReads++;
          return const Rpcs3MemoryBaseCandidate(
            memoryBase: _memoryBase,
            logPath: 'RPCS3.log',
          );
        },
      ).validate(
        processId: _processId,
        memoryBase: _memoryBase,
        profile: _profile,
        selectedDetection: _detection(),
        selectedProcessStartedAtUtc: _startedAtUtc,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.processUnavailable, isTrue);
      expect(metadataReads, 0);
      expect(detectionCalls, 0);
      expect(baseReads, 0);
    });

    test('Method validate() rejects a changed process session', () {
      var detectionCalls = 0;
      var baseReads = 0;
      final result = _validator(
        readMetadata:
            (_) => _metadata(
              startedAtUtc: _startedAtUtc.add(const Duration(seconds: 1)),
            ),
        detectGame: (_, _) {
          detectionCalls++;
          return _detection();
        },
        resolveBase: (_) {
          baseReads++;
          return const Rpcs3MemoryBaseCandidate(
            memoryBase: _memoryBase,
            logPath: 'RPCS3.log',
          );
        },
      ).validate(
        processId: _processId,
        memoryBase: _memoryBase,
        profile: _profile,
        selectedDetection: _detection(),
        selectedProcessStartedAtUtc: _startedAtUtc,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.processSessionChanged, isTrue);
      expect(detectionCalls, 0);
      expect(baseReads, 0);
    });

    test('Method validate() rejects when the selected session is unknown', () {
      var detectionCalls = 0;
      var baseReads = 0;
      final result = _validator(
        detectGame: (_, _) {
          detectionCalls++;
          return _detection();
        },
        resolveBase: (_) {
          baseReads++;
          return const Rpcs3MemoryBaseCandidate(
            memoryBase: _memoryBase,
            logPath: 'RPCS3.log',
          );
        },
      ).validate(
        processId: _processId,
        memoryBase: _memoryBase,
        profile: _profile,
        selectedDetection: _detection(),
        selectedProcessStartedAtUtc: null,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.processSessionChanged, isTrue);
      expect(detectionCalls, 0);
      expect(baseReads, 0);
    });

    test('Method validate() rejects a different current game identity', () {
      final result = _validator(
        detectGame:
            (_, _) => GameDetectionResult(
              status: GameDetectionStatus.supportedGame,
              processId: _processId,
              confidence: GameIdentityConfidence.confirmed,
              profile: _profile,
              executableHash: 'different-hash',
              evidenceDescription: 'Changed PPU identity.',
            ),
      ).validate(
        processId: _processId,
        memoryBase: _memoryBase,
        profile: _profile,
        selectedDetection: _detection(),
        selectedProcessStartedAtUtc: _startedAtUtc,
      );

      expect(result.isAuthorized, isFalse);
      expect(
        result.rejectionMessage,
        contains('active game or memory base changed'),
      );
    });

    test('Method validate() rejects a changed current memory base', () {
      final result = _validator(
        resolveBase:
            (_) => const Rpcs3MemoryBaseCandidate(
              memoryBase: _memoryBase + 1,
              logPath: 'RPCS3.log',
            ),
      ).validate(
        processId: _processId,
        memoryBase: _memoryBase,
        profile: _profile,
        selectedDetection: _detection(),
        selectedProcessStartedAtUtc: _startedAtUtc,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.rejectionMessage, contains('memory base changed'));
    });

    test('Method validate() rejects failed identity revalidation', () {
      final result = _validator(
        detectGame: (_, _) => throw Exception('identity read failed'),
      ).validate(
        processId: _processId,
        memoryBase: _memoryBase,
        profile: _profile,
        selectedDetection: _detection(),
        selectedProcessStartedAtUtc: _startedAtUtc,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.rejectionMessage, contains('identity read failed'));
    });

    test('Method validate() rejects unsupported current-session checks', () {
      final result = _validator(
        resolveBase: (_) => throw UnsupportedError('Windows only'),
      ).validate(
        processId: _processId,
        memoryBase: _memoryBase,
        profile: _profile,
        selectedDetection: _detection(),
        selectedProcessStartedAtUtc: _startedAtUtc,
      );

      expect(result.isAuthorized, isFalse);
      expect(result.rejectionMessage, contains('Windows only'));
    });

    test('Method validate() authorizes a matching current target', () {
      final result = _validator().validate(
        processId: _processId,
        memoryBase: _memoryBase,
        profile: _profile,
        selectedDetection: _detection(),
        selectedProcessStartedAtUtc: _startedAtUtc,
      );

      expect(result.isAuthorized, isTrue);
      expect(result.rejectionMessage, isNull);
    });
  });
}

TrainerWriteValidator _validator({
  List<int> Function()? discover,
  Rpcs3ProcessMetadata Function(int processId)? readMetadata,
  GameDetectionResult? Function(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  )?
  detectGame,
  Rpcs3MemoryBaseCandidate? Function(Rpcs3ProcessMetadata processMetadata)?
  resolveBase,
}) => TrainerWriteValidator(
  discoverProcessIds: discover ?? () => const [_processId],
  readProcessMetadata: readMetadata ?? (_) => _metadata(),
  resolveMemoryBaseCandidate:
      resolveBase ??
      (_) => const Rpcs3MemoryBaseCandidate(
        memoryBase: _memoryBase,
        logPath: 'RPCS3.log',
      ),
  detectGame: detectGame ?? (_, _) => _detection(),
);

Rpcs3ProcessMetadata _metadata({DateTime? startedAtUtc}) =>
    Rpcs3ProcessMetadata(
      executablePath: 'RPCS3.exe',
      startedAtUtc: startedAtUtc ?? _startedAtUtc,
    );

GameDetectionResult _detection() => GameDetectionResult(
  status: GameDetectionStatus.supportedGame,
  processId: _processId,
  confidence: GameIdentityConfidence.confirmed,
  profile: _profile,
  executableHash: _profile.executableHash,
  evidenceDescription: 'Current identity.',
);
