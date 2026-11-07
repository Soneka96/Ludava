import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:window_manager/window_manager.dart';

/// Applies native desktop window settings and caption actions.
class LudavaWindowController {
  /// Creates a window controller with an optional current-window test seam.
  LudavaWindowController({
    Window? Function()? currentWindow,
    bool Function()? isWindows,

    /// Replaces native configuration in deterministic controller tests.
    void Function(Window window, Size minimumSize, Size initialSize)?
    onConfigureWindow,

    /// Replaces native state observation in deterministic controller tests.
    VoidCallback Function(ValueChanged<bool> onMaximizedChanged)?
    registerWindowStateObserver,
  }) : _currentWindow = currentWindow ?? _findCurrentWindow,
       _isWindows = isWindows ?? _isWindowsPlatform,
       _configureWindow = onConfigureWindow,
       _listenForWindowState = registerWindowStateObserver;

  final Window? Function() _currentWindow;
  final bool Function() _isWindows;
  final void Function(Window window, Size minimumSize, Size initialSize)?
  _configureWindow;
  final VoidCallback Function(ValueChanged<bool> onMaximizedChanged)?
  _listenForWindowState;
  final ValueNotifier<bool> _isMaximized = ValueNotifier(false);
  VoidCallback? _removeWindowStateListener;

  /// Current native maximize state, observed from window-manager events.
  ValueListenable<bool> get isMaximized => _isMaximized;

  /// Configures the hidden title bar and size limits on Windows.
  void configure() {
    if (!_isWindows()) return;
    final window = _currentWindow();
    if (window == null) return;
    final configureWindow = _configureWindow;
    if (configureWindow != null) {
      configureWindow(
        window,
        LudavaDimensions.minimumWindowSize,
        LudavaDimensions.initialWindowSize,
      );
      _startWindowStateListener();
      return;
    }
    _isMaximized.value = window.isMaximized;
    window
      ..title = 'Ludava'
      ..titleBarStyle = TitleBarStyle.hidden
      ..minimumSize = LudavaDimensions.minimumWindowSize.toNative();
    window.setSize(LudavaDimensions.initialWindowSize.toNative(), false);
    window.center();
    _startWindowStateListener();
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
    _isMaximized.value = window.isMaximized;
  }

  /// Closes the current window when a native window is available.
  void close() {
    _currentWindow()?.close();
  }

  /// Releases the window-state subscription and listenable value.
  void dispose() {
    _removeWindowStateListener?.call();
    _removeWindowStateListener = null;
    _isMaximized.dispose();
  }

  /// Registers once for native maximize and restore events.
  void _startWindowStateListener() {
    if (_removeWindowStateListener != null) return;
    final listen = _listenForWindowState ?? _listenToNativeWindowState;
    _removeWindowStateListener = listen((maximized) {
      _isMaximized.value = maximized;
    });
  }

  /// Observes actual state changes from the maintained native window package.
  static VoidCallback _listenToNativeWindowState(
    ValueChanged<bool> onMaximizedChanged,
  ) {
    final listenerId = WindowManager.instance.addListener((event) {
      switch (event) {
        case WindowMaximizedEvent():
          onMaximizedChanged(true);
        case WindowRestoredEvent():
          onMaximizedChanged(false);
        default:
          break;
      }
    });
    return () => WindowManager.instance.removeListener(listenerId);
  }

  /// Gets the app's active native window from the window manager plugin.
  static Window? _findCurrentWindow() => WindowManager.instance.getCurrent();

  /// Reports whether the current Flutter desktop target is Windows.
  static bool _isWindowsPlatform() =>
      defaultTargetPlatform == TargetPlatform.windows;
}
