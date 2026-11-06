import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/memory_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/memory_write_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/repositories/Igame_memory.repository.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/params/read_game_field.params.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/read_game_field.usecase.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Method execute() behaves correctly', () {
    test('Method execute() reads and decodes an eligible field', () {
      final repository = _ReadGameFieldTestData.repository(
        readResult: MemoryReadResult(
          status: MemoryReadStatus.complete,
          bytes: [0, 0, 0, 42],
          bytesRead: 4,
          requestedBytes: 4,
        ),
      );
      final result = ReadGameFieldUseCase(repository).execute(
        ReadGameFieldParams(
          profile: _ReadGameFieldTestData.profile(),
          fieldId: 'bolts',
          memoryBase: 0x300000000,
        ),
      );

      expect(result.status, GameReadStatus.success);
      expect(result.succeeded, isTrue);
      expect(result.fieldId, 'bolts');
      expect(result.value, 42);
      expect(repository.lastAddress, 0x301329e80);
      expect(repository.lastByteCount, 4);
    });

    test('Method execute() preserves a successfully read zero value', () {
      final repository = _ReadGameFieldTestData.repository(
        readResult: MemoryReadResult(
          status: MemoryReadStatus.complete,
          bytes: [0, 0, 0, 0],
          bytesRead: 4,
          requestedBytes: 4,
        ),
      );
      final result = ReadGameFieldUseCase(repository).execute(
        ReadGameFieldParams(
          profile: _ReadGameFieldTestData.profile(),
          fieldId: 'bolts',
          memoryBase: 0x300000000,
        ),
      );

      expect(result.succeeded, isTrue);
      expect(result.value, 0);
    });

    test('Method execute() rejects unsupported profiles before reading', () {
      final repository = _ReadGameFieldTestData.repository();
      final profile = _ReadGameFieldTestData.profile(
        readStatus: VerificationStatus.unsupported,
      );

      final result = ReadGameFieldUseCase(repository).execute(
        ReadGameFieldParams(
          profile: profile,
          fieldId: 'bolts',
          memoryBase: 0x300000000,
        ),
      );

      expect(result.status, GameReadStatus.unsupportedProfile);
      expect(repository.readCalls, 0);
    });

    test(
      'Method execute() rejects missing or unapproved fields before reading',
      () {
        final repository = _ReadGameFieldTestData.repository();
        final profile = _ReadGameFieldTestData.profile(
          fieldReadStatus: VerificationStatus.unsupported,
        );

        final unsupported = ReadGameFieldUseCase(repository).execute(
          ReadGameFieldParams(
            profile: profile,
            fieldId: 'bolts',
            memoryBase: 0x300000000,
          ),
        );
        final missing = ReadGameFieldUseCase(repository).execute(
          ReadGameFieldParams(
            profile: profile,
            fieldId: 'health',
            memoryBase: 0x300000000,
          ),
        );

        expect(unsupported.status, GameReadStatus.unsupportedField);
        expect(missing.status, GameReadStatus.unsupportedField);
        expect(repository.readCalls, 0);
      },
    );

    test('Method execute() rejects invalid mappings before reading', () {
      final repository = _ReadGameFieldTestData.repository();

      final result = ReadGameFieldUseCase(repository).execute(
        ReadGameFieldParams(
          profile: _ReadGameFieldTestData.profile(),
          fieldId: 'bolts',
          memoryBase: -1,
        ),
      );

      expect(result.status, GameReadStatus.invalidMapping);
      expect(repository.readCalls, 0);
    });

    test(
      'Method execute() maps failed and partial reads to explicit outcomes',
      () {
        final failedRepository = _ReadGameFieldTestData.repository(
          readResult: MemoryReadResult(
            status: MemoryReadStatus.nativeFailure,
            bytes: [],
            bytesRead: 0,
            requestedBytes: 4,
            errorCode: 299,
          ),
        );
        final partialRepository = _ReadGameFieldTestData.repository(
          readResult: MemoryReadResult(
            status: MemoryReadStatus.partial,
            bytes: [0, 0],
            bytesRead: 2,
            requestedBytes: 4,
          ),
        );
        final params = ReadGameFieldParams(
          profile: _ReadGameFieldTestData.profile(),
          fieldId: 'bolts',
          memoryBase: 0x300000000,
        );

        final failed = ReadGameFieldUseCase(failedRepository).execute(params);
        final partial = ReadGameFieldUseCase(partialRepository).execute(params);

        expect(failed.status, GameReadStatus.readFailed);
        expect(failed.errorCode, 299);
        expect(failed.value, isNull);
        expect(partial.status, GameReadStatus.incompleteRead);
        expect(partial.value, isNull);
      },
    );

    test(
      'Method execute() rejects inconsistent and unsupported value data',
      () {
        final inconsistentRepository = _ReadGameFieldTestData.repository(
          readResult: MemoryReadResult(
            status: MemoryReadStatus.complete,
            bytes: [0, 0],
            bytesRead: 2,
            requestedBytes: 4,
          ),
        );
        final unsupportedTypeRepository = _ReadGameFieldTestData.repository();
        final unsupportedTypeProfile = _ReadGameFieldTestData.profile(
          valueType: MemoryValueType.none,
        );
        final unsupportedByteOrderRepository =
            _ReadGameFieldTestData.repository(
              readResult: MemoryReadResult(
                status: MemoryReadStatus.complete,
                bytes: [0, 0, 0, 42],
                bytesRead: 4,
                requestedBytes: 4,
              ),
            );
        final unsupportedByteOrderProfile = _ReadGameFieldTestData.profile(
          byteOrder: ByteOrder.none,
        );
        final params =
            (GameProfile profile) => ReadGameFieldParams(
              profile: profile,
              fieldId: 'bolts',
              memoryBase: 0x300000000,
            );

        final inconsistent = ReadGameFieldUseCase(
          inconsistentRepository,
        ).execute(params(_ReadGameFieldTestData.profile()));
        final unsupportedType = ReadGameFieldUseCase(
          unsupportedTypeRepository,
        ).execute(params(unsupportedTypeProfile));
        final unsupportedByteOrder = ReadGameFieldUseCase(
          unsupportedByteOrderRepository,
        ).execute(params(unsupportedByteOrderProfile));

        expect(inconsistent.status, GameReadStatus.invalidReadResult);
        expect(unsupportedType.status, GameReadStatus.invalidReadResult);
        expect(unsupportedTypeRepository.readCalls, 0);
        expect(unsupportedByteOrder.status, GameReadStatus.invalidReadResult);
        expect(unsupportedByteOrder.value, isNull);
      },
    );
  });
}

