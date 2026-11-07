import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/theme/ludava_colors.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';

void main() {
  group('Property GraphiteTealTheme.tokens behaves correctly', () {
    test('Property GraphiteTealTheme.tokens maps every semantic role', () {
      final tokens = GraphiteTealTheme.tokens;

      expect(tokens.canvas, LudavaColors.graphite950);
      expect(tokens.surface, LudavaColors.graphite900);
      expect(tokens.surfaceElevated, LudavaColors.graphite800);
      expect(tokens.surfaceHover, LudavaColors.graphite750);
      expect(tokens.surfacePressed, LudavaColors.graphite700);
      expect(tokens.accent, LudavaColors.teal400);
      expect(tokens.onAccent, LudavaColors.graphite950);
      expect(tokens.textPrimary, LudavaColors.neutral100);
      expect(tokens.textSecondary, LudavaColors.neutral300);
      expect(tokens.textMuted, LudavaColors.neutral500);
      expect(tokens.textDisabled, LudavaColors.neutral650);
      expect(tokens.borderSubtle, LudavaColors.graphite800);
      expect(tokens.borderDefault, LudavaColors.graphite700);
      expect(tokens.borderStrong, LudavaColors.neutral650);
      expect(tokens.focus, LudavaColors.teal400);
      expect(tokens.success, LudavaColors.green400);
      expect(tokens.warning, LudavaColors.amber400);
      expect(tokens.error, LudavaColors.red400);
      expect(tokens.information, LudavaColors.blue400);
    });
  });

  group('Property GraphiteTealTheme.data behaves correctly', () {
    test('Property GraphiteTealTheme.data maps Material roles explicitly', () {
      final theme = GraphiteTealTheme.data;
      final tokens = GraphiteTealTheme.tokens;
      final scheme = theme.colorScheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, tokens.canvas);
      expect(scheme.primary, tokens.accent);
      expect(scheme.onPrimary, tokens.onAccent);
      expect(scheme.primaryContainer, tokens.surfaceElevated);
      expect(scheme.onPrimaryContainer, tokens.textPrimary);
      expect(scheme.primaryFixed, tokens.accent);
      expect(scheme.primaryFixedDim, tokens.accent);
      expect(scheme.onPrimaryFixed, tokens.onAccent);
      expect(scheme.onPrimaryFixedVariant, tokens.textPrimary);
      expect(scheme.secondary, tokens.accent);
      expect(scheme.onSecondary, tokens.onAccent);
      expect(scheme.secondaryContainer, tokens.surfaceElevated);
      expect(scheme.onSecondaryContainer, tokens.textPrimary);
      expect(scheme.secondaryFixed, tokens.accent);
      expect(scheme.secondaryFixedDim, tokens.accent);
      expect(scheme.onSecondaryFixed, tokens.onAccent);
      expect(scheme.onSecondaryFixedVariant, tokens.textPrimary);
      expect(scheme.tertiary, tokens.information);
      expect(scheme.onTertiary, tokens.canvas);
      expect(scheme.tertiaryContainer, tokens.surfaceElevated);
      expect(scheme.onTertiaryContainer, tokens.textPrimary);
      expect(scheme.tertiaryFixed, tokens.information);
      expect(scheme.tertiaryFixedDim, tokens.information);
      expect(scheme.onTertiaryFixed, tokens.canvas);
      expect(scheme.onTertiaryFixedVariant, tokens.textPrimary);
      expect(scheme.error, tokens.error);
      expect(scheme.onError, tokens.canvas);
      expect(scheme.errorContainer, tokens.surfacePressed);
      expect(scheme.onErrorContainer, tokens.textPrimary);
      expect(scheme.surface, tokens.surface);
      expect(scheme.onSurface, tokens.textPrimary);
      expect(scheme.onSurfaceVariant, tokens.textSecondary);
      expect(scheme.outline, tokens.borderDefault);
      expect(scheme.outlineVariant, tokens.borderSubtle);
      expect(scheme.shadow, tokens.canvas);
      expect(scheme.scrim, tokens.canvas);
      expect(scheme.inverseSurface, tokens.textPrimary);
      expect(scheme.onInverseSurface, tokens.canvas);
      expect(scheme.inversePrimary, tokens.surface);
      expect(scheme.surfaceTint, tokens.accent);
      expect(scheme.surfaceDim, tokens.canvas);
      expect(scheme.surfaceBright, tokens.borderStrong);
      expect(scheme.surfaceContainerLowest, tokens.canvas);
      expect(scheme.surfaceContainerLow, tokens.surface);
      expect(scheme.surfaceContainer, tokens.surface);
      expect(scheme.surfaceContainerHigh, tokens.surfaceElevated);
      expect(scheme.surfaceContainerHighest, tokens.surfacePressed);
    });
  });
}
