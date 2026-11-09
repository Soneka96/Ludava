import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_connection_guidance.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? LudavaTheme.graphiteAndTeal,
  home: Scaffold(body: child),
);

void main() {
  group('Class Rpcs3ConnectionGuidance presentation behavior', () {
    testWidgets(
      'Class Rpcs3ConnectionGuidance displays informational appearance',
      (tester) async {
        const message = 'Connect to RPCS3 to detect the active game.';
        await tester.pumpWidget(
          _wrap(
            const Rpcs3ConnectionGuidance(message: message, isError: false),
          ),
        );

        final theme = LudavaTheme.graphiteAndTeal;
        final icon = tester.widget<Icon>(find.byType(Icon));
        final text = tester.widget<Text>(find.text(message));
        expect(icon.icon, Icons.info_outline_rounded);
        expect(icon.color, theme.extension<LudavaThemeTokens>()!.textMuted);
        expect(text.style?.fontSize, theme.textTheme.bodyLarge?.fontSize);
        expect(text.style?.color, theme.textTheme.bodyLarge?.color);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Class Rpcs3ConnectionGuidance displays error appearance', (
      tester,
    ) async {
      const message = 'Game detection failed. Select Refresh to try again.';
      await tester.pumpWidget(
        _wrap(const Rpcs3ConnectionGuidance(message: message, isError: true)),
      );

      final theme = LudavaTheme.graphiteAndTeal;
      final icon = tester.widget<Icon>(find.byType(Icon));
      final text = tester.widget<Text>(find.text(message));
      expect(icon.icon, Icons.error_outline_rounded);
      expect(icon.color, theme.colorScheme.error);
      expect(text.style?.fontSize, theme.textTheme.bodyLarge?.fontSize);
      expect(text.style?.color, theme.textTheme.bodyLarge?.color);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Class Rpcs3ConnectionGuidance respects its readable width constraint',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _wrap(
            const Rpcs3ConnectionGuidance(
              message: 'RPCS3 is available.',
              isError: false,
            ),
          ),
        );

        final row = find.descendant(
          of: find.byType(Rpcs3ConnectionGuidance),
          matching: find.byType(Row),
        );
        expect(tester.getSize(row).width, ConnectionDimensions.contentMaxWidth);
      },
    );

    testWidgets(
      'Class Rpcs3ConnectionGuidance keeps long text usable at minimum size',
      (tester) async {
        const message =
            'The active RPCS3 session could not be verified because the current '
            'executable and process lifecycle evidence disagree.';
        for (final size in const [Size(520, 360), Size(480, 340)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          await tester.pumpWidget(
            _wrap(
              const Rpcs3ConnectionGuidance(message: message, isError: true),
            ),
          );

          final textRect = tester.getRect(find.text(message));
          expect(find.text(message), findsOneWidget);
          expect(textRect.left, greaterThanOrEqualTo(0));
          expect(textRect.right, lessThanOrEqualTo(size.width));
          expect(textRect.top, greaterThanOrEqualTo(0));
          expect(textRect.bottom, lessThanOrEqualTo(size.height));
          expect(tester.takeException(), isNull);
        }
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      },
    );

    testWidgets(
      'Class Rpcs3ConnectionGuidance follows alternate theme roles and typography',
      (tester) async {
        final baseTheme = LudavaTheme.graphiteAndTeal;
        final baseTokens = baseTheme.extension<LudavaThemeTokens>()!;
        final theme = baseTheme.copyWith(
          colorScheme: baseTheme.colorScheme.copyWith(error: Colors.deepOrange),
          textTheme: baseTheme.textTheme.copyWith(
            bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(fontSize: 21),
          ),
          extensions: [baseTokens.copyWith(textMuted: Colors.purple)],
        );

        await tester.pumpWidget(
          _wrap(
            const Rpcs3ConnectionGuidance(
              message: 'Informational guidance.',
              isError: false,
            ),
            theme: theme,
          ),
        );
        expect(tester.widget<Icon>(find.byType(Icon)).color, Colors.purple);
        expect(
          tester
              .widget<Text>(find.text('Informational guidance.'))
              .style
              ?.fontSize,
          21,
        );

        await tester.pumpWidget(
          _wrap(
            const Rpcs3ConnectionGuidance(
              message: 'Error guidance.',
              isError: true,
            ),
            theme: theme,
          ),
        );
        expect(tester.widget<Icon>(find.byType(Icon)).color, Colors.deepOrange);
      },
    );
  });
}
