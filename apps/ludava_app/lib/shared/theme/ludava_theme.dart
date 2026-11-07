import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/layout_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

/// Palette and Material theme for Ludava's Graphite & Teal visual system.
abstract final class LudavaTheme {
  /// Deep graphite used behind the app's main content.
  static const Color graphite950 = Color(0xFF11191B);

  /// Graphite used for the title bar and primary surfaces.
  static const Color graphite900 = Color(0xFF192326);

  /// Raised graphite used for grouped surfaces and hover feedback.
  static const Color graphite800 = Color(0xFF233135);

  /// Graphite outline used for quiet separators.
  static const Color graphite700 = Color(0xFF36474B);

  /// Teal accent used for primary actions and active emphasis.
  static const Color teal400 = Color(0xFF5FD4BF);

  /// High contrast text color used for primary content.
  static const Color textPrimary = Color(0xFFE5EFED);

  /// Semantic color for successful actions.
  static const Color successGreen = Color(0xFF83D5A0);

  /// Semantic color for warnings that need attention.
  static const Color attentionAmber = Color(0xFFF0C875);

  /// Complete dark Material theme and semantic Ludava tokens.
  static ThemeData get graphiteAndTeal {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: teal400,
          brightness: Brightness.dark,
        ).copyWith(
          primary: teal400,
          onPrimary: graphite950,
          secondary: teal400,
          onSecondary: graphite950,
          surface: graphite900,
          onSurface: textPrimary,
          surfaceContainerLowest: graphite950,
          surfaceContainerLow: graphite900,
          surfaceContainer: graphite900,
          surfaceContainerHigh: graphite800,
          surfaceContainerHighest: graphite800,
          outline: graphite700,
          outlineVariant: graphite700,
        );
    final tokens = LudavaThemeTokens(
      windowChrome: graphite900,
      surfaceRaised: graphite800,
      outlineSubtle: graphite700,
      textMuted: scheme.onSurfaceVariant,
      success: successGreen,
      warning: attentionAmber,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: graphite950,
      extensions: [tokens],
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.textMuted,
          hoverColor: graphite800,
          minimumSize: const Size(
            AppLayoutConstants.windowControlWidth,
            AppLayoutConstants.titleBarHeight,
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppLayoutConstants.smallCornerRadius,
            ),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: graphite800,
          borderRadius: BorderRadius.circular(
            AppLayoutConstants.smallCornerRadius,
          ),
        ),
        textStyle: TextStyle(color: textPrimary),
      ),
    );
  }
}
