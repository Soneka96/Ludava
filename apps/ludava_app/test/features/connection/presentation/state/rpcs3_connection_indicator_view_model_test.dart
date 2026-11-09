import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/state/rpcs3_connection_indicator_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_state.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:redux/redux.dart';

void main() {
  group('Property props behaves correctly', () {
    test('Property props includes the SDK snapshot', () {
      final session = trainerStateFixtureSession();
      final viewModel = Rpcs3ConnectionIndicatorViewModel(session: session);

      expect(viewModel.props, [session]);
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
        Rpcs3ConnectionIndicatorViewModel.fromStore(store).session,
        same(session),
      );
    });
  });
}
