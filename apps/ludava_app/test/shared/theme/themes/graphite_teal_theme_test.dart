import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/theme/ludava_colors.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';

void main() {
  group('Property GraphiteTealTheme.colors behaves correctly', () {
    test(
      'Property GraphiteTealTheme.brightness declares the shipped dark mode',
      () {
        expect(GraphiteTealTheme.brightness, Brightness.dark);
      },
    );

    test('Property GraphiteTealTheme.colors maps every semantic role', () {
      final colors = GraphiteTealTheme.colors;

      expect(colors.canvas, LudavaColors.graphite950);
      expect(colors.surface, LudavaColors.graphite900);
      expect(colors.surfaceElevated, LudavaColors.graphite800);
      expect(colors.surfaceHover, LudavaColors.graphite750);
      expect(colors.surfacePressed, LudavaColors.graphite700);
      expect(colors.accent, LudavaColors.teal400);
      expect(colors.onAccent, LudavaColors.graphite950);
      expect(colors.textPrimary, LudavaColors.neutral100);
      expect(colors.textSecondary, LudavaColors.neutral300);
      expect(colors.textMuted, LudavaColors.neutral500);
      expect(colors.textDisabled, LudavaColors.neutral650);
      expect(colors.borderSubtle, LudavaColors.graphite800);
      expect(colors.borderDefault, LudavaColors.graphite700);
      expect(colors.borderStrong, LudavaColors.neutral650);
      expect(colors.focus, LudavaColors.teal400);
      expect(colors.success, LudavaColors.green400);
      expect(colors.warning, LudavaColors.amber400);
      expect(colors.error, LudavaColors.red400);
      expect(colors.information, LudavaColors.blue400);
    });
  });
}
