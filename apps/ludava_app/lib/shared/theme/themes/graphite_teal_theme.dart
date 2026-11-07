import 'package:ludava_app/shared/theme/ludava_colors.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

/// Graphite & Teal mappings from raw palette values to semantic roles.
abstract final class GraphiteTealTheme {
  /// Semantic roles mapped from the Graphite & Teal raw color palette.
  static const LudavaThemeTokens colors = LudavaThemeTokens(
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
}
