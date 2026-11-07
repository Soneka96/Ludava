import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';

void main() {
  group('Property LudavaTheme.graphiteAndTeal behaves correctly', () {
    test('Property LudavaTheme.graphiteAndTeal exposes cached theme data', () {
      final theme = LudavaTheme.graphiteAndTeal;

      expect(identical(theme, LudavaTheme.graphiteAndTeal), isTrue);
      expect(theme.extension<LudavaThemeTokens>(), GraphiteTealTheme.colors);
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Segoe UI');
      expect(theme.filledButtonTheme.style, isNotNull);
      expect(theme.outlinedButtonTheme.style, isNotNull);
      expect(theme.textButtonTheme.style, isNotNull);
      expect(theme.iconButtonTheme.style, isNotNull);
      expect(
        theme.tooltipTheme.textStyle?.color,
        GraphiteTealTheme.colors.textPrimary,
      );
      expect(theme.inputDecorationTheme.filled, isTrue);
    });
  });
}
