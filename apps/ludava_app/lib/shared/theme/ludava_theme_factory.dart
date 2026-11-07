import 'package:flutter/material.dart';
import 'package:ludava_app/shared/theme/ludava_style_preset.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

/// Builds a shared Material theme from semantic colors and visual style.
abstract final class LudavaThemeFactory {
  /// Builds Material 3 styling without coupling it to a particular palette.
  static ThemeData build({
    required LudavaThemeTokens colors,
    required LudavaStylePreset style,
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
      brightness: Brightness.dark,
      colorScheme: _colorScheme(colors),
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
          borderSide: BorderSide(color: colors.focus, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
      ),
    );
  }

  /// Maps the semantic color roles used by Material 3 controls.
  static ColorScheme _colorScheme(LudavaThemeTokens colors) =>
      ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: colors.accent,
        onPrimary: colors.onAccent,
        primaryContainer: colors.surfaceElevated,
        onPrimaryContainer: colors.textPrimary,
        secondary: colors.accent,
        onSecondary: colors.onAccent,
        secondaryContainer: colors.surfaceElevated,
        onSecondaryContainer: colors.textPrimary,
        tertiary: colors.information,
        onTertiary: colors.canvas,
        error: colors.error,
        onError: colors.canvas,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        onSurfaceVariant: colors.textSecondary,
        outline: colors.borderDefault,
        outlineVariant: colors.borderSubtle,
        surfaceDim: colors.canvas,
        surfaceBright: colors.borderStrong,
        surfaceContainerLowest: colors.canvas,
        surfaceContainerLow: colors.surface,
        surfaceContainer: colors.surface,
        surfaceContainerHigh: colors.surfaceElevated,
        surfaceContainerHighest: colors.surfacePressed,
        surfaceTint: colors.accent,
      );
}
