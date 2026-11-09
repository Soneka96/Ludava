import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Property succeeded behaves correctly', () {
    test(
      'Property succeeded returns true when status and value indicate success',
      () {
        const result = GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
          value: 0,
        );

        expect(result.succeeded, isTrue);
      },
    );

    test('Property succeeded returns false when status is not success', () {
      const result = GameReadResult(
        status: GameReadStatus.readFailed,
        fieldId: 'credits',
        value: 100,
      );

      expect(result.succeeded, isFalse);
    });

    test(
      'Property succeeded returns false when successful status has no value',
      () {
        const result = GameReadResult(status: GameReadStatus.success);

        expect(result.succeeded, isFalse);
      },
    );

    test(
      'Property succeeded returns false when successful result has no field id',
      () {
        const result = GameReadResult(
          status: GameReadStatus.success,
          value: 10,
        );

        expect(result.succeeded, isFalse);
      },
    );

    test(
      'Property succeeded returns false when successful result has an empty field id',
      () {
        const result = GameReadResult(
          status: GameReadStatus.success,
          fieldId: '',
          value: 10,
        );

        expect(result.succeeded, isFalse);
      },
    );
  });
}
