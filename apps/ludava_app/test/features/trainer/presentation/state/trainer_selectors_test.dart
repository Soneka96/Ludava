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

  group('Method focused selectors behave correctly', () {
    test('Method focused selectors expose profile identity values', () {
      final state = AppState(
        trainer: TrainerState(session: trainerStateFixtureSession()),
      );

      expect(TrainerSelectors.profile(state)?.id, 'synthetic-profile');
      expect(TrainerSelectors.hasProfile(state), isTrue);
      expect(TrainerSelectors.detectedTitle(state), isNull);
      expect(
        TrainerSelectors.detectionStatus(state),
        GameDetectionStatus.supportedGame,
      );
    });

    test(
      'Method focused selectors return empty identity without detection',
      () {
        final state = AppState(
          trainer: TrainerState(session: TrainerSessionState()),
        );

        expect(TrainerSelectors.profile(state), isNull);
        expect(TrainerSelectors.hasProfile(state), isFalse);
        expect(TrainerSelectors.detectedTitle(state), isNull);
        expect(TrainerSelectors.detectionStatus(state), isNull);
      },
    );
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

  group('Method fieldRows() behaves correctly', () {
    test('Method fieldRows() projects ordered SDK row values', () {
      final session = trainerStateFixtureSession(
        additionalFieldIds: ['scrap'],
        readResult: const GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
          value: 25,
        ),
        lastWriteResult: const GameWriteResult(
          status: GameWriteStatus.writeFailed,
          fieldId: 'credits',
          requestedValue: 26,
        ),
      );
      final state = AppState(
        trainer: TrainerState(session: session, editingFieldId: 'credits'),
      );

      final rows = TrainerSelectors.fieldRows(state);

      expect(rows.map((row) => row.field.id), ['credits', 'scrap']);
      expect(rows.first.readResult?.value, 25);
      expect(rows.first.writeResult?.requestedValue, 26);
      expect(rows.first.canRead, isTrue);
      expect(rows.first.canWrite, isTrue);
      expect(rows.first.isEditing, isTrue);
      expect(rows.last.readResult, isNull);
      expect(rows.last.writeResult, isNull);
      expect(rows.last.isEditing, isFalse);
    });

    test('Method fieldRows() keeps SDK write eligibility authoritative', () {
      final session = trainerStateFixtureSession(
        fieldWriteStatus: VerificationStatus.experimental,
        readResult: const GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
          value: 25,
        ),
      );
      final state = AppState(
        trainer: TrainerState(session: session, editingFieldId: 'credits'),
      );

      final row = TrainerSelectors.fieldRows(state).single;

      expect(row.canWrite, isFalse);
      expect(row.isEditing, isFalse);
      expect(
        TrainerSelectors.canEdit(state, session.profile!.fields['credits']!),
        isFalse,
      );
    });

    test('Method fieldRows() respects profile read permission', () {
      final field = trainerStateFixtureField();
      final profile = GameProfile(
        id: 'synthetic-profile',
        gameName: 'Synthetic Game',
        buildId: 'test-build',
        executable: 'synthetic.exe',
        readStatus: VerificationStatus.none,
        fields: {field.id: field},
      );
      final session = TrainerSessionState(
        detection: GameDetectionResult(
          status: GameDetectionStatus.supportedGame,
          confidence: GameIdentityConfidence.confirmed,
          profile: profile,
          evidenceDescription: 'Synthetic test evidence',
        ),
      );
      final state = AppState(trainer: TrainerState(session: session));

      expect(TrainerSelectors.fieldRows(state).single.canRead, isFalse);
      expect(TrainerSelectors.canRead(state, field), isFalse);
    });

    test('Method fieldRows() respects field read permission', () {
      final field = trainerStateFixtureField(
        readStatus: VerificationStatus.none,
      );
      final profile = GameProfile(
        id: 'synthetic-profile',
        gameName: 'Synthetic Game',
        buildId: 'test-build',
        executable: 'synthetic.exe',
        readStatus: VerificationStatus.verified,
        fields: {field.id: field},
      );
      final session = TrainerSessionState(
        detection: GameDetectionResult(
          status: GameDetectionStatus.supportedGame,
          confidence: GameIdentityConfidence.confirmed,
          profile: profile,
          evidenceDescription: 'Synthetic test evidence',
        ),
      );
      final state = AppState(trainer: TrainerState(session: session));

      expect(TrainerSelectors.fieldRows(state).single.canRead, isFalse);
      expect(TrainerSelectors.canRead(state, field), isFalse);
    });

    test('Method fieldRows() returns no rows without a selected profile', () {
      final state = AppState(
        trainer: TrainerState(session: TrainerSessionState()),
      );

      expect(TrainerSelectors.fieldRows(state), isEmpty);
    });

    test('Method fieldRows() returns an immutable projection', () {
      final state = AppState(
        trainer: TrainerState(session: trainerStateFixtureSession()),
      );
      final rows = TrainerSelectors.fieldRows(state);

      expect(() => rows.add(rows.single), throwsUnsupportedError);
    });
  });

  group('Method processIds() behaves correctly', () {
    test('Method processIds() returns the SDK immutable collection', () {
      final session = trainerStateFixtureSession();
      final state = AppState(trainer: TrainerState(session: session));

      expect(TrainerSelectors.processIds(state), same(session.processIds));
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
