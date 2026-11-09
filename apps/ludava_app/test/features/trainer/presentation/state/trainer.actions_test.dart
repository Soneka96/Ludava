import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';

import '../../../../support/trainer_state_fixture.dart';

void main() {
  group('Class TrainerSessionChangedAction construction', () {
    test('Class TrainerSessionChangedAction retains its SDK snapshot', () {
      final session = trainerStateFixtureSession();

      expect(TrainerSessionChangedAction(session).session, same(session));
    });
  });

  group('Class BeginEditingAction construction', () {
    test('Class BeginEditingAction retains the requested field identifier', () {
      expect(const BeginEditingAction('credits').fieldId, 'credits');
    });
  });

  group('Class CancelEditingAction construction', () {
    test('Class CancelEditingAction can be constructed as a const action', () {
      expect(const CancelEditingAction(), isA<CancelEditingAction>());
    });
  });
}
