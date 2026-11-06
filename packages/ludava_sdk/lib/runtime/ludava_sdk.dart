import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_detection/application/rpcs3_game_detection_workflow.dart';
import 'package:ludava_sdk/features/game_detection/data/datasources/rpcs3_game_identity_log.datasource.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/data/datasources/windows_memory_api.dart';
import 'package:ludava_sdk/features/game_memory/data/datasources/windows_process_memory.datasource.dart';
import 'package:ludava_sdk/features/game_memory/data/repositories/game_memory.repository.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/params/read_game_field.params.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/params/write_game_field.params.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/read_game_field.usecase.dart';
import 'package:ludava_sdk/features/game_memory/domain/usecases/write_game_field.usecase.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/rpcs3_memory_base_resolver.datasource.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_process_discovery.datasource.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_process_metadata.datasource.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava_sdk/features/trainer/application/trainer_session_controller.dart';
import 'package:ludava_sdk/features/trainer/application/diagnostics/diagnostic_game_memory_service.dart';

/// Owns the typed capabilities and resources for one Ludava SDK instance.
class LudavaSdk {
  /// Trainer-session capability for this runtime.
  late final TrainerSessionController session;

  /// Structured diagnostic operations for this runtime.
  late final DiagnosticGameMemoryService diagnostics;

  /// Creates an SDK runtime with optional seams for deterministic callers.
  LudavaSdk.create({
    WindowsMemoryApi? api,
    bool? isWindows,
    int? pointerSize,
    List<int> Function()? discoverProcessIds,
    Rpcs3ProcessMetadata Function(int processId)? readProcessMetadata,
    Rpcs3MemoryBaseCandidate? Function(Rpcs3ProcessMetadata processMetadata)?
    resolveMemoryBaseCandidate,
    GameDetectionResult Function(
      int processId,
      Rpcs3ProcessMetadata processMetadata,
    )?
    detectGame,
    Rpcs3GameIdentityLogDataSource? gameIdentityLogDataSource,
  }) : _api = api,
       _isWindows = isWindows,
       _pointerSize = pointerSize,
       _discoverProcessIds = discoverProcessIds,
       _readProcessMetadata = readProcessMetadata,
       _resolveMemoryBaseCandidate = resolveMemoryBaseCandidate,
       _detectGame = detectGame,
       _gameIdentityLogDataSource = gameIdentityLogDataSource {
    session = _createTrainerSessionController();
    diagnostics = _createDiagnosticGameMemoryService();
  }

  final WindowsMemoryApi? _api;
  final bool? _isWindows;
  final int? _pointerSize;
  final List<int> Function()? _discoverProcessIds;
  final Rpcs3ProcessMetadata Function(int processId)? _readProcessMetadata;
  final Rpcs3MemoryBaseCandidate? Function(
    Rpcs3ProcessMetadata processMetadata,
  )?
  _resolveMemoryBaseCandidate;
  final GameDetectionResult Function(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  )?
  _detectGame;
  final Rpcs3GameIdentityLogDataSource? _gameIdentityLogDataSource;
  Future<void>? _disposeFuture;

  /// Stops this runtime's session notifications and releases owned resources.
  Future<void> dispose() => _disposeFuture ??= session.dispose();

  /// Creates the trainer session with RPCS3, detection, and memory capabilities.
  TrainerSessionController _createTrainerSessionController() =>
      TrainerSessionController(
        discoverProcessIds: _findRpcs3ProcessIds,
        readProcessMetadata: _readMetadata,
        resolveMemoryBaseCandidate: _resolveBaseCandidate,
        detectGame: _detectCurrentGame,
        readField: _readField,
        writeField: _writeField,
      );

  /// Creates the structured diagnostic workflow with the same SDK boundaries.
  DiagnosticGameMemoryService _createDiagnosticGameMemoryService() =>
      DiagnosticGameMemoryService(
        api: _api,
        isWindows: _isWindows,
        pointerSize: _pointerSize,
        discoverProcessIds: _findRpcs3ProcessIds,
        readProcessMetadata: _readMetadata,
        resolveMemoryBaseCandidate: _resolveBaseCandidate,
        detectGame: _detectCurrentGame,
        gameIdentityLogDataSource: _gameIdentityLogDataSource,
      );

  /// Opens and closes the process around one guarded field read.
  GameReadResult _readField(
    int processId,
    GameProfile profile,
    int memoryBase,
    String fieldId,
  ) {
    WindowsProcessMemoryDataSource? dataSource;
    try {
      dataSource = WindowsProcessMemoryDataSource.open(
        processId,
        api: _api,
        isWindows: _isWindows,
        pointerSize: _pointerSize,
      );
      return ReadGameFieldUseCase(GameMemoryRepository(dataSource)).execute(
        ReadGameFieldParams(
          profile: profile,
          fieldId: fieldId,
          memoryBase: memoryBase,
        ),
      );
    } finally {
      dataSource?.close();
    }
  }

  /// Opens and closes the process around one guarded field write.
  GameWriteResult _writeField(
    int processId,
    GameProfile profile,
    int memoryBase,
    String fieldId,
    int value,
    bool confirmed,
  ) {
    WindowsProcessMemoryDataSource? dataSource;
    try {
      dataSource = WindowsProcessMemoryDataSource.open(
        processId,
        api: _api,
        isWindows: _isWindows,
        pointerSize: _pointerSize,
        allowWrites: true,
      );
      return WriteGameFieldUseCase(GameMemoryRepository(dataSource)).execute(
        WriteGameFieldParams(
          profile: profile,
          fieldId: fieldId,
          memoryBase: memoryBase,
          value: value,
          confirmed: confirmed,
        ),
      );
    } finally {
      dataSource?.close();
    }
  }

  /// Uses the injected discovery seam or the Windows process adapter.
  List<int> _findRpcs3ProcessIds() =>
      _discoverProcessIds?.call() ??
      WindowsProcessDiscoveryDataSource().findRpcs3ProcessIds();

  /// Uses the injected metadata seam or the Windows metadata adapter.
  Rpcs3ProcessMetadata _readMetadata(int processId) =>
      _readProcessMetadata?.call(processId) ??
      WindowsProcessMetadataDataSource().read(processId);

  /// Resolves a fresh memory base through its injected or native adapter.
  Rpcs3MemoryBaseCandidate? _resolveBaseCandidate(
    Rpcs3ProcessMetadata processMetadata,
  ) {
    final resolver = _resolveMemoryBaseCandidate;
    if (resolver != null) return resolver(processMetadata);
    return Rpcs3MemoryBaseResolverDataSource().resolveCandidate(
      processMetadata,
    );
  }

  /// Uses injected detection behavior or fresh RPCS3 log evidence.
  GameDetectionResult _detectCurrentGame(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  ) =>
      _detectGame?.call(processId, processMetadata) ??
      Rpcs3GameDetectionWorkflow(
        discoverProcessIds: _findRpcs3ProcessIds,
        readProcessMetadata: _readMetadata,
        readIdentityLogCandidates:
            (metadata) =>
                (_gameIdentityLogDataSource ?? Rpcs3GameIdentityLogDataSource())
                    .readCandidates(metadata),
      ).detect(processId, processMetadata);
}
