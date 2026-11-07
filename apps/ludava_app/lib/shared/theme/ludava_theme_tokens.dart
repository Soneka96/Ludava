import 'package:flutter/material.dart';

/// Semantic colors used by the Ludava desktop presentation.
@immutable
class LudavaThemeTokens extends ThemeExtension<LudavaThemeTokens> {
  /// Color behind the app's integrated window title bar.
  final Color windowChrome;

  /// Raised surface color for grouped content.
  final Color surfaceRaised;

  /// Low emphasis border color for separators and outlines.
  final Color outlineSubtle;

  /// Secondary text color for supporting information.
  final Color textMuted;

  /// Color for confirmed successful actions.
  final Color success;

  /// Color for attention and warning states.
  final Color warning;

  /// Creates the semantic Ludava tokens required by presentation widgets.
  const LudavaThemeTokens({
    required this.windowChrome,
    required this.surfaceRaised,
    required this.outlineSubtle,
    required this.textMuted,
    required this.success,
    required this.warning,
  });

  /// Copies this token set while replacing selected semantic values.
  @override
  LudavaThemeTokens copyWith({
    Color? windowChrome,
    Color? surfaceRaised,
    Color? outlineSubtle,
    Color? textMuted,
    Color? success,
    Color? warning,
  }) => LudavaThemeTokens(
    windowChrome: windowChrome ?? this.windowChrome,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    outlineSubtle: outlineSubtle ?? this.outlineSubtle,
    textMuted: textMuted ?? this.textMuted,
    success: success ?? this.success,
    warning: warning ?? this.warning,
  );

  /// Interpolates token colors between themes during a theme transition.
  @override
  LudavaThemeTokens lerp(covariant LudavaThemeTokens? other, double t) =>
      other == null
      ? this
      : LudavaThemeTokens(
          windowChrome: Color.lerp(windowChrome, other.windowChrome, t)!,
          surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
          outlineSubtle: Color.lerp(outlineSubtle, other.outlineSubtle, t)!,
          textMuted: Color.lerp(textMuted, other.textMuted, t)!,
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
        );
}
