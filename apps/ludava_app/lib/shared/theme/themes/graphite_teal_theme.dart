import 'package:flutter/material.dart';
import 'package:ludava_app/shared/theme/ludava_colors.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

/// Graphite & Teal semantic roles and Material styling.
abstract final class GraphiteTealTheme {
  /// Subtle Material pointer hover state opacity.
  static const double _hoverOverlayOpacity = 0.08;

  /// Visible keyboard focus state opacity.
  static const double _focusOverlayOpacity = 0.12;

  /// Semantic roles mapped from the Graphite & Teal raw color palette.
  static const LudavaThemeTokens tokens = LudavaThemeTokens(
    canvas: LudavaColors.graphite950,
    surface: LudavaColors.graphite900,
    surfaceElevated: LudavaColors.graphite800,
    surfaceHover: LudavaColors.graphite750,
    surfacePressed: LudavaColors.graphite700,
    accent: LudavaColors.teal400,
    onAccent: LudavaColors.graphite950,
    textPrimary: LudavaColors.neutral100,
    textSecondary: LudavaColors.neutral300,
    textMuted: LudavaColors.neutral500,
    textDisabled: LudavaColors.neutral650,
    borderSubtle: LudavaColors.graphite800,
    borderDefault: LudavaColors.graphite700,
    borderStrong: LudavaColors.neutral650,
    focus: LudavaColors.teal400,
    success: LudavaColors.green400,
    warning: LudavaColors.amber400,
    error: LudavaColors.red400,
    information: LudavaColors.blue400,
  );

  /// Cached Material theme configured from these semantic roles.
  static final ThemeData data = _buildTheme();

  /// Builds the Material scheme and common control styling once.
  static ThemeData _buildTheme() {
    final colorScheme = _buildColorScheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: 'Segoe UI',
      textTheme: Typography.material2021().white.apply(
        fontFamily: 'Segoe UI',
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
      ),
      scaffoldBackgroundColor: tokens.canvas,
      iconTheme: IconThemeData(color: tokens.textSecondary),
      extensions: const [tokens],
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.textSecondary,
          disabledForegroundColor: tokens.textDisabled,
          hoverColor: tokens.surfaceHover.withValues(
            alpha: _hoverOverlayOpacity,
          ),
          focusColor: tokens.focus.withValues(alpha: _focusOverlayOpacity),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(color: tokens.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceElevated,
        labelStyle: TextStyle(color: tokens.textSecondary),
        hintStyle: TextStyle(color: tokens.textMuted),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.focus),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokens.error),
        ),
      ),
    );
  }

  /// Maps Material color roles directly from the semantic contract.
  static ColorScheme _buildColorScheme() => ColorScheme(
    brightness: Brightness.dark,
    primary: tokens.accent,
    onPrimary: tokens.onAccent,
    primaryContainer: tokens.surfaceElevated,
    onPrimaryContainer: tokens.textPrimary,
    primaryFixed: tokens.accent,
    primaryFixedDim: tokens.accent,
    onPrimaryFixed: tokens.onAccent,
    onPrimaryFixedVariant: tokens.textPrimary,
    secondary: tokens.accent,
    onSecondary: tokens.onAccent,
    secondaryContainer: tokens.surfaceElevated,
    onSecondaryContainer: tokens.textPrimary,
    secondaryFixed: tokens.accent,
    secondaryFixedDim: tokens.accent,
    onSecondaryFixed: tokens.onAccent,
    onSecondaryFixedVariant: tokens.textPrimary,
    tertiary: tokens.information,
    onTertiary: tokens.canvas,
    tertiaryContainer: tokens.surfaceElevated,
    onTertiaryContainer: tokens.textPrimary,
    tertiaryFixed: tokens.information,
    tertiaryFixedDim: tokens.information,
    onTertiaryFixed: tokens.canvas,
    onTertiaryFixedVariant: tokens.textPrimary,
    error: tokens.error,
    onError: tokens.canvas,
    errorContainer: tokens.surfacePressed,
    onErrorContainer: tokens.textPrimary,
    surface: tokens.surface,
    onSurface: tokens.textPrimary,
    surfaceDim: tokens.canvas,
    surfaceBright: tokens.borderStrong,
    surfaceContainerLowest: tokens.canvas,
    surfaceContainerLow: tokens.surface,
    surfaceContainer: tokens.surface,
    surfaceContainerHigh: tokens.surfaceElevated,
    surfaceContainerHighest: tokens.surfacePressed,
    onSurfaceVariant: tokens.textSecondary,
    outline: tokens.borderDefault,
    outlineVariant: tokens.borderSubtle,
    shadow: tokens.canvas,
    scrim: tokens.canvas,
    inverseSurface: tokens.textPrimary,
    onInverseSurface: tokens.canvas,
    inversePrimary: tokens.surface,
    surfaceTint: tokens.accent,
  );
}
