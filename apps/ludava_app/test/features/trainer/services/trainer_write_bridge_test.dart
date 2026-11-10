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

import '../../../support/trainer_state_fixture.dart';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

Store<AppState> _createStore(
  TrainerSessionState session,
  String? editingFieldId,
) => Store<AppState>(
  appReducer,
  initialState: AppState(
    trainer: TrainerState(session: session, editingFieldId: editingFieldId),
  ),
  middleware: [TrainerMiddleware().call],
  syncStream: true,
);

Future<void> _shutdown(Store<AppState> store) async {
  final action = ShutdownRequestedAction();
  store.dispatch(action);
  await action.waitForCleanup();
}

class _FakeTrainerSdkCapability implements TrainerSdkCapability {
  final StreamController<TrainerSessionState> _changes =
      StreamController<TrainerSessionState>.broadcast(sync: true);
  TrainerSessionState currentState = TrainerSessionState();
  TrainerSessionState? sessionDuringWrite;
  GameWriteResult? writeResult;
  Object? writeError;
  int writeCalls = 0;

  @override
  TrainerSessionState get state => currentState;

  @override
  Stream<TrainerSessionState> get stateChanges => _changes.stream;

  @override
  void connect() {}

  @override
  void refresh() {}

  @override
  bool selectProcess(int processId) => false;

  @override
  GameWriteResult writeField(String fieldId, int value) {
    writeCalls++;
    if (writeError case final error?) throw error;
    final nextSession = sessionDuringWrite;
    if (nextSession != null) {
      currentState = nextSession;
      _changes.add(nextSession);
    }
    return writeResult ??
        GameWriteResult(
          status: GameWriteStatus.none,
          fieldId: fieldId,
          requestedValue: value,
        );
  }

  @override
  Future<void> dispose() => close();

  /// Closes the fake session stream after middleware cleanup.
  Future<void> close() => _changes.close();
}

void main() {
  late _FakeTrainerSdkCapability capability;
  late SdkOperationGate operationGate;
  late TrainerWriteBridge bridge;

  setUp(() {
    sl.pushNewScope();
    capability = _FakeTrainerSdkCapability();
    operationGate = SdkOperationGate();
    sl.registerSingleton<TrainerSdkCapability>(capability);
    sl.registerSingleton<SdkOperationGate>(operationGate);
    bridge = TrainerWriteBridge(capability, operationGate);
  });

  tearDown(() async {
    await sl.popScope();
    await capability.close();
  });

  group('Method writeField() behaves correctly', () {
    test('Method writeField() returns the actual successful SDK result', () {
      final result = const GameWriteResult(
        status: GameWriteStatus.success,
        fieldId: 'credits',
        requestedValue: 44,
        readBackValue: 44,
      );
      capability.writeResult = result;

      expect(bridge.writeField('credits', 44), same(result));
      expect(capability.writeCalls, 1);
    });

    test('Method writeField() returns the actual unsuccessful SDK result', () {
      final result = const GameWriteResult(
        status: GameWriteStatus.readBackMismatch,
        fieldId: 'credits',
        requestedValue: 44,
        readBackValue: 43,
      );
      capability.writeResult = result;

      expect(bridge.writeField('credits', 44), same(result));
      expect(capability.writeCalls, 1);
    });

    test('Method writeField() propagates SDK exceptions', () {
      capability.writeError = StateError('write failed');

      expect(
        () => bridge.writeField('credits', 44),
        throwsA(isA<StateError>()),
      );
      expect(capability.writeCalls, 1);
    });

    test(
      'Method writeField() returns the sentinel without calling a closed SDK',
      () {
        operationGate.close();

        final result = bridge.writeField('credits', 44);

        expect(result.status, GameWriteStatus.none);
        expect(result.fieldId, 'credits');
        expect(result.requestedValue, 44);
        expect(result.readBackValue, isNull);
        expect(capability.writeCalls, 0);
      },
    );
  });

  group('Method writeField() preserves synchronous SDK notifications', () {
    test(
      'Method writeField() keeps a valid edit through reentrant success',
      () async {
        final initialSession = trainerStateFixtureSession();
        final nextSession = trainerStateFixtureSession();
        final result = const GameWriteResult(
          status: GameWriteStatus.success,
          fieldId: 'credits',
          requestedValue: 44,
          readBackValue: 44,
        );
        capability
          ..currentState = initialSession
          ..writeResult = result
          ..sessionDuringWrite = nextSession;
        final store = _createStore(initialSession, 'credits');
        store.dispatch(const InitializeAppAction());

        final returnedResult = bridge.writeField('credits', 44);

        expect(returnedResult, same(result));
        expect(store.state.trainer.session, same(nextSession));
        expect(store.state.trainer.editingFieldId, 'credits');
        expect(capability.writeCalls, 1);
        await _shutdown(store);
      },
    );

    test('Method writeField() invalidates a stale target and returns the real failure', () async {
      final initialSession = trainerStateFixtureSession();
      final staleSession = trainerStateFixtureSession(memoryBase: 0x2000);
      final result = const GameWriteResult(
        status: GameWriteStatus.readBackFailed,
        fieldId: 'credits',
        requestedValue: 44,
      );
      capability
        ..currentState = initialSession
        ..writeResult = result
        ..sessionDuringWrite = staleSession;
      final store = _createStore(initialSession, 'credits');
      store.dispatch(const InitializeAppAction());

      final returnedResult = bridge.writeField('credits', 44);

      expect(returnedResult, same(result));
      expect(store.state.trainer.session, same(staleSession));
      expect(store.state.trainer.editingFieldId, isNull);
      expect(capability.writeCalls, 1);
      await _shutdown(store);
    });
  });
}
