import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

abstract final class _GameFieldTestData {
  static GameField build({int? minimumValue, int? maximumValue}) => GameField(
    id: 'credits',
    name: 'Credits',
    guestOffset: 0x1234,
    valueType: MemoryValueType.unsigned32,
    byteOrder: ByteOrder.big,
    minimumValue: minimumValue,
    maximumValue: maximumValue,
  );
}

void main() {
  group('Class GameField construction', () {
    test('Class GameField accepts valid inclusive unsigned bounds', () {
      final field = _GameFieldTestData.build(
        minimumValue: GameMemoryConstants.maxUnsigned32,
        maximumValue: GameMemoryConstants.maxUnsigned32,
      );

      expect(field.minimumValue, GameMemoryConstants.maxUnsigned32);
      expect(field.maximumValue, GameMemoryConstants.maxUnsigned32);
    });

    test(
      'Class GameField accepts zero and a non-degenerate unsigned range',
      () {
        final field = _GameFieldTestData.build(
          minimumValue: 0,
          maximumValue: 123,
        );

        expect(field.minimumValue, 0);
        expect(field.maximumValue, 123);
      },
    );

    test(
      'Class GameField rejects bounds outside the unsigned 32-bit range',
      () {
        expect(
          () => _GameFieldTestData.build(minimumValue: -1),
          throwsArgumentError,
        );
        expect(
          () => _GameFieldTestData.build(
            minimumValue: GameMemoryConstants.maxUnsigned32 + 1,
          ),
          throwsArgumentError,
        );
        expect(
          () => _GameFieldTestData.build(maximumValue: -1),
          throwsArgumentError,
        );
        expect(
          () => _GameFieldTestData.build(
            maximumValue: GameMemoryConstants.maxUnsigned32 + 1,
          ),
          throwsArgumentError,
        );
      },
    );

    test('Class GameField rejects an inverted value range', () {
      expect(
        () => _GameFieldTestData.build(minimumValue: 2, maximumValue: 1),
        throwsArgumentError,
      );
    });
  });
}
