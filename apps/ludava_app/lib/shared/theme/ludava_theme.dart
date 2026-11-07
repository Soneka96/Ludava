import 'package:flutter/material.dart';
import 'package:ludava_app/shared/theme/ludava_style_presets.dart';
import 'package:ludava_app/shared/theme/ludava_theme_factory.dart';
import 'package:ludava_app/shared/theme/themes/graphite_teal_theme.dart';

/// Central access point for the selected application theme.
abstract final class LudavaTheme {
  /// Cached Graphite & Teal theme used by the desktop application.
  static final ThemeData graphiteAndTeal = LudavaThemeFactory.build(
    colors: GraphiteTealTheme.colors,
    style: LudavaStylePresets.comfortable,
    brightness: GraphiteTealTheme.brightness,
  );
}
