import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_selectors.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Method fields() behaves correctly', () {
    test('Method fields() selects the synthetic profile fields', () {
      final state = AppState(
        trainer: TrainerState(
          session: trainerStateFixtureSession(additionalFieldIds: ['scrap']),
        ),
      );

      expect(TrainerSelectors.fields(state).map((field) => field.id), [
        'credits',
        'scrap',
      ]);
    });

    test('Method fields() returns an empty list without a profile', () {
      final state = AppState(
        trainer: TrainerState(session: TrainerSessionState()),
      );

      expect(TrainerSelectors.fields(state), isEmpty);
    });
  });

  group('Method canEdit() behaves correctly', () {
    test('Method canEdit() reflects SDK eligibility', () {
      final session = trainerStateFixtureSession(
        readResult: const GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
          value: 25,
        ),
      );
      final state = AppState(trainer: TrainerState(session: session));
      final field = session.profile!.fields['credits']!;

      expect(TrainerSelectors.canEdit(state, field), isTrue);
    });
  });

  group('Method editingField() behaves correctly', () {
    test('Method editingField() resolves the active profile field', () {
      final state = AppState(
        trainer: TrainerState(
          session: trainerStateFixtureSession(),
          editingFieldId: 'credits',
        ),
      );

      expect(TrainerSelectors.editingField(state)?.id, 'credits');
    });

    test('Method editingField() returns null without an active edit', () {
      final state = AppState(
        trainer: TrainerState(session: trainerStateFixtureSession()),
      );

      expect(TrainerSelectors.editingField(state), isNull);
    });
  });
}
