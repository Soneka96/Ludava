import 'package:ludava_sdk/features/trainer/application/diagnostics/diagnostic_game_memory_request.entity.dart';
import 'package:ludava_sdk/features/trainer/application/diagnostics/diagnostic_game_memory_service.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava_sdk/features/game_detection/data/datasources/rpcs3_game_identity_log.datasource.dart';
import 'package:ludava_sdk/features/game_memory/data/datasources/windows_memory_api.dart';
import 'package:ludava_sdk/features/game_memory/data/process_game_memory_operations.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:ludava_sdk/shared/platform/windows_memory_exception.dart';
import 'package:test/test.dart';

import '../../../../support/fake_windows_memory_api.dart';

GameField _field() => GameField(
  id: 'credits',
  name: 'Credits',
  guestOffset: 0x1000,
  valueType: MemoryValueType.unsigned32,
  byteOrder: ByteOrder.big,
  minimumValue: 0,
  maximumValue: 0xffffffff,
);

GameProfile _profile({Map<String, GameField>? fields}) => GameProfile(
  id: 'synthetic-profile',
  gameName: 'Synthetic game',
  buildId: 'TEST00001',
  executable: 'SYNTHETIC.self',
  executableHash: 'PPU-synthetic-hash',
  fields: fields ?? {'credits': _field()},
);

List<GameProfile> _profiles() => [_profile()];

DiagnosticGameMemoryService _createService({
  Iterable<GameProfile>? profiles,
  WindowsMemoryApi? api,
  bool? isWindows,
  int? pointerSize,
  ProcessGameMemoryOperations? memoryOperations,
  List<int> Function()? discoverProcessIds,
  Rpcs3ProcessMetadata Function(int processId)? readProcessMetadata,
  Rpcs3MemoryBaseCandidate? Function(Rpcs3ProcessMetadata processMetadata)?
  resolveMemoryBaseCandidate,
  GameDetectionResult Function(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  )?
  detectGame,
  Rpcs3GameIdentityLogDataSource? gameIdentityLogDataSource,
}) => DiagnosticGameMemoryService(
  profiles: profiles ?? _profiles(),
  api: api,
  isWindows: isWindows,
  pointerSize: pointerSize,
  memoryOperations: memoryOperations,
  discoverProcessIds: discoverProcessIds,
  readProcessMetadata: readProcessMetadata,
  resolveMemoryBaseCandidate: resolveMemoryBaseCandidate,
  detectGame: detectGame,
  gameIdentityLogDataSource: gameIdentityLogDataSource,
);

final _metadata = Rpcs3ProcessMetadata(
  executablePath: r'C:\RPCS3\rpcs3.exe',
  startedAtUtc: DateTime.utc(2026, 11, 5),
);

GameDetectionResult _identity({
  int processId = 42,
  String? executableHash = 'PPU-synthetic-hash',
}) => GameDetectionResult(
  status: GameDetectionStatus.supportedGame,
  processId: processId,
  titleId: 'TEST00001',
  gameTitle: 'Synthetic game',
  executable: 'SYNTHETIC.self',
  executableHash: executableHash,
  confidence: GameIdentityConfidence.confirmed,
  profile: _profile(),
  evidenceDescription: 'Confirmed synthetic identity.',
);

final _confirmedIdentity = _identity();
final _mismatchedIdentity = GameDetectionResult(
  status: GameDetectionStatus.noActiveGame,
  processId: 42,
  confidence: GameIdentityConfidence.uncertain,
  evidenceDescription: 'No active game in the synthetic session.',
);
final _wrongHashIdentity = _identity(
  executableHash: 'PPU-wrong-synthetic-hash',
);
final _otherProcessIdentity = _identity(processId: 43);

DiagnosticGameMemoryRequest _readRequest({
  bool requireCurrentIdentity = false,
}) => DiagnosticGameMemoryRequest(
  gameId: 'synthetic-profile',
  fieldId: 'credits',
  processId: 42,
  memoryBase: 0x300000000,
  action: GameMemoryAction.read,
  requireCurrentIdentity: requireCurrentIdentity,
);

