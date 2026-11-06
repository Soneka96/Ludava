import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_memory/data/datasources/windows_memory_api.dart';
import 'package:ludava_sdk/features/game_memory/data/datasources/windows_process_memory.datasource.dart';
import 'package:ludava_sdk/features/game_memory/data/process_game_memory_operation_result.dart';
import 'package:ludava_sdk/features/game_memory/data/repositories/game_memory.repository.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/params/read_game_field.params.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/params/write_game_field.params.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/read_game_field.usecase.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/write_game_field.usecase.dart';
import 'package:ludava_sdk/shared/platform/windows_memory_exception.dart';

/// Executes generic field operations and owns each process handle's lifetime.
class ProcessGameMemoryOperations {
  /// Creates operations with optional native boundaries for deterministic tests.
  const ProcessGameMemoryOperations({
    WindowsMemoryApi? api,
    bool? isWindows,
    int? pointerSize,
  }) : _api = api,
       _isWindows = isWindows,
       _pointerSize = pointerSize;

  final WindowsMemoryApi? _api;
  final bool? _isWindows;
  final int? _pointerSize;

  /// Reads [fieldId] from [profile] in the selected process session.
  ProcessGameMemoryOperationResult readField({
    required int processId,
    required GameProfile profile,
    required int memoryBase,
    required String fieldId,
  }) => _execute(
    processId: processId,
    profile: profile,
    memoryBase: memoryBase,
    fieldId: fieldId,
  );

  /// Performs a guarded field write and returns its verified read-back result.
  ProcessGameMemoryOperationResult writeField({
    required int processId,
    required GameProfile profile,
    required int memoryBase,
    required String fieldId,
    required int value,
    required bool confirmed,
  }) => _execute(
    processId: processId,
    profile: profile,
    memoryBase: memoryBase,
    fieldId: fieldId,
    value: value,
    confirmed: confirmed,
  );

  /// Opens the process once, executes one use case, and classifies cleanup.
  ProcessGameMemoryOperationResult _execute({
    required int processId,
    required GameProfile profile,
    required int memoryBase,
    required String fieldId,
    int? value,
    bool confirmed = false,
  }) {
    final isWrite = value != null;
    WindowsProcessMemoryDataSource? dataSource;
    GameReadResult? readResult;
    GameWriteResult? writeResult;
    Object? operationError;
    Object? cleanupError;
    try {
      dataSource = WindowsProcessMemoryDataSource.open(
        processId,
        api: _api,
        isWindows: _isWindows,
        pointerSize: _pointerSize,
        allowWrites: isWrite,
      );
      final repository = GameMemoryRepository(dataSource);
      if (isWrite) {
        writeResult = WriteGameFieldUseCase(repository).execute(
          WriteGameFieldParams(
            profile: profile,
            fieldId: fieldId,
            memoryBase: memoryBase,
            value: value,
            confirmed: confirmed,
          ),
        );
      } else {
        readResult = ReadGameFieldUseCase(repository).execute(
          ReadGameFieldParams(
            profile: profile,
            fieldId: fieldId,
            memoryBase: memoryBase,
          ),
        );
      }
    } on WindowsMemoryException catch (error) {
      operationError = error;
    } on UnsupportedError catch (error) {
      operationError = error;
    } finally {
      try {
        dataSource?.close();
      } on WindowsMemoryException catch (error) {
        cleanupError = error;
      }
    }

    return ProcessGameMemoryOperationResult(
      readResult: readResult,
      writeResult: writeResult,
      operationError: operationError,
      cleanupError: cleanupError,
    );
  }
}
