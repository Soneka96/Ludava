import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

void main() {
  group('Property LudavaTheme.graphiteAndTeal behaves correctly', () {
    test('Property LudavaTheme.graphiteAndTeal supplies all theme tokens', () {
      final theme = LudavaTheme.graphiteAndTeal;
      final tokens = theme.extension<LudavaThemeTokens>();

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, LudavaTheme.teal400);
      expect(theme.colorScheme.surface, LudavaTheme.graphite900);
      expect(tokens, isNotNull);
      expect(tokens!.windowChrome, LudavaTheme.graphite900);
      expect(tokens.surfaceRaised, LudavaTheme.graphite800);
      expect(tokens.outlineSubtle, LudavaTheme.graphite700);
      expect(tokens.textMuted, isNot(theme.colorScheme.onSurface));
      expect(tokens.success, LudavaTheme.successGreen);
      expect(tokens.warning, LudavaTheme.attentionAmber);
      expect(LudavaTheme.statusBadgeFillOpacity, 0.12);
      expect(LudavaTheme.statusBadgeOutlineOpacity, 0.35);
      expect(
        identical(LudavaTheme.graphiteAndTeal, LudavaTheme.graphiteAndTeal),
        isTrue,
      );
      expect(theme.iconButtonTheme.style, isNotNull);
      expect(theme.tooltipTheme.decoration, isNotNull);
    });
  });
}
