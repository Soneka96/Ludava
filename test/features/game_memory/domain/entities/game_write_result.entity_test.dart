import 'package:ludava/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class GameWriteResult construction', () {
    test('Class GameWriteResult initializes status and optional evidence', () {
      const result = GameWriteResult(
        status: GameWriteStatus.readBackMismatch,
        fieldId: 'bolts',
        requestedValue: 100,
        readBackValue: 99,
        errorCode: 299,
      );

      expect(result.status, GameWriteStatus.readBackMismatch);
      expect(result.fieldId, 'bolts');
      expect(result.requestedValue, 100);
      expect(result.readBackValue, 99);
      expect(result.errorCode, 299);
    });
  });

  group('Method succeeded behaves correctly', () {
    test('Method succeeded returns true when read-back matches request', () {
      const result = GameWriteResult(
        status: GameWriteStatus.success,
        fieldId: 'bolts',
        requestedValue: 0,
        readBackValue: 0,
      );

      expect(result.succeeded, isTrue);
    });

    test('Method succeeded returns false when read-back differs from request',
        () {
      const result = GameWriteResult(
        status: GameWriteStatus.success,
        fieldId: 'bolts',
        requestedValue: 100,
        readBackValue: 99,
      );

      expect(result.succeeded, isFalse);
    });

    test('Method succeeded returns false when status is not success', () {
      const result = GameWriteResult(
        status: GameWriteStatus.writeFailed,
        fieldId: 'bolts',
        requestedValue: 100,
        readBackValue: 100,
      );

      expect(result.succeeded, isFalse);
    });

    test('Method succeeded returns false when field or request is missing', () {
      const noField = GameWriteResult(
        status: GameWriteStatus.success,
        requestedValue: 10,
        readBackValue: 10,
      );
      const noRequest = GameWriteResult(
        status: GameWriteStatus.success,
        fieldId: 'bolts',
        readBackValue: 10,
      );

      expect(noField.succeeded, isFalse);
      expect(noRequest.succeeded, isFalse);
    });

    test('Method succeeded returns false when field id is empty', () {
      const result = GameWriteResult(
        status: GameWriteStatus.success,
        fieldId: '',
        requestedValue: 10,
        readBackValue: 10,
      );

      expect(result.succeeded, isFalse);
    });

    test('Method succeeded returns false when read-back value is missing', () {
      const result = GameWriteResult(
        status: GameWriteStatus.success,
        fieldId: 'bolts',
        requestedValue: 10,
      );

      expect(result.succeeded, isFalse);
    });
  });
}
