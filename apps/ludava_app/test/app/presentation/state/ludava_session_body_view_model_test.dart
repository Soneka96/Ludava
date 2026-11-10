import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/state/ludava_session_body_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_state.dart';

import '../../../support/trainer_state_fixture.dart';

import 'package:redux/redux.dart';

void main() {
  group('Class LudavaSessionBodyViewModel construction', () {
    test(
      'Class LudavaSessionBodyViewModel.fromStore dispatches process selection',
      () {
        final actions = <Object>[];
        final store = Store<AppState>(
          (state, action) {
            actions.add(action);
            return state;
          },
          initialState: AppState(
            trainer: TrainerState(session: trainerStateFixtureSession()),
          ),
        );

        LudavaSessionBodyViewModel.fromStore(store).onSelectProcess(42);

        expect(actions, hasLength(1));
        expect(actions.single, isA<SelectRpcs3ProcessAction>());
        expect((actions.single as SelectRpcs3ProcessAction).processId, 42);
      },
    );
  });
}
