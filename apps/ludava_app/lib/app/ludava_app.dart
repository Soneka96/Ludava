import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:ludava_app/app/presentation/screens/ludava_shell.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_controller.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Root Flutter composition for the trainer controller and desktop window.
class LudavaApp extends StatefulWidget {
  /// Optional controller injected for deterministic composition tests.
  final TrainerController? controller;

  /// Optional SDK input used when the app creates its trainer controller.
  final LudavaSdk? sdk;

  /// Optional native window controller for tests and desktop composition.
  final LudavaWindowController? windowController;

  /// Optional theme override for deterministic presentation tests.
  final ThemeData? theme;

  /// Creates the app, accepting either an owned controller or an SDK seam.
  const LudavaApp({
    this.controller,
    this.sdk,
    this.windowController,
    this.theme,
    super.key,
  }) : assert(controller == null || sdk == null);

  /// Creates state that owns the trainer controller and window controller.
  @override
  State<LudavaApp> createState() => _LudavaAppState();
}

class _LudavaAppState extends State<LudavaApp> {
  late final TrainerController _controller;
  late final LudavaWindowController _windowController;
  Future<void>? _closeFuture;

  /// Creates the controller and registers the awaited native close sequence.
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TrainerController(sdk: widget.sdk);
    _windowController = widget.windowController ?? LudavaWindowController();
    _windowController.configure(onCloseRequested: _closeAfterDisposal);
  }

  /// Releases window observation and starts fallback cleanup for tree removal.
  @override
  void dispose() {
    _windowController.dispose();
    if (_closeFuture == null) unawaited(_reportControllerDisposal());
    super.dispose();
  }

  /// Renders the latest controller snapshot inside the desktop app shell.
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? LudavaTheme.graphiteAndTeal;
    return MaterialApp(
      title: 'Ludava',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) => LudavaShell(
          session: _controller.session,
          editingFieldId: _controller.editingFieldId,
          onEditField: (field) => _controller.editField(field),
          onApplyField: _controller.writeField,
          onCancelEditing: _controller.cancelEditing,
          onMinimize: _minimizeWindow,
          onToggleMaximize: _toggleMaximizeWindow,
          isMaximized: _windowController.isMaximized,
          onClose: _requestWindowClose,
          onRefresh: _controller.refresh,
          onRedetect: _controller.redetect,
          onSelectProcess: (processId) => _controller.selectProcess(processId),
        ),
      ),
    );
  }

  /// Minimizes the current native application window when it is available.
  void _minimizeWindow() => _windowController.minimize();

  /// Toggles the current native window between maximized and restored sizes.
  void _toggleMaximizeWindow() => _windowController.toggleMaximize();

  /// Starts the same awaited cleanup path for title-bar close requests.
  void _requestWindowClose() {
    unawaited(_closeAfterDisposal());
  }

  /// Shares one cleanup future across repeated title-bar and native requests.
  Future<void> _closeAfterDisposal() =>
      _closeFuture ??= _disposeControllerAndCloseWindow();

  /// Awaits controller cleanup and then closes the native window.
  Future<void> _disposeControllerAndCloseWindow() async {
    try {
      await _controller.dispose();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'while disposing the trainer controller');
    }
    await _windowController.close();
  }

  /// Reports fallback controller cleanup errors after external tree removal.
  Future<void> _reportControllerDisposal() async {
    try {
      await _controller.dispose();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'while disposing the trainer controller');
    }
  }

  /// Reports [error] with context about the failed asynchronous operation.
  void _reportError(Object error, StackTrace stackTrace, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'ludava_app',
        context: ErrorDescription(context),
      ),
    );
  }
}