class _ReadGameFieldTestData implements IGameMemoryRepository {
  int readCalls = 0;
  int? lastAddress;
  int? lastByteCount;

  _ReadGameFieldTestData([MemoryReadResult? readResult])
    : _readResult =
          readResult ??
          MemoryReadResult(
            status: MemoryReadStatus.complete,
            bytes: [0, 0, 0, 42],
            bytesRead: 4,
            requestedBytes: 4,
          );

  final MemoryReadResult _readResult;

  static GameProfile profile({
    VerificationStatus readStatus = VerificationStatus.experimental,
    VerificationStatus fieldReadStatus = VerificationStatus.experimental,
    MemoryValueType valueType = MemoryValueType.unsigned32,
    ByteOrder byteOrder = ByteOrder.big,
  }) => GameProfile(
    id: 'rc2-test',
    gameName: 'Test game',
    buildId: 'TEST',
    executable: 'test.exe',
    readStatus: readStatus,
    fields: {
      'bolts': GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x1329e80,
        valueType: valueType,
        byteOrder: byteOrder,
        readStatus: fieldReadStatus,
      ),
    },
  );

  static _ReadGameFieldTestData repository({MemoryReadResult? readResult}) =>
      _ReadGameFieldTestData(readResult);

  @override
  MemoryReadResult read(int address, int byteCount) {
    readCalls++;
    lastAddress = address;
    lastByteCount = byteCount;
    return _readResult;
  }

  @override
  MemoryWriteResult write(int address, List<int> bytes) => MemoryWriteResult(
    status: MemoryWriteStatus.invalidRequest,
    bytesWritten: 0,
    requestedBytes: bytes.length,
  );
}
