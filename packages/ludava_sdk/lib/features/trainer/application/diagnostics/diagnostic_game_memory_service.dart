import 'package:ludava_sdk/features/trainer/application/diagnostics/diagnostic_game_memory_request.entity.dart';
import 'package:ludava_sdk/features/trainer/application/diagnostics/diagnostic_game_memory_result.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/game_profile_catalog.dart';
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
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:ludava_sdk/shared/platform/windows_memory_exception.dart';

/// Coordinates safe diagnostic reads and writes without frontend dependencies.
class DiagnosticGameMemoryService {
  /// Creates the service with optional boundaries for deterministic callers.
  DiagnosticGameMemoryService({
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
       _gameIdentityLogDataSource = gameIdentityLogDataSource;

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

  /// Executes [request] and returns typed identity, memory, and cleanup results.
  DiagnosticGameMemoryResult execute(DiagnosticGameMemoryRequest request) {
    final action = request.action;
    if (action != GameMemoryAction.read && action != GameMemoryAction.write) {
      return const DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.invalidRequest,
      );
    }
    if (request.processId <= 0 ||
        request.processId > 0xffffffff ||
        (action == GameMemoryAction.write && request.value == null)) {
      return const DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.invalidRequest,
      );
    }

    final profile = GameProfileCatalog.find(request.gameId);
    if (profile == null) {
      return const DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.unknownGame,
      );
    }

    final preflightResult = _preflightProfile(profile, request);
    if (preflightResult != null) return preflightResult;

