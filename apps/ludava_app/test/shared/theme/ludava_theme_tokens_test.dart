import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

void main() {
  group('Class LudavaThemeTokens behavior', () {
    test('Class LudavaThemeTokens copyWith replaces all selected tokens', () {
      const tokens = LudavaThemeTokens(
        windowChrome: Colors.black,
        surfaceRaised: Colors.blueGrey,
        outlineSubtle: Colors.grey,
        textMuted: Colors.white70,
        success: Colors.green,
        warning: Colors.amber,
      );

      final unchanged = tokens.copyWith();
      final updated = tokens.copyWith(
        windowChrome: Colors.red,
        surfaceRaised: Colors.redAccent,
        outlineSubtle: Colors.black12,
        textMuted: Colors.black54,
        success: Colors.lightGreen,
        warning: Colors.deepOrange,
      );

      expect(unchanged.windowChrome, tokens.windowChrome);
      expect(unchanged.surfaceRaised, tokens.surfaceRaised);
      expect(unchanged.outlineSubtle, tokens.outlineSubtle);
      expect(unchanged.textMuted, tokens.textMuted);
      expect(unchanged.success, tokens.success);
      expect(unchanged.warning, tokens.warning);
      expect(updated.windowChrome, Colors.red);
      expect(updated.surfaceRaised, Colors.redAccent);
      expect(updated.outlineSubtle, Colors.black12);
      expect(updated.textMuted, Colors.black54);
      expect(updated.success, Colors.lightGreen);
      expect(updated.warning, Colors.deepOrange);
    });

    test('Class LudavaThemeTokens lerp interpolates semantic colors', () {
      const first = LudavaThemeTokens(
        windowChrome: Colors.black,
        surfaceRaised: Colors.black,
        outlineSubtle: Colors.black,
        textMuted: Colors.black,
        success: Colors.black,
        warning: Colors.black,
      );
      const second = LudavaThemeTokens(
        windowChrome: Colors.white,
        surfaceRaised: Colors.white,
        outlineSubtle: Colors.white,
        textMuted: Colors.white,
        success: Colors.white,
        warning: Colors.white,
      );

      final start = first.lerp(second, 0);
      final midpoint = first.lerp(second, 0.5);
      final end = first.lerp(second, 1);
      final unchanged = first.lerp(null, 0.5);

      expect(start.windowChrome, Colors.black);
      expect(start.surfaceRaised, Colors.black);
      expect(start.outlineSubtle, Colors.black);
      expect(start.textMuted, Colors.black);
      expect(start.success, Colors.black);
      expect(start.warning, Colors.black);
      expect(
        midpoint.windowChrome,
        Color.lerp(Colors.black, Colors.white, 0.5),
      );
      expect(
        midpoint.surfaceRaised,
        Color.lerp(Colors.black, Colors.white, 0.5),
      );
      expect(
        midpoint.outlineSubtle,
        Color.lerp(Colors.black, Colors.white, 0.5),
      );
      expect(midpoint.textMuted, Color.lerp(Colors.black, Colors.white, 0.5));
      expect(midpoint.success, Color.lerp(Colors.black, Colors.white, 0.5));
      expect(midpoint.warning, Color.lerp(Colors.black, Colors.white, 0.5));
      expect(end.windowChrome, Colors.white);
      expect(end.surfaceRaised, Colors.white);
      expect(end.outlineSubtle, Colors.white);
      expect(end.textMuted, Colors.white);
      expect(end.success, Colors.white);
      expect(end.warning, Colors.white);
      expect(unchanged.warning, Colors.black);
    });
  });
}