DiagnosticGameMemoryRequest _writeRequest({
  bool confirmed = true,
  int value = 0x01020304,
  String fieldId = 'credits',
}) => DiagnosticGameMemoryRequest(
  gameId: 'synthetic-profile',
  fieldId: fieldId,
  processId: 42,
  memoryBase: 0x300000000,
  action: GameMemoryAction.write,
  value: value,
  confirmed: confirmed,
);

void main() {
  group('Method execute() behaves correctly', () {
    test(
      'Method execute() reads a field without current identity evidence',
      () {
        final api = FakeWindowsMemoryApi();
        final result = _createService(
          memoryOperations: ProcessGameMemoryOperations(
            api: api.adapter,
            isWindows: true,
            pointerSize: 8,
          ),
          discoverProcessIds: () => const [],
        ).execute(_readRequest());

        expect(result.status, DiagnosticGameMemoryStatus.completed);
        expect(result.identityConfirmed, isFalse);
        expect(result.readResult?.value, 0x01020304);
        expect(result.succeeded, isTrue);
        expect(api.openCalls, 1);
        expect(api.writeCalls, 0);
        expect(api.closeCalls, 1);
      },
    );

    test('Method execute() writes only after matching identity and base', () {
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [42],
        readProcessMetadata: (_) => _metadata,
        detectGame: (_, __) => _confirmedIdentity,
        resolveMemoryBaseCandidate:
            (_) => const Rpcs3MemoryBaseCandidate(
              memoryBase: 0x300000000,
              logPath: r'C:\RPCS3\log\RPCS3.log',
            ),
      ).execute(_writeRequest());

      expect(result.status, DiagnosticGameMemoryStatus.completed);
      expect(result.identityConfirmed, isTrue);
      expect(result.writeResult?.readBackValue, 0x01020304);
      expect(result.succeeded, isTrue);
      expect(api.writeCalls, 1);
      expect(api.closeCalls, 1);
    });

    test('Method execute() rejects a write without explicit confirmation', () {
      var discoveryCalls = 0;
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () {
          discoveryCalls++;
          return const [42];
        },
      ).execute(_writeRequest(confirmed: false));

      expect(result.status, DiagnosticGameMemoryStatus.memoryOperationFailed);
      expect(result.writeResult?.status, GameWriteStatus.confirmationRequired);
      expect(discoveryCalls, 0);
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test('Method execute() rejects a write when current identity differs', () {
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [42],
        readProcessMetadata: (_) => _metadata,
        detectGame: (_, __) => _mismatchedIdentity,
      ).execute(_writeRequest());

      expect(result.status, DiagnosticGameMemoryStatus.identityMismatch);
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test(
      'Method execute() rejects a write when the confirmed PPU hash differs',
      () {
        final api = FakeWindowsMemoryApi();
        final result = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () => const [42],
          readProcessMetadata: (_) => _metadata,
          detectGame: (_, __) => _wrongHashIdentity,
        ).execute(_writeRequest());

        expect(result.status, DiagnosticGameMemoryStatus.identityMismatch);
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test(
      'Method execute() rejects identity evidence for a different process',
      () {
        final api = FakeWindowsMemoryApi();
        final result = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () => const [42],
          readProcessMetadata: (_) => _metadata,
          detectGame: (_, __) => _otherProcessIdentity,
        ).execute(_writeRequest());

        expect(result.status, DiagnosticGameMemoryStatus.identityMismatch);
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test('Method execute() rejects a write when the current base differs', () {
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [42],
        readProcessMetadata: (_) => _metadata,
        detectGame: (_, __) => _confirmedIdentity,
        resolveMemoryBaseCandidate:
            (_) => const Rpcs3MemoryBaseCandidate(
              memoryBase: 0x310000000,
              logPath: r'C:\RPCS3\log\RPCS3.log',
            ),
      ).execute(_writeRequest());

      expect(result.status, DiagnosticGameMemoryStatus.memoryBaseMismatch);
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test(
      'Method execute() rejects a required-identity read without a match',
      () {
        final api = FakeWindowsMemoryApi();
        final result = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () => const [],
        ).execute(_readRequest(requireCurrentIdentity: true));

        expect(result.status, DiagnosticGameMemoryStatus.identityMismatch);
        expect(api.openCalls, 0);
        expect(api.readCalls, 0);
      },
    );

    test(
      'Method execute() preserves native memory errors as typed failures',
      () {
        final api = FakeWindowsMemoryApi(handleAddress: 0)..errorCode = 5;
        final result = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () => const [],
        ).execute(_readRequest());

        expect(result.status, DiagnosticGameMemoryStatus.nativeFailure);
        expect(result.error, isA<WindowsMemoryException>());
        expect(result.cleanupError, isNull);
      },
    );

    test('Method execute() reports handle cleanup failures separately', () {
      final api = FakeWindowsMemoryApi()..closeReturnValue = 0;
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [],
      ).execute(_readRequest());

      expect(result.status, DiagnosticGameMemoryStatus.cleanupFailed);
      expect(result.readResult?.succeeded, isTrue);
      expect(result.cleanupError, isA<WindowsMemoryException>());
      expect(result.succeeded, isFalse);
    });

    test(
      'Method execute() rejects incomplete write requests before discovery',
      () {
        var discoveryCalls = 0;
        final api = FakeWindowsMemoryApi();
        final result = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () {
            discoveryCalls++;
            return const [];
          },
        ).execute(
          const DiagnosticGameMemoryRequest(
            gameId: 'synthetic-profile',
            fieldId: 'credits',
            processId: 42,
            memoryBase: 0x300000000,
            action: GameMemoryAction.write,
            confirmed: true,
          ),
        );

        expect(result.status, DiagnosticGameMemoryStatus.invalidRequest);
        expect(discoveryCalls, 0);
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test(
      'Method execute() rejects an out-of-range process ID before discovery',
      () {
        var discoveryCalls = 0;
        final api = FakeWindowsMemoryApi();
        final result = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () {
            discoveryCalls++;
            return const [];
          },
        ).execute(
          const DiagnosticGameMemoryRequest(
            gameId: 'synthetic-profile',
            fieldId: 'credits',
            processId: 0x100000000,
            memoryBase: 0x300000000,
            action: GameMemoryAction.read,
          ),
        );

        expect(result.status, DiagnosticGameMemoryStatus.invalidRequest);
        expect(discoveryCalls, 0);
        expect(api.openCalls, 0);
        expect(api.readCalls, 0);
      },
    );
    test('Method execute() rejects an unsupported action before discovery', () {
      var discoveryCalls = 0;
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () {
          discoveryCalls++;
          return const [];
        },
      ).execute(
        const DiagnosticGameMemoryRequest(
          gameId: 'synthetic-profile',
          fieldId: 'credits',
          processId: 42,
          memoryBase: 0x300000000,
          action: GameMemoryAction.none,
        ),
      );

      expect(result.status, DiagnosticGameMemoryStatus.invalidRequest);
      expect(discoveryCalls, 0);
      expect(api.openCalls, 0);
    });

    test('Method execute() returns unknown-game status before discovery', () {
      var discoveryCalls = 0;
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () {
          discoveryCalls++;
          return const [];
        },
      ).execute(
        const DiagnosticGameMemoryRequest(
          gameId: 'unknown',
          fieldId: 'credits',
          processId: 42,
          memoryBase: 0x300000000,
          action: GameMemoryAction.read,
        ),
      );

      expect(result.status, DiagnosticGameMemoryStatus.unknownGame);
      expect(result.profile, isNull);
      expect(discoveryCalls, 0);
      expect(api.openCalls, 0);
    });

    test('Method execute() rejects an unknown field before discovery', () {
      var discoveryCalls = 0;
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () {
          discoveryCalls++;
          return const [];
        },
      ).execute(
        const DiagnosticGameMemoryRequest(
          gameId: 'synthetic-profile',
          fieldId: 'missing',
          processId: 42,
          memoryBase: 0x300000000,
          action: GameMemoryAction.read,
        ),
      );

      expect(result.status, DiagnosticGameMemoryStatus.memoryOperationFailed);
      expect(result.readResult?.status, GameReadStatus.unsupportedField);
      expect(discoveryCalls, 0);
      expect(api.openCalls, 0);
    });

    test('Method execute() rejects a missing write field before discovery', () {
      var discoveryCalls = 0;
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () {
          discoveryCalls++;
          return const [];
        },
      ).execute(_writeRequest(fieldId: 'missing'));

      expect(result.status, DiagnosticGameMemoryStatus.memoryOperationFailed);
      expect(result.writeResult?.status, GameWriteStatus.unsupportedField);
      expect(discoveryCalls, 0);
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test(
      'Method execute() rejects a nonpositive process ID before discovery',
      () {
        var discoveryCalls = 0;
        final api = FakeWindowsMemoryApi();
        final result = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () {
            discoveryCalls++;
            return const [];
          },
        ).execute(
          const DiagnosticGameMemoryRequest(
            gameId: 'synthetic-profile',
            fieldId: 'credits',
            processId: 0,
            memoryBase: 0x300000000,
            action: GameMemoryAction.read,
          ),
        );

        expect(result.status, DiagnosticGameMemoryStatus.invalidRequest);
        expect(discoveryCalls, 0);
        expect(api.openCalls, 0);
      },
    );

    test('Method execute() requires identity before a requested read', () {
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [42],
        readProcessMetadata: (_) => _metadata,
        detectGame: (_, __) => _confirmedIdentity,
      ).execute(_readRequest(requireCurrentIdentity: true));

      expect(result.status, DiagnosticGameMemoryStatus.completed);
      expect(result.identityConfirmed, isTrue);
      expect(result.readResult?.value, 0x01020304);
      expect(api.openCalls, 1);
      expect(api.readCalls, 1);
    });

    test(
      'Method execute() classifies identity-check exceptions for writes',
      () {
        final api = FakeWindowsMemoryApi();
        final result = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds:
              () => throw const FormatException('discovery failed'),
        ).execute(_writeRequest());

        expect(result.status, DiagnosticGameMemoryStatus.identityCheckFailed);
        expect(result.error, isA<FormatException>());
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test(
      'Method execute() classifies unsupported identity checks for writes',
      () {
        final api = FakeWindowsMemoryApi();
        final result = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds:
              () => throw UnsupportedError('discovery unavailable'),
        ).execute(_writeRequest());

        expect(result.status, DiagnosticGameMemoryStatus.identityCheckFailed);
        expect(result.error, isA<UnsupportedError>());
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test('Method execute() classifies a missing current memory base', () {
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [42],
        readProcessMetadata: (_) => _metadata,
        detectGame: (_, __) => _confirmedIdentity,
        resolveMemoryBaseCandidate: (_) => null,
      ).execute(_writeRequest());

      expect(result.status, DiagnosticGameMemoryStatus.memoryBaseMismatch);
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test('Method execute() classifies memory-base resolver exceptions', () {
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [42],
        readProcessMetadata: (_) => _metadata,
        detectGame: (_, __) => _confirmedIdentity,
        resolveMemoryBaseCandidate:
            (_) => throw const FormatException('base failed'),
      ).execute(_writeRequest());

      expect(result.status, DiagnosticGameMemoryStatus.memoryBaseCheckFailed);
      expect(result.error, isA<FormatException>());
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test('Method execute() classifies unsupported memory-base checks', () {
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [42],
        readProcessMetadata: (_) => _metadata,
        detectGame: (_, __) => _confirmedIdentity,
        resolveMemoryBaseCandidate:
            (_) => throw UnsupportedError('base unavailable'),
      ).execute(_writeRequest());

      expect(result.status, DiagnosticGameMemoryStatus.memoryBaseCheckFailed);
      expect(result.error, isA<UnsupportedError>());
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test('Method execute() reports a failed preliminary write read', () {
      final api = FakeWindowsMemoryApi()..readReturnValue = 0;
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [42],
        readProcessMetadata: (_) => _metadata,
        detectGame: (_, __) => _confirmedIdentity,
        resolveMemoryBaseCandidate:
            (_) => const Rpcs3MemoryBaseCandidate(
              memoryBase: 0x300000000,
              logPath: r'C:\RPCS3\log\RPCS3.log',
            ),
      ).execute(_writeRequest());

      expect(result.status, DiagnosticGameMemoryStatus.memoryOperationFailed);
      expect(result.writeResult?.status, GameWriteStatus.preliminaryReadFailed);
      expect(api.writeCalls, 0);
    });

    test('Method execute() reports mismatched write read-back', () {
      final api = FakeWindowsMemoryApi();
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [42],
        readProcessMetadata: (_) => _metadata,
        detectGame: (_, __) => _confirmedIdentity,
        resolveMemoryBaseCandidate:
            (_) => const Rpcs3MemoryBaseCandidate(
              memoryBase: 0x300000000,
              logPath: r'C:\RPCS3\log\RPCS3.log',
            ),
      ).execute(_writeRequest(value: 0x01020305));

      expect(result.status, DiagnosticGameMemoryStatus.memoryOperationFailed);
      expect(result.writeResult?.status, GameWriteStatus.readBackMismatch);
      expect(result.writeResult?.readBackValue, 0x01020304);
    });

    test('Method execute() returns a typed read failure without fake zero', () {
      final api = FakeWindowsMemoryApi()..readReturnValue = 0;
      final result = _createService(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [],
      ).execute(_readRequest());

      expect(result.status, DiagnosticGameMemoryStatus.memoryOperationFailed);
      expect(result.readResult?.status, GameReadStatus.readFailed);
      expect(result.readResult?.value, isNull);
      expect(result.succeeded, isFalse);
      expect(api.writeCalls, 0);
      expect(api.closeCalls, 1);
    });

    test('Method execute() preserves unsupported-platform errors', () {
      final result = _createService(
        isWindows: false,
        pointerSize: 8,
        discoverProcessIds: () => const [],
      ).execute(_readRequest());

      expect(result.status, DiagnosticGameMemoryStatus.nativeFailure);
      expect(result.error, isA<UnsupportedError>());
    });
  });

  group('Method dispose() behaves correctly', () {
    test(
      'Method dispose() rejects execution before any collaborator or memory call',
      () async {
        var discoveryCalls = 0;
        var metadataCalls = 0;
        var detectionCalls = 0;
        var baseResolutionCalls = 0;
        final api = FakeWindowsMemoryApi();
        final service = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () {
            discoveryCalls++;
            return const [42];
          },
          readProcessMetadata: (_) {
            metadataCalls++;
            return _metadata;
          },
          detectGame: (_, __) {
            detectionCalls++;
            return _confirmedIdentity;
          },
          resolveMemoryBaseCandidate: (_) {
            baseResolutionCalls++;
            return const Rpcs3MemoryBaseCandidate(
              memoryBase: 0x300000000,
              logPath: r'C:\RPCS3\log\RPCS3.log',
            );
          },
        );

        final firstDisposal = service.dispose();
        var disposalCompleted = false;
        firstDisposal.then((_) => disposalCompleted = true);
        final secondDisposal = service.dispose();
        expect(secondDisposal, same(firstDisposal));
        expect(disposalCompleted, isFalse);
        expect(() => service.execute(_readRequest()), throwsStateError);
        expect(discoveryCalls, 0);
        expect(metadataCalls, 0);
        expect(detectionCalls, 0);
        expect(baseResolutionCalls, 0);
        expect(api.openCalls, 0);
        expect(api.readCalls, 0);
        expect(api.writeCalls, 0);

        await firstDisposal;
      },
    );

    test(
      'Method dispose() stops identity checks when discovery disposes the service',
      () async {
        late DiagnosticGameMemoryService service;
        Future<void>? disposal;
        var metadataCalls = 0;
        var detectionCalls = 0;
        final api = FakeWindowsMemoryApi();
        service = _createService(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () {
            disposal = service.dispose();
            return const [42];
          },
          readProcessMetadata: (_) {
            metadataCalls++;
            return _metadata;
          },
          detectGame: (_, __) {
            detectionCalls++;
            return _confirmedIdentity;
          },
        );

        expect(() => service.execute(_readRequest()), throwsStateError);
        expect(metadataCalls, 0);
        expect(detectionCalls, 0);
        expect(api.openCalls, 0);
        expect(api.readCalls, 0);
        expect(api.writeCalls, 0);

        expect(disposal, isNotNull);
        await disposal!;
      },
    );
  });
}
