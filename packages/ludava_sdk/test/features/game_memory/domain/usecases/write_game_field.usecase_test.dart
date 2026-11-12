import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/memory_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/memory_write_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/repositories/Igame_memory.repository.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/params/write_game_field.params.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/write_game_field.usecase.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

class _WriteGameFieldTestRepository implements IGameMemoryRepository {
  int readCalls = 0;
  int writeCalls = 0;
  int? lastReadAddress;
  int? lastReadByteCount;
  int? lastWriteAddress;
  List<int>? writtenBytes;

  _WriteGameFieldTestRepository({
    MemoryReadResult? readResult,
    List<MemoryReadResult>? readResults,
    MemoryWriteResult? writeResult,
  }) : _readResults =
           readResults ??
           [
             readResult ??
                 MemoryReadResult(
                   status: MemoryReadStatus.complete,
                   bytes: [0, 0, 0, 42],
                   bytesRead: 4,
                   requestedBytes: 4,
                 ),
           ],
       _writeResult =
           writeResult ??
           const MemoryWriteResult(
             status: MemoryWriteStatus.complete,
             bytesWritten: 4,
             requestedBytes: 4,
           );

  final List<MemoryReadResult> _readResults;
  final MemoryWriteResult _writeResult;

  static WriteGameFieldParams params({
    int? minimumValue = 0,
    int? maximumValue = 100,
    int value = 42,
    int memoryBase = 0x300000000,
    bool confirmed = true,
    String fieldId = 'credits',
  }) => WriteGameFieldParams(
    profile: GameProfile(
      id: 'synthetic-profile',
      gameName: 'Test game',
      buildId: 'TEST',
      executable: 'test.exe',
      fields: {
        'credits': GameField(
          id: 'credits',
          name: 'Credits',
          guestOffset: 0x1234,
          valueType: MemoryValueType.unsigned32,
          byteOrder: ByteOrder.big,
          minimumValue: minimumValue,
          maximumValue: maximumValue,
        ),
      },
    ),
    fieldId: fieldId,
    memoryBase: memoryBase,
    value: value,
    confirmed: confirmed,
  );

  @override
  MemoryReadResult read(int address, int byteCount) {
    final index = readCalls;
    readCalls++;
    lastReadAddress = address;
    lastReadByteCount = byteCount;
    return _readResults[index < _readResults.length
        ? index
        : _readResults.length - 1];
  }

  @override
  MemoryWriteResult write(int address, List<int> bytes) {
    writeCalls++;
    lastWriteAddress = address;
    writtenBytes = List.unmodifiable(bytes);
    return _writeResult;
  }
}

MemoryReadResult _completeRead(int value) => MemoryReadResult(
  status: MemoryReadStatus.complete,
  bytes: [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ],
  bytesRead: 4,
  requestedBytes: 4,
);

