import 'dart:ui';

/// Shared spacing values for Flutter presentation.
abstract final class LudavaSpacing {
  /// Smallest spacing step.
  static const double xs = 4;

  /// Small spacing step.
  static const double sm = 8;

  /// Medium spacing step.
  static const double md = 12;

  /// Large spacing step.
  static const double lg = 16;

  /// Extra-large spacing step.
  static const double xl = 24;

  /// Largest spacing step.
  static const double xxl = 32;
}

/// Shared desktop-window, content, and control dimensions in logical pixels.
abstract final class LudavaDimensions {
  /// Initial desktop window width.
  static const double initialWindowWidth = 520;

  /// Initial desktop window height.
  static const double initialWindowHeight = 360;

  /// Minimum resizable window width.
  static const double minimumWindowWidth = 480;

  /// Minimum resizable window height.
  static const double minimumWindowHeight = 340;

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
  static const double maximumContentWidth = 720;

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
}

/// Shared dimensions for RPCS3 connection guidance and process choices.
abstract final class ConnectionDimensions {
  /// Maximum readable width for connection guidance and picker content.
  static const double contentMaxWidth = 560;

  /// Extent of the separator between RPCS3 process choices.
  static const double processSeparatorExtent = 1;
}
