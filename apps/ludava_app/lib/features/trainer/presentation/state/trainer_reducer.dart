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
  final retainsEdit =
      _sameTarget(state.session, nextSession) &&
      _sameFieldMapping(
        state.session.profile?.findField(editingFieldId),
        field,
      ) &&
      field != null;

  return TrainerState(
    session: nextSession,
    editingFieldId: retainsEdit ? editingFieldId : null,
  );
}

/// Begins editing when the registered field has an exact successful read.
TrainerState _beginEditing(TrainerState state, BeginEditingAction action) {
  final field = state.session.profile?.findField(action.fieldId);
  final readResult = state.session.readResults[action.fieldId];
  if (field == null ||
      readResult?.fieldId != field.id ||
      readResult?.succeeded != true ||
      readResult?.value == null ||
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

/// Reports whether both snapshots still describe the same selected target.
bool _sameTarget(TrainerSessionState first, TrainerSessionState second) =>
    first.selectedProcessId == second.selectedProcessId &&
    first.processMetadata?.startedAtUtc ==
        second.processMetadata?.startedAtUtc &&
    first.profile?.id == second.profile?.id &&
    first.profile?.buildId == second.profile?.buildId &&
    first.profile?.executable == second.profile?.executable &&
    first.profile?.executableHash == second.profile?.executableHash &&
    first.detection?.executableHash == second.detection?.executableHash &&
    first.memoryBase == second.memoryBase;

/// Reports whether [first] and [second] use the same registered field mapping.
bool _sameFieldMapping(GameField? first, GameField? second) =>
    first != null &&
    second != null &&
    first.id == second.id &&
    first.guestOffset == second.guestOffset &&
    first.valueType == second.valueType &&
    first.byteOrder == second.byteOrder;
