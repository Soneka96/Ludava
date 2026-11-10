import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/state/rpcs3_connection_indicator_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_state.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:redux/redux.dart';

void main() {
  group('Property props behaves correctly', () {
    test('Property props includes selected process presentation values', () {
      final viewModel = Rpcs3ConnectionIndicatorViewModel(
        processIds: const [42],
        selectedProcessId: 42,
      );

      expect(viewModel.props, [
        const [42],
        42,
      ]);
    });

    test('Property props compares process values and ignores edit state', () {
      final session = trainerStateFixtureSession();
      Rpcs3ConnectionIndicatorViewModel fromState(TrainerState state) {
        final store = Store<AppState>(
          (state, action) => state,
          initialState: AppState(trainer: state),
        );
        return Rpcs3ConnectionIndicatorViewModel.fromStore(store);
      }

      final first = fromState(TrainerState(session: session));
      final equal = fromState(TrainerState(session: session));
      final unrelated = fromState(
        TrainerState(session: session, editingFieldId: 'missing-field'),
      );
      final changed = fromState(
        TrainerState(session: trainerStateFixtureSession(processId: 84)),
      );

      expect(first, equal);
      expect(first, unrelated);
      expect(first, isNot(changed));
    });
  });

  group('Class Rpcs3ConnectionIndicatorViewModel construction', () {
    test('Class Rpcs3ConnectionIndicatorViewModel.fromStore selects current session', () {
      final session = trainerStateFixtureSession();
      final store = Store<AppState>(
        (state, action) => state,
        initialState: AppState(trainer: TrainerState(session: session)),
      );

      expect(
        Rpcs3ConnectionIndicatorViewModel.fromStore(store).processIds,
        session.processIds,
      );
    });
  });
}
