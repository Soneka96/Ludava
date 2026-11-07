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

  /// Vertical inset around the game status header.
  static const double headerVerticalInset = 16;

  /// Minimum height of refresh and re-detect actions.
  static const double headerActionHeight = 40;

  /// Maximum readable width for connection guidance text.
  static const double connectionMessageMaxWidth = 560;

  /// Spacing between adjacent header items.
  static const double headerItemGap = 12;

  /// Gap between a title and its supporting process description.
  static const double headerTitleGap = 4;

  /// Horizontal inset inside the session status badge.
  static const double statusBadgeHorizontalInset = 10;

  /// Vertical inset inside the session status badge.
  static const double statusBadgeVerticalInset = 6;

  /// Corner radius for the compact status badge.
  static const double statusBadgeRadius = 20;

  /// Gap between connection picker guidance rows.
  static const double connectionPickerGap = 12;

  /// Gap between a process name and supporting picker instructions.
  static const double connectionPickerCopyGap = 6;

  /// Height of a separator between RPCS3 process choices.
  static const double connectionPickerDividerHeight = 1;

  /// Small corner radius for title-bar controls and mark.
  static const double smallCornerRadius = 4;

  /// Icon size used by the window controls.
  static const double windowIconSize = 18;
}
