import 'package:flutter/material.dart';
import 'package:ludava_app/shared/theme/ludava_style_preset.dart';

/// Production style presets used to build Ludava's Material theme.
abstract final class LudavaStylePresets {
  /// Comfortable typography and control sizing for the desktop utility.
  static const LudavaStylePreset comfortable = LudavaStylePreset(
    fontFamily: 'Segoe UI',
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 15),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
    controlRadius: 8,
    surfaceRadius: 10,
    buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    buttonMinimumSize: Size(0, 48),
    inputPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
