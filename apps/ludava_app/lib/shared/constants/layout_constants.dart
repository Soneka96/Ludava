/// Shared dimensions for the Flutter desktop shell and its controls.
abstract final class AppLayoutConstants {
  /// Minimum resizable window width in logical pixels.
  static const double minimumWindowWidth = 720;

  /// Minimum resizable window height in logical pixels.
  static const double minimumWindowHeight = 560;

  /// Initial window width in logical pixels.
  static const double initialWindowWidth = 1180;

  /// Initial window height in logical pixels.
  static const double initialWindowHeight = 760;

  /// Height of the integrated title bar.
  static const double titleBarHeight = 44;

  /// Width of each title-bar window control.
  static const double windowControlWidth = 46;

  /// Horizontal inset for the title-bar wordmark.
  static const double titleBarInset = 20;

  /// Width of the title-bar resize hit regions.
  static const double resizeHandleSize = 8;

  /// General app content inset in logical pixels.
  static const double contentInset = 24;

  /// Small corner radius for title-bar controls and mark.
  static const double smallCornerRadius = 4;

  /// Icon size used by the window controls.
  static const double windowIconSize = 18;
}
