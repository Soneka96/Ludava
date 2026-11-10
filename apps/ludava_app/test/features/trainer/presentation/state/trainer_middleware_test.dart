import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_middleware.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_state.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/state/app.actions.dart';
import 'package:ludava_app/shared/state/app_reducer.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

class _FakeTrainerSdkCapability implements TrainerSdkCapability {
  final StreamController<TrainerSessionState> _changes =
      StreamController<TrainerSessionState>.broadcast(sync: true);
  TrainerSessionState _state = TrainerSessionState();
  final List<String> calls = [];
  final List<int> selectedProcessIds = [];
  int subscriptionCount = 0;
  int connectCalls = 0;
  int refreshCalls = 0;
  int commandCalls = 0;
  Object? connectError;
  Object? refreshError;
  Object? selectionError;
  Stream<TrainerSessionState>? customStateChanges;
  bool Function()? nextCalledWhenSubscriptionRequested;
  bool nextWasCalledWhenSubscribed = false;

  @override
  TrainerSessionState get state => _state;

  @override
  Stream<TrainerSessionState> get stateChanges {
    nextWasCalledWhenSubscribed =
        nextCalledWhenSubscriptionRequested?.call() ?? false;
    subscriptionCount++;
    calls.add('subscribe');
    return customStateChanges ?? _changes.stream;
  }

  @override
  void connect() {
    calls.add('connect');
    connectCalls++;
    commandCalls++;
    if (connectError case final error?) throw error;
  }

  @override
  void refresh() {
    refreshCalls++;
    commandCalls++;
    if (refreshError case final error?) throw error;
  }

  @override
  bool selectProcess(int processId) {
    commandCalls++;
    if (selectionError case final error?) throw error;
    selectedProcessIds.add(processId);
    return true;
  }

  @override
  GameWriteResult writeField(String fieldId, int value) =>
      GameWriteResult(status: GameWriteStatus.none, fieldId: fieldId);

  @override
  Future<void> dispose() => close();

  /// Emits an SDK-authoritative session update.
  void emit(TrainerSessionState session) {
    _state = session;
    _changes.add(session);
  }

  /// Emits an SDK stream error.
  void emitError(Object error) => _changes.addError(error, StackTrace.current);

  /// Closes the fake observation stream.
  Future<void> close() => _changes.close();
}

class _ListenThrowingStream<T> extends Stream<T> {
  _ListenThrowingStream(this._error);

  final Object _error;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => throw _error;
}

