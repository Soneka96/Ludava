import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/state/ludava_session_body_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';

import '../../../support/trainer_state_fixture.dart';

import 'package:redux/redux.dart';

void main() {
  group('Property props behaves correctly', () {
    test(
      'Property props includes Redux state but excludes callback identity',
      () {
        final state = AppState(
          trainer: TrainerState(session: trainerStateFixtureSession()),
        );
        final first = LudavaSessionBodyViewModel(
          state: state,
          onSelectProcess: (_) {},
        );
        final second = LudavaSessionBodyViewModel(
          state: state,
          onSelectProcess: (_) =>
              throw StateError('callback identity is ignored'),
        );

        expect(first.props, [state]);
        expect(first, second);
      },
    );
  });

  group('Class LudavaSessionBodyViewModel construction', () {
    test(
      'Class LudavaSessionBodyViewModel.fromStore dispatches process selection',
      () {
        final actions = <Object>[];
        final store = Store<AppState>(
          (state, action) {
            actions.add(action);
            return appReducer(state, action);
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
