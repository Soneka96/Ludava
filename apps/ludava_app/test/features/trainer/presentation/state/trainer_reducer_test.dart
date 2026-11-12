import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_reducer.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

import '../../../../support/trainer_state_fixture.dart';

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

    test('Reducer trainerReducer() begins editing an exactly read field', () {
      final session = trainerStateFixtureSession(
        readResult: const GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
          value: 25,
        ),
      );

      expect(
        trainerReducer(
          TrainerState(session: session),
          const BeginEditingAction('credits'),
        ).editingFieldId,
        'credits',
      );
    });

    test(
      'Reducer trainerReducer() allows editing unconfirmed unbounded values',
      () {
        final session = trainerStateFixtureSession(
          confidence: GameIdentityConfidence.manuallySelected,
          minimumValue: null,
          maximumValue: null,
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 25,
          ),
        );

        expect(
          trainerReducer(
            TrainerState(session: session),
            const BeginEditingAction('credits'),
          ).editingFieldId,
          'credits',
        );
      },
    );

    test(
      'Reducer trainerReducer() requires a registered successful numeric read',
      () {
        final missingProfileField = trainerStateFixtureSession(
          emptyProfile: true,
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 25,
          ),
        );
        final missingRead = trainerStateFixtureSession();
        final failedRead = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.readFailed,
            fieldId: 'credits',
          ),
        );
        final mismatchedRead = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'other-field',
            value: 25,
          ),
        );

        for (final session in [
          missingProfileField,
          missingRead,
          failedRead,
          mismatchedRead,
        ]) {
          final state = TrainerState(session: session);
          expect(
            trainerReducer(state, const BeginEditingAction('credits')),
            same(state),
          );
        }
      },
    );

    test(
      'Reducer trainerReducer() preserves drafts across same-target reads',
      () {
        final initial = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 25,
          ),
        );
        final state = TrainerState(session: initial, editingFieldId: 'credits');
        final updates = [
          trainerStateFixtureSession(
            readResult: const GameReadResult(
              status: GameReadStatus.readFailed,
              fieldId: 'credits',
            ),
          ),
          trainerStateFixtureSession(
            readResult: const GameReadResult(
              status: GameReadStatus.success,
              fieldId: 'credits',
              value: 99,
            ),
          ),
          trainerStateFixtureSession(
            confidence: GameIdentityConfidence.manuallySelected,
          ),
        ];

        for (final session in updates) {
          final next = trainerReducer(
            state,
            TrainerSessionChangedAction(session),
          );
          expect(next.editingFieldId, 'credits');
          expect(next.session, same(session));
        }
      },
    );

    test(
      'Reducer trainerReducer() invalidates drafts when process changes',
      () {
        final state = TrainerState(
          session: trainerStateFixtureSession(),
          editingFieldId: 'credits',
        );

        expect(
          trainerReducer(
            state,
            TrainerSessionChangedAction(
              trainerStateFixtureSession(processId: 43),
            ),
          ).editingFieldId,
          isNull,
        );
        expect(
          trainerReducer(
            state,
            TrainerSessionChangedAction(
              trainerStateFixtureSession(startedAtUtc: DateTime.utc(2025)),
            ),
          ).editingFieldId,
          isNull,
        );
      },
    );

    test(
      'Reducer trainerReducer() invalidates drafts when game target changes',
      () {
        final state = TrainerState(
          session: trainerStateFixtureSession(),
          editingFieldId: 'credits',
        );
        final changedTargets = [
          trainerStateFixtureSession(profileId: 'other-profile'),
          trainerStateFixtureSession(buildId: 'other-build'),
          trainerStateFixtureSession(executableHash: 'other-hash'),
          trainerStateFixtureSession(memoryBase: 0x2000),
        ];

        for (final session in changedTargets) {
          expect(
            trainerReducer(
              state,
              TrainerSessionChangedAction(session),
            ).editingFieldId,
            isNull,
          );
        }
      },
    );

    test('Reducer trainerReducer() invalidates a changed field mapping', () {
      final state = TrainerState(
        session: trainerStateFixtureSession(),
        editingFieldId: 'credits',
      );
      final changedMappings = [
        trainerStateFixtureSession(guestOffset: 0x200),
        trainerStateFixtureSession(byteOrder: ByteOrder.big),
      ];

      for (final session in changedMappings) {
        expect(
          trainerReducer(
            state,
            TrainerSessionChangedAction(session),
          ).editingFieldId,
          isNull,
        );
      }
    });

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
