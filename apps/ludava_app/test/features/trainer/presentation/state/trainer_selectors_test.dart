import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_selectors.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

import '../../../../support/trainer_state_fixture.dart';

void main() {
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
      expect(rows.first.isEditing, isTrue);
      expect(rows.last.readResult, isNull);
      expect(rows.last.writeResult, isNull);
      expect(rows.last.isEditing, isFalse);
    });

    test(
      'Method fieldRows() preserves an active edit independently of reads',
      () {
        final session = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.readFailed,
            fieldId: 'credits',
          ),
        );
        final state = AppState(trainer: TrainerState(session: session));

        final row = TrainerSelectors.fieldRows(state).single;

        final active = AppState(
          trainer: TrainerState(session: session, editingFieldId: 'credits'),
        );
        expect(row.readResult, isNotNull);
        expect(TrainerSelectors.fieldRows(active).single.isEditing, isTrue);
      },
    );

    test(
      'Method fieldRows() preserves registered fields without read results',
      () {
        final field = trainerStateFixtureField();
        final profile = GameProfile(
          id: 'synthetic-profile',
          gameName: 'Synthetic Game',
          buildId: 'test-build',
          executable: 'synthetic.exe',
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

        final row = TrainerSelectors.fieldRows(state).single;
        expect(row.readResult, isNull);
        expect(row.isEditing, isFalse);
      },
    );

    test('Method fieldRows() returns no rows without a selected profile', () {
      final state = AppState(
        trainer: TrainerState(session: TrainerSessionState()),
      );

      expect(TrainerSelectors.fieldRows(state), isEmpty);
    });

    test('Method fieldRows() omits a read result for a different field', () {
      final state = AppState(
        trainer: TrainerState(
          session: trainerStateFixtureSession(
            readResult: const GameReadResult(
              status: GameReadStatus.success,
              fieldId: 'other-field',
              value: 25,
            ),
          ),
        ),
      );

      final row = TrainerSelectors.fieldRows(state).single;

      expect(row.readResult, isNull);
    });

    test('Method fieldRows() returns an immutable projection', () {
      final state = AppState(
        trainer: TrainerState(session: trainerStateFixtureSession()),
      );
      final rows = TrainerSelectors.fieldRows(state);

      expect(() => rows.add(rows.single), throwsUnsupportedError);
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
