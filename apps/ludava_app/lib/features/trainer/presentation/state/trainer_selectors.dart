import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Selects pure trainer presentation values from Redux state.
abstract final class TrainerSelectors {
  /// Returns the latest authoritative trainer session from [state].
  static TrainerSessionState session(AppState state) => state.trainer.session;

  /// Returns fields from the current SDK profile in profile order.
  static List<GameField> fields(AppState state) =>
      session(state).profile?.fields.values.toList(growable: false) ??
      const <GameField>[];

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

  /// Returns whether a supported profile has a usable session memory base.
  static bool isReady(AppState state) =>
      session(state).detection?.status == GameDetectionStatus.supportedGame &&
      session(state).memoryBase != null;

  /// Returns the field currently being edited, if it still exists.
  static GameField? editingField(AppState state) {
    final fieldId = state.trainer.editingFieldId;
    return fieldId == null ? null : session(state).profile?.findField(fieldId);
  }
}
