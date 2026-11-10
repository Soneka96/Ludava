import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/ludava_app.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_shutdown_overlay.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

import '../support/trainer_state_fixture.dart';


class _RecordingWindowController extends LudavaWindowController {
  _RecordingWindowController(this.events) : super(currentWindow: () => null);

  final List<String> events;
  Future<void> Function(bool requestCancelled)? onCloseRequested;
  int closeCalls = 0;
  bool failNextClose = false;

  @override
  void configure({
    Future<void> Function(bool requestCancelled)? onCloseRequested,
  }) {
    events.add('configure');
    this.onCloseRequested = onCloseRequested;
  }

  @override
  Future<void> close() async {
    events.add('close');
    closeCalls++;
    if (failNextClose) {
      failNextClose = false;
      throw StateError('native close failed');
    }
  }
}

class _FakeTrainerSdkCapability implements TrainerSdkCapability {
  _FakeTrainerSdkCapability(this.events) {
    _changes = StreamController<TrainerSessionState>.broadcast(sync: true);
  }

  final List<String> events;
  late final StreamController<TrainerSessionState> _changes;
  Completer<void>? cancelGate;
  Object? cancelError;
  Object? disposeError;
  int cancelCalls = 0;
  int connectCalls = 0;
  int refreshCalls = 0;
  int disposeCalls = 0;
  int initialSnapshotReads = 0;

  @override
  TrainerSessionState get state {
    initialSnapshotReads++;
    return stateForTest;
  }

  TrainerSessionState stateForTest = TrainerSessionState();

  @override
  Stream<TrainerSessionState> get stateChanges =>
      _ControlledStateStream(_changes.stream, this);

  @override
  void connect() {
    events.add('connect');
    connectCalls++;
  }

  @override
  void refresh() => refreshCalls++;

  @override
  bool selectProcess(int processId) => true;

  @override
  GameWriteResult writeField(String fieldId, int value) =>
      GameWriteResult(status: GameWriteStatus.none, fieldId: fieldId);

  @override
  Future<void> dispose() async {
    events.add('dispose');
    disposeCalls++;
    if (disposeError case final error?) throw error;
  }

  /// Closes the broadcast stream after a test's app lifecycle has completed.
  Future<void> close() async {
    if (!_changes.isClosed) await _changes.close();
  }
}

class _ControlledStateStream extends Stream<TrainerSessionState> {
  _ControlledStateStream(this._source, this._capability);

  final Stream<TrainerSessionState> _source;
  final _FakeTrainerSdkCapability _capability;

