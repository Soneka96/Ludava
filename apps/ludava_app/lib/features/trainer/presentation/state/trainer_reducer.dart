import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

/// Reduces trainer actions while keeping SDK session facts authoritative.
final Reducer<TrainerState> trainerReducer = combineReducers<TrainerState>([
  TypedReducer<TrainerState, TrainerSessionChangedAction>(_sessionChanged).call,
  TypedReducer<TrainerState, BeginEditingAction>(_beginEditing).call,
  TypedReducer<TrainerState, CancelEditingAction>(_cancelEditing).call,
]);

/// Replaces an SDK snapshot and atomically invalidates stale edits.
TrainerState _sessionChanged(
  TrainerState state,
  TrainerSessionChangedAction action,
) {
  final nextSession = action.session;
  if (identical(state.session, nextSession)) return state;

  final editingFieldId = state.editingFieldId;
  if (editingFieldId == null) {
    return TrainerState(session: nextSession);
  }

  final field = nextSession.profile?.findField(editingFieldId);
  final readResult = nextSession.readResults[editingFieldId];
  final retainsEdit =
      _sameSession(state.session, nextSession) &&
      field != null &&
      TrainerWriteEligibility.hasValidTarget(nextSession, field) &&
      (readResult == null ||
          readResult.succeeded ||
          nextSession.lastWriteResult?.fieldId == editingFieldId);

  return TrainerState(
    session: nextSession,
    editingFieldId: retainsEdit ? editingFieldId : null,
  );
}

/// Begins editing only when the SDK snapshot marks the field eligible.
TrainerState _beginEditing(TrainerState state, BeginEditingAction action) {
  final field = state.session.profile?.findField(action.fieldId);
  if (field == null ||
      !TrainerWriteEligibility.isWriteEligible(state.session, field) ||
      state.editingFieldId == action.fieldId) {
    return state;
  }
  return state.copyWith(editingFieldId: action.fieldId);
}

/// Clears the active edit when one exists.
TrainerState _cancelEditing(TrainerState state, CancelEditingAction action) =>
    state.editingFieldId == null
    ? state
    : state.copyWith(clearEditingField: true);

/// Reports whether both snapshots describe the same write target.
bool _sameSession(TrainerSessionState first, TrainerSessionState second) =>
    first.selectedProcessId == second.selectedProcessId &&
    first.processMetadata?.startedAtUtc ==
        second.processMetadata?.startedAtUtc &&
    first.detection?.status == second.detection?.status &&
    first.detection?.confidence == second.detection?.confidence &&
    first.profile?.id == second.profile?.id &&
    first.detection?.executableHash == second.detection?.executableHash &&
    first.memoryBase == second.memoryBase;
