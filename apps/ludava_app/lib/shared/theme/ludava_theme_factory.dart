import 'package:flutter/material.dart';
import 'package:ludava_app/shared/theme/ludava_style_preset.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

/// Builds a shared Material theme from semantic colors and visual style.
abstract final class LudavaThemeFactory {
  /// Builds Material 3 styling from semantic colors and [brightness].
  static ThemeData build({
    required LudavaThemeTokens colors,
    required LudavaStylePreset style,
    required Brightness brightness,
  }) {
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(style.controlRadius),
    );
    final surfaceShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(style.surfaceRadius),
      side: BorderSide(color: colors.borderSubtle),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(style.controlRadius),
      borderSide: BorderSide(color: colors.borderDefault),
    );
    final textTheme = style.textTheme.apply(
      fontFamily: style.fontFamily,
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: _colorScheme(colors, brightness),
      fontFamily: style.fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.canvas,
      iconTheme: IconThemeData(color: colors.textSecondary),
      extensions: [colors],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: colors.onAccent,
          backgroundColor: colors.accent,
          disabledForegroundColor: colors.textDisabled,
          disabledBackgroundColor: colors.surfacePressed,
          textStyle: textTheme.labelLarge,
          padding: style.buttonPadding,
          minimumSize: style.buttonMinimumSize,
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          disabledForegroundColor: colors.textDisabled,
          side: BorderSide(color: colors.borderDefault),
          textStyle: textTheme.labelLarge,
          padding: style.buttonPadding,
          minimumSize: style.buttonMinimumSize,
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          disabledForegroundColor: colors.textDisabled,
          textStyle: textTheme.labelLarge,
          padding: style.buttonPadding,
          minimumSize: style.buttonMinimumSize,
          shape: controlShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.textSecondary,
          disabledForegroundColor: colors.textDisabled,
          hoverColor: colors.surfaceHover.withValues(alpha: 0.08),
          focusColor: colors.focus.withValues(alpha: 0.12),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: surfaceShape,
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: textTheme.bodySmall,
        decoration: BoxDecoration(
          color: colors.surfacePressed,
          borderRadius: BorderRadius.circular(style.controlRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        contentPadding: style.inputPadding,
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colors.focus,
            width: style.inputFocusedBorderWidth,
          ),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colors.error,
            width: style.inputFocusedBorderWidth,
          ),
        ),
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
      ),
    );
  }

  /// Maps every Material color role to an explicit semantic token.
  static ColorScheme _colorScheme(
    LudavaThemeTokens colors,
    Brightness brightness,
  ) => ColorScheme(
    brightness: brightness,
    primary: colors.accent,
    onPrimary: colors.onAccent,
    primaryContainer: colors.surfaceElevated,
    onPrimaryContainer: colors.textPrimary,
    primaryFixed: colors.surfaceElevated,
    primaryFixedDim: colors.surface,
    onPrimaryFixed: colors.textPrimary,
    onPrimaryFixedVariant: colors.textSecondary,
    secondary: colors.accent,
    onSecondary: colors.onAccent,
    secondaryContainer: colors.surfaceElevated,
    onSecondaryContainer: colors.textPrimary,
    secondaryFixed: colors.surfaceElevated,
    secondaryFixedDim: colors.surface,
    onSecondaryFixed: colors.textPrimary,
    onSecondaryFixedVariant: colors.textSecondary,
    tertiary: colors.information,
    onTertiary: colors.canvas,
    tertiaryContainer: colors.surfaceElevated,
    onTertiaryContainer: colors.textPrimary,
    tertiaryFixed: colors.surfaceElevated,
    tertiaryFixedDim: colors.surface,
    onTertiaryFixed: colors.textPrimary,
    onTertiaryFixedVariant: colors.textSecondary,
    error: colors.error,
    onError: colors.canvas,
    errorContainer: colors.surfacePressed,
    onErrorContainer: colors.textPrimary,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    surfaceDim: colors.canvas,
    surfaceBright: colors.borderStrong,
    surfaceContainerLowest: colors.canvas,
    surfaceContainerLow: colors.surface,
    surfaceContainer: colors.surface,
    surfaceContainerHigh: colors.surfaceElevated,
    surfaceContainerHighest: colors.surfacePressed,
    onSurfaceVariant: colors.textSecondary,
    outline: colors.borderDefault,
    outlineVariant: colors.borderSubtle,
    shadow: colors.canvas,
    scrim: colors.canvas.withValues(alpha: 0.32),
    inverseSurface: colors.textPrimary,
    onInverseSurface: colors.canvas,
    inversePrimary: colors.accent,
    surfaceTint: colors.accent,
  );
}