  @override
  StreamSubscription<TrainerSessionState> listen(
    void Function(TrainerSessionState event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _capability.events.add('subscribe');
    final subscription = _source.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    return _ControlledStateSubscription(subscription, _capability);
  }
}

class _ControlledStateSubscription
    implements StreamSubscription<TrainerSessionState> {
  _ControlledStateSubscription(this._subscription, this._capability);

  final StreamSubscription<TrainerSessionState> _subscription;
  final _FakeTrainerSdkCapability _capability;

  @override
  Future<void> cancel() async {
    unawaited(_subscription.cancel().catchError((Object error) {}));
    _capability.events.add('cancel');
    _capability.cancelCalls++;
    final gate = _capability.cancelGate;
    if (gate != null) await gate.future;
    if (_capability.cancelError case final error?) throw error;
  }

  @override
  bool get isPaused => _subscription.isPaused;

  @override
  void onData(void Function(TrainerSessionState event)? handleData) =>
      _subscription.onData(handleData);

  @override
  void onDone(void Function()? handleDone) => _subscription.onDone(handleDone);

  @override
  void onError(Function? handleError) => _subscription.onError(handleError);

  @override
  void pause([Future<void>? resumeSignal]) => _subscription.pause(resumeSignal);

  @override
  void resume() => _subscription.resume();

  @override
  Future<E> asFuture<E>([E? futureValue]) =>
      _subscription.asFuture<E>(futureValue);
}

void main() {
  late _FakeTrainerSdkCapability capability;
  late List<String> events;

  setUp(() {
    sl.pushNewScope();
    events = [];
    capability = _FakeTrainerSdkCapability(events);
    initDependencies(trainerSdkCapability: capability);
  });

  tearDown(() async {
    await sl.popScope();
    await capability.close();
  });

  group('Class LudavaApp startup behavior', () {
    testWidgets(
      'Class LudavaApp configures native close before SDK initialization',
      (tester) async {
        final windowController = _RecordingWindowController(events);

        await tester.pumpWidget(LudavaApp(windowController: windowController));

        expect(events.take(3), ['configure', 'subscribe', 'connect']);
        expect(capability.initialSnapshotReads, 1);
        expect(
          sl<Store<AppState>>().state.trainer.session,
          same(capability.stateForTest),
        );
        expect(windowController.onCloseRequested, isNotNull);
        expect(find.byType(StoreProvider<AppState>), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(capability.disposeCalls, 1);
      },
    );
  });

  group('Class LudavaApp shutdown behavior', () {
    testWidgets(
      'Class LudavaApp waits for cleanup before disposal and native close',
      (tester) async {
        final cancelGate = Completer<void>();
        capability.cancelGate = cancelGate;
        final windowController = _RecordingWindowController(events);
        await tester.pumpWidget(LudavaApp(windowController: windowController));

        final firstClose = windowController.onCloseRequested!(true);
        final overlappingClose = windowController.onCloseRequested!(true);
        await tester.pump();

        expect(firstClose, same(overlappingClose));
        expect(sl<SdkOperationGate>().isOpen, isFalse);
        expect(capability.cancelCalls, 1);
        expect(capability.disposeCalls, 0);
        expect(windowController.closeCalls, 0);

        cancelGate.complete();
        await firstClose;

        expect(capability.disposeCalls, 1);
        expect(windowController.closeCalls, 1);
        expect(events.indexOf('cancel'), lessThan(events.indexOf('dispose')));
        expect(events.indexOf('dispose'), lessThan(events.indexOf('close')));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Class LudavaApp reports cleanup failures and retries native close without restarting',
      (tester) async {
        final previousHandler = FlutterError.onError;
        final errors = <FlutterErrorDetails>[];
        FlutterError.onError = errors.add;
        capability.cancelError = StateError('observation cleanup failed');
        final windowController = _RecordingWindowController(events)
          ..failNextClose = true;
        try {
          await tester.pumpWidget(
            LudavaApp(windowController: windowController),
          );
          await windowController.onCloseRequested!(true);
          await tester.pump();

          expect(capability.cancelCalls, 1);
          expect(capability.disposeCalls, 1);
          expect(windowController.closeCalls, 1);
          expect(errors, hasLength(2));
          expect(
            errors.first.exception.toString(),
            contains('observation cleanup failed'),
          );
          expect(find.byType(LudavaShutdownOverlay), findsOneWidget);
          expect(find.text('Retry close'), findsOneWidget);
          expect(find.byType(AbsorbPointer), findsWidgets);
          expect(find.byType(ExcludeFocus), findsWidgets);

          final store = sl<Store<AppState>>();
          final nextSession = TrainerSessionState(processIds: [99]);
          store.dispatch(TrainerSessionChangedAction(nextSession));
          expect(store.state.trainer.session, same(nextSession));
          store.dispatch(const RefreshTrainerAction());
          expect(capability.connectCalls, 1);
          expect(capability.refreshCalls, 0);

          await tester.tap(find.text('Retry close'));
          await tester.pump();
          expect(capability.cancelCalls, 1);
          expect(capability.disposeCalls, 1);
          expect(windowController.closeCalls, 2);
          expect(sl<SdkOperationGate>().isOpen, isFalse);
          await tester.pumpWidget(const SizedBox());
        } finally {
          FlutterError.onError = previousHandler;
        }
      },
    );

    testWidgets(
      'Class LudavaApp removes focus and keeps retry accessible after close failure',
      (tester) async {
        final previousHandler = FlutterError.onError;
        final errors = <FlutterErrorDetails>[];
        FlutterError.onError = errors.add;
        capability.stateForTest = trainerStateFixtureSession(
          readResult: const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'credits',
            value: 25,
          ),
        );
        sl<Store<AppState>>().dispatch(
          TrainerSessionChangedAction(capability.stateForTest),
        );
        final windowController = _RecordingWindowController(events)
          ..failNextClose = true;
        try {
          await tester.pumpWidget(
            LudavaApp(windowController: windowController),
          );
          await tester.tap(find.byTooltip('Edit Credits'));
          await tester.pump();
          final input = find.byKey(
            const ValueKey('inline-editor-input-credits'),
          );
          await tester.tap(input);
          await tester.pump();
          expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);

          await tester.tap(find.byTooltip('Close window'));
          await tester.pump();
          await tester.pump();

          expect(capability.disposeCalls, 1);
          expect(windowController.closeCalls, 1);
          expect(errors, hasLength(1));
          expect(find.byType(LudavaShutdownOverlay), findsOneWidget);
          expect(find.text('Retry close'), findsOneWidget);
          expect(tester.widget<TextField>(input).focusNode!.hasFocus, isFalse);
          expect(
            tester.getSemantics(find.text('Retry close')).label,
            'Retry close',
          );

          await tester.tap(find.text('Retry close'));
          await tester.pump();
          await tester.pump();
          expect(windowController.closeCalls, 2);
          expect(capability.disposeCalls, 1);
          expect(capability.cancelCalls, 1);
          await tester.pumpWidget(const SizedBox());
        } finally {
          FlutterError.onError = previousHandler;
        }
      },
    );

    testWidgets(
      'Class LudavaApp honors native close veto and keeps retry reachable',
      (tester) async {
        final previousHandler = FlutterError.onError;
        final errors = <FlutterErrorDetails>[];
        FlutterError.onError = errors.add;
        final windowController = _RecordingWindowController(events);
        try {
          await tester.pumpWidget(
            LudavaApp(windowController: windowController),
          );
          await windowController.onCloseRequested!(false);
          await tester.pump();
          expect(capability.disposeCalls, 1);
          expect(windowController.closeCalls, 0);
          expect(errors, hasLength(1));
          expect(find.text('Retry close'), findsOneWidget);
          await tester.tap(find.text('Retry close'));
          await tester.pump();
          expect(windowController.closeCalls, 1);
          expect(capability.disposeCalls, 1);
          await tester.pumpWidget(const SizedBox());
        } finally {
          FlutterError.onError = previousHandler;
        }
      },
    );

    testWidgets(
      'Class LudavaApp retries native close after SDK disposal failure',
      (tester) async {
        final previousHandler = FlutterError.onError;
        final errors = <FlutterErrorDetails>[];
        FlutterError.onError = errors.add;
        capability.disposeError = StateError('SDK disposal failed');
        final windowController = _RecordingWindowController(events);
        try {
          await tester.pumpWidget(
            LudavaApp(windowController: windowController),
          );
          await windowController.onCloseRequested!(true);
          await tester.pump();
          expect(capability.disposeCalls, 1);
          expect(windowController.closeCalls, 0);
          expect(errors, hasLength(1));
          expect(find.text('Retry close'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Retry close'));
          await tester.pump();
          await tester.pump();

          expect(capability.disposeCalls, 1);
          expect(windowController.closeCalls, 1);
          await tester.pumpWidget(const SizedBox());
        } finally {
          FlutterError.onError = previousHandler;
        }
      },
    );

    testWidgets(
      'Class LudavaApp performs the same shutdown fallback on tree removal',
      (tester) async {
        final windowController = _RecordingWindowController(events);
        await tester.pumpWidget(LudavaApp(windowController: windowController));

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        expect(sl<SdkOperationGate>().isOpen, isFalse);
        expect(capability.cancelCalls, 1);
        expect(capability.disposeCalls, 1);
        expect(windowController.closeCalls, 0);
      },
    );
  });
}
