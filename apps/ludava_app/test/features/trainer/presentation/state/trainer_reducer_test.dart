import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_reducer.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Reducer trainerReducer() behaves correctly', () {
    test(
      'Reducer trainerReducer() preserves identity for an inactive cancel',
      () {
        final state = TrainerState(session: TrainerSessionState());

        expect(trainerReducer(state, const CancelEditingAction()), same(state));
      },
    );

    test(
      'Reducer trainerReducer() ignores an identical snapshot reference',
      () {
        final session = trainerStateFixtureSession();
        final state = TrainerState(session: session, editingFieldId: 'credits');

        expect(
          trainerReducer(state, TrainerSessionChangedAction(session)),
          same(state),
        );
      },
    );

    test('Reducer trainerReducer() accepts a distinct SDK snapshot', () {
      final state = TrainerState(session: trainerStateFixtureSession());
      final nextSession = trainerStateFixtureSession(memoryBase: 0x2000);

      final next = trainerReducer(
        state,
        TrainerSessionChangedAction(nextSession),
      );

      expect(next, isNot(same(state)));
      expect(next.session, same(nextSession));
    });

    test('Reducer trainerReducer() begins editing an eligible field', () {
      final session = trainerStateFixtureSession(
        readResult: GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
          value: 25,
        ),
      );
      final state = TrainerState(session: session);

      expect(
        trainerReducer(
          state,
          const BeginEditingAction('credits'),
        ).editingFieldId,
        'credits',
      );
    });

    test('Reducer trainerReducer() rejects an ineligible field edit', () {
      final state = TrainerState(session: trainerStateFixtureSession());

      expect(
        trainerReducer(state, const BeginEditingAction('credits')),
        same(state),
      );
      expect(
        trainerReducer(state, const BeginEditingAction('missing')),
        same(state),
      );
    });

    test(
      'Reducer trainerReducer() preserves an edit in the same valid session',
      () {
        final state = TrainerState(
          session: trainerStateFixtureSession(),
          editingFieldId: 'credits',
        );
        final nextSession = trainerStateFixtureSession();

        final next = trainerReducer(
          state,
          TrainerSessionChangedAction(nextSession),
        );

        expect(next.editingFieldId, 'credits');
        expect(next.session, same(nextSession));
      },
    );

    test('Reducer trainerReducer() preserves a matching failed-read edit', () {
      final failedRead = GameReadResult(
        status: GameReadStatus.readFailed,
        fieldId: 'credits',
      );
      final state = TrainerState(
        session: trainerStateFixtureSession(),
        editingFieldId: 'credits',
      );
      final nextSession = trainerStateFixtureSession(
        readResult: failedRead,
        lastWriteResult: const GameWriteResult(
          status: GameWriteStatus.writeFailed,
          fieldId: 'credits',
        ),
      );

      expect(
        trainerReducer(
          state,
          TrainerSessionChangedAction(nextSession),
        ).editingFieldId,
        'credits',
      );
    });

    test('Reducer trainerReducer() clears failed-read edits without a matching write', () {
      final state = TrainerState(
        session: trainerStateFixtureSession(),
        editingFieldId: 'credits',
      );
      final nextSession = trainerStateFixtureSession(
        readResult: GameReadResult(
          status: GameReadStatus.readFailed,
          fieldId: 'credits',
        ),
      );

      expect(
        trainerReducer(
          state,
          TrainerSessionChangedAction(nextSession),
        ).editingFieldId,
        isNull,
      );
    });

    test(
      'Reducer trainerReducer() clears edits when the session target changes',
      () {
        final state = TrainerState(
          session: trainerStateFixtureSession(),
          editingFieldId: 'credits',
        );
        final nextSession = trainerStateFixtureSession(memoryBase: 0x2000);

        expect(
          trainerReducer(
            state,
            TrainerSessionChangedAction(nextSession),
          ).editingFieldId,
          isNull,
        );
      },
    );

    test('Reducer trainerReducer() clears edits after the process changes', () {
      final state = TrainerState(
        session: trainerStateFixtureSession(),
        editingFieldId: 'credits',
      );
      final nextSession = trainerStateFixtureSession(processId: 43);

      expect(
        trainerReducer(
          state,
          TrainerSessionChangedAction(nextSession),
        ).editingFieldId,
        isNull,
      );
    });

    test('Reducer trainerReducer() clears edits after process restart', () {
      final state = TrainerState(
        session: trainerStateFixtureSession(),
        editingFieldId: 'credits',
      );
      final nextSession = trainerStateFixtureSession(
        startedAtUtc: DateTime.utc(2025),
      );

      expect(
        trainerReducer(
          state,
          TrainerSessionChangedAction(nextSession),
        ).editingFieldId,
        isNull,
      );
    });

    test('Reducer trainerReducer() clears edits after detection changes', () {
      final state = TrainerState(
        session: trainerStateFixtureSession(),
        editingFieldId: 'credits',
      );
      final nextSession = trainerStateFixtureSession(
        detectionStatus: GameDetectionStatus.noActiveGame,
      );

      expect(
        trainerReducer(
          state,
          TrainerSessionChangedAction(nextSession),
        ).editingFieldId,
        isNull,
      );
    });

    test(
      'Reducer trainerReducer() clears edits after identity confidence changes',
      () {
        final state = TrainerState(
          session: trainerStateFixtureSession(),
          editingFieldId: 'credits',
        );
        final nextSession = trainerStateFixtureSession(
          confidence: GameIdentityConfidence.manuallySelected,
        );

        expect(
          trainerReducer(
            state,
            TrainerSessionChangedAction(nextSession),
          ).editingFieldId,
          isNull,
        );
      },
    );

    test(
      'Reducer trainerReducer() clears edits after profile identity changes',
      () {
        final state = TrainerState(
          session: trainerStateFixtureSession(),
          editingFieldId: 'credits',
        );
        final nextSession = trainerStateFixtureSession(
          profileId: 'other-profile',
        );

        expect(
          trainerReducer(
            state,
            TrainerSessionChangedAction(nextSession),
          ).editingFieldId,
          isNull,
        );
      },
    );

    test(
      'Reducer trainerReducer() clears edits after executable hash changes',
      () {
        final state = TrainerState(
          session: trainerStateFixtureSession(),
          editingFieldId: 'credits',
        );
        final nextSession = trainerStateFixtureSession(
          executableHash: 'new-hash',
        );

        expect(
          trainerReducer(
            state,
            TrainerSessionChangedAction(nextSession),
          ).editingFieldId,
          isNull,
        );
      },
    );

    test('Reducer trainerReducer() clears edits when the field disappears', () {
      final state = TrainerState(
        session: trainerStateFixtureSession(),
        editingFieldId: 'credits',
      );
      final nextSession = trainerStateFixtureSession(fieldId: 'scrap');

      expect(
        trainerReducer(
          state,
          TrainerSessionChangedAction(nextSession),
        ).editingFieldId,
        isNull,
      );
    });

    test(
      'Reducer trainerReducer() clears edits when the target is ineligible',
      () {
        final state = TrainerState(
          session: trainerStateFixtureSession(),
          editingFieldId: 'credits',
        );
        final nextSession = trainerStateFixtureSession(
          selectedProcessPresent: false,
        );

        expect(
          trainerReducer(
            state,
            TrainerSessionChangedAction(nextSession),
          ).editingFieldId,
          isNull,
        );
      },
    );

    test('Reducer trainerReducer() cancels an active edit', () {
      final state = TrainerState(
        session: trainerStateFixtureSession(),
        editingFieldId: 'credits',
      );

      expect(
        trainerReducer(state, const CancelEditingAction()).editingFieldId,
        isNull,
      );
    });
  });
}
