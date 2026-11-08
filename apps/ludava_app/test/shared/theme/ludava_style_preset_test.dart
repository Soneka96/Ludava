import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludava_app/shared/theme/ludava_style_preset.dart';

void main() {
  group('Class LudavaStylePreset construction', () {
    test('Class LudavaStylePreset retains its native Flutter style values', () {
      const textTheme = TextTheme(bodyMedium: TextStyle(fontSize: 14));
      const preset = LudavaStylePreset(
        fontFamily: 'Test Sans',
        textTheme: textTheme,
        controlRadius: 7,
        surfaceRadius: 11,
        buttonPadding: EdgeInsets.all(10),
        buttonMinimumSize: Size(0, 48),
        inputPadding: EdgeInsets.all(12),
        inputFocusedBorderWidth: 1.5,
      );

      expect(preset.fontFamily, 'Test Sans');
      expect(preset.textTheme, textTheme);
      expect(preset.controlRadius, 7);
      expect(preset.surfaceRadius, 11);
      expect(preset.buttonPadding, const EdgeInsets.all(10));
      expect(preset.buttonMinimumSize, const Size(0, 48));
      expect(preset.inputPadding, const EdgeInsets.all(12));
      expect(preset.inputFocusedBorderWidth, 1.5);
    });
  });
}