    final isWrite = action == GameMemoryAction.write;
    if (isWrite && !request.confirmed) {
      return DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.memoryOperationFailed,
        profile: profile,
        writeResult: GameWriteResult(
          status: GameWriteStatus.confirmationRequired,
          fieldId: request.fieldId,
          requestedValue: request.value,
        ),
      );
    }

    Rpcs3ProcessMetadata? metadata;
    var identityConfirmed = false;
    try {
      if (_findRpcs3ProcessIds().contains(request.processId)) {
        metadata = _readMetadata(request.processId);
        final identity = _detectCurrentGame(request.processId, metadata);
        identityConfirmed = _identityMatchesProfile(
          identity,
          request.processId,
          profile,
        );
      }
    } on Exception catch (error) {
      if (isWrite) {
        return DiagnosticGameMemoryResult(
          status: DiagnosticGameMemoryStatus.identityCheckFailed,
          profile: profile,
          error: error,
        );
      }
    } on UnsupportedError catch (error) {
      if (isWrite) {
        return DiagnosticGameMemoryResult(
          status: DiagnosticGameMemoryStatus.identityCheckFailed,
          profile: profile,
          error: error,
        );
      }
    }

    if ((isWrite || request.requireCurrentIdentity) && !identityConfirmed) {
      return DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.identityMismatch,
        profile: profile,
      );
    }

    if (isWrite) {
      final baseResult = _validateCurrentMemoryBase(metadata, request);
      if (baseResult != null) {
        return DiagnosticGameMemoryResult(
          status: baseResult.status,
          profile: profile,
          identityConfirmed: identityConfirmed,
          error: baseResult.error,
        );
      }
    }

    WindowsProcessMemoryDataSource? dataSource;
    GameReadResult? readResult;
    GameWriteResult? writeResult;
    Object? operationError;
    Object? cleanupError;
    try {
      dataSource = WindowsProcessMemoryDataSource.open(
        request.processId,
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
            fieldId: request.fieldId,
            memoryBase: request.memoryBase,
            value: request.value!,
            confirmed: request.confirmed,
          ),
        );
      } else {
        readResult = ReadGameFieldUseCase(repository).execute(
          ReadGameFieldParams(
            profile: profile,
            fieldId: request.fieldId,
            memoryBase: request.memoryBase,
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

    final memorySucceeded =
        readResult?.succeeded ?? writeResult?.succeeded ?? false;
    final status =
        operationError != null
            ? DiagnosticGameMemoryStatus.nativeFailure
            : cleanupError != null
            ? DiagnosticGameMemoryStatus.cleanupFailed
            : memorySucceeded
            ? DiagnosticGameMemoryStatus.completed
            : DiagnosticGameMemoryStatus.memoryOperationFailed;
    return DiagnosticGameMemoryResult(
      status: status,
      profile: profile,
      identityConfirmed: identityConfirmed,
      readResult: readResult,
      writeResult: writeResult,
      error: operationError,
      cleanupError: cleanupError,
    );
  }

  /// Returns an SDK memory result when profile or field policy rejects a request.
  DiagnosticGameMemoryResult? _preflightProfile(
    GameProfile profile,
    DiagnosticGameMemoryRequest request,
  ) {
    if (request.action == GameMemoryAction.write) {
      if (!profile.canWrite) {
        return DiagnosticGameMemoryResult(
          status: DiagnosticGameMemoryStatus.memoryOperationFailed,
          profile: profile,
          writeResult: GameWriteResult(
            status: GameWriteStatus.unsupportedProfile,
            fieldId: request.fieldId,
            requestedValue: request.value,
          ),
        );
      }
      final field = profile.findField(request.fieldId);
      if (field == null || !field.canWrite) {
        return DiagnosticGameMemoryResult(
          status: DiagnosticGameMemoryStatus.memoryOperationFailed,
          profile: profile,
          writeResult: GameWriteResult(
            status: GameWriteStatus.unsupportedField,
            fieldId: request.fieldId,
            requestedValue: request.value,
          ),
        );
      }
      return null;
    }

    final field = profile.findField(request.fieldId);
    if (field == null || !field.canRead) {
      return DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.memoryOperationFailed,
        profile: profile,
        readResult: GameReadResult(
          status: GameReadStatus.unsupportedField,
          fieldId: request.fieldId,
        ),
      );
    }
    if (!profile.canRead) {
      return DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.memoryOperationFailed,
        profile: profile,
        readResult: GameReadResult(
          status: GameReadStatus.unsupportedProfile,
          fieldId: request.fieldId,
        ),
      );
    }
    return null;
  }

  /// Rejects writes when current process evidence cannot validate the requested base.
  DiagnosticGameMemoryResult? _validateCurrentMemoryBase(
    Rpcs3ProcessMetadata? metadata,
    DiagnosticGameMemoryRequest request,
  ) {
    Rpcs3MemoryBaseCandidate? currentBase;
    try {
      if (metadata != null) currentBase = _resolveBaseCandidate(metadata);
    } on Exception catch (error) {
      return DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.memoryBaseCheckFailed,
        error: error,
      );
    } on UnsupportedError catch (error) {
      return DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.memoryBaseCheckFailed,
        error: error,
      );
    }
    if (currentBase == null || currentBase.memoryBase != request.memoryBase) {
      return const DiagnosticGameMemoryResult(
        status: DiagnosticGameMemoryStatus.memoryBaseMismatch,
      );
    }
    return null;
  }

  /// Uses the injected discovery seam or the Windows process adapter.
  List<int> _findRpcs3ProcessIds() =>
      _discoverProcessIds?.call() ??
      WindowsProcessDiscoveryDataSource().findRpcs3ProcessIds();

  /// Uses the injected metadata seam or the Windows metadata adapter.
  Rpcs3ProcessMetadata _readMetadata(int processId) =>
      _readProcessMetadata?.call(processId) ??
      WindowsProcessMetadataDataSource().read(processId);

  /// Resolves the current session base through its injected or native adapter.
  Rpcs3MemoryBaseCandidate? _resolveBaseCandidate(
    Rpcs3ProcessMetadata processMetadata,
  ) =>
      _resolveMemoryBaseCandidate?.call(processMetadata) ??
      Rpcs3MemoryBaseResolverDataSource().resolveCandidate(processMetadata);

  /// Uses injected detection behavior or the configured RPCS3 workflow.
  GameDetectionResult _detectCurrentGame(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  ) =>
      _detectGame?.call(processId, processMetadata) ??
      _detectGameFromLog(processId, processMetadata);

  /// Builds game detection from fresh RPCS3 process and log evidence.
  GameDetectionResult _detectGameFromLog(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  ) => Rpcs3GameDetectionWorkflow(
    discoverProcessIds: _findRpcs3ProcessIds,
    readProcessMetadata: _readMetadata,
    readIdentityLogCandidates:
        (metadata) =>
            (_gameIdentityLogDataSource ?? Rpcs3GameIdentityLogDataSource())
                .readCandidates(metadata),
  ).detect(processId, processMetadata);

  /// Checks whether [identity] confirms both the selected process and [profile].
  bool _identityMatchesProfile(
    GameDetectionResult? identity,
    int processId,
    GameProfile profile,
  ) =>
      identity?.processId == processId &&
      identity?.status == GameDetectionStatus.supportedGame &&
      identity?.confidence == GameIdentityConfidence.confirmed &&
      identity?.profile?.id == profile.id &&
      profile.executableHash != null &&
      identity?.executableHash?.toLowerCase() ==
          profile.executableHash!.toLowerCase();
}
