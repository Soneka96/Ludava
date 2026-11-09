import 'package:ludava_sdk/features/trainer/application/diagnostics/diagnostic_game_memory_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Property succeeded behaves correctly', () {
    test('Property succeeded returns true for a completed read', () {
      const result = DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.completed,
        readResult: GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
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
          fieldId: 'credits',
        ),
      );

      expect(result.succeeded, isFalse);
    });

    test('Property succeeded returns true for a completed verified write', () {
      const result = DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.completed,
        writeResult: GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'credits',
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
          fieldId: 'credits',
          requestedValue: 50,
          readBackValue: 49,
        ),
      );

      expect(result.succeeded, isFalse);
    });
  });
}
