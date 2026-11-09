import 'package:ludava_app/features/trainer/presentation/state/trainer_reducer.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:redux/redux.dart';

/// Combines feature reducers into the root application reducer.
final Reducer<AppState> appReducer = combineReducers<AppState>([
  TypedReducer<AppState, TrainerSessionChangedAction>(_reduceTrainer).call,
  TypedReducer<AppState, BeginEditingAction>(_reduceTrainer).call,
  TypedReducer<AppState, CancelEditingAction>(_reduceTrainer).call,
]);

/// Applies trainer state changes while preserving app state identity on no-op.
AppState _reduceTrainer(AppState state, Object action) {
  final trainer = trainerReducer(state.trainer, action);
  return identical(trainer, state.trainer) ? state : AppState(trainer: trainer);
}
