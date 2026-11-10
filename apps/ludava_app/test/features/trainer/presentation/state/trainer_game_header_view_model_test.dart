import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_game_header_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

void main() {
  group('Property props behaves correctly', () {
    test('Property props includes state and excludes callback identity', () {
      final state = AppState(
        trainer: TrainerState(session: trainerStateFixtureSession()),
      );
      final first = TrainerGameHeaderViewModel.fromStore(
        Store<AppState>((state, action) => state, initialState: state),
      );
      final second = TrainerGameHeaderViewModel(
        profile: first.profile,
        detectedTitle: first.detectedTitle,
        processIds: first.processIds,
        selectedProcessId: first.selectedProcessId,
        detectionStatus: first.detectionStatus,
        hasMemoryBase: first.hasMemoryBase,
        errorMessage: first.errorMessage,
        onRefresh: () => throw StateError('callback identity is ignored'),
      );

      expect(first.props, second.props);
      expect(first, second);
    });

    test('Property props compares equal selected presentation values', () {
      TrainerGameHeaderViewModel fromSession({
        String gameName = 'Synthetic Game',
        int processId = 42,
        GameDetectionStatus detectionStatus = GameDetectionStatus.supportedGame,
      }) {
        final store = Store<AppState>(
          (state, action) => state,
          initialState: AppState(
            trainer: TrainerState(
              session: trainerStateFixtureSession(
                gameName: gameName,
                processId: processId,
                detectionStatus: detectionStatus,
              ),
            ),
          ),
        );
        return TrainerGameHeaderViewModel.fromStore(store);
      }

      expect(fromSession(), fromSession());
      expect(fromSession(), isNot(fromSession(gameName: 'Another Game')));
      expect(fromSession(), isNot(fromSession(processId: 84)));
      expect(
        fromSession(),
        isNot(
          fromSession(detectionStatus: GameDetectionStatus.unsupportedGame),
        ),
      );
    });

    test('Property props ignores unrelated editing state changes', () {
      final session = trainerStateFixtureSession();
      TrainerGameHeaderViewModel fromEditingId(String? editingFieldId) {
        final store = Store<AppState>(
          (state, action) => state,
          initialState: AppState(
            trainer: TrainerState(
              session: session,
              editingFieldId: editingFieldId,
            ),
          ),
        );
        return TrainerGameHeaderViewModel.fromStore(store);
      }

      expect(fromEditingId(null), fromEditingId('missing-field'));
    });
  });

  group('Class TrainerGameHeaderViewModel construction', () {
    test('Class TrainerGameHeaderViewModel.fromStore dispatches refresh', () {
      final receivedActions = <Object>[];
      final store = Store<AppState>(
        (state, action) {
          receivedActions.add(action);
          return appReducer(state, action);
        },
        initialState: AppState(
          trainer: TrainerState(session: trainerStateFixtureSession()),
        ),
      );
      final viewModel = TrainerGameHeaderViewModel.fromStore(store);

      viewModel.onRefresh();

      expect(receivedActions, hasLength(1));
      expect(receivedActions.single, isA<RefreshTrainerAction>());
    });
  });
}
