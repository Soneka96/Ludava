import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_window_title_bar.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';

void main() {
  group('Property LudavaTheme.graphiteAndTeal behaves correctly', () {
    test('Property LudavaTheme.graphiteAndTeal exposes cached theme data', () {
      final theme = LudavaTheme.graphiteAndTeal;

      expect(identical(theme, LudavaTheme.graphiteAndTeal), isTrue);
      expect(identical(theme, GraphiteTealTheme.data), isTrue);
      expect(theme.extension<LudavaThemeTokens>(), GraphiteTealTheme.tokens);
      expect(theme.brightness, Brightness.dark);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Segoe UI');
      expect(theme.iconButtonTheme.style, isNotNull);
      expect(
        theme.tooltipTheme.textStyle?.color,
        GraphiteTealTheme.tokens.textPrimary,
      );
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(
        (theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
            .borderSide
            .color,
        GraphiteTealTheme.tokens.borderDefault,
      );
      expect(
        (theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder)
            .borderSide
            .color,
        GraphiteTealTheme.tokens.focus,
      );
      expect(
        (theme.inputDecorationTheme.errorBorder! as OutlineInputBorder)
            .borderSide
            .color,
        GraphiteTealTheme.tokens.error,
      );
      final overlayColor = theme.iconButtonTheme.style!.overlayColor!;
      expect(
        overlayColor.resolve({WidgetState.hovered}),
        GraphiteTealTheme.tokens.surfaceHover.withValues(alpha: 0.08),
      );
      expect(
        overlayColor.resolve({WidgetState.focused}),
        GraphiteTealTheme.tokens.focus.withValues(alpha: 0.12),
      );
    });

    testWidgets('Property LudavaTheme supports a test-only semantic variant', (
      tester,
    ) async {
      final alternateTokens = GraphiteTealTheme.tokens.copyWith(
        surface: Colors.deepPurple,
        borderSubtle: Colors.orange,
      );
      final alternateTheme = ThemeData.dark().copyWith(
        extensions: [alternateTokens],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: alternateTheme,
          home: Scaffold(
            body: LudavaWindowTitleBar(
              onMinimize: () {},
              onToggleMaximize: () {},
              onClose: () {},
            ),
          ),
        ),
      );

      final surface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('ludava-titlebar-surface')),
      );
      final decoration = surface.decoration as BoxDecoration;
      expect(decoration.color, Colors.deepPurple);
      expect((decoration.border! as Border).bottom.color, Colors.orange);
    });
  });
}
