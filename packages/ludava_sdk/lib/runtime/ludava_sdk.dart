import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/game_profile_catalog.dart';
import 'package:ludava_sdk/features/game_detection/application/rpcs3_game_detection_workflow.dart';
import 'package:ludava_sdk/features/game_detection/data/datasources/rpcs3_game_identity_log.datasource.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/data/datasources/windows_memory_api.dart';
import 'package:ludava_sdk/features/game_memory/data/process_game_memory_operations.dart';
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

  /// Immutable profile snapshot available to detection and manual selection.
  List<GameProfile> get profiles => _profiles;

  /// Creates a runtime with one immutable profile snapshot and replaceable adapters.
  LudavaSdk.create({
    Iterable<GameProfile>? profiles,
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
  }) : _profiles = List<GameProfile>.unmodifiable(
         profiles ?? GameProfileCatalog.profiles,
       ),
       _memoryOperations = ProcessGameMemoryOperations(
         api: api,
         isWindows: isWindows,
         pointerSize: pointerSize,
       ),
       _discoverProcessIds = discoverProcessIds,
       _readProcessMetadata = readProcessMetadata,
       _resolveMemoryBaseCandidate = resolveMemoryBaseCandidate,
       _detectGame = detectGame,
       _gameIdentityLogDataSource = gameIdentityLogDataSource {
    final detectGameOperation = _createGameDetectionOperation();
    session = _createTrainerSessionController(detectGameOperation);
    diagnostics = _createDiagnosticGameMemoryService(detectGameOperation);
  }

  final List<GameProfile> _profiles;
  final ProcessGameMemoryOperations _memoryOperations;
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
  Future<void> dispose() => _disposeFuture ??= _disposeOwnedCapabilities();

  /// Creates the trainer session with RPCS3, detection, and memory capabilities.
  TrainerSessionController _createTrainerSessionController(
    GameDetectionResult Function(
      int processId,
      Rpcs3ProcessMetadata processMetadata,
    )
    detectGameOperation,
  ) => TrainerSessionController(
    discoverProcessIds: _findRpcs3ProcessIds,
    readProcessMetadata: _readMetadata,
    resolveMemoryBaseCandidate: _resolveBaseCandidate,
    detectGame: detectGameOperation,
    readField: (processId, profile, memoryBase, fieldId) {
      final result = _memoryOperations.readField(
        processId: processId,
        profile: profile,
        memoryBase: memoryBase,
        fieldId: fieldId,
      );
      if (result.operationError case final error?) throw error;
      if (result.cleanupError case final error?) throw error;
      return result.readResult!;
    },
    writeField: (processId, profile, memoryBase, fieldId, value, confirmed) {
      final result = _memoryOperations.writeField(
        processId: processId,
        profile: profile,
        memoryBase: memoryBase,
        fieldId: fieldId,
        value: value,
        confirmed: confirmed,
      );
      if (result.operationError case final error?) throw error;
      if (result.cleanupError case final error?) throw error;
      return result.writeResult!;
    },
  );

  /// Creates the structured diagnostic workflow with the same SDK boundaries.
  DiagnosticGameMemoryService _createDiagnosticGameMemoryService(
    GameDetectionResult Function(
      int processId,
      Rpcs3ProcessMetadata processMetadata,
    )
    detectGameOperation,
  ) => DiagnosticGameMemoryService(
    profiles: _profiles,
    memoryOperations: _memoryOperations,
    discoverProcessIds: _findRpcs3ProcessIds,
    readProcessMetadata: _readMetadata,
    resolveMemoryBaseCandidate: _resolveBaseCandidate,
    detectGame: detectGameOperation,
    gameIdentityLogDataSource: _gameIdentityLogDataSource,
  );

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

  /// Assembles the feature-owned detection workflow or injected test seam.
  GameDetectionResult Function(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  )
  _createGameDetectionOperation() {
    final injectedDetection = _detectGame;
    if (injectedDetection != null) return injectedDetection;
    return Rpcs3GameDetectionWorkflow(
      profiles: _profiles,
      discoverProcessIds: _findRpcs3ProcessIds,
      readProcessMetadata: _readMetadata,
      readIdentityLogCandidates:
          (metadata) =>
              (_gameIdentityLogDataSource ?? Rpcs3GameIdentityLogDataSource())
                  .readCandidates(metadata),
    ).detect;
  }

  /// Starts disposal on both owned capabilities before awaiting their cleanup.
  Future<void> _disposeOwnedCapabilities() {
    final sessionDisposal = session.dispose();
    final diagnosticsDisposal = diagnostics.dispose();
    return Future.wait<void>([sessionDisposal, diagnosticsDisposal]);
  }
}
