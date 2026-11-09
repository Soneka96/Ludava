import 'package:ludava_sdk/features/game_memory/data/process_game_memory_operation_result.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class ProcessGameMemoryOperationResult construction', () {
    test(
      'Class ProcessGameMemoryOperationResult preserves operation outcomes',
      () {
        final readResult = GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
          value: 61,
        );
        final writeResult = GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'credits',
          requestedValue: 61,
          readBackValue: 61,
        );
        final operationError = StateError('read failed');
        final cleanupError = StateError('close failed');

        final result = ProcessGameMemoryOperationResult(
          readResult: readResult,
          writeResult: writeResult,
          operationError: operationError,
          cleanupError: cleanupError,
        );

        expect(result.readResult, same(readResult));
        expect(result.writeResult, same(writeResult));
        expect(result.operationError, same(operationError));
        expect(result.cleanupError, same(cleanupError));
      },
    );
  });
}
