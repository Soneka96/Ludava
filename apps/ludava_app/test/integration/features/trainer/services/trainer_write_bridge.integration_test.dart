import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_middleware.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/features/trainer/services/trainer_write_bridge.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/state/app.actions.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:redux/redux.dart';

import '../../../../support/mock_trainer_sdk_capability.dart';
import '../../../../support/trainer_state_fixture.dart';

void main() {
  late MockTrainerSdkCapability capability;
  late StreamController<TrainerSessionState> sessionChanges;
  Store<AppState>? activeStore;

  setUp(() {
    sl.pushNewScope();
    capability = MockTrainerSdkCapability();
    sessionChanges = StreamController<TrainerSessionState>.broadcast(
      sync: true,
    );
    when(() => capability.stateChanges)
        .thenAnswer((_) => sessionChanges.stream);
    when(() => capability.connect()).thenAnswer((_) {});
    sl.registerSingleton<TrainerSdkCapability>(capability);
    final gate = SdkOperationGate();
    sl.registerSingleton<SdkOperationGate>(gate);
    sl.registerSingleton<TrainerWriteBridge>(
      TrainerWriteBridge(capability, gate),
    );
  });

  tearDown(() async {
    final store = activeStore;
    if (store != null) {
      final action = ShutdownRequestedAction();
      store.dispatch(action);
      await action.waitForCleanup();
      activeStore = null;
    }
    await sl.popScope();
    await sessionChanges.close();
  });

  group('Integration TrainerWriteBridge reentrant SDK write behavior', () {
    test(
      'Integration TrainerWriteBridge preserves the active edit '
      'on reentrant success',
      () {
        final initialSession = trainerStateFixtureSession();
        final nextSession = trainerStateFixtureSession();
        const result = GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'credits',
          requestedValue: 44,
          readBackValue: 44,
        );
        when(() => capability.writeField('credits', 44)).thenAnswer((_) {
          sessionChanges.add(nextSession);
          return result;
        });
        final store = Store<AppState>(
          appReducer,
          initialState: AppState(
            trainer: TrainerState(
              session: initialSession,
              editingFieldId: 'credits',
            ),
          ),
          middleware: [TrainerMiddleware().call],
          syncStream: true,
        );
        activeStore = store;
        store.dispatch(const InitializeAppAction());

        final returnedResult = sl<TrainerWriteBridge>().writeField(
          'credits',
          44,
        );

        expect(returnedResult, same(result));
        expect(store.state.trainer.session, same(nextSession));
        expect(store.state.trainer.editingFieldId, 'credits');
        final writtenArguments = verify(
          () => capability.writeField(captureAny(), captureAny()),
        ).captured;
        expect(writtenArguments, ['credits', 44]);
      },
    );
  });
}
