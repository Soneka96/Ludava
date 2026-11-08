import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

void main() {
  Map<String, Color> roles(LudavaThemeTokens tokens) => {
    'canvas': tokens.canvas,
    'surface': tokens.surface,
    'surfaceElevated': tokens.surfaceElevated,
    'surfaceHover': tokens.surfaceHover,
    'surfacePressed': tokens.surfacePressed,
    'accent': tokens.accent,
    'onAccent': tokens.onAccent,
    'textPrimary': tokens.textPrimary,
    'textSecondary': tokens.textSecondary,
    'textMuted': tokens.textMuted,
    'textDisabled': tokens.textDisabled,
    'borderSubtle': tokens.borderSubtle,
    'borderDefault': tokens.borderDefault,
    'borderStrong': tokens.borderStrong,
    'focus': tokens.focus,
    'success': tokens.success,
    'warning': tokens.warning,
    'error': tokens.error,
    'information': tokens.information,
  };

  group('Method copyWith behaves correctly', () {
    test(
      'Method copyWith preserves other roles when replacing selected ones',
      () {
        const initial = LudavaThemeTokens(
          canvas: Colors.black,
          surface: Colors.black,
          surfaceElevated: Colors.black,
          surfaceHover: Colors.black,
          surfacePressed: Colors.black,
          accent: Colors.black,
          onAccent: Colors.black,
          textPrimary: Colors.black,
          textSecondary: Colors.black,
          textMuted: Colors.black,
          textDisabled: Colors.black,
          borderSubtle: Colors.black,
          borderDefault: Colors.black,
          borderStrong: Colors.black,
          focus: Colors.black,
          success: Colors.black,
          warning: Colors.black,
          error: Colors.black,
          information: Colors.black,
        );

        final copied = initial.copyWith(
          surface: Colors.red,
          focus: Colors.blue,
        );
        final expected = roles(initial)
          ..['surface'] = Colors.red
          ..['focus'] = Colors.blue;

        expect(roles(copied), expected);
        expect(roles(initial).values, everyElement(Colors.black));
      },
    );
  });

  group('Method lerp behaves correctly', () {
    test('Method lerp interpolates each role and returns this for null', () {
      const first = LudavaThemeTokens(
        canvas: Colors.black,
        surface: Colors.black,
        surfaceElevated: Colors.black,
        surfaceHover: Colors.black,
        surfacePressed: Colors.black,
        accent: Colors.black,
        onAccent: Colors.black,
        textPrimary: Colors.black,
        textSecondary: Colors.black,
        textMuted: Colors.black,
        textDisabled: Colors.black,
        borderSubtle: Colors.black,
        borderDefault: Colors.black,
        borderStrong: Colors.black,
        focus: Colors.black,
        success: Colors.black,
        warning: Colors.black,
        error: Colors.black,
        information: Colors.black,
      );
      const second = LudavaThemeTokens(
        canvas: Colors.white,
        surface: Colors.white,
        surfaceElevated: Colors.white,
        surfaceHover: Colors.white,
        surfacePressed: Colors.white,
        accent: Colors.white,
        onAccent: Colors.white,
        textPrimary: Colors.white,
        textSecondary: Colors.white,
        textMuted: Colors.white,
        textDisabled: Colors.white,
        borderSubtle: Colors.white,
        borderDefault: Colors.white,
        borderStrong: Colors.white,
        focus: Colors.white,
        success: Colors.white,
        warning: Colors.white,
        error: Colors.white,
        information: Colors.white,
      );
      final midpoint = Color.lerp(Colors.black, Colors.white, 0.5)!;

      expect(roles(first.lerp(null, 0.5)), roles(first));
      expect(roles(first.lerp(second, 0)).values, everyElement(Colors.black));
      expect(roles(first.lerp(second, 0.5)).values, everyElement(midpoint));
      expect(roles(first.lerp(second, 1)).values, everyElement(Colors.white));
    });
  });
}
