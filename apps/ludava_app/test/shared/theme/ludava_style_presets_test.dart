import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/theme/ludava_style_presets.dart';

void main() {
  group('Property LudavaStylePresets.comfortable behaves correctly', () {
    test('Property LudavaStylePresets.comfortable sets shared hierarchy', () {
      final preset = LudavaStylePresets.comfortable;

      expect(preset.fontFamily, 'Segoe UI');
      expect(preset.textTheme.titleSmall?.fontSize, 14);
      expect(preset.textTheme.titleSmall?.fontWeight, FontWeight.w600);
      expect(
        preset.textTheme.titleSmall?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(preset.textTheme.titleLarge?.fontSize, 18);
      expect(preset.textTheme.titleMedium?.fontSize, 16);
      expect(preset.textTheme.bodyMedium?.fontSize, 14);
      expect(preset.textTheme.labelMedium?.fontSize, 12);
      expect(preset.textTheme.headlineMedium?.fontSize, 24);
      expect(
        preset.textTheme.headlineMedium?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(
        preset.textTheme.titleLarge?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(preset.controlRadius, 8);
      expect(preset.surfaceRadius, 10);
      expect(preset.buttonMinimumSize, const Size(0, 48));
    });
  });
}
