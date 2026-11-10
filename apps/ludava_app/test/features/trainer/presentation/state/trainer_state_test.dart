import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';

import '../../../../support/trainer_state_fixture.dart';

void main() {
  group('Method copyWith() behaves correctly', () {
    test('Method copyWith() replaces the snapshot and preserves the edit', () {
      final state = TrainerState(
        session: trainerStateFixtureSession(),
        editingFieldId: 'credits',
      );
      final nextSession = trainerStateFixtureSession(memoryBase: 0x2000);

      final next = state.copyWith(session: nextSession);

      expect(next.session, same(nextSession));
      expect(next.editingFieldId, 'credits');
    });

    test('Method copyWith() clears the edit when requested', () {
      final state = TrainerState(
        session: trainerStateFixtureSession(),
        editingFieldId: 'credits',
      );

      expect(state.copyWith(clearEditingField: true).editingFieldId, isNull);
    });
  });
}
