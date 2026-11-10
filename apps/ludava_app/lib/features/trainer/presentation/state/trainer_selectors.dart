import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Selects pure trainer presentation values from Redux state.
abstract final class TrainerSelectors {
  /// Returns the latest authoritative trainer session from [state].
  static TrainerSessionState session(AppState state) => state.trainer.session;

  /// Returns the selected profile, when the current session has one.
  static GameProfile? profile(AppState state) => session(state).profile;

  /// Returns whether the current session has a selected profile.
  static bool hasProfile(AppState state) => profile(state) != null;

  /// Returns the detected game title, when identity is available.
  static String? detectedTitle(AppState state) =>
      session(state).detection?.gameTitle;

  /// Returns the status of the current game detection, when available.
  static GameDetectionStatus? detectionStatus(AppState state) =>
      session(state).detection?.status;

  /// Returns whether the current supported session has a usable memory base.
  static bool isReady(AppState state) =>
      session(state).detection?.status == GameDetectionStatus.supportedGame &&
      session(state).memoryBase != null;

  /// Returns the selected process IDs for connection presentation.
  static List<int> processIds(AppState state) => session(state).processIds;

  /// Returns the selected process ID for connection presentation.
  static int? selectedProcessId(AppState state) =>
      session(state).selectedProcessId;

  /// Returns the current detection outcome for connection presentation.
  static GameDetectionResult? detection(AppState state) =>
      session(state).detection;

  /// Returns the current session error for presentation.
  static String? errorMessage(AppState state) => session(state).errorMessage;

  /// Returns whether the current session has a usable guest memory base.
  static bool hasMemoryBase(AppState state) =>
      session(state).memoryBase != null;

  /// Returns fields from the current SDK profile in profile order.
  static List<GameField> fields(AppState state) =>
      session(state).profile?.fields.values.toList(growable: false) ??
      const <GameField>[];

  /// Selects each profile field with the SDK outcomes and row permissions.
  static List<
    ({
      GameField field,
      GameReadResult? readResult,
      GameWriteResult? writeResult,
      bool canRead,
      bool canWrite,
      bool isEditing,
    })
  >
  fieldRows(AppState state) {
    final currentSession = session(state);
    final currentProfile = currentSession.profile;
    if (currentProfile == null) return const [];

    return List.unmodifiable(
      currentProfile.fields.values.map(
        (field) => (
          field: field,
          readResult: currentSession.readResults[field.id],
          writeResult: currentSession.lastWriteResult?.fieldId == field.id
              ? currentSession.lastWriteResult
              : null,
          canRead: currentProfile.canRead && field.canRead,
          canWrite: TrainerWriteEligibility.isWriteEligible(
            currentSession,
            field,
          ),
          isEditing:
              state.trainer.editingFieldId == field.id &&
              TrainerWriteEligibility.hasValidTarget(currentSession, field),
        ),
      ),
    );
  }

  /// Returns the SDK read outcome for [field] in the current session.
  static GameReadResult? readResult(AppState state, GameField field) =>
      session(state).readResults[field.id];

  /// Returns the latest SDK write outcome when it belongs to [field].
  static GameWriteResult? writeResult(AppState state, GameField field) {
    final result = session(state).lastWriteResult;
    return result?.fieldId == field.id ? result : null;
  }

  /// Returns whether the current profile and [field] permit displaying reads.
  static bool canRead(AppState state, GameField field) =>
      session(state).profile?.canRead == true && field.canRead;

  /// Returns whether the current SDK snapshot allows [field] to be edited.
  static bool canEdit(AppState state, GameField field) =>
      TrainerWriteEligibility.isWriteEligible(session(state), field);

  /// Returns whether the selected edit still targets [field] safely.
  static bool isEditing(AppState state, GameField field) =>
      state.trainer.editingFieldId == field.id &&
      TrainerWriteEligibility.hasValidTarget(session(state), field);

  /// Returns the field currently being edited, if it still exists.
  static GameField? editingField(AppState state) {
    final fieldId = state.trainer.editingFieldId;
    return fieldId == null ? null : session(state).profile?.findField(fieldId);
  }
}
