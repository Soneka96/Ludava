import 'package:ludava_sdk/features/game_memory/domain/entities/memory_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/memory_write_result.entity.dart';

/// Reads checked byte ranges for game-memory operations.
abstract interface class IGameMemoryRepository {
  /// Reads [byteCount] bytes starting at [address].
  MemoryReadResult read(int address, int byteCount);

  /// Writes [bytes] starting at [address].
  ///
  /// The write use case checks profile and field eligibility, value bounds,
  /// explicit confirmation, native transfer, and read-back around this call.
  MemoryWriteResult write(int address, List<int> bytes);
}
