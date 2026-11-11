import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/memory_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/repositories/Igame_memory.repository.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/params/read_game_field.params.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/read_game_field.usecase.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockGameMemoryRepository extends Mock implements IGameMemoryRepository {}

GameProfile _profile({
  MemoryValueType valueType = MemoryValueType.unsigned32,
  ByteOrder byteOrder = ByteOrder.big,
}) => GameProfile(
  id: 'synthetic-profile',
  gameName: 'Test game',
  buildId: 'TEST',
  executable: 'test.exe',
  fields: {
    'credits': GameField(
      id: 'credits',
      name: 'Credits',
      guestOffset: 0x1234,
      valueType: valueType,
      byteOrder: byteOrder,
    ),
  },
);

ReadGameFieldParams _params({
  GameProfile? profile,
  int memoryBase = 0x300000000,
  String fieldId = 'credits',
}) => ReadGameFieldParams(
  profile: profile ?? _profile(),
  fieldId: fieldId,
  memoryBase: memoryBase,
);

MemoryReadResult _completeRead(List<int> bytes) => MemoryReadResult(
  status: MemoryReadStatus.complete,
  bytes: bytes,
  bytesRead: bytes.length,
  requestedBytes: bytes.length,
);

void main() {
  group('Method execute() behaves correctly', () {
    test(
      'Method execute() reads four big-endian bytes at a synthetic session-relative address',
      () {
        final repository = _MockGameMemoryRepository();
        when(
          () => repository.read(0x310001234, 4),
        ).thenReturn(_completeRead([0, 1, 0x23, 0x45]));

        final result = ReadGameFieldUseCase(
          repository,
        ).execute(_params(memoryBase: 0x310000000));

        expect(result.status, GameReadStatus.success);
        expect(result.succeeded, isTrue);
        expect(result.fieldId, 'credits');
        expect(result.value, 0x00012345);
        verify(() => repository.read(0x310001234, 4)).called(1);
      },
    );

    test('Method execute() preserves a successfully read zero value', () {
      final repository = _MockGameMemoryRepository();
      when(
        () => repository.read(0x300001234, 4),
      ).thenReturn(_completeRead([0, 0, 0, 0]));

      final result = ReadGameFieldUseCase(repository).execute(_params());

      expect(result.succeeded, isTrue);
      expect(result.value, 0);
      verify(() => repository.read(0x300001234, 4)).called(1);
    });

    test('Method execute() rejects missing fields before reading', () {
      final repository = _MockGameMemoryRepository();
      final missingField = ReadGameFieldUseCase(
        repository,
      ).execute(_params(fieldId: 'missing'));
      final missing = ReadGameFieldUseCase(
        repository,
      ).execute(_params(fieldId: 'also-missing'));

      expect(missingField.status, GameReadStatus.unsupportedField);
      expect(missing.status, GameReadStatus.unsupportedField);
      verifyNever(() => repository.read(any(), any()));
    });

    test(
      'Method execute() rejects negative and overflowing mappings before reading',
      () {
        final repository = _MockGameMemoryRepository();
        final useCase = ReadGameFieldUseCase(repository);
        final negativeBase = useCase.execute(_params(memoryBase: -1));
        final overflowingOffset = useCase.execute(
          _params(memoryBase: 0x7FFFFFFFFFFFFFFF - 0x1233),
        );
        final overflowingRange = useCase.execute(
          _params(memoryBase: 0x7FFFFFFFFFFFFFFF - 0x1234 - 2),
        );

        expect(negativeBase.status, GameReadStatus.invalidMapping);
        expect(overflowingOffset.status, GameReadStatus.invalidMapping);
        expect(overflowingRange.status, GameReadStatus.invalidMapping);
        verifyNever(() => repository.read(any(), any()));
      },
    );

    test(
      'Method execute() maps failed and partial reads to explicit outcomes',
      () {
        final failedRepository = _MockGameMemoryRepository();
        when(() => failedRepository.read(0x300001234, 4)).thenReturn(
          MemoryReadResult(
            status: MemoryReadStatus.nativeFailure,
            bytes: [],
            bytesRead: 0,
            requestedBytes: 4,
            errorCode: 299,
          ),
        );
        final partialRepository = _MockGameMemoryRepository();
        when(() => partialRepository.read(0x300001234, 4)).thenReturn(
          MemoryReadResult(
            status: MemoryReadStatus.partial,
            bytes: [0, 0],
            bytesRead: 2,
            requestedBytes: 4,
          ),
        );

        final failed = ReadGameFieldUseCase(
          failedRepository,
        ).execute(_params());
        final partial = ReadGameFieldUseCase(
          partialRepository,
        ).execute(_params());

        expect(failed.status, GameReadStatus.readFailed);
        expect(failed.errorCode, 299);
        expect(failed.value, isNull);
        expect(partial.status, GameReadStatus.incompleteRead);
        expect(partial.value, isNull);
        verify(() => failedRepository.read(0x300001234, 4)).called(1);
        verify(() => partialRepository.read(0x300001234, 4)).called(1);
      },
    );

    test(
      'Method execute() rejects inconsistent and unsupported value data',
      () {
        final inconsistentRepository = _MockGameMemoryRepository();
        when(() => inconsistentRepository.read(0x300001234, 4)).thenReturn(
          MemoryReadResult(
            status: MemoryReadStatus.complete,
            bytes: [0, 0],
            bytesRead: 2,
            requestedBytes: 4,
          ),
        );
        final unsupportedTypeRepository = _MockGameMemoryRepository();
        final unsupportedByteOrderRepository = _MockGameMemoryRepository();
        when(
          () => unsupportedByteOrderRepository.read(0x300001234, 4),
        ).thenReturn(_completeRead([0, 0, 0, 42]));

        final inconsistent = ReadGameFieldUseCase(
          inconsistentRepository,
        ).execute(_params());
        final unsupportedType = ReadGameFieldUseCase(
          unsupportedTypeRepository,
        ).execute(_params(profile: _profile(valueType: MemoryValueType.none)));
        final unsupportedByteOrder = ReadGameFieldUseCase(
          unsupportedByteOrderRepository,
        ).execute(_params(profile: _profile(byteOrder: ByteOrder.none)));

        expect(inconsistent.status, GameReadStatus.invalidReadResult);
        expect(unsupportedType.status, GameReadStatus.invalidReadResult);
        expect(unsupportedByteOrder.status, GameReadStatus.invalidReadResult);
        expect(unsupportedByteOrder.value, isNull);
        verifyNever(() => unsupportedTypeRepository.read(any(), any()));
        verify(() => inconsistentRepository.read(0x300001234, 4)).called(1);
        verify(
          () => unsupportedByteOrderRepository.read(0x300001234, 4),
        ).called(1);
      },
    );
  });
}
