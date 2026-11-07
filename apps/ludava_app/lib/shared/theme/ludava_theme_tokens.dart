import 'package:flutter/material.dart';

/// Semantic color roles consumed by Ludava's Flutter widgets.
@immutable
class LudavaThemeTokens extends ThemeExtension<LudavaThemeTokens> {
  /// Main application canvas color.
  final Color canvas;

  /// Default content surface color.
  final Color surface;

  /// Raised content surface color.
  final Color surfaceElevated;

  /// Surface color for pointer hover states.
  final Color surfaceHover;

  /// Surface color for pressed states.
  final Color surfacePressed;

  /// Primary interactive accent color.
  final Color accent;

  /// Foreground color for the accent surface.
  final Color onAccent;

  /// Highest-emphasis text color.
  final Color textPrimary;

  /// Supporting text color.
  final Color textSecondary;

  /// Low-emphasis text color.
  final Color textMuted;

  /// Text color for unavailable controls.
  final Color textDisabled;

  /// Low-contrast separator and outline color.
  final Color borderSubtle;

  /// Default outline color.
  final Color borderDefault;

  /// High-emphasis outline color.
  final Color borderStrong;

  /// Keyboard and accessibility focus color.
  final Color focus;

  /// Successful-operation color.
  final Color success;

  /// Attention-required color.
  final Color warning;

  /// Failed-operation color.
  final Color error;

  /// Informational status color.
  final Color information;

  /// Creates the complete semantic color contract for one theme.
  const LudavaThemeTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHover,
    required this.surfacePressed,
    required this.accent,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderStrong,
    required this.focus,
    required this.success,
    required this.warning,
    required this.error,
    required this.information,
  });

  /// Copies these semantic roles, replacing only supplied values.
  @override
  LudavaThemeTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceHover,
    Color? surfacePressed,
    Color? accent,
    Color? onAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? borderSubtle,
    Color? borderDefault,
    Color? borderStrong,
    Color? focus,
    Color? success,
    Color? warning,
    Color? error,
    Color? information,
  }) => LudavaThemeTokens(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    surfaceHover: surfaceHover ?? this.surfaceHover,
    surfacePressed: surfacePressed ?? this.surfacePressed,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    textDisabled: textDisabled ?? this.textDisabled,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    borderDefault: borderDefault ?? this.borderDefault,
    borderStrong: borderStrong ?? this.borderStrong,
    focus: focus ?? this.focus,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    information: information ?? this.information,
  );

  /// Interpolates each role independently during a theme transition.
  @override
  LudavaThemeTokens lerp(covariant LudavaThemeTokens? other, double t) =>
      other == null
      ? this
      : LudavaThemeTokens(
          canvas: Color.lerp(canvas, other.canvas, t)!,
          surface: Color.lerp(surface, other.surface, t)!,
          surfaceElevated: Color.lerp(
            surfaceElevated,
            other.surfaceElevated,
            t,
          )!,
          surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
          surfacePressed: Color.lerp(surfacePressed, other.surfacePressed, t)!,
          accent: Color.lerp(accent, other.accent, t)!,
          onAccent: Color.lerp(onAccent, other.onAccent, t)!,
          textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
          textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
          textMuted: Color.lerp(textMuted, other.textMuted, t)!,
          textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
          borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
          borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
          borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
          focus: Color.lerp(focus, other.focus, t)!,
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          error: Color.lerp(error, other.error, t)!,
          information: Color.lerp(information, other.information, t)!,
        );
}
