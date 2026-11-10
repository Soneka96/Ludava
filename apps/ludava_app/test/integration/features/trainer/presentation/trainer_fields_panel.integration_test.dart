import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_fields_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_middleware.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/features/trainer/services/trainer_write_bridge.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/state/app.actions.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:redux/redux.dart';

import '../../../../support/mock_trainer_sdk_capability.dart';
import '../../../../support/trainer_state_fixture.dart';

Store<AppState> _createStore(TrainerSessionState session) => Store<AppState>(
  appReducer,
  initialState: AppState(trainer: TrainerState(session: session)),
  middleware: [TrainerMiddleware().call],
  syncStream: true,
);

Widget _wrap(Store<AppState> store) => StoreProvider<AppState>(
  store: store,
  child: MaterialApp(
    theme: LudavaTheme.graphiteAndTeal,
    home: const Scaffold(body: TrainerFieldsPanel()),
  ),
);

Future<void> _openCreditsEditor(
  WidgetTester tester,
  Store<AppState> store,
) async {
  await tester.tap(find.byTooltip('Edit Credits'));
  await tester.pump();
  expect(store.state.trainer.editingFieldId, 'credits');
}

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
    final operationGate = SdkOperationGate();
    sl.registerSingleton<SdkOperationGate>(operationGate);
    sl.registerSingleton<TrainerWriteBridge>(
      TrainerWriteBridge(capability, operationGate),
    );
    sl.registerFactoryParam<TrainerFieldsViewModel, Store<AppState>, void>(
      (store, _) => TrainerFieldsViewModel.fromStore(store),
    );
  });

  tearDown(() async {
    final store = activeStore;
    if (store != null) {
      final action = ShutdownRequestedAction();
      store.dispatch(action);
      await action.waitForCleanup();
    }
    await sl.popScope();
    await sessionChanges.close();
  });

  group('Integration TrainerFieldsPanel reentrant SDK writes', () {
    testWidgets(
      'Integration TrainerFieldsPanel retries a preserved draft after write failure',
      (tester) async {
        final initialSession = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 17,
          ),
        );
        final failure = const GameWriteResult(
          status: GameWriteStatus.writeFailed,
          fieldId: 'credits',
          requestedValue: 42,
          errorCode: 5,
        );
        final failedSession = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.readFailed,
            fieldId: 'credits',
            errorCode: 5,
          ),
          lastWriteResult: failure,
        );
        var writeAttempts = 0;
        when(() => capability.writeField('credits', 42)).thenAnswer((_) {
          writeAttempts++;
          if (writeAttempts == 1) {
            sessionChanges.add(failedSession);
            return failure;
          }
          return const GameWriteResult(
            status: GameWriteStatus.success,
            fieldId: 'credits',
            requestedValue: 42,
            readBackValue: 42,
          );
        });
        final store = _createStore(initialSession);
        activeStore = store;
        store.dispatch(const InitializeAppAction());
        await tester.pumpWidget(_wrap(store));
        await _openCreditsEditor(tester, store);

        final input = find.byKey(const ValueKey('inline-editor-input-credits'));
        await tester.enterText(input, '42');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        expect(store.state.trainer.editingFieldId, 'credits');
        expect(tester.widget<TextField>(input).controller!.text, '42');
        expect(
          find.byTooltip('The write failed with system error 5.'),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        final writtenArguments = verify(
          () => capability.writeField(captureAny(), captureAny()),
        ).captured;
        expect(writtenArguments, ['credits', 42, 'credits', 42]);
        expect(store.state.trainer.editingFieldId, isNull);
        expect(input, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Integration TrainerFieldsPanel closes an editor after stale failure',
      (tester) async {
        final initialSession = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 17,
          ),
        );
        final staleSession = trainerStateFixtureSession(
          memoryBase: 0x2000,
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 17,
          ),
          lastWriteResult: const GameWriteResult(
            status: GameWriteStatus.readBackFailed,
            fieldId: 'credits',
            requestedValue: 42,
          ),
        );
        when(() => capability.writeField('credits', 42)).thenAnswer((_) {
          sessionChanges.add(staleSession);
          return staleSession.lastWriteResult!;
        });
        final store = _createStore(initialSession);
        activeStore = store;
        store.dispatch(const InitializeAppAction());
        await tester.pumpWidget(_wrap(store));
        await _openCreditsEditor(tester, store);

        final input = find.byKey(const ValueKey('inline-editor-input-credits'));
        await tester.enterText(input, '42');
        await tester.pump();
        await tester.tap(find.byTooltip('Apply Credits'));
        await tester.pump();

        final writtenArguments = verify(
          () => capability.writeField(captureAny(), captureAny()),
        ).captured;
        expect(writtenArguments, ['credits', 42]);
        expect(store.state.trainer.session.memoryBase, 0x2000);
        expect(store.state.trainer.editingFieldId, isNull);
        expect(input, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
