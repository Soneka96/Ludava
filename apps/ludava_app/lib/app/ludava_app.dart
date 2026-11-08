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
  Future<void>? _controllerDisposalFuture;
  _ShutdownState _shutdownState = _ShutdownState.running;
  String? _closeFailure;

  /// Creates the controller and registers the awaited native close sequence.
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TrainerController(sdk: widget.sdk);
    _windowController = widget.windowController ?? LudavaWindowController();
    _windowController.configure(onCloseRequested: _handleNativeCloseRequest);
  }

  /// Releases window observation and starts fallback cleanup for tree removal.
  @override
  void dispose() {
    _windowController.dispose();
    if (_controllerDisposalFuture == null) {
      unawaited(_reportControllerDisposal());
    }
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
          onEditField: _editField,
          onApplyField: _writeField,
          onCancelEditing: _cancelEditing,
          onMinimize: _minimizeWindow,
          onToggleMaximize: _toggleMaximizeWindow,
          isMaximized: _windowController.isMaximized,
          onClose: _requestWindowClose,
          isClosing: _shutdownState == _ShutdownState.closing,
          closeFailure: _closeFailure,
          onRefresh: _refresh,
          onSelectProcess: _selectProcess,
        ),
      ),
    );
  }

  /// Opens a field editor only while the controller is still active.
  void _editField(GameField field) {
    if (_shutdownState == _ShutdownState.running) {
      _controller.editField(field);
    }
  }

  /// Writes a value only while the controller is still active.
  GameWriteResult _writeField(String fieldId, int value) {
    if (_shutdownState == _ShutdownState.running) {
      return _controller.writeField(fieldId, value);
    }
    return GameWriteResult(
      status: GameWriteStatus.none,
      fieldId: fieldId,
      requestedValue: value,
    );
  }

  /// Cancels editing only while the controller is still active.
  void _cancelEditing() {
    if (_shutdownState == _ShutdownState.running) {
      _controller.cancelEditing();
    }
  }

  /// Refreshes the session only while the controller is still active.
  void _refresh() {
    if (_shutdownState == _ShutdownState.running) _controller.refresh();
  }

  /// Selects a process only while the controller is still active.
  void _selectProcess(int processId) {
    if (_shutdownState == _ShutdownState.running) {
      _controller.selectProcess(processId);
    }
  }

  /// Minimizes the current native application window when it is available.
  void _minimizeWindow() {
    if (_shutdownState == _ShutdownState.running) _windowController.minimize();
  }

  /// Toggles the current native window between maximized and restored sizes.
  void _toggleMaximizeWindow() {
    if (_shutdownState == _ShutdownState.running) {
      _windowController.toggleMaximize();
    }
  }

  /// Starts the same awaited cleanup path for title-bar close requests.
  void _requestWindowClose() {
    if (_shutdownState == _ShutdownState.closing) return;
    unawaited(_closeAfterDisposal(requestCancelled: true));
  }

  /// Shares one cleanup future across repeated title-bar and native requests.
  Future<void> _closeAfterDisposal({required bool requestCancelled}) {
    final activeClose = _closeFuture;
    if (activeClose != null) return activeClose;
    if (_shutdownState == _ShutdownState.closing) return Future<void>.value();

    if (_shutdownState == _ShutdownState.running) {
      setState(() => _shutdownState = _ShutdownState.closing);
    }

    final closeFuture =
        _disposeControllerAndCloseWindow(requestCancelled: requestCancelled)
            .whenComplete(() {
              _closeFuture = null;
            });
    _closeFuture = closeFuture;
    return closeFuture;
  }

  /// Awaits controller cleanup and then closes the native window.
  Future<void> _disposeControllerAndCloseWindow({
    required bool requestCancelled,
  }) async {
    try {
      await _disposeControllerOnce();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'while disposing the trainer controller');
    }
    if (!requestCancelled) {
      final error = StateError(
        'The native close event could not be cancelled.',
      );
      _reportError(
        error,
        StackTrace.current,
        'while intercepting the native window close request',
      );
      _showCloseFailure(error.message);
      return;
    }

    try {
      await _windowController.close();
      if (mounted) setState(() => _shutdownState = _ShutdownState.closing);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'while closing the native window');
      _showCloseFailure(error.toString());
    }
  }

  /// Completes cleanup after a native close event's veto result is known.
  Future<void> _handleNativeCloseRequest(bool requestCancelled) async {
    await _closeAfterDisposal(requestCancelled: requestCancelled);
  }

  /// Keeps the terminal disposed controller behind a retryable failure state.
  void _showCloseFailure(String failure) {
    if (mounted) {
      setState(() {
        _shutdownState = _ShutdownState.closeFailed;
        _closeFailure = failure;
      });
    }
  }

  /// Shares terminal SDK cleanup between close retries and tree disposal.
  Future<void> _disposeControllerOnce() =>
      _controllerDisposalFuture ??= _controller.dispose();

  /// Reports fallback controller cleanup errors after external tree removal.
  Future<void> _reportControllerDisposal() async {
    try {
      await _disposeControllerOnce();
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

/// Tracks the terminal application shutdown path without reviving the SDK.
enum _ShutdownState { running, closing, closeFailed }
