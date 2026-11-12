import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_fields_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/services/trainer_write_bridge.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:redux/redux.dart';

import '../../../../support/trainer_state_fixture.dart';

class _MockTrainerWriteBridge extends Mock implements TrainerWriteBridge {}

void main() {
  setUp(() {
    GetIt.instance.pushNewScope();
  });

  tearDown(() async {
    await GetIt.instance.popScope();
  });

  group('Class TrainerFieldsViewModel construction', () {
    test('Class TrainerFieldsViewModel.fromStore dispatches edit actions', () {
      final session = trainerStateFixtureSession(
        readResult: const GameReadResult(
          status: GameReadStatus.success,
          fieldId: 'credits',
          value: 25,
        ),
      );
      final actions = <Object>[];
      final store = Store<AppState>((state, action) {
        actions.add(action);
        return state;
      }, initialState: AppState(trainer: TrainerState(session: session)));
      final viewModel = TrainerFieldsViewModel.fromStore(store);

      viewModel.onEditField('credits');
      viewModel.onCancelEditing();

      expect(actions, hasLength(2));
      expect(actions.first, isA<BeginEditingAction>());
      expect((actions.first as BeginEditingAction).fieldId, 'credits');
      expect(actions.last, isA<CancelEditingAction>());
    });

    test(
      'Class TrainerFieldsViewModel.fromStore routes writes through the bridge',
      () {
        const result = GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'credits',
          requestedValue: 44,
          readBackValue: 44,
        );
        final bridge = _MockTrainerWriteBridge();
        final session = trainerStateFixtureSession();
        final field = session.profile!.findField('credits')!;
        when(
          () => bridge.writeField(
            'credits',
            44,
            expectedSession: session,
            expectedField: field,
          ),
        ).thenReturn(result);
        GetIt.instance.registerSingleton<TrainerWriteBridge>(bridge);
        final store = Store<AppState>(
          (state, action) => state,
          initialState: AppState(
            trainer: TrainerState(session: session, editingFieldId: 'credits'),
          ),
        );
        final viewModel = TrainerFieldsViewModel.fromStore(store);

        expect(viewModel.onApplyField('credits', 44), same(result));
        verify(
          () => bridge.writeField(
            'credits',
            44,
            expectedSession: session,
            expectedField: field,
          ),
        ).called(1);
        verifyNoMoreInteractions(bridge);
      },
    );

    test('Class TrainerFieldsViewModel.fromStore rejects a callback without an active edit', () {
      final bridge = _MockTrainerWriteBridge();
      GetIt.instance.registerSingleton<TrainerWriteBridge>(bridge);
      final store = Store<AppState>(
        (state, action) => state,
        initialState: AppState(
          trainer: TrainerState(session: trainerStateFixtureSession()),
        ),
      );
      final viewModel = TrainerFieldsViewModel.fromStore(store);

      final result = viewModel.onApplyField('credits', 44);

      expect(result.status, GameWriteStatus.none);
      verifyNoMoreInteractions(bridge);
    });
  });
}
