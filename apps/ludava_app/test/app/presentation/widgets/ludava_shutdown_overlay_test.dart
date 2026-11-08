import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_shutdown_overlay.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';

void main() {
  group('Class LudavaShutdownOverlay shutdown behavior', () {
    testWidgets('Class LudavaShutdownOverlay renders no UI while idle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LudavaShutdownOverlay(
            isClosing: false,
            closeFailure: null,
            onRetryClose: _noOp,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text('Ludava could not close. App actions are disabled.'),
        findsNothing,
      );
      expect(find.text('Retry close'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class LudavaShutdownOverlay prioritizes progress over stale failure details',
      (tester) async {
        const failure = 'A previous close attempt failed.';
        await tester.pumpWidget(
          _wrap(
            const LudavaShutdownOverlay(
              isClosing: true,
              closeFailure: failure,
              onRetryClose: _noOp,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Closing Ludava…'), findsOneWidget);
        expect(find.byTooltip(failure), findsNothing);
        expect(find.text('Retry close'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaShutdownOverlay exposes accessible cleanup progress',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _wrap(
            const LudavaShutdownOverlay(
              isClosing: true,
              closeFailure: null,
              onRetryClose: _noOp,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Closing Ludava…'), findsOneWidget);
        expect(find.text('Finishing cleanup'), findsOneWidget);

        const label = 'Closing Ludava… Finishing cleanup';
        final semanticsFinder = find.bySemanticsLabel(RegExp('Closing Ludava'));
        expect(semanticsFinder, findsOneWidget);
        final semanticsData = tester.getSemantics(semanticsFinder);
        expect(semanticsData.label, contains(label));
        expect(semanticsData.flagsCollection.isLiveRegion, isTrue);
        semantics.dispose();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Class LudavaShutdownOverlay presents full failure details and retries by mouse',
      (tester) async {
        const failure =
            'Bad state: The native window rejected the close request with full details.';
        var retryCalls = 0;
        await tester.pumpWidget(
          _wrap(
            LudavaShutdownOverlay(
              isClosing: false,
              closeFailure: failure,
              onRetryClose: () => retryCalls++,
            ),
          ),
        );

        expect(
          find.text('Ludava could not close. App actions are disabled.'),
          findsOneWidget,
        );
        expect(find.byTooltip(failure), findsOneWidget);
        expect(find.text('Retry close'), findsOneWidget);
        await tester.tap(find.text('Retry close'));

        expect(retryCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class LudavaShutdownOverlay retries by keyboard', (
      tester,
    ) async {
      var retryCalls = 0;
      await tester.pumpWidget(
        _wrap(
          LudavaShutdownOverlay(
            isClosing: false,
            closeFailure: 'The native close request was rejected.',
            onRetryClose: () => retryCalls++,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(retryCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Class LudavaShutdownOverlay follows alternate theme colors', (
      tester,
    ) async {
      final theme = ThemeData(
        colorScheme: ColorScheme.dark().copyWith(
          scrim: Colors.purple,
          secondary: Colors.lime,
        ),
      );
      await tester.pumpWidget(
        _wrap(
          const LudavaShutdownOverlay(
            isClosing: true,
            closeFailure: null,
            onRetryClose: _noOp,
          ),
          theme: theme,
        ),
      );

      final scrim = tester.widget<ColoredBox>(
        find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox &&
              widget.color == Colors.purple.withValues(alpha: 0.72),
        ),
      );
      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(scrim.color, Colors.purple.withValues(alpha: 0.72));
      expect(spinner.color, Colors.lime);
    });

    testWidgets('Class LudavaShutdownOverlay fits the 480 by 340 window', (
      tester,
    ) async {
      tester.view.physicalSize = LudavaDimensions.minimumWindowSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _wrap(
          const LudavaShutdownOverlay(
            isClosing: false,
            closeFailure:
                'The native window could not close after cleanup failed '
                'while preserving all diagnostic detail for the tooltip.',
            onRetryClose: _noOp,
          ),
        ),
      );

      final overlayRect = tester.getRect(find.byType(LudavaShutdownOverlay));
      final retryRect = tester.getRect(find.text('Retry close'));
      expect(overlayRect, Offset.zero & LudavaDimensions.minimumWindowSize);
      expect(retryRect.left, greaterThanOrEqualTo(0));
      expect(retryRect.top, greaterThanOrEqualTo(0));
      expect(retryRect.right, lessThanOrEqualTo(480));
      expect(retryRect.bottom, lessThanOrEqualTo(340));
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

void _noOp() {}
