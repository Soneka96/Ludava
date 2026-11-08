import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/ludava_app.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_controller.dart';
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
      await tester.tap(find.byTooltip('Close window'));
      final nativeCloseFuture = windowController.onCloseRequested!.call(true);
      await tester.pump();

      expect(controller.disposeCalls, 1);
      expect(windowController.closeCalls, 0);

      controller.disposalGate.complete();
      await nativeCloseFuture;
      await tester.pump();

      expect(windowController.closeCalls, 1);
      await tester.pumpWidget(const SizedBox());
      await controller.disposeSdk();
    });

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
        await windowController.onCloseRequested!(true);
        await tester.pump();

        expect(controller.disposeCalls, 1);
        expect(windowController.closeCalls, 2);
        expect(reportedErrors, hasLength(1));
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
  bool failNextClose = false;

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
  _RejectingNativeWindowController(_NativeClosePlan closePlan)
    : super(
        currentWindow: () => Window.borrowed(0),
        requestNativeClose: (_) => closePlan.request(),
      );

  @override
  void configure({
    Future<void> Function(bool requestCancelled)? onCloseRequested,
  }) {}
}

class _NativeClosePlan {
  _NativeClosePlan(this.responses);

  final List<bool> responses;
  int calls = 0;

  Future<bool> request() async {
    calls++;
    return responses.removeAt(0);
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
