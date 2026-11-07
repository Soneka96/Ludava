import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/ludava_app.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  group('Class LudavaApp lifecycle behavior', () {
    testWidgets('Class LudavaApp renders the missing RPCS3 state', (
      tester,
    ) async {
      var discoveryCalls = 0;
      final sdk = _createSdk(() {
        discoveryCalls++;
        return const [];
      });

      await tester.pumpWidget(_app(sdk: sdk));

      expect(
        find.byKey(const ValueKey('ludava-session-heading')),
        findsOneWidget,
      );
      expect(find.byType(DragToResizeArea), findsOneWidget);
      expect(
        find.text('RPCS3 was not found. Start RPCS3 to connect.'),
        findsOneWidget,
      );
      expect(discoveryCalls, 1);

      await tester.pumpWidget(const SizedBox());
      expect(sdk.session.connect, throwsStateError);
    });

    testWidgets('Class LudavaApp renders the latest process snapshot', (
      tester,
    ) async {
      var processIds = <int>[];
      final sdk = _createSdk(() => processIds);

      await tester.pumpWidget(_app(sdk: sdk));
      expect(
        find.text('RPCS3 was not found. Start RPCS3 to connect.'),
        findsOneWidget,
      );

      processIds = [120, 240];
      sdk.session.connect();
      await tester.pump();

      expect(find.text('Select an RPCS3 process to continue.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await expectLater(sdk.session.stateChanges, emitsDone);
    });

    testWidgets(
      'Class LudavaApp renders at the supported minimum window size',
      (tester) async {
        tester.view.physicalSize = const Size(720, 560);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final sdk = _createSdk(() => const []);

        await tester.pumpWidget(_app(sdk: sdk));

        expect(
          find.byKey(const ValueKey('ludava-session-heading')),
          findsOneWidget,
        );
        expect(
          find.text('RPCS3 was not found. Start RPCS3 to connect.'),
          findsOneWidget,
        );
        expect(find.byTooltip('Minimize window'), findsOneWidget);
        expect(find.byTooltip('Maximize or restore window'), findsOneWidget);
        expect(find.byTooltip('Close window'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('Class LudavaApp accepts an alternate test theme', (
      tester,
    ) async {
      final sdk = _createSdk(() => const []);
      final alternateTheme = ThemeData.light().copyWith(
        extensions: const [
          LudavaThemeTokens(
            windowChrome: Colors.amber,
            surfaceRaised: Colors.blueGrey,
            outlineSubtle: Colors.indigo,
            textMuted: Colors.teal,
            success: Colors.green,
            warning: Colors.orange,
          ),
        ],
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Colors.purple),
        ),
      );

      await tester.pumpWidget(_app(sdk: sdk, theme: alternateTheme));

      final heading = tester.widget<Text>(
        find.byKey(const ValueKey('ludava-session-heading')),
      );
      expect(heading.style?.color, Colors.purple);
      final titleBar = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('ludava-titlebar-surface')),
      );
      expect((titleBar.decoration as BoxDecoration).color, Colors.amber);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Class LudavaApp wires title-bar actions to its window owner', (
      tester,
    ) async {
      final sdk = _createSdk(() => const []);
      final window = _RecordingWindowController();

      await tester.pumpWidget(_app(sdk: sdk, windowController: window));
      await tester.tap(find.byTooltip('Minimize window'));
      await tester.tap(find.byTooltip('Maximize or restore window'));
      await tester.tap(find.byTooltip('Close window'));

      expect(window.configureCalls, 1);
      expect(window.minimizeCalls, 1);
      expect(window.maximizeCalls, 1);
      expect(window.closeCalls, 1);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Class LudavaApp selects the single discovered process', (
      tester,
    ) async {
      final sdk = LudavaSdk.create(
        isWindows: false,
        discoverProcessIds: () => const [120],
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

      await tester.pumpWidget(_app(sdk: sdk));
      await tester.pump();

      expect(find.text('Connected to RPCS3 (PID 120).'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(sdk.session.connect, throwsStateError);
    });

    testWidgets('Class LudavaApp displays SDK connection errors', (
      tester,
    ) async {
      final sdk = _createSdk(
        () => throw StateError('Process discovery failed.'),
      );

      await tester.pumpWidget(_app(sdk: sdk));
      await tester.pump();

      expect(
        sdk.session.state.errorMessage,
        'Bad state: Process discovery failed.',
      );
      expect(find.text('Bad state: Process discovery failed.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(sdk.session.connect, throwsStateError);
    });
  });
}

LudavaSdk _createSdk(List<int> Function() discoverProcessIds) =>
    LudavaSdk.create(
      isWindows: false,
      discoverProcessIds: discoverProcessIds,
      readProcessMetadata: (_) => throw StateError('Not used by these tests.'),
      resolveMemoryBaseCandidate: (_) => null,
      detectGame: (_, _) => throw StateError('Not used by these tests.'),
    );

/// Creates an app with a window adapter that never calls native code.
LudavaApp _app({
  required LudavaSdk sdk,
  LudavaWindowController? windowController,
  ThemeData? theme,
}) => LudavaApp(
  sdk: sdk,
  windowController:
      windowController ?? LudavaWindowController(currentWindow: () => null),
  theme: theme,
);

/// Records window controller calls from the app shell tests.
class _RecordingWindowController extends LudavaWindowController {
  /// Creates a recorder without a native window.
  _RecordingWindowController() : super(currentWindow: () => null);

  int configureCalls = 0;
  int minimizeCalls = 0;
  int maximizeCalls = 0;
  int closeCalls = 0;

  /// Records the app startup window configuration request.
  @override
  void configure() => configureCalls++;

  /// Records the app's minimize action.
  @override
  void minimize() => minimizeCalls++;

  /// Records the app's maximize toggle action.
  @override
  void toggleMaximize() => maximizeCalls++;

  /// Records the app's close action.
  @override
  void close() => closeCalls++;
}
