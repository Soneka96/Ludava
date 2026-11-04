import 'package:ludava/features/game_memory/data/datasources/windows_process_memory.datasource.dart';
import 'package:ludava/features/game_memory/domain/entities/memory_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/repositories/Igame_memory.repository.dart';

/// Implements [IGameMemoryRepository] by mapping Windows transfer models to domain results.
class GameMemoryRepository implements IGameMemoryRepository {
  /// Creates the repository around an open process-memory data source.
  GameMemoryRepository(this._dataSource);

  final WindowsProcessMemoryDataSource _dataSource;

  /// Reads through the Windows data source and returns a domain result.
  @override
  MemoryReadResult read(int address, int byteCount) {
    final model = _dataSource.read(address, byteCount);
    return MemoryReadResult(
      status: model.status,
      bytes: model.bytes,
      bytesRead: model.bytesRead,
      requestedBytes: model.requestedBytes,
      errorCode: model.errorCode,
    );
  }
}
