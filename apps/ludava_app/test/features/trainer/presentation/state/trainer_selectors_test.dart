import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_selectors.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Method session() behaves correctly', () {
    test('Method session() returns the authoritative SDK snapshot', () {
      final session = trainerStateFixtureSession();
      final state = AppState(trainer: TrainerState(session: session));

      expect(TrainerSelectors.session(state), same(session));
    });
  });

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

  group('Method readResult() behaves correctly', () {
    test('Method readResult() selects the SDK result for a field', () {
      final result = const GameReadResult(
        status: GameReadStatus.success,
        fieldId: 'credits',
        value: 25,
      );
      final state = AppState(
        trainer: TrainerState(
          session: trainerStateFixtureSession(readResult: result),
        ),
      );
      final field = state.trainer.session.profile!.fields['credits']!;

      expect(TrainerSelectors.readResult(state, field), same(result));
    });
  });

  group('Method writeResult() behaves correctly', () {
    test(
      'Method writeResult() returns only a result for its matching field',
      () {
        final result = const GameWriteResult(
          status: GameWriteStatus.writeFailed,
          fieldId: 'credits',
          requestedValue: 25,
        );
        final state = AppState(
          trainer: TrainerState(
            session: trainerStateFixtureSession(lastWriteResult: result),
          ),
        );
        final matchingField = state.trainer.session.profile!.fields['credits']!;
        final otherField = trainerStateFixtureField(id: 'scrap');

        expect(
          TrainerSelectors.writeResult(state, matchingField),
          same(result),
        );
        expect(TrainerSelectors.writeResult(state, otherField), isNull);
      },
    );
  });

  group('Method canRead() behaves correctly', () {
    test('Method canRead() reflects profile and field read permission', () {
      final state = AppState(
        trainer: TrainerState(session: trainerStateFixtureSession()),
      );
      final field = state.trainer.session.profile!.fields['credits']!;

      expect(TrainerSelectors.canRead(state, field), isTrue);
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

  group('Method isEditing() behaves correctly', () {
    test('Method isEditing() requires a matching valid active edit', () {
      final state = AppState(
        trainer: TrainerState(
          session: trainerStateFixtureSession(),
          editingFieldId: 'credits',
        ),
      );
      final field = state.trainer.session.profile!.fields['credits']!;

      expect(TrainerSelectors.isEditing(state, field), isTrue);
      expect(
        TrainerSelectors.isEditing(
          state,
          trainerStateFixtureField(id: 'scrap'),
        ),
        isFalse,
      );
    });
  });

  group('Method isReady() behaves correctly', () {
    test('Method isReady() requires supported detection and a memory base', () {
      final ready = AppState(
        trainer: TrainerState(session: trainerStateFixtureSession()),
      );
      final missingBase = AppState(
        trainer: TrainerState(
          session: trainerStateFixtureSession(memoryBase: null),
        ),
      );
      final unsupported = AppState(
        trainer: TrainerState(
          session: trainerStateFixtureSession(
            detectionStatus: GameDetectionStatus.unsupportedGame,
          ),
        ),
      );

      expect(TrainerSelectors.isReady(ready), isTrue);
      expect(TrainerSelectors.isReady(missingBase), isFalse);
      expect(TrainerSelectors.isReady(unsupported), isFalse);
    });
  });
}
