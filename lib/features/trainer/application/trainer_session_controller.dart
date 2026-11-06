import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/trainer/application/trainer_session_state.entity.dart';
import 'package:ludava/features/trainer/application/trainer_write_validation_result.dart';
import 'package:ludava/features/trainer/application/trainer_write_validator.dart';
import 'package:ludava/shared/constants/enums.dart';

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
       _writeField = writeField,
       _writeValidator = TrainerWriteValidator(
         discoverProcessIds: discoverProcessIds,
         readProcessMetadata: readProcessMetadata,
         resolveMemoryBaseCandidate: resolveMemoryBaseCandidate,
         detectGame: detectGame,
       );

  TrainerSessionState _state = TrainerSessionState();

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
  final TrainerWriteValidator _writeValidator;

  /// Current immutable session state for a presentation to render.
  TrainerSessionState get state => _state;

  /// Discovers RPCS3 and automatically selects it when exactly one is found.
  void connect() {
    try {
      final processIds = _discoverProcessIds();
      _state = TrainerSessionState(processIds: processIds);
      if (processIds.length == 1) selectProcess(processIds.single);
    } catch (error) {
      _state = TrainerSessionState(errorMessage: error.toString());
    }
  }

  /// Selects [processId], then detects its current game and reads available fields.
  bool selectProcess(int processId) {
    if (!_state.processIds.contains(processId)) return false;
    try {
      final metadata = _readProcessMetadata(processId);
      final detection = _detectGame(processId, metadata);
      if (detection.processId != processId) {
        _state = TrainerSessionState(
          processIds: _state.processIds,
          selectedProcessId: processId,
          processMetadata: metadata,
          detection: _failedDetection(
            processId,
            'Detection returned another process.',
          ),
          errorMessage: 'Game detection returned evidence for another process.',
        );
        return false;
      }
      final base = _baseFor(detection, metadata);
      _state = TrainerSessionState(
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
      );
      if (detection.status == GameDetectionStatus.supportedGame &&
          base != null) {
        refresh();
      }
      return true;
    } catch (error) {
      _state = TrainerSessionState(
        processIds: _state.processIds,
        selectedProcessId: processId,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  /// Selects [profile] for read-only inspection without claiming live identity.
  bool selectManualProfile(GameProfile profile) {
    final processId = _state.selectedProcessId;
    final metadata = _state.processMetadata;
    if (processId == null || metadata == null) return false;
    try {
      final candidate = _resolveMemoryBaseCandidate(metadata);
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
      _state = TrainerSessionState(
        processIds: _state.processIds,
        selectedProcessId: processId,
        processMetadata: metadata,
        detection: detection,
        memoryBase: candidate?.memoryBase,
        errorMessage:
            candidate == null
                ? 'The current game memory base is unavailable.'
                : null,
      );
      _readAvailableFields(processId, detection, candidate?.memoryBase);
      return true;
    } catch (error) {
      _state = TrainerSessionState(
        processIds: _state.processIds,
        selectedProcessId: processId,
        processMetadata: metadata,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  /// Rechecks current process identity and base before refreshing field values.
  void refresh() {
    final processId = _state.selectedProcessId;
    final previousMetadata = _state.processMetadata;
    if (processId == null || previousMetadata == null) return;
    _state = TrainerSessionState(
      processIds: _state.processIds,
      selectedProcessId: processId,
      processMetadata: previousMetadata,
    );
    try {
      final processIds = _discoverProcessIds();
      if (!processIds.contains(processId)) {
        _state = TrainerSessionState(
          processIds: processIds,
          detection: _failedDetection(
            processId,
            'RPCS3 is no longer running.',
            status: GameDetectionStatus.rpcs3NotRunning,
          ),
          errorMessage: 'RPCS3 is no longer running.',
        );
        return;
      }
      final metadata = _readProcessMetadata(processId);
      final detection = _detectGame(processId, metadata);
      if (detection.processId != processId) {
        _state = TrainerSessionState(
          processIds: processIds,
          selectedProcessId: processId,
          processMetadata: metadata,
          detection: _failedDetection(
            processId,
            'Detection returned another process.',
          ),
          errorMessage: 'Game detection returned evidence for another process.',
        );
        return;
      }
      final base = _baseFor(detection, metadata);
      _state = TrainerSessionState(
        processIds: processIds,
        selectedProcessId: processId,
        processMetadata: metadata,
        detection: detection,
        memoryBase: base,
      );
      if (metadata.startedAtUtc != previousMetadata.startedAtUtc) {
        _state = _withError('The RPCS3 session changed. Re-detect the game.');
        return;
      }
      if (detection.status != GameDetectionStatus.supportedGame) return;
      if (base == null) {
        _state = _withError('The current game memory base is unavailable.');
        return;
      }
      _readAvailableFields(processId, detection, base);
    } catch (error) {
      _state = _withError(error.toString());
    }
  }

  /// Clears displayed values and checks the selected process identity again.
  void redetect() => refresh();

  /// Validates and writes [value], then exposes only verified read-back values.
  GameWriteResult writeField(String fieldId, int value) {
    final profile = _state.profile;
    final processId = _state.selectedProcessId;
    final metadata = _state.processMetadata;
    final base = _state.memoryBase;
    final field = profile?.findField(fieldId);
    if (profile == null || field == null || !field.canWrite) {
      return _rejectWrite(
        GameWriteStatus.unsupportedField,
        fieldId,
        value,
        'This field is not approved for writing.',
      );
    }
    if (!profile.canWrite) {
      return _rejectWrite(
        GameWriteStatus.unsupportedProfile,
        fieldId,
        value,
        'This profile is not approved for writing.',
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
    } catch (error) {
      return _rejectWrite(
        GameWriteStatus.unsupportedProfile,
        fieldId,
        value,
        'Could not revalidate the game before writing. No write was made: $error',
      );
    }
    if (!validation.isAuthorized) {
      return _rejectWrite(
        GameWriteStatus.unsupportedProfile,
        fieldId,
        value,
        validation.rejectionMessage ??
            'The current session rejected the write.',
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
      final reads = Map<String, GameReadResult>.of(_state.readResults)
        ..remove(fieldId);
      if (result.succeeded) {
        reads[fieldId] = GameReadResult(
          status: GameReadStatus.success,
          fieldId: fieldId,
          value: result.readBackValue,
        );
      }
      _state = _copyState(readResults: reads, lastWriteResult: result);
      return result;
    } catch (error) {
      return _rejectWrite(
        GameWriteStatus.writeFailed,
        fieldId,
        value,
        error.toString(),
      );
    }
  }

  void _readAvailableFields(
    int processId,
    GameDetectionResult detection,
    int? memoryBase,
  ) {
    final profile = detection.profile;
    if (profile == null || memoryBase == null || !profile.canRead) return;
    final results = <String, GameReadResult>{};
    String? readError;
    for (final field in profile.fields.values) {
      if (!field.canRead) continue;
      try {
        results[field.id] = _readField(
          processId,
          profile,
          memoryBase,
          field.id,
        );
      } catch (error) {
        results[field.id] = GameReadResult(
          status: GameReadStatus.readFailed,
          fieldId: field.id,
        );
        readError = error.toString();
      }
    }
    _state = _copyState(readResults: results, errorMessage: readError);
  }

  int? _baseFor(GameDetectionResult detection, Rpcs3ProcessMetadata metadata) {
    if (detection.status != GameDetectionStatus.supportedGame) return null;
    return _resolveMemoryBaseCandidate(metadata)?.memoryBase;
  }

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

  TrainerSessionState _withError(String message) => TrainerSessionState(
    processIds: _state.processIds,
    selectedProcessId: _state.selectedProcessId,
    processMetadata: _state.processMetadata,
    detection: _state.detection,
    memoryBase: _state.memoryBase,
    errorMessage: message,
  );

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

  GameWriteResult _rejectWrite(
    GameWriteStatus status,
    String fieldId,
    int value,
    String message,
  ) {
    final result = GameWriteResult(
      status: status,
      fieldId: fieldId,
      requestedValue: value,
    );
    _state = TrainerSessionState(
      processIds: _state.processIds,
      selectedProcessId: _state.selectedProcessId,
      processMetadata: _state.processMetadata,
      detection: _state.detection,
      memoryBase: _state.memoryBase,
      lastWriteResult: result,
      errorMessage: message,
    );
    return result;
  }
}
