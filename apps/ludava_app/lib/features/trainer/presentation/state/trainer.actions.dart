import 'package:ludava_sdk/ludava_sdk.dart';

/// Reconciles Redux with an authoritative SDK session snapshot.
class TrainerSessionChangedAction {
  /// Snapshot to publish in trainer state.
  final TrainerSessionState session;

  /// Creates an update for [session].
  const TrainerSessionChangedAction(this.session);
}

/// Requests editing for the field identified by [fieldId].
class BeginEditingAction {
  /// Stable identifier of the requested [GameField].
  final String fieldId;

  /// Creates an edit request for [fieldId].
  const BeginEditingAction(this.fieldId);
}

/// Clears the active field edit without changing the SDK snapshot.
class CancelEditingAction {
  /// Creates an edit cancellation request.
  const CancelEditingAction();
}