void main() {
  group('Method execute() behaves correctly', () {
    test(
      'Method execute() requires explicit confirmation before reading memory',
      () {
        final repository = _WriteGameFieldTestRepository();
        final result = WriteGameFieldUseCase(repository).execute(
          _WriteGameFieldTestRepository.params(
            memoryBase: 0x310000000,
            maximumValue: 1000,
            value: 123,
            confirmed: false,
          ),
        );

        expect(result.status, GameWriteStatus.confirmationRequired);
        expect(repository.readCalls, 0);
        expect(repository.writeCalls, 0);
      },
    );

    test(
      'Method execute() writes a synthetic field through the guarded read-back path',
      () {
        final repository = _WriteGameFieldTestRepository(
          readResults: [_completeRead(4903), _completeRead(4904)],
        );
        final result = WriteGameFieldUseCase(repository).execute(
          _WriteGameFieldTestRepository.params(
            memoryBase: 0x300000000,
            maximumValue: 5000,
            value: 4904,
            confirmed: true,
          ),
        );

        expect(result.status, GameWriteStatus.success);
        expect(result.readBackValue, 4904);
        expect(repository.readCalls, 2);
        expect(repository.writeCalls, 1);
        expect(repository.lastReadAddress, 0x300001234);
        expect(repository.lastWriteAddress, 0x300001234);
        expect(repository.lastReadByteCount, 4);
        expect(repository.writtenBytes, [0, 0, 0x13, 0x28]);
      },
    );

    test('Method execute() requires explicit confirmation before writing', () {
      final repository = _WriteGameFieldTestRepository();

      final result = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params(confirmed: false));

      expect(result.status, GameWriteStatus.confirmationRequired);
      expect(repository.writeCalls, 0);
      expect(repository.readCalls, 0);
    });

    test('Method execute() rejects missing fields before memory access', () {
      final repository = _WriteGameFieldTestRepository();
      final useCase = WriteGameFieldUseCase(repository);
      final missingField = useCase.execute(
        _WriteGameFieldTestRepository.params(fieldId: 'missing'),
      );

      expect(missingField.status, GameWriteStatus.unsupportedField);
      expect(repository.writeCalls, 0);
      expect(repository.readCalls, 0);
    });

    test('Method execute() rejects values without a verified safe range', () {
      final repository = _WriteGameFieldTestRepository();
      final missingBounds = WriteGameFieldUseCase(repository).execute(
        _WriteGameFieldTestRepository.params(
          minimumValue: null,
          maximumValue: null,
        ),
      );
      final belowMinimum = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params(value: -1));
      final aboveMaximum = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params(value: 101));

      expect(missingBounds.status, GameWriteStatus.invalidValue);
      expect(belowMinimum.status, GameWriteStatus.invalidValue);
      expect(aboveMaximum.status, GameWriteStatus.invalidValue);
      expect(repository.writeCalls, 0);
    });

    test('Method execute() accepts research-confirmed profile and field', () {
      final repository = _WriteGameFieldTestRepository(
        readResult: MemoryReadResult(
          status: MemoryReadStatus.complete,
          bytes: [0, 0, 0, 42],
          bytesRead: 4,
          requestedBytes: 4,
        ),
      );

      final result = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params());

      expect(result.status, GameWriteStatus.success);
      expect(repository.writeCalls, 1);
      expect(repository.readCalls, 2);
    });

    test('Method execute() accepts a preliminary read containing zero', () {
      final repository = _WriteGameFieldTestRepository(
        readResults: [
          MemoryReadResult(
            status: MemoryReadStatus.complete,
            bytes: [0, 0, 0, 0],
            bytesRead: 4,
            requestedBytes: 4,
          ),
          MemoryReadResult(
            status: MemoryReadStatus.complete,
            bytes: [0, 0, 0, 42],
            bytesRead: 4,
            requestedBytes: 4,
          ),
        ],
      );

      final result = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params(value: 42));

      expect(result.status, GameWriteStatus.success);
      expect(repository.readCalls, 2);
      expect(repository.writeCalls, 1);
    });

    test(
      'Method execute() rejects failed and incomplete preliminary reads',
      () {
        final failedRead = _WriteGameFieldTestRepository(
          readResult: MemoryReadResult(
            status: MemoryReadStatus.nativeFailure,
            bytes: [],
            bytesRead: 0,
            requestedBytes: 4,
            errorCode: 299,
          ),
        );
        final incompleteRead = _WriteGameFieldTestRepository(
          readResult: MemoryReadResult(
            status: MemoryReadStatus.partial,
            bytes: [0, 0],
            bytesRead: 2,
            requestedBytes: 4,
          ),
        );

        final failed = WriteGameFieldUseCase(
          failedRead,
        ).execute(_WriteGameFieldTestRepository.params());
        final incomplete = WriteGameFieldUseCase(
          incompleteRead,
        ).execute(_WriteGameFieldTestRepository.params());

        expect(failed.status, GameWriteStatus.preliminaryReadFailed);
        expect(failed.errorCode, 299);
        expect(failedRead.readCalls, 1);
        expect(failedRead.writeCalls, 0);
        expect(incomplete.status, GameWriteStatus.preliminaryReadFailed);
        expect(incompleteRead.readCalls, 1);
        expect(incompleteRead.writeCalls, 0);
      },
    );

    test('Method execute() rejects invalid preliminary read data', () {
      final inconsistentRead = _WriteGameFieldTestRepository(
        readResult: MemoryReadResult(
          status: MemoryReadStatus.complete,
          bytes: [0, 0],
          bytesRead: 4,
          requestedBytes: 4,
        ),
      );
      final invalidByte = _WriteGameFieldTestRepository(
        readResult: MemoryReadResult(
          status: MemoryReadStatus.complete,
          bytes: [0, 0, 0, 300],
          bytesRead: 4,
          requestedBytes: 4,
        ),
      );

      final inconsistent = WriteGameFieldUseCase(
        inconsistentRead,
      ).execute(_WriteGameFieldTestRepository.params());
      final invalid = WriteGameFieldUseCase(
        invalidByte,
      ).execute(_WriteGameFieldTestRepository.params());

      expect(inconsistent.status, GameWriteStatus.preliminaryReadFailed);
      expect(inconsistentRead.readCalls, 1);
      expect(inconsistentRead.writeCalls, 0);
      expect(invalid.status, GameWriteStatus.preliminaryReadFailed);
      expect(invalidByte.readCalls, 1);
      expect(invalidByte.writeCalls, 0);
    });

    test(
      'Method execute() rejects a preliminary value outside the field range',
      () {
        final repository = _WriteGameFieldTestRepository(
          readResult: _completeRead(101),
        );

        final result = WriteGameFieldUseCase(
          repository,
        ).execute(_WriteGameFieldTestRepository.params());

        expect(result.status, GameWriteStatus.preliminaryReadFailed);
        expect(repository.readCalls, 1);
        expect(repository.writeCalls, 0);
      },
    );

    test('Method execute() rejects invalid mappings before writing', () {
      final repository = _WriteGameFieldTestRepository();

      final result = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params(memoryBase: -1));

      expect(result.status, GameWriteStatus.invalidMapping);
      expect(repository.writeCalls, 0);
    });

    test(
      'Method execute() maps failed or partial writes without reading back',
      () {
        final failedRepository = _WriteGameFieldTestRepository(
          writeResult: const MemoryWriteResult(
            status: MemoryWriteStatus.nativeFailure,
            bytesWritten: 0,
            requestedBytes: 4,
            errorCode: 5,
          ),
        );
        final partialRepository = _WriteGameFieldTestRepository(
          writeResult: const MemoryWriteResult(
            status: MemoryWriteStatus.partial,
            bytesWritten: 2,
            requestedBytes: 4,
          ),
        );
        final params = _WriteGameFieldTestRepository.params();

        final failed = WriteGameFieldUseCase(failedRepository).execute(params);
        final partial = WriteGameFieldUseCase(
          partialRepository,
        ).execute(params);

        expect(failed.status, GameWriteStatus.writeFailed);
        expect(failed.errorCode, 5);
        expect(failedRepository.readCalls, 1);
        expect(partial.status, GameWriteStatus.incompleteWrite);
        expect(partialRepository.readCalls, 1);
      },
    );

    test('Method execute() maps an invalid write address before read-back', () {
      final repository = _WriteGameFieldTestRepository(
        writeResult: const MemoryWriteResult(
          status: MemoryWriteStatus.invalidAddress,
          bytesWritten: 0,
          requestedBytes: 4,
        ),
      );

      final result = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params());

      expect(result.status, GameWriteStatus.invalidMapping);
      expect(repository.readCalls, 1);
    });

    test('Method execute() rejects non-transfer write results', () {
      for (final status in [
        MemoryWriteStatus.none,
        MemoryWriteStatus.invalidRequest,
        MemoryWriteStatus.invalidByteCount,
      ]) {
        final repository = _WriteGameFieldTestRepository(
          writeResult: MemoryWriteResult(
            status: status,
            bytesWritten: 0,
            requestedBytes: 4,
          ),
        );

        final result = WriteGameFieldUseCase(
          repository,
        ).execute(_WriteGameFieldTestRepository.params());

        expect(result.status, GameWriteStatus.invalidWriteResult);
        expect(repository.readCalls, 1);
      }
    });

    test('Method execute() rejects impossible native write results', () {
      final repository = _WriteGameFieldTestRepository(
        writeResult: const MemoryWriteResult(
          status: MemoryWriteStatus.complete,
          bytesWritten: 3,
          requestedBytes: 4,
        ),
      );

      final result = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params());

      expect(result.status, GameWriteStatus.invalidWriteResult);
      expect(repository.readCalls, 1);
    });

    test('Method execute() reports read-back failures and mismatches', () {
      final failedReadBack = _WriteGameFieldTestRepository(
        readResults: [
          _completeRead(42),
          MemoryReadResult(
            status: MemoryReadStatus.nativeFailure,
            bytes: [],
            bytesRead: 0,
            requestedBytes: 4,
            errorCode: 299,
          ),
        ],
      );
      final partialReadBack = _WriteGameFieldTestRepository(
        readResults: [
          _completeRead(42),
          MemoryReadResult(
            status: MemoryReadStatus.partial,
            bytes: [0, 0],
            bytesRead: 2,
            requestedBytes: 4,
          ),
        ],
      );
      final invalidAddressReadBack = _WriteGameFieldTestRepository(
        readResults: [
          _completeRead(42),
          MemoryReadResult(
            status: MemoryReadStatus.invalidAddress,
            bytes: [],
            bytesRead: 0,
            requestedBytes: 4,
          ),
        ],
      );
      final mismatch = _WriteGameFieldTestRepository(
        readResults: [_completeRead(42), _completeRead(41)],
      );
      final params = _WriteGameFieldTestRepository.params(value: 42);

      final failed = WriteGameFieldUseCase(failedReadBack).execute(params);
      final partial = WriteGameFieldUseCase(partialReadBack).execute(params);
      final invalidAddress = WriteGameFieldUseCase(
        invalidAddressReadBack,
      ).execute(params);
      final mismatched = WriteGameFieldUseCase(mismatch).execute(params);

      expect(failed.status, GameWriteStatus.readBackFailed);
      expect(failed.errorCode, 299);
      expect(partial.status, GameWriteStatus.readBackFailed);
      expect(invalidAddress.status, GameWriteStatus.readBackFailed);
      expect(mismatched.status, GameWriteStatus.readBackMismatch);
      expect(mismatched.readBackValue, 41);
    });

    test('Method execute() rejects malformed read-back results', () {
      final invalidRequest = _WriteGameFieldTestRepository(
        readResults: [
          _completeRead(42),
          MemoryReadResult(
            status: MemoryReadStatus.invalidRequest,
            bytes: [],
            bytesRead: 0,
            requestedBytes: 4,
          ),
        ],
      );
      final impossibleCount = _WriteGameFieldTestRepository(
        readResults: [
          _completeRead(42),
          MemoryReadResult(
            status: MemoryReadStatus.complete,
            bytes: [0, 0],
            bytesRead: 2,
            requestedBytes: 4,
          ),
        ],
      );
      final invalidByteCount = _WriteGameFieldTestRepository(
        readResults: [
          _completeRead(42),
          MemoryReadResult(
            status: MemoryReadStatus.invalidByteCount,
            bytes: [],
            bytesRead: 5,
            requestedBytes: 4,
          ),
        ],
      );
      final params = _WriteGameFieldTestRepository.params(value: 42);

      final invalid = WriteGameFieldUseCase(invalidRequest).execute(params);
      final inconsistent = WriteGameFieldUseCase(
        impossibleCount,
      ).execute(params);
      final invalidCount = WriteGameFieldUseCase(
        invalidByteCount,
      ).execute(params);

      expect(invalid.status, GameWriteStatus.invalidWriteResult);
      expect(inconsistent.status, GameWriteStatus.invalidWriteResult);
      expect(invalidCount.status, GameWriteStatus.invalidWriteResult);
      expect(invalidRequest.writeCalls, 1);
      expect(impossibleCount.writeCalls, 1);
      expect(invalidByteCount.writeCalls, 1);
    });

    test('Method execute() succeeds only after a matching read-back', () {
      final repository = _WriteGameFieldTestRepository(
        readResult: MemoryReadResult(
          status: MemoryReadStatus.complete,
          bytes: [0, 0, 0, 42],
          bytesRead: 4,
          requestedBytes: 4,
        ),
      );

      final result = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params(value: 42));

      expect(result.status, GameWriteStatus.success);
      expect(result.succeeded, isTrue);
      expect(result.requestedValue, 42);
      expect(result.readBackValue, 42);
      expect(repository.writtenBytes, [0, 0, 0, 42]);
      expect(repository.lastWriteAddress, 0x300001234);
      expect(repository.readCalls, 2);
      expect(repository.lastReadAddress, 0x300001234);
      expect(repository.lastReadByteCount, 4);
    });

    test('Method execute() accepts the inclusive minimum value', () {
      final repository = _WriteGameFieldTestRepository(
        readResult: MemoryReadResult(
          status: MemoryReadStatus.complete,
          bytes: [0, 0, 0, 0],
          bytesRead: 4,
          requestedBytes: 4,
        ),
      );

      final result = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params(value: 0));

      expect(result.status, GameWriteStatus.success);
      expect(repository.writtenBytes, [0, 0, 0, 0]);
    });

    test('Method execute() accepts the inclusive maximum value', () {
      final repository = _WriteGameFieldTestRepository(
        readResult: MemoryReadResult(
          status: MemoryReadStatus.complete,
          bytes: [0, 0, 0, 100],
          bytesRead: 4,
          requestedBytes: 4,
        ),
      );

      final result = WriteGameFieldUseCase(
        repository,
      ).execute(_WriteGameFieldTestRepository.params(value: 100));

      expect(result.status, GameWriteStatus.success);
      expect(repository.writtenBytes, [0, 0, 0, 100]);
    });
  });
}
