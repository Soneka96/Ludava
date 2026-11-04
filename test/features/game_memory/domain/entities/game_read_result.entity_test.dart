import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class GameReadResult construction', () {
    test('Class GameReadResult initializes status and optional details', () {
      const result = GameReadResult(
        status: GameReadStatus.readFailed,
        fieldId: 'bolts',
        errorCode: 299,
      );

      expect(result.status, GameReadStatus.readFailed);
      expect(result.fieldId, 'bolts');
      expect(result.value, isNull);
      expect(result.errorCode, 299);
    });
  });

  group('Method succeeded behaves correctly', () {
    test('Method succeeded returns true when status and value indicate success',
        () {
      const result = GameReadResult(
        status: GameReadStatus.success,
        fieldId: 'bolts',
        value: 0,
      );

      expect(result.succeeded, isTrue);
    });

    test('Method succeeded returns false when status is not success', () {
      const result = GameReadResult(
        status: GameReadStatus.readFailed,
        fieldId: 'bolts',
        value: 100,
      );

      expect(result.succeeded, isFalse);
    });

    test('Method succeeded returns false when successful status has no value',
        () {
      const result = GameReadResult(status: GameReadStatus.success);

      expect(result.succeeded, isFalse);
    });

    test(
        'Method succeeded returns false when successful result has no field id',
        () {
      const result = GameReadResult(
        status: GameReadStatus.success,
        value: 10,
      );

      expect(result.succeeded, isFalse);
    });

    test(
        'Method succeeded returns false when successful result has an empty field id',
        () {
      const result = GameReadResult(
        status: GameReadStatus.success,
        fieldId: '',
        value: 10,
      );

      expect(result.succeeded, isFalse);
    });
  });
}
