import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

void main() {
  group('Class AppState construction', () {
    test('Class AppState initializes with the supplied trainer state', () {
      final state = AppState(
        trainer: TrainerState(session: TrainerSessionState()),
      );

      expect(state.trainer.session, isA<TrainerSessionState>());
    });
  });

  group('Property props behaves correctly', () {
    test('Property props includes trainer presentation state', () {
      final trainer = TrainerState(session: TrainerSessionState());

      expect(AppState(trainer: trainer).props, [trainer]);
    });
  });
}
