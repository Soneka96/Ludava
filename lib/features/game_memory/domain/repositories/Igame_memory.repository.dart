import 'package:ludava/features/game_memory/domain/entities/memory_read_result.entity.dart';

/// Reads checked byte ranges for game-memory operations.
abstract interface class IGameMemoryRepository {
  /// Reads [byteCount] bytes starting at [address].
  MemoryReadResult read(int address, int byteCount);
}
