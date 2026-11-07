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

    /// Replaces native close observation in deterministic controller tests.
    VoidCallback Function(
      Future<void> Function(VoidCallback cancelRequest) onCloseRequested,
    )?
    registerWindowCloseObserver,

    /// Replaces the native close request in deterministic controller tests.
    this.requestNativeClose,
  }) : _currentWindow = currentWindow ?? _findCurrentWindow,
       _isWindows = isWindows ?? _isWindowsPlatform,
       _configureWindow = onConfigureWindow,
       _listenForWindowState = registerWindowStateObserver,
       _listenForWindowClose = registerWindowCloseObserver;

  final Window? Function() _currentWindow;
  final bool Function() _isWindows;
  final void Function(Window window, Size minimumSize, Size initialSize)?
  _configureWindow;
  final VoidCallback Function(ValueChanged<bool> onMaximizedChanged)?
  _listenForWindowState;
  final VoidCallback Function(
    Future<void> Function(VoidCallback cancelRequest) onCloseRequested,
  )?
  _listenForWindowClose;

  /// Optional close operation used by deterministic desktop controller tests.
  final Future<bool> Function(Window window)? requestNativeClose;
  final ValueNotifier<bool> _isMaximized = ValueNotifier(false);
  VoidCallback? _removeWindowStateListener;
  VoidCallback? _removeWindowCloseListener;
  Future<void> Function()? _onCloseRequested;
  bool _closingAfterCleanup = false;

  /// Current native maximize state, observed from window-manager events.
  ValueListenable<bool> get isMaximized => _isMaximized;

  /// Configures window geometry and intercepts close requests on Windows.
  void configure({Future<void> Function()? onCloseRequested}) {
    _onCloseRequested = onCloseRequested;
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
      _startWindowCloseListener();
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
    _startWindowCloseListener();
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

  /// Closes the current window after its caller has completed resource cleanup.
  Future<void> close() async {
    final window = _currentWindow();
    if (window == null) return;
    _closingAfterCleanup = true;
    try {
      final requestNativeClose = this.requestNativeClose;
      final closeAccepted = requestNativeClose == null
          ? window.close()
          : await requestNativeClose(window);
      if (!closeAccepted) _closingAfterCleanup = false;
    } catch (_) {
      _closingAfterCleanup = false;
      rethrow;
    }
  }

  /// Releases the window-state subscription and listenable value.
  void dispose() {
    _removeWindowStateListener?.call();
    _removeWindowStateListener = null;
    _removeWindowCloseListener?.call();
    _removeWindowCloseListener = null;
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

  /// Registers once for native close requests so cleanup can finish first.
  void _startWindowCloseListener() {
    if (_removeWindowCloseListener != null) return;
    final listen = _listenForWindowClose ?? _listenToNativeWindowClose;
    _removeWindowCloseListener = listen(_handleWindowCloseRequest);
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

  /// Cancels native close until the app's asynchronous cleanup has completed.
  VoidCallback _listenToNativeWindowClose(
    Future<void> Function(VoidCallback cancelRequest) onCloseRequested,
  ) {
    final window = _currentWindow();
    if (window == null) return () {};
    final listenerId = window.addListener((event) async {
      if (event case WindowCloseRequestedEvent(:final request)) {
        await onCloseRequested(request.cancel);
      }
    });
    return () => window.removeListener(listenerId);
  }

  /// Cancels unsolicited closure, then awaits cleanup before allowing closure.
  Future<void> _handleWindowCloseRequest(VoidCallback cancelRequest) async {
    if (_closingAfterCleanup) {
      _closingAfterCleanup = false;
      return;
    }
    cancelRequest();
    await _onCloseRequested?.call();
  }

  /// Gets the app's active native window from the window manager plugin.
  static Window? _findCurrentWindow() => WindowManager.instance.getCurrent();

  /// Reports whether the current Flutter desktop target is Windows.
  static bool _isWindowsPlatform() =>
      defaultTargetPlatform == TargetPlatform.windows;
}
