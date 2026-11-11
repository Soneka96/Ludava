import 'dart:async';

import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava_sdk/features/trainer/application/trainer_session_state.entity.dart';
import 'package:ludava_sdk/features/trainer/application/trainer_write_validation_result.dart';
import 'package:ludava_sdk/features/trainer/application/trainer_write_validator.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Coordinates a reusable trainer session without depending on a UI toolkit.
class TrainerSessionController {
  /// Creates a session controller with process, detection, and memory actions.
  TrainerSessionController({
    required List<int> Function() discoverProcessIds,
    required Rpcs3ProcessMetadata Function(int processId) readProcessMetadata,
    required Rpcs3MemoryBaseCandidate? Function(
      Rpcs3ProcessMetadata processMetadata,
    )
    resolveMemoryBaseCandidate,
    required GameDetectionResult Function(
      int processId,
      Rpcs3ProcessMetadata processMetadata,
    )
    detectGame,
    required GameReadResult Function(
      int processId,
      GameProfile profile,
      int memoryBase,
      String fieldId,
    )
    readField,
    required GameWriteResult Function(
      int processId,
      GameProfile profile,
      int memoryBase,
      String fieldId,
      int value,
      bool confirmed,
    )
    writeField,
  }) : _discoverProcessIds = discoverProcessIds,
       _readProcessMetadata = readProcessMetadata,
       _resolveMemoryBaseCandidate = resolveMemoryBaseCandidate,
       _detectGame = detectGame,
       _readField = readField,
       _writeField = writeField {
    _writeValidator = TrainerWriteValidator(
      discoverProcessIds: _discoverForWriteValidation,
      readProcessMetadata: _readMetadataForWriteValidation,
      resolveMemoryBaseCandidate: _resolveBaseForWriteValidation,
      detectGame: _detectForWriteValidation,
    );
  }

  TrainerSessionState _state = TrainerSessionState();
  final StreamController<TrainerSessionState> _stateChanges =
      StreamController<TrainerSessionState>.broadcast(sync: true);
  bool _disposed = false;
  Future<void>? _disposeFuture;

  final List<int> Function() _discoverProcessIds;
  final Rpcs3ProcessMetadata Function(int processId) _readProcessMetadata;
  final Rpcs3MemoryBaseCandidate? Function(Rpcs3ProcessMetadata processMetadata)
  _resolveMemoryBaseCandidate;
  final GameDetectionResult Function(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  )
  _detectGame;
  final GameReadResult Function(
    int processId,
    GameProfile profile,
    int memoryBase,
    String fieldId,
  )
  _readField;
  final GameWriteResult Function(
    int processId,
    GameProfile profile,
    int memoryBase,
    String fieldId,
    int value,
    bool confirmed,
  )
  _writeField;
  late final TrainerWriteValidator _writeValidator;

  /// Current immutable session state for a presentation to render.
  TrainerSessionState get state => _state;

  /// Emits the current snapshot, then changes; after disposal new listeners close.
  Stream<TrainerSessionState> get stateChanges =>
      Stream<TrainerSessionState>.multi((subscriber) {
        if (_disposed) {
          subscriber.close();
          return;
        }
        final subscription = _stateChanges.stream.listen(
          subscriber.addSync,
          onError: subscriber.addErrorSync,
          onDone: subscriber.close,
        );
        subscriber.addSync(_state);
        subscriber.onCancel = subscription.cancel;
      }, isBroadcast: true);

  /// Stops state notifications and releases the controller's stream resources.
  Future<void> dispose() {
    final currentDisposal = _disposeFuture;
    if (currentDisposal != null) return currentDisposal;
    _disposed = true;
    return _disposeFuture = _stateChanges.close();
  }

  /// Discovers RPCS3 and automatically selects it when exactly one is found.
  void connect() {
    _ensureActive();
    try {
      final processIds = _discoverProcessIds();
      _ensureActive();
      _publish(TrainerSessionState(processIds: processIds));
      if (processIds.length == 1) selectProcess(processIds.single);
    } catch (error) {
      if (_disposed) rethrow;
      _publish(TrainerSessionState(errorMessage: error.toString()));
    }
  }

