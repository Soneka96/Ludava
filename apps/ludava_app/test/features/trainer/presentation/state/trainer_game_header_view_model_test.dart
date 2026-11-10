import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_game_header_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_state.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:redux/redux.dart';

void main() {
  group('Class TrainerGameHeaderViewModel construction', () {
    test('Class TrainerGameHeaderViewModel.fromStore dispatches refresh', () {
      final receivedActions = <Object>[];
      final store = Store<AppState>(
        (state, action) {
          receivedActions.add(action);
          return state;
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
