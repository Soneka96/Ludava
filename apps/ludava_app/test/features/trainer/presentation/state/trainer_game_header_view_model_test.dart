import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_game_header_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:redux/redux.dart';

void main() {
  group('Property props behaves correctly', () {
    test('Property props includes state and excludes callback identity', () {
      final state = AppState(
        trainer: TrainerState(session: trainerStateFixtureSession()),
      );
      final first = TrainerGameHeaderViewModel(state: state, onRefresh: () {});
      final second = TrainerGameHeaderViewModel(
        state: state,
        onRefresh: () => throw StateError('callback identity is ignored'),
      );

      expect(first.props, [state]);
      expect(first, second);
    });
  });

  group('Class TrainerGameHeaderViewModel construction', () {
    test('Class TrainerGameHeaderViewModel.fromStore dispatches refresh', () {
      final receivedActions = <Object>[];
      final store = Store<AppState>(
        (state, action) {
          receivedActions.add(action);
          return appReducer(state, action);
        },
        initialState: AppState(
          trainer: TrainerState(session: trainerStateFixtureSession()),
        ),
      );
      final viewModel = TrainerGameHeaderViewModel.fromStore(store);

      viewModel.onRefresh();

      expect(receivedActions, hasLength(1));
      expect(receivedActions.single, isA<RefreshTrainerAction>());
    });
  });
}