  /// Selects [processId], then detects its current game and reads available fields.
  bool selectProcess(int processId) {
    _ensureActive();
    if (!_state.processIds.contains(processId)) return false;
    try {
      final metadata = _readProcessMetadata(processId);
      _ensureActive();
      final detection = _detectGame(processId, metadata);
      _ensureActive();
      if (detection.processId != processId) {
        _publish(
          TrainerSessionState(
            processIds: _state.processIds,
            selectedProcessId: processId,
            processMetadata: metadata,
            detection: _failedDetection(
              processId,
              'Detection returned another process.',
            ),
            errorMessage:
                'Game detection returned evidence for another process.',
          ),
        );
        return false;
      }
      final base = _baseFor(detection, metadata);
      _ensureActive();
      _publish(
        TrainerSessionState(
          processIds: _state.processIds,
          selectedProcessId: processId,
          processMetadata: metadata,
          detection: detection,
          memoryBase: base,
          errorMessage:
              detection.status == GameDetectionStatus.supportedGame &&
                      base == null
                  ? 'The current game memory base is unavailable.'
                  : null,
        ),
      );
      if (detection.status == GameDetectionStatus.supportedGame &&
          base != null) {
        refresh();
      }
      return true;
    } catch (error) {
      if (_disposed) rethrow;
      _publish(
        TrainerSessionState(
          processIds: _state.processIds,
          selectedProcessId: processId,
          errorMessage: error.toString(),
        ),
      );
      return false;
    }
  }

  /// Selects [profile] for read-only inspection without claiming live identity.
  bool selectManualProfile(GameProfile profile) {
    _ensureActive();
    final processId = _state.selectedProcessId;
    final metadata = _state.processMetadata;
    if (processId == null || metadata == null) return false;
    try {
      final candidate = _resolveMemoryBaseCandidate(metadata);
      _ensureActive();
      final detection = GameDetectionResult(
        status: GameDetectionStatus.supportedGame,
        processId: processId,
        titleId: profile.buildId,
        gameTitle: profile.gameName,
        executable: profile.executable,
        executableHash: profile.executableHash,
        confidence: GameIdentityConfidence.manuallySelected,
        profile: profile,
        evidenceDescription: 'The profile was selected manually.',
      );
      _publish(
        TrainerSessionState(
          processIds: _state.processIds,
          selectedProcessId: processId,
          processMetadata: metadata,
          detection: detection,
          memoryBase: candidate?.memoryBase,
          errorMessage:
              candidate == null
                  ? 'The current game memory base is unavailable.'
                  : null,
        ),
      );
      _readAvailableFields(processId, detection, candidate?.memoryBase);
      return true;
    } catch (error) {
      if (_disposed) rethrow;
      _publish(
        TrainerSessionState(
          processIds: _state.processIds,
          selectedProcessId: processId,
          processMetadata: metadata,
          errorMessage: error.toString(),
        ),
      );
      return false;
    }
  }

