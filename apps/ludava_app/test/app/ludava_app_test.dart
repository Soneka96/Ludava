import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/ludava_app.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:ludava_app/app/presentation/screens/ludava_shell.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_controller.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_sdk_capability.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  group('Class LudavaApp composition behavior', () {
    testWidgets('Class LudavaApp creates one controller from an injected SDK', (
      tester,
    ) async {
      var discoveryCalls = 0;
      final sdk = _createSdk(() {
        discoveryCalls++;
        return const [];
      });
      final theme = ThemeData.light().copyWith(
        extensions: [GraphiteTealTheme.colors.copyWith(surface: Colors.amber)],
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Colors.purple),
        ),
      );
      await tester.pumpWidget(
        LudavaApp(
          sdk: sdk,
          windowController: _RecordingWindowController(),
          theme: theme,
        ),
      );

      final heading = tester.widget<Text>(find.text('Connect to RPCS3'));
      expect(heading.style?.color, Colors.purple);
      expect(find.byType(DragToResizeArea), findsOneWidget);
      expect(
        find.byTooltip('Refresh values or rediscover RPCS3'),
        findsOneWidget,
      );
      expect(discoveryCalls, 1);
      final titleBar = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('ludava-titlebar-surface')),
      );
      expect((titleBar.decoration as BoxDecoration).color, Colors.amber);

      await tester.pumpWidget(const SizedBox());
      expect(sdk.session.connect, throwsStateError);
      await sdk.dispose();
    });

    testWidgets(
      'Class LudavaApp forwards process selection to its controller',
      (tester) async {
        final sdk = _createSelectableSdk();
        final controller = _AppTestTrainerController(sdk);

        await tester.pumpWidget(
          LudavaApp(
            controller: controller,
            windowController: _RecordingWindowController(),
          ),
        );
        await tester.pump();
        expect(find.text('Available RPCS3 processes'), findsOneWidget);
        expect(find.text('Process ID 120'), findsOneWidget);
        expect(find.text('Process ID 240'), findsOneWidget);

        await tester.tap(find.text('Process ID 240'));
        await tester.pump();

        expect(find.text('No active game'), findsOneWidget);
        expect(
          find.byTooltip('No active game\nRPCS3 process ID: 240'),
          findsOneWidget,
        );
        await controller.disposeSdk();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('Class LudavaApp awaits cleanup and coalesces close requests', (
      tester,
    ) async {
      final controller = _DelayedTrainerController();
      final windowController = _RecordingWindowController();
      await tester.pumpWidget(
        LudavaApp(controller: controller, windowController: windowController),
      );

      await tester.tap(find.byTooltip('Close window'));
      await tester.pump();
      final nativeCloseFuture = windowController.onCloseRequested!.call(true);
      await tester.pump();

      expect(controller.disposeCalls, 1);
      expect(windowController.closeCalls, 0);

      controller.disposalGate.complete();
      await tester.pump();
      await nativeCloseFuture;
      await tester.pump();

      expect(windowController.closeCalls, 1);
      await tester.pumpWidget(const SizedBox());
      await controller.disposeSdk();
    });

    testWidgets(
      'Class LudavaApp blocks focused editor input and actions during terminal cleanup',
      (tester) async {
        tester.view.physicalSize = const Size(520, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final field = GameProfileCatalog.profiles.first.fields.values.first;
        final controller = _TerminalDelayedTrainerController(field);
        final windowController = _RecordingWindowController();
        await tester.pumpWidget(
          LudavaApp(controller: controller, windowController: windowController),
        );
        await tester.pump();

        final inputFinder = find.byKey(
          ValueKey('inline-editor-input-${field.id}'),
        );
        await tester.tap(inputFinder);
        await tester.pump();
        final inputFocusNode = tester.widget<TextField>(inputFinder).focusNode!;
        expect(inputFocusNode.hasFocus, isTrue);

        await tester.tap(find.byTooltip('Close window'));
        await tester.pump();
        expect(find.text('Closing Ludava…'), findsOneWidget);
        expect(find.text('Finishing cleanup'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(inputFocusNode.hasFocus, isFalse);
        expect(windowController.closeCalls, 0);
        expect(controller.disposeCalls, 1);
        expect(controller.sdkDisposed, isTrue);

        final shell = tester.widget<LudavaShell>(find.byType(LudavaShell));
        shell.onRefresh();
        shell.onSelectProcess(42);
        shell.onEditField(field);
        final blockedWrite = shell.onApplyField(field.id, 99);
        shell.onCancelEditing();
        shell.onMinimize();
        shell.onToggleMaximize();
        shell.onClose();

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(windowController.minimizeCalls, 0);
        expect(windowController.maximizeCalls, 0);
        expect(blockedWrite.status, GameWriteStatus.none);
        expect(windowController.closeCalls, 0);

        final nativeClose = windowController.onCloseRequested!.call(true);
        await tester.pump();
        controller.disposalGate.complete();
        await tester.pump();
        await tester.pump();
        await nativeClose;
        await tester.pump();
        expect(windowController.closeCalls, 1);
        expect(controller.disposeCalls, 1);
        expect(controller.sdkDisposed, isTrue);
        expect(find.text('Closing Ludava…'), findsOneWidget);
        expect(tester.takeException(), isNull);

        expect(controller.refresh, throwsStateError);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Class LudavaApp keeps terminal actions blocked after rejection and retries by keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(480, 340);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final field = GameProfileCatalog.profiles.first.fields.values.first;
        final controller = _TerminalDelayedTrainerController(field);
        final retryGate = Completer<void>();
        final closePlan = _NativeClosePlan(
          [false, false, false, true],
          delayedCall: 2,
          delayGate: retryGate,
        );
        final windowController = _RejectingNativeWindowController(closePlan);

        await tester.pumpWidget(
          LudavaApp(controller: controller, windowController: windowController),
        );
        await tester.pump();
        final input = find.byKey(ValueKey('inline-editor-input-${field.id}'));
        await tester.tap(input);
        await tester.pump();
        expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);

        await tester.tap(find.byTooltip('Close window'));
        await tester.pump();
        expect(controller.disposeCalls, 1);
        expect(closePlan.calls, 0);
        controller.disposalGate.complete();
        await tester.pump();
        await tester.pump();
        expect(closePlan.calls, 1);
        await tester.pump();
        expect(
          find.text('Ludava could not close. App actions are disabled.'),
          findsOneWidget,
        );
        expect(
          find.text('Bad state: The native window rejected the close request.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isA<StateError>());
        expect(tester.widget<TextField>(input).focusNode!.hasFocus, isFalse);

        final shell = tester.widget<LudavaShell>(find.byType(LudavaShell));
        shell.onRefresh();
        shell.onSelectProcess(42);
        shell.onEditField(field);
        shell.onApplyField(field.id, 100);
        shell.onCancelEditing();
        shell.onMinimize();
        shell.onToggleMaximize();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        expect(windowController.minimizeCalls, 0);
        expect(windowController.maximizeCalls, 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(closePlan.calls, 2);
        expect(find.text('Closing Ludava…'), findsOneWidget);
        expect(find.text('Finishing cleanup'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.text('Ludava could not close. App actions are disabled.'),
          findsNothing,
        );
        expect(
          find.text('Bad state: The native window rejected the close request.'),
          findsNothing,
        );
        expect(find.text('Retry close'), findsNothing);
        expect(controller.disposeCalls, 1);
        expect(controller.sdkDisposed, isTrue);

        final retryShell = tester.widget<LudavaShell>(find.byType(LudavaShell));
        expect(retryShell.isClosing, isTrue);
        expect(retryShell.closeFailure, isNull);
        retryShell.onRefresh();
        retryShell.onSelectProcess(42);
        retryShell.onEditField(field);
        expect(
          retryShell.onApplyField(field.id, 100).status,
          GameWriteStatus.none,
        );
        retryShell.onCancelEditing();
        retryShell.onMinimize();
        retryShell.onToggleMaximize();
        tester.widget<LudavaShell>(find.byType(LudavaShell)).onClose();
        tester.widget<LudavaShell>(find.byType(LudavaShell)).onClose();
        final nativeCloseDuringRetry = windowController.onCloseRequested!.call(
          true,
        );
        expect(closePlan.calls, 2);
        retryGate.complete();
        await tester.pump();
        await tester.pump();
        await nativeCloseDuringRetry;
        await tester.pump();
        expect(closePlan.calls, 2);
        expect(controller.disposeCalls, 1);
        expect(tester.takeException(), isA<StateError>());
        expect(
          find.text('Ludava could not close. App actions are disabled.'),
          findsOneWidget,
        );
        expect(find.text('Retry close'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        await tester.pump();
        expect(closePlan.calls, 3);
        expect(tester.takeException(), isA<StateError>());
        expect(find.text('Retry close'), findsOneWidget);

        await tester.tap(find.text('Retry close'));
        await tester.pump();
        await tester.pump();
        expect(closePlan.calls, 4);
        expect(controller.disposeCalls, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Class LudavaApp completes pending cleanup safely after its widget is removed',
      (tester) async {
        final controller = _TerminalDelayedTrainerController(
          GameProfileCatalog.profiles.first.fields.values.first,
        );
        final windowController = _RecordingWindowController();
        final errors = <FlutterErrorDetails>[];
        final oldHandler = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = oldHandler);

        await tester.pumpWidget(
          LudavaApp(controller: controller, windowController: windowController),
        );
        await tester.tap(find.byTooltip('Close window'));
        await tester.pump();
        expect(controller.disposeCalls, 1);
        expect(windowController.closeCalls, 0);

        await tester.pumpWidget(const SizedBox());
        controller.disposalGate.complete();
        await tester.pump();
        await tester.pump();

        expect(controller.disposeCalls, 1);
        expect(windowController.closeCalls, 1);
        expect(errors, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaApp reports disposal failure before attempting native close',
      (tester) async {
        final sdk = _createSdk(() => const []);
        final controller = _AppTestTrainerController(sdk)..failDisposal = true;
        final windowController = _RecordingWindowController();
        final reportedErrors = <FlutterErrorDetails>[];
        final previousErrorHandler = FlutterError.onError;
        FlutterError.onError = reportedErrors.add;
        addTearDown(() => FlutterError.onError = previousErrorHandler);
        await tester.pumpWidget(
          LudavaApp(controller: controller, windowController: windowController),
        );

        await tester.tap(find.byTooltip('Close window'));
        await tester.pump();

        expect(controller.disposeCalls, 1);
        expect(windowController.closeCalls, 1);
        expect(reportedErrors, hasLength(1));
        expect(reportedErrors.single.exception, isA<StateError>());
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await controller.disposeSdk();
      },
    );

    testWidgets(
      'Class LudavaApp reports title-bar close failure and retries without disposing twice',
      (tester) async {
        final sdk = _createSdk(() => const []);
        final controller = _AppTestTrainerController(sdk);
        final windowController = _RecordingWindowController()
          ..failNextClose = true;
        final reportedErrors = <FlutterErrorDetails>[];
        final previousErrorHandler = FlutterError.onError;
        FlutterError.onError = reportedErrors.add;
        addTearDown(() => FlutterError.onError = previousErrorHandler);
        await tester.pumpWidget(
          LudavaApp(controller: controller, windowController: windowController),
        );

        await tester.tap(find.byTooltip('Close window'));
        await tester.pump();

        expect(windowController.closeCalls, 1);
        expect(controller.disposeCalls, 1);
        expect(
          find.text('Ludava could not close. App actions are disabled.'),
          findsOneWidget,
        );
        expect(reportedErrors, hasLength(1));
        expect(reportedErrors.single.exception, isA<StateError>());

        await tester.tap(find.text('Retry close'));
        await tester.pump();

        expect(windowController.closeCalls, 2);
        expect(controller.disposeCalls, 1);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await controller.disposeSdk();
      },
    );

    testWidgets(
      'Class LudavaApp blocks interaction after native close returns false',
      (tester) async {
        final sdk = _createSdk(() => const []);
        final controller = _AppTestTrainerController(sdk);
        final closePlan = _NativeClosePlan([false, true]);
        final windowController = _RejectingNativeWindowController(closePlan);
        final reportedErrors = <FlutterErrorDetails>[];
        final previousErrorHandler = FlutterError.onError;
        FlutterError.onError = reportedErrors.add;
        addTearDown(() => FlutterError.onError = previousErrorHandler);

        await tester.pumpWidget(
          LudavaApp(controller: controller, windowController: windowController),
        );
        await tester.tap(find.byTooltip('Close window'));
        await tester.pump();

        expect(closePlan.calls, 1);
        expect(controller.disposeCalls, 1);
        expect(
          find.text('Ludava could not close. App actions are disabled.'),
          findsOneWidget,
        );
        expect(reportedErrors, hasLength(1));
        expect(reportedErrors.single.exception, isA<StateError>());
        expect(tester.takeException(), isNull);

        await tester.tap(
          find.byTooltip('Refresh values or rediscover RPCS3'),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(controller.refreshCalls, 0);

        await tester.tap(find.text('Retry close'));
        await tester.pump();

        expect(closePlan.calls, 2);
        expect(controller.disposeCalls, 1);
        await tester.pumpWidget(const SizedBox());
        await controller.disposeSdk();
      },
    );

    testWidgets(
      'Class LudavaApp handles native close events and repeated requests after rejection',
      (tester) async {
        final sdk = _createSdk(() => const []);
        final controller = _AppTestTrainerController(sdk);
        final windowController = _RecordingWindowController()
          ..failNextClose = true;
        final reportedErrors = <FlutterErrorDetails>[];
        final previousErrorHandler = FlutterError.onError;
        FlutterError.onError = reportedErrors.add;
        addTearDown(() => FlutterError.onError = previousErrorHandler);
        await tester.pumpWidget(
          LudavaApp(controller: controller, windowController: windowController),
        );

        await windowController.onCloseRequested!(true);
        await tester.pump();
        windowController.failNextClose = true;
        await windowController.onCloseRequested!(true);
        await tester.pump();

        expect(controller.disposeCalls, 1);
        expect(windowController.closeCalls, 2);
        expect(reportedErrors, hasLength(2));
        expect(find.text('Retry close'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Retry close'));
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        await controller.disposeSdk();
      },
    );

    testWidgets(
      'Class LudavaApp handles a native close event that could not be vetoed',
      (tester) async {
        final sdk = _createSdk(() => const []);
        final controller = _AppTestTrainerController(sdk);
        final windowController = _RecordingWindowController();
        final reportedErrors = <FlutterErrorDetails>[];
        final previousErrorHandler = FlutterError.onError;
        FlutterError.onError = reportedErrors.add;
        addTearDown(() => FlutterError.onError = previousErrorHandler);
        await tester.pumpWidget(
          LudavaApp(controller: controller, windowController: windowController),
        );

        await windowController.onCloseRequested!(false);
        await tester.pump();

        expect(controller.disposeCalls, 1);
        expect(windowController.closeCalls, 0);
        expect(find.text('Retry close'), findsOneWidget);
        expect(reportedErrors, hasLength(1));
        expect(reportedErrors.single.exception, isA<StateError>());

        await tester.tap(find.text('Retry close'));
        await tester.pump();
        expect(windowController.closeCalls, 1);
        expect(controller.disposeCalls, 1);
        await tester.pumpWidget(const SizedBox());
        await controller.disposeSdk();
      },
    );
  });
}

/// Creates an SDK runtime whose startup discovery is controlled by the caller.
LudavaSdk _createSdk(List<int> Function() discoverProcessIds) =>
    LudavaSdk.create(
      isWindows: false,
      discoverProcessIds: discoverProcessIds,
      readProcessMetadata: (_) => throw StateError('No process is selected.'),
      resolveMemoryBaseCandidate: (_) => null,
      detectGame: (_, _) => throw StateError('Game detection is not reached.'),
    );

/// Creates an SDK runtime that reports two processes without a detected game.
LudavaSdk _createSelectableSdk() => LudavaSdk.create(
  isWindows: false,
  discoverProcessIds: () => const [120, 240],
  readProcessMetadata: (_) => Rpcs3ProcessMetadata(
    executablePath: r'C:\Games\rpcs3.exe',
    startedAtUtc: DateTime.utc(2026),
  ),
  resolveMemoryBaseCandidate: (_) => null,
  detectGame: (processId, _) => GameDetectionResult(
    status: GameDetectionStatus.noActiveGame,
    processId: processId,
    confidence: GameIdentityConfidence.none,
    evidenceDescription: 'No game is active.',
  ),
);

/// Records the close callback and native close calls without opening a window.
class _RecordingWindowController extends LudavaWindowController {
  /// Creates a controller with no native window.
  _RecordingWindowController() : super(currentWindow: () => null);

  /// Close callback registered by the app composition root.
  Future<void> Function(bool requestCancelled)? onCloseRequested;

  /// Number of native close operations received after cleanup.
  int closeCalls = 0;
  int minimizeCalls = 0;
  int maximizeCalls = 0;
  bool failNextClose = false;

  @override
  void minimize() => minimizeCalls++;

  @override
  void toggleMaximize() => maximizeCalls++;

  /// Registers the test callback instead of configuring a native window.
  @override
  void configure({
    Future<void> Function(bool requestCancelled)? onCloseRequested,
  }) {
    this.onCloseRequested = onCloseRequested;
  }

  /// Records the post-cleanup native close request.
  @override
  Future<void> close() async {
    closeCalls++;
    if (failNextClose) {
      failNextClose = false;
      throw StateError('The native window rejected the close request.');
    }
  }
}

/// Returns native rejection once, then accepts a retry without opening a window.
class _RejectingNativeWindowController extends LudavaWindowController {
  _RejectingNativeWindowController(this.closePlan)
    : super(
        currentWindow: () => Window.borrowed(0),
        requestNativeClose: (_) => closePlan.request(),
      );

  final _NativeClosePlan closePlan;
  int minimizeCalls = 0;
  int maximizeCalls = 0;
  Future<void> Function(bool requestCancelled)? onCloseRequested;

  @override
  void minimize() => minimizeCalls++;

  @override
  void toggleMaximize() => maximizeCalls++;

  @override
  void configure({
    Future<void> Function(bool requestCancelled)? onCloseRequested,
  }) {
    this.onCloseRequested = onCloseRequested;
  }
}

/// Returns configured native-close results to exercise rejection and retry.
class _NativeClosePlan {
  _NativeClosePlan(this.responses, {this.delayedCall, this.delayGate});

  /// Native acceptance and rejection outcomes in request order.
  final List<bool> responses;

  /// Request number held at [delayGate], when a close must remain in flight.
  final int? delayedCall;

  /// Gate released by the retry-coalescing test.
  final Completer<void>? delayGate;

  /// Number of native close attempts made so far.
  int calls = 0;

  /// Returns the next configured native result, optionally after a gate.
  Future<bool> request() async {
    calls++;
    final response = responses.removeAt(0);
    if (calls == delayedCall) await delayGate!.future;
    return response;
  }
}

/// Keeps SDK cleanup separate from widget-test controller disposal.
class _AppTestTrainerController extends TrainerController {
  /// Creates a controller that owns [sdk] for explicit test cleanup.
  _AppTestTrainerController(this._sdk) : super(sdk: _sdk);

  final LudavaSdk _sdk;
  int disposeCalls = 0;
  int refreshCalls = 0;
  bool failDisposal = false;
  Future<void>? _disposeFuture;

  /// Records the app lifecycle cleanup request without disposing the test SDK.
  @override
  Future<void> dispose() => _disposeFuture ??= _recordDisposal();

  @override
  void refresh() {
    refreshCalls++;
    super.refresh();
  }

  /// Records the first lifecycle cleanup request for an idempotent capability.
  Future<void> _recordDisposal() async {
    disposeCalls++;
    if (failDisposal) throw StateError('Trainer disposal failed.');
  }

  /// Disposes the SDK after the test removes its app tree.
  Future<void> disposeSdk() => _sdk.dispose();
}

/// Holds disposal until the app's native-close sequence reaches its barrier.
class _DelayedTrainerController extends _AppTestTrainerController {
  /// Creates a controller backed by an empty process discovery result.
  _DelayedTrainerController() : super(_createSdk(() => const []));

  /// Gate released by the close-ordering test.
  final Completer<void> disposalGate = Completer<void>();

  /// Delays SDK cleanup until [disposalGate] completes.
  @override
  Future<void> dispose() async {
    disposeCalls++;
    await disposalGate.future;
  }
}

/// Exposes a real trainer controller's terminal state behind delayed cleanup.
class _TerminalDelayedTrainerController extends TrainerController {
  factory _TerminalDelayedTrainerController(GameField field) =>
      _TerminalDelayedTrainerController._(
        field,
        _TerminalTrainerSdkCapability(_readySession(field)),
      );

  _TerminalDelayedTrainerController._(
    this._field,
    _TerminalTrainerSdkCapability capability,
  ) : _capability = capability,
      super(capability: capability);

  final GameField _field;
  final Completer<void> _disposalGate = Completer<void>();
  final _TerminalTrainerSdkCapability _capability;

  /// Gate controlling the trainer controller's awaited cleanup completion.
  Completer<void> get disposalGate => _disposalGate;

  int _disposeCalls = 0;
  Future<void>? _disposeFuture;

  /// Number of terminal cleanup calls forwarded by the real controller.
  int get disposeCalls => _disposeCalls;

  /// Whether the injected SDK capability has entered terminal disposal.
  bool get sdkDisposed => _capability.isDisposed;

  /// Returns the test field as the active editor target.
  @override
  String? get editingFieldId => _field.id;

  /// Makes the real controller terminal and returns the test cleanup barrier.
  @override
  Future<void> dispose() {
    final activeDisposal = _disposeFuture;
    if (activeDisposal != null) return activeDisposal;
    _disposeCalls++;
    final terminalDisposal = super.dispose();
    unawaited(
      terminalDisposal.catchError((Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      }),
    );
    return _disposeFuture = _disposalGate.future;
  }
}

/// Models an SDK capability that rejects operations as soon as cleanup starts.
class _TerminalTrainerSdkCapability implements TrainerSdkCapability {
  _TerminalTrainerSdkCapability(this.state);

  final StreamController<TrainerSessionState> _stateChanges =
      StreamController<TrainerSessionState>.broadcast(sync: true);

  /// Initial session used to render the focused field editor.
  @override
  final TrainerSessionState state;

  /// Whether SDK operations have become terminal.
  bool isDisposed = false;

  /// Provides the controller's state subscription.
  @override
  Stream<TrainerSessionState> get stateChanges => _stateChanges.stream;

  /// Models discovery while the SDK capability is active.
  @override
  void connect() => _ensureActive();

  /// Models refresh while the SDK capability is active.
  @override
  void refresh() => _ensureActive();

  /// Models process selection and rejects access after disposal.
  @override
  bool selectProcess(int processId) {
    _ensureActive();
    return state.processIds.contains(processId);
  }

  /// Models a guarded write and rejects access after disposal.
  @override
  GameWriteResult writeField(String fieldId, int value) {
    _ensureActive();
    return GameWriteResult(
      status: GameWriteStatus.writeFailed,
      fieldId: fieldId,
      requestedValue: value,
    );
  }

  /// Marks the test capability terminal and closes state observation.
  @override
  Future<void> dispose() {
    isDisposed = true;
    return _stateChanges.close();
  }

  /// Rejects every capability call after cleanup has started.
  void _ensureActive() {
    if (isDisposed) throw StateError('The test SDK capability is disposed.');
  }
}

/// Builds a ready test session whose first profile field can be edited.
TrainerSessionState _readySession(GameField field) {
  final profile = GameProfileCatalog.profiles.first;
  return TrainerSessionState(
    processIds: const [42],
    selectedProcessId: 42,
    processMetadata: Rpcs3ProcessMetadata(
      executablePath: r'C:\RPCS3\rpcs3.exe',
      startedAtUtc: DateTime.utc(2026),
    ),
    detection: GameDetectionResult(
      status: GameDetectionStatus.supportedGame,
      processId: 42,
      profile: profile,
      confidence: GameIdentityConfidence.confirmed,
      evidenceDescription: 'Confirmed test profile.',
    ),
    memoryBase: 0x1000,
    readResults: {
      field.id: GameReadResult(
        status: GameReadStatus.success,
        fieldId: field.id,
        value: 17,
      ),
    },
  );
}
