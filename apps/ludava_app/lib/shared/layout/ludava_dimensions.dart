import 'dart:ui';

/// Reusable desktop and interactive dimensions in logical pixels.
abstract final class LudavaDimensions {
  /// Initial desktop window width.
  static const double initialWindowWidth = 1180;

  /// Initial desktop window height.
  static const double initialWindowHeight = 760;

  /// Minimum resizable window width.
  static const double minimumWindowWidth = 720;

  /// Minimum resizable window height.
  static const double minimumWindowHeight = 560;

  /// Initial native window size.
  static const Size initialWindowSize = Size(
    initialWindowWidth,
    initialWindowHeight,
  );

  /// Minimum native window size.
  static const Size minimumWindowSize = Size(
    minimumWindowWidth,
    minimumWindowHeight,
  );

  /// Minimum square hit-target width and height.
  static const double minimumInteractiveTarget = 48;

  /// Maximum width for the centered application content.
  static const double maximumContentWidth = 1440;

  /// Height of the integrated window title bar.
  static const double titleBarHeight = 48;

  /// Width of a title-bar control hit target.
  static const double windowControlWidth = 48;

  /// Thickness of the native window resize edge hit region.
  static const double windowResizeHandleSize = 8;

  /// Small reusable icon dimension.
  static const double iconSmall = 20;

  /// Medium reusable icon dimension.
  static const double iconMedium = 24;

  /// Shared small corner radius.
  static const double smallCornerRadius = 4;
}