  /// Rechecks current process identity and base before refreshing field values.
  void refresh() {
    _ensureActive();
    final processId = _state.selectedProcessId;
    final previousMetadata = _state.processMetadata;
    if (processId == null || previousMetadata == null) return;
    var processIds = _state.processIds;
    var currentMetadata = previousMetadata;
    try {
      processIds = _discoverProcessIds();
      _ensureActive();
      if (!processIds.contains(processId)) {
        _publish(
          TrainerSessionState(
            processIds: processIds,
            detection: _failedDetection(
              processId,
              'RPCS3 is no longer running.',
              status: GameDetectionStatus.rpcs3NotRunning,
            ),
            errorMessage: 'RPCS3 is no longer running.',
          ),
        );
        return;
      }
      final metadata = _readProcessMetadata(processId);
      _ensureActive();
      currentMetadata = metadata;
      if (metadata.startedAtUtc != previousMetadata.startedAtUtc) {
        _publish(
          TrainerSessionState(
            processIds: processIds,
            selectedProcessId: processId,
            processMetadata: metadata,
            errorMessage: 'The RPCS3 session changed. Re-detect the game.',
          ),
        );
        return;
      }
      final detection = _detectGame(processId, metadata);
      _ensureActive();
      if (detection.processId != processId) {
        _publish(
          TrainerSessionState(
            processIds: processIds,
            selectedProcessId: processId,
            processMetadata: metadata,
            detection: _failedDetection(
              processId,
              'Detection returned another process.',
            ),
            errorMessage:
                'Game detection returned evidence for another process.',
          ),
        );
        return;
      }
      final base = _baseFor(detection, metadata);
      _ensureActive();
      _publish(
        TrainerSessionState(
          processIds: processIds,
          selectedProcessId: processId,
          processMetadata: metadata,
          detection: detection,
          memoryBase: base,
        ),
      );
      if (detection.status != GameDetectionStatus.supportedGame) return;
      if (base == null) {
        _publish(_withError('The current game memory base is unavailable.'));
        return;
      }
      _readAvailableFields(processId, detection, base);
    } catch (error) {
      if (_disposed) rethrow;
      _publish(
        TrainerSessionState(
          processIds: processIds,
          selectedProcessId: processId,
          processMetadata: currentMetadata,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Clears displayed values and checks the selected process identity again.
  void redetect() => refresh();

  /// Validates and writes [value], then exposes only verified read-back values.
  GameWriteResult writeField(String fieldId, int value) {
    _ensureActive();
    final profile = _state.profile;
    final processId = _state.selectedProcessId;
    final metadata = _state.processMetadata;
    final base = _state.memoryBase;
    final field = profile?.findField(fieldId);
    if (profile == null || field == null) {
      return _rejectWrite(
        GameWriteStatus.unsupportedField,
        fieldId,
        value,
        'The selected field is not registered in the current profile.',
      );
    }
    if (processId == null ||
        metadata == null ||
        base == null ||
        _state.detection?.confidence != GameIdentityConfidence.confirmed) {
      return _rejectWrite(
        GameWriteStatus.unsupportedProfile,
        fieldId,
        value,
        'A confirmed current game session is required before writing.',
      );
    }
    if (field.minimumValue == null ||
        field.maximumValue == null ||
        value < field.minimumValue! ||
        value > field.maximumValue!) {
      return _rejectWrite(
        GameWriteStatus.invalidValue,
        fieldId,
        value,
        'The value is outside the allowed field range.',
      );
    }
    final displayedResult = _state.readResults[fieldId];
    if (displayedResult?.succeeded == true && displayedResult?.value == value) {
      return GameWriteResult(
        status: GameWriteStatus.none,
        fieldId: fieldId,
        requestedValue: value,
      );
    }

    final selectedDetection = _state.detection;
    if (selectedDetection == null) {
      return _rejectWrite(
        GameWriteStatus.unsupportedProfile,
        fieldId,
        value,
        'Current game identity is unavailable.',
      );
    }
    late final TrainerWriteValidationResult validation;
    try {
      validation = _writeValidator.validate(
        processId: processId,
        memoryBase: base,
        profile: profile,
        selectedDetection: selectedDetection,
        selectedProcessStartedAtUtc: metadata.startedAtUtc,
      );
      _ensureActive();
    } catch (error) {
      if (_disposed) rethrow;
      return _rejectWrite(
        GameWriteStatus.unsupportedProfile,
        fieldId,
        value,
        'Could not revalidate the game before writing. No write was made: $error',
        invalidateSession: true,
      );
    }
    if (!validation.isAuthorized) {
      return _rejectWrite(
        GameWriteStatus.unsupportedProfile,
        fieldId,
        value,
        validation.rejectionMessage ??
            'The current session rejected the write.',
        invalidateSession: true,
      );
    }

    try {
      final result = _writeField(
        processId,
        profile,
        base,
        fieldId,
        value,
        true,
      );
      _ensureActive();
      final reads = Map<String, GameReadResult>.of(_state.readResults)
        ..remove(fieldId);
      if (result.succeeded) {
        reads[fieldId] = GameReadResult(
          status: GameReadStatus.success,
          fieldId: fieldId,
          value: result.readBackValue,
        );
      }
      _publish(_copyState(readResults: reads, lastWriteResult: result));
      return result;
    } catch (error) {
      if (_disposed) rethrow;
      return _rejectWrite(
        GameWriteStatus.writeFailed,
        fieldId,
        value,
        error.toString(),
        invalidateFieldValue: true,
      );
    }
  }

  /// Reads every registered field and replaces the snapshot with those results.
  void _readAvailableFields(
    int processId,
    GameDetectionResult detection,
    int? memoryBase,
  ) {
    final profile = detection.profile;
    if (profile == null || memoryBase == null) return;
    final results = <String, GameReadResult>{};
    String? readError;
    for (final field in profile.fields.values) {
      _ensureActive();
      try {
        results[field.id] = _readField(
          processId,
          profile,
          memoryBase,
          field.id,
        );
        _ensureActive();
      } catch (error) {
        if (_disposed) rethrow;
        results[field.id] = GameReadResult(
          status: GameReadStatus.readFailed,
          fieldId: field.id,
        );
        readError = error.toString();
      }
    }
    _publish(_copyState(readResults: results, errorMessage: readError));
  }

  /// Resolves a memory base only for a supported detected game.
  int? _baseFor(GameDetectionResult detection, Rpcs3ProcessMetadata metadata) {
    if (detection.status != GameDetectionStatus.supportedGame) return null;
    return _resolveMemoryBaseCandidate(metadata)?.memoryBase;
  }

  /// Creates an unresolved identity result for the selected process.
  GameDetectionResult _failedDetection(
    int processId,
    String message, {
    GameDetectionStatus status = GameDetectionStatus.failed,
  }) => GameDetectionResult(
    status: status,
    processId: processId,
    confidence: GameIdentityConfidence.none,
    evidenceDescription: message,
  );

  /// Clears cached values while retaining the current target and [message].
  TrainerSessionState _withError(String message) => TrainerSessionState(
    processIds: _state.processIds,
    selectedProcessId: _state.selectedProcessId,
    processMetadata: _state.processMetadata,
    detection: _state.detection,
    memoryBase: _state.memoryBase,
    errorMessage: message,
  );

  /// Copies the active target with updated read, write, or error information.
  TrainerSessionState _copyState({
    Map<String, GameReadResult>? readResults,
    GameWriteResult? lastWriteResult,
    String? errorMessage,
  }) => TrainerSessionState(
    processIds: _state.processIds,
    selectedProcessId: _state.selectedProcessId,
    processMetadata: _state.processMetadata,
    detection: _state.detection,
    memoryBase: _state.memoryBase,
    readResults: readResults ?? _state.readResults,
    lastWriteResult: lastWriteResult,
    errorMessage: errorMessage,
  );

  /// Publishes a rejected write result, optionally invalidating the target.
  GameWriteResult _rejectWrite(
    GameWriteStatus status,
    String fieldId,
    int value,
    String message, {
    bool invalidateSession = false,
    bool invalidateFieldValue = false,
  }) {
    final result = GameWriteResult(
      status: status,
      fieldId: fieldId,
      requestedValue: value,
    );
    final readResults =
        invalidateSession ? <String, GameReadResult>{} : _state.readResults;
    final retainedReadResults =
        invalidateFieldValue
            ? (Map<String, GameReadResult>.of(readResults)..remove(fieldId))
            : readResults;
    _publish(
      TrainerSessionState(
        processIds: _state.processIds,
        selectedProcessId: invalidateSession ? null : _state.selectedProcessId,
        processMetadata: invalidateSession ? null : _state.processMetadata,
        detection: invalidateSession ? null : _state.detection,
        memoryBase: invalidateSession ? null : _state.memoryBase,
        readResults: retainedReadResults,
        lastWriteResult: result,
        errorMessage: message,
      ),
    );
    return result;
  }

  /// Replaces the snapshot and notifies active state subscribers.
  void _publish(TrainerSessionState state) {
    _ensureActive();
    _state = state;
    _stateChanges.add(state);
  }

  /// Rejects operations once this session's terminal disposal has started.
  void _ensureActive() {
    if (_disposed) {
      throw StateError('This SDK capability has been disposed.');
    }
  }

  /// Guards process discovery between each write-validation collaborator call.
  List<int> _discoverForWriteValidation() {
    _ensureActive();
    final processIds = _discoverProcessIds();
    _ensureActive();
    return processIds;
  }

  /// Guards process metadata lookup during write validation.
  Rpcs3ProcessMetadata _readMetadataForWriteValidation(int processId) {
    _ensureActive();
    final metadata = _readProcessMetadata(processId);
    _ensureActive();
    return metadata;
  }

  /// Guards current-session base resolution during write validation.
  Rpcs3MemoryBaseCandidate? _resolveBaseForWriteValidation(
    Rpcs3ProcessMetadata processMetadata,
  ) {
    _ensureActive();
    final memoryBase = _resolveMemoryBaseCandidate(processMetadata);
    _ensureActive();
    return memoryBase;
  }

  /// Guards game detection during write validation.
  GameDetectionResult _detectForWriteValidation(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  ) {
    _ensureActive();
    final detection = _detectGame(processId, processMetadata);
    _ensureActive();
    return detection;
  }
}
