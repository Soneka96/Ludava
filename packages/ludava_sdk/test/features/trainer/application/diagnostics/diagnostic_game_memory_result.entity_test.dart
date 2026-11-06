import 'package:ludava_sdk/features/trainer/application/diagnostics/diagnostic_game_memory_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class DiagnosticGameMemoryResult construction', () {
    test(
      'Class DiagnosticGameMemoryResult initializes structured operation details',
      () {
        const result = DiagnosticGameMemoryResult(
          status: DiagnosticGameMemoryStatus.identityMismatch,
          identityConfirmed: false,
        );

        expect(result.status, DiagnosticGameMemoryStatus.identityMismatch);
        expect(result.identityConfirmed, isFalse);
        expect(result.readResult, isNull);
        expect(result.writeResult, isNull);
        expect(result.error, isNull);
        expect(result.cleanupError, isNull);
      },
    );
  });

  group('Property succeeded behaves correctly', () {
    test('Property succeeded returns true for a completed read', () {
      const result = DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.completed,
        readResult: GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'bolts',
          value: 50,
        ),
      );

      expect(result.succeeded, isTrue);
    });

    test('Property succeeded returns false for a failed completed read', () {
      const result = DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.completed,
        readResult: GameReadResult(
          status: GameReadStatus.readFailed,
          fieldId: 'bolts',
        ),
      );

      expect(result.succeeded, isFalse);
    });

    test('Property succeeded returns true for a completed verified write', () {
      const result = DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.completed,
        writeResult: GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'bolts',
          requestedValue: 50,
          readBackValue: 50,
        ),
      );

      expect(result.succeeded, isTrue);
    });

    test('Property succeeded returns false when the operation is blocked', () {
      const result = DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.identityMismatch,
      );

      expect(result.succeeded, isFalse);
    });

    test('Property succeeded returns false for a failed verified write', () {
      const result = DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.completed,
        writeResult: GameWriteResult(
          status: GameWriteStatus.readBackMismatch,
          fieldId: 'bolts',
          requestedValue: 50,
          readBackValue: 49,
        ),
      );

      expect(result.succeeded, isFalse);
    });
  });
}
