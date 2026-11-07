import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/layout_constants.dart';
import 'package:window_manager/window_manager.dart';

/// Applies native desktop window settings and caption actions.
class LudavaWindowController {
  /// Creates a window controller with an optional current-window test seam.
  LudavaWindowController({
    Window? Function()? currentWindow,
    bool Function()? isWindows,
  }) : _currentWindow = currentWindow ?? _findCurrentWindow,
       _isWindows = isWindows ?? _isWindowsPlatform;

  final Window? Function() _currentWindow;
  final bool Function() _isWindows;

  /// Configures the hidden title bar and size limits on Windows.
  void configure() {
    if (!_isWindows()) return;
    final window = _currentWindow();
    if (window == null) return;
    window
      ..title = 'Ludava'
      ..titleBarStyle = TitleBarStyle.hidden
      ..minimumSize = const Size(
        AppLayoutConstants.minimumWindowWidth,
        AppLayoutConstants.minimumWindowHeight,
      ).toNative();
    window.setSize(
      const Size(
        AppLayoutConstants.initialWindowWidth,
        AppLayoutConstants.initialWindowHeight,
      ).toNative(),
      false,
    );
    window.center();
  }

  /// Minimizes the current window when a native window is available.
  void minimize() => _currentWindow()?.minimize();

  /// Maximizes or restores the current window when it is available.
  void toggleMaximize() {
    final window = _currentWindow();
    if (window == null) return;
    if (window.isMaximized) {
      window.unmaximize();
    } else {
      window.maximize();
    }
  }

  /// Closes the current window when a native window is available.
  void close() {
    _currentWindow()?.close();
  }

  /// Gets the app's active native window from the window manager plugin.
  static Window? _findCurrentWindow() => WindowManager.instance.getCurrent();

  /// Reports whether the current Flutter desktop target is Windows.
  static bool _isWindowsPlatform() =>
      defaultTargetPlatform == TargetPlatform.windows;
}
