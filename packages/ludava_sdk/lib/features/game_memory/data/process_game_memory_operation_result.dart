import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_write_result.entity.dart';

/// Holds one field operation result and any operation or cleanup failure.
class ProcessGameMemoryOperationResult {
  /// Result of the field read, when this operation was a read.
  final GameReadResult? readResult;

  /// Result of the field write, when this operation was a write.
  final GameWriteResult? writeResult;

  /// Native or platform error raised while executing the field operation.
  final Object? operationError;

  /// Native error raised while closing the operation's process handle.
  final Object? cleanupError;

  /// Creates a result for one field read or write operation.
  const ProcessGameMemoryOperationResult({
    this.readResult,
    this.writeResult,
    this.operationError,
    this.cleanupError,
  });
}
