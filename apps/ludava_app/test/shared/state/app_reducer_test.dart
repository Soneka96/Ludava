import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';

import '../../support/trainer_state_fixture.dart';

void main() {
  group('Reducer appReducer() behaves correctly', () {
    test('Reducer appReducer() preserves identity for an unrelated action', () {
      final state = AppState(
        trainer: TrainerState(session: trainerStateFixtureSession()),
      );

      expect(appReducer(state, Object()), same(state));
    });

    test('Reducer appReducer() applies trainer state changes', () {
      final session = trainerStateFixtureSession();
      final state = AppState(trainer: TrainerState(session: session));
      final nextSession = trainerStateFixtureSession(memoryBase: 0x2000);

      final next = appReducer(state, TrainerSessionChangedAction(nextSession));

      expect(next, isNot(same(state)));
      expect(next.trainer.session, same(nextSession));
    });
  });
}
