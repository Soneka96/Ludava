import 'package:ludava/features/game_memory/domain/entities/memory_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/memory_write_result.entity.dart';

/// Reads checked byte ranges for game-memory operations.
abstract interface class IGameMemoryRepository {
  /// Reads [byteCount] bytes starting at [address].
  MemoryReadResult read(int address, int byteCount);

  /// Writes [bytes] starting at [address].
  ///
  /// Only a write use case that verifies the profile, field, value range,
  /// active build, user confirmation, and read-back may call this low-level
  /// operation.
  MemoryWriteResult write(int address, List<int> bytes);
}