class _ThrowingCancelStream extends Stream<TrainerSessionState> {
  @override
  StreamSubscription<TrainerSessionState> listen(
    void Function(TrainerSessionState event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _ThrowingCancelSubscription();
}

class _ThrowingCancelSubscription
    implements StreamSubscription<TrainerSessionState> {
  @override
  Future<void> cancel() => throw StateError('subscription cancellation failed');

  @override
  bool get isPaused => false;

  @override
  void onData(void Function(TrainerSessionState event)? handleData) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void onError(Function? handleError) {}

  @override
  void pause([Future<void>? resumeSignal]) {}

  @override
  void resume() {}

  @override
  Future<E> asFuture<E>([E? futureValue]) => Future<E>.value(futureValue);
}

class _FailsFirstCleanupRegistrationAction extends ShutdownRequestedAction {
  bool _failed = false;

  @override
  void addCleanup(Future<void> cleanup) {
    if (!_failed) {
      _failed = true;
      throw StateError('cleanup registration failed');
    }
    super.addCleanup(cleanup);
  }
}

void main() {
  late _FakeTrainerSdkCapability capability;

  setUp(() async {
    sl.pushNewScope();
    capability = _FakeTrainerSdkCapability();
    sl.registerSingleton<TrainerSdkCapability>(capability);
    sl.registerSingleton<SdkOperationGate>(SdkOperationGate());
  });

  tearDown(() async {
    await sl.popScope();
    await capability.close();
  });

  Store<AppState> createStore({TrainerSessionState? session}) =>
      Store<AppState>(
        appReducer,
        initialState: AppState(
          trainer: TrainerState(session: session ?? capability.state),
        ),
        middleware: [TrainerMiddleware().call],
        syncStream: true,
      );

  List<FlutterErrorDetails> captureErrors() {
    final errors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousHandler);
    return errors;
  }

  Future<void> shutdown(Store<AppState> store) async {
    final action = ShutdownRequestedAction();
    store.dispatch(action);
    await action.waitForCleanup();
  }

  group('Method call() behaves correctly', () {
    test('Method call() forwards the action before handling it', () async {
      final store = createStore();
      final middleware = TrainerMiddleware();
      final action = const InitializeAppAction();
      var nextCalled = false;
      Object? forwardedAction;
      capability.nextCalledWhenSubscriptionRequested = () => nextCalled;

      middleware.call(store, action, (forwarded) {
        forwardedAction = forwarded;
        nextCalled = true;
      });

      expect(forwardedAction, same(action));
      expect(capability.nextWasCalledWhenSubscribed, isTrue);
      final shutdownAction = ShutdownRequestedAction();
      middleware.call(store, shutdownAction, (forwarded) => forwarded);
      await shutdownAction.waitForCleanup();
    });

    test(
      'Method call() subscribes before connecting and dispatches snapshots',
      () async {
        final store = createStore();

        store.dispatch(const InitializeAppAction());
        final updatedSession = TrainerSessionState(processIds: [7]);
        capability.emit(updatedSession);

        expect(capability.calls, ['subscribe', 'connect']);
        expect(store.state.trainer.session, same(updatedSession));
        await shutdown(store);
      },
    );

    test(
      'Method call() initializes observation and connection only once',
      () async {
        final store = createStore();

        store.dispatch(const InitializeAppAction());
        store.dispatch(const InitializeAppAction());

        expect(capability.subscriptionCount, 1);
        expect(capability.connectCalls, 1);
        await shutdown(store);
      },
    );

    test(
      'Method call() connects when refreshing without a selected process',
      () async {
        final store = createStore();

        store.dispatch(const RefreshTrainerAction());

        expect(capability.connectCalls, 1);
        expect(capability.refreshCalls, 0);
        await shutdown(store);
      },
    );

    test('Method call() refreshes when a process is selected', () async {
      final session = TrainerSessionState(selectedProcessId: 7);
      final store = createStore(session: session);

      store.dispatch(const RefreshTrainerAction());

      expect(capability.refreshCalls, 1);
      expect(capability.connectCalls, 0);
      expect(store.state.trainer.session, same(session));
      await shutdown(store);
    });

    test(
      'Method call() routes process selection through the capability',
      () async {
        final store = createStore();

        store.dispatch(const SelectRpcs3ProcessAction(19));

        expect(capability.selectedProcessIds, [19]);
        await shutdown(store);
      },
    );

    test(
      'Method call() reports command exceptions without synthesizing snapshots',
      () async {
        final errors = captureErrors();
        capability.connectError = StateError('discovery failed');
        final initial = capability.state;
        final store = createStore(session: initial);

        store.dispatch(const InitializeAppAction());

        expect(errors, hasLength(1));
        expect(errors.single.exception, isA<StateError>());
        expect(store.state.trainer.session, same(initial));
        await shutdown(store);
      },
    );

    test(
      'Method call() reports selection exceptions at the command boundary',
      () async {
        final errors = captureErrors();
        capability.selectionError = StateError('selection failed');
        final store = createStore();

        store.dispatch(const SelectRpcs3ProcessAction(19));

        expect(errors, hasLength(1));
        expect(errors.single.exception, isA<StateError>());
        await shutdown(store);
      },
    );

    test(
      'Method call() reports refresh exceptions at the command boundary',
      () async {
        final errors = captureErrors();
        capability.refreshError = StateError('refresh failed');
        final store = createStore(
          session: TrainerSessionState(selectedProcessId: 7),
        );

        store.dispatch(const RefreshTrainerAction());

        expect(errors, hasLength(1));
        expect(errors.single.exception, isA<StateError>());
        await shutdown(store);
      },
    );

    test('Method call() reports stream errors without reconnecting', () async {
      final errors = captureErrors();
      final store = createStore();

      store.dispatch(const InitializeAppAction());
      capability.emitError(StateError('observation failed'));

      expect(errors, hasLength(1));
      expect(errors.single.exception, isA<StateError>());
      expect(capability.connectCalls, 1);
      await shutdown(store);
    });

    test(
      'Method call() reports synchronous observation setup errors',
      () async {
        final errors = captureErrors();
        capability.customStateChanges = _ListenThrowingStream(
          StateError('subscription failed'),
        );
        final store = createStore();

        store.dispatch(const InitializeAppAction());

        expect(errors, hasLength(1));
        expect(errors.single.exception, isA<StateError>());
        expect(capability.connectCalls, 0);
        await shutdown(store);
      },
    );

    test('Method call() ignores late events and blocks reinitialization after shutdown', () async {
      final store = createStore();
      store.dispatch(const InitializeAppAction());
      final beforeShutdown = store.state.trainer.session;
      await shutdown(store);

      capability.emit(TrainerSessionState(processIds: [99]));
      store.dispatch(const InitializeAppAction());

      expect(store.state.trainer.session, same(beforeShutdown));
      expect(capability.subscriptionCount, 1);
      expect(capability.connectCalls, 1);
      await shutdown(store);
    });

    test('Method call() avoids SDK observation and commands when the gate is closed', () async {
      final store = createStore();
      sl<SdkOperationGate>().close();

      store.dispatch(const InitializeAppAction());
      store.dispatch(const RefreshTrainerAction());
      store.dispatch(const SelectRpcs3ProcessAction(42));

      expect(capability.subscriptionCount, 0);
      expect(capability.commandCalls, 0);
      await shutdown(store);
    });

    test(
      'Method call() registers a future when cancellation throws synchronously',
      () async {
        capability.customStateChanges = _ThrowingCancelStream();
        final store = createStore();
        store.dispatch(const InitializeAppAction());
        final action = ShutdownRequestedAction();

        store.dispatch(action);

        await expectLater(
          action.waitForCleanup(),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('subscription cancellation failed'),
            ),
          ),
        );
      },
    );

    test(
      'Method call() registers a failure after cleanup registration throws',
      () async {
        final store = createStore();
        final action = _FailsFirstCleanupRegistrationAction();

        store.dispatch(action);

        await expectLater(
          action.waitForCleanup(),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('cleanup registration failed'),
            ),
          ),
        );
      },
    );
  });
}
