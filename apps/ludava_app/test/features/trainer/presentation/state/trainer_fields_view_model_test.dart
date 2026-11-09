import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_fields_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/features/trainer/services/trainer_write_bridge.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';

import '../../../../support/trainer_state_fixture.dart';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

void main() {
  setUp(() {
    GetIt.instance.pushNewScope();
  });

  tearDown(() async {
    await GetIt.instance.popScope();
  });

  group('Property props behaves correctly', () {
    test(
      'Property props includes presentation state but excludes callbacks',
      () {
        final state = AppState(
          trainer: TrainerState(session: trainerStateFixtureSession()),
        );
        final first = TrainerFieldsViewModel(
          state: state,
          onEditField: (_) {},
          onApplyField: (_, _) =>
              const GameWriteResult(status: GameWriteStatus.none),
          onCancelEditing: () {},
        );
        final second = TrainerFieldsViewModel(
          state: state,
          onEditField: (_) => throw StateError('callback identity is ignored'),
          onApplyField: (_, _) =>
              const GameWriteResult(status: GameWriteStatus.writeFailed),
          onCancelEditing: () =>
              throw StateError('callback identity is ignored'),
        );

        expect(first.props, [state]);
        expect(first, second);
      },
    );
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
      final store = Store<AppState>(
        appReducer,
        initialState: AppState(trainer: TrainerState(session: session)),
      );
      final viewModel = TrainerFieldsViewModel.fromStore(store);

      viewModel.onEditField('credits');
      expect(store.state.trainer.editingFieldId, 'credits');

      viewModel.onCancelEditing();
      expect(store.state.trainer.editingFieldId, isNull);
    });

    test(
      'Class TrainerFieldsViewModel.fromStore routes writes through the bridge',
      () {
        final result = const GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'credits',
          requestedValue: 44,
          readBackValue: 44,
        );
        final capability = _FakeTrainerSdkCapability(result);
        GetIt.instance.registerSingleton<TrainerSdkCapability>(capability);
        GetIt.instance.registerSingleton<SdkOperationGate>(SdkOperationGate());
        GetIt.instance.registerSingleton<TrainerWriteBridge>(
          TrainerWriteBridge(
            GetIt.instance<TrainerSdkCapability>(),
            GetIt.instance<SdkOperationGate>(),
          ),
        );
        final store = Store<AppState>(
          appReducer,
          initialState: AppState(
            trainer: TrainerState(session: trainerStateFixtureSession()),
          ),
        );
        final viewModel = TrainerFieldsViewModel.fromStore(store);

        expect(viewModel.onApplyField('credits', 44), same(result));
        expect(capability.writeCalls, 1);
      },
    );
  });
}

class _FakeTrainerSdkCapability implements TrainerSdkCapability {
  _FakeTrainerSdkCapability(this.result);

  final GameWriteResult result;
  int writeCalls = 0;

  @override
  TrainerSessionState get state => TrainerSessionState();

  @override
  Stream<TrainerSessionState> get stateChanges => const Stream.empty();

  @override
  void connect() {}

  @override
  void refresh() {}

  @override
  bool selectProcess(int processId) => false;

  @override
  GameWriteResult writeField(String fieldId, int value) {
    writeCalls++;
    return result;
  }

  @override
  Future<void> dispose() async {}
}
