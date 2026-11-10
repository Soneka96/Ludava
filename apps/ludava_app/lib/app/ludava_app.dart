import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:ludava_app/app/presentation/screens/ludava_shell.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/state/app.actions.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:redux/redux.dart';

/// Root Flutter composition for the Redux store and native desktop window.
class LudavaApp extends StatefulWidget {
  /// Optional native window controller for deterministic lifecycle tests.
  final LudavaWindowController? windowController;

  /// Optional theme override for deterministic presentation tests.
  final ThemeData? theme;

  /// Creates the app with optional window and theme test seams.
  const LudavaApp({this.windowController, this.theme, super.key});

  /// Creates state that owns the Redux startup and native close coordination.
  @override
  State<LudavaApp> createState() => _LudavaAppState();
}

class _LudavaAppState extends State<LudavaApp> {
  late final Store<AppState> _store;
  late final SdkOperationGate _operationGate;
  late final LudavaWindowController _windowController;
  Future<void>? _shutdownFuture;
  Future<void>? _sdkDisposalFuture;
  Future<void>? _closeFuture;
  Object? _sdkDisposalFailure;
  bool _disposalFailureRetryOffered = false;
  _ShutdownState _shutdownState = _ShutdownState.running;
  String? _closeFailure;

  /// Configures native close interception before Redux initializes the SDK.
  @override
  void initState() {
    super.initState();
    _windowController = widget.windowController ?? LudavaWindowController();
    _windowController.configure(onCloseRequested: _handleNativeCloseRequest);
    if (!sl.isRegistered<Store<AppState>>()) initDependencies();
    _store = sl<Store<AppState>>();
    _operationGate = sl<SdkOperationGate>();
    _store.dispatch(const InitializeAppAction());
  }

  /// Starts the shared shutdown path if the widget tree is removed directly.
  @override
  void dispose() {
    _windowController.dispose();
    if (_shutdownFuture == null) unawaited(_shutdownAndDispose());
    super.dispose();
  }

  /// Provides the single store to focused Redux connectors in the app shell.
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ludava',
    debugShowCheckedModeBanner: false,
    theme: widget.theme ?? LudavaTheme.graphiteAndTeal,
    home: StoreProvider<AppState>(
      store: _store,
      child: LudavaShell(
        onMinimize: _minimizeWindow,
        onToggleMaximize: _toggleMaximizeWindow,
        isMaximized: _windowController.isMaximized,
        onClose: _requestWindowClose,
        isClosing:
            _shutdownState == _ShutdownState.closing ||
            _shutdownState == _ShutdownState.none,
        closeFailure: _closeFailure,
      ),
    ),
  );

  /// Reports whether native or trainer interaction is terminally blocked.
  bool get _isInteractionBlocked => switch (_shutdownState) {
    _ShutdownState.none => true,
    _ShutdownState.running => false,
    _ShutdownState.closing || _ShutdownState.closeFailed => true,
  };

  /// Requests native close after SDK cleanup, unless shutdown already began.
  void _requestWindowClose() {
    if (_shutdownState == _ShutdownState.closing) return;
    unawaited(_closeAfterDisposal(requestCancelled: true));
  }

  /// Shares one native close future across overlapping close requests.
  Future<void> _closeAfterDisposal({required bool requestCancelled}) {
    final activeClose = _closeFuture;
    if (activeClose != null) return activeClose;
    setState(() {
      _shutdownState = _ShutdownState.closing;
      _closeFailure = null;
    });
    final closeFuture = _finishNativeClose(requestCancelled: requestCancelled)
        .whenComplete(() => _closeFuture = null);
    _closeFuture = closeFuture;
    return closeFuture;
  }

  /// Awaits shared resource shutdown before attempting native close.
  Future<void> _finishNativeClose({required bool requestCancelled}) async {
    await _shutdownAndDispose();
    if (!requestCancelled) {
      final error = StateError(
        'The native close event could not be cancelled.',
      );
      _reportError(
        error,
        StackTrace.current,
        'while intercepting the native window close request',
      );
      final disposalFailure = _sdkDisposalFailure;
      if (disposalFailure != null) _disposalFailureRetryOffered = true;
      _showCloseFailure(
        disposalFailure == null
            ? error.message
            : '${error.message}\n$disposalFailure',
      );
      return;
    }
    final disposalFailure = _sdkDisposalFailure;
    if (disposalFailure != null && !_disposalFailureRetryOffered) {
      _disposalFailureRetryOffered = true;
      _showCloseFailure(disposalFailure.toString());
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

  /// Closes the SDK gate, awaits middleware cleanup, and disposes the SDK once.
  Future<void> _shutdownAndDispose() {
    final existingShutdown = _shutdownFuture;
    if (existingShutdown != null) return existingShutdown;

    _operationGate.close();
    final action = ShutdownRequestedAction();
    try {
      _store.dispatch(action);
    } on Object catch (error, stackTrace) {
      _reportError(error, stackTrace, 'while dispatching application shutdown');
    }
    return _shutdownFuture = _finishShutdown(action);
  }

  /// Attempts SDK disposal even when one or more observation cleanups fail.
  Future<void> _finishShutdown(ShutdownRequestedAction action) async {
    try {
      await action.waitForCleanup();
    } on Object catch (error, stackTrace) {
      _reportError(error, stackTrace, 'while cleaning up trainer observation');
    }
    try {
      await (_sdkDisposalFuture ??= Future<void>.sync(
        () => sl<TrainerSdkCapability>().dispose(),
      ));
    } on Object catch (error, stackTrace) {
      _sdkDisposalFailure = error;
      _reportError(error, stackTrace, 'while disposing the trainer SDK');
    }
  }

  /// Handles a native close event after its veto result is known.
  Future<void> _handleNativeCloseRequest(bool requestCancelled) =>
      _closeAfterDisposal(requestCancelled: requestCancelled);

  /// Shows a retryable close failure while keeping Redux and its store alive.
  void _showCloseFailure(String failure) {
    if (mounted) {
      setState(() {
        _shutdownState = _ShutdownState.closeFailed;
        _closeFailure = failure;
      });
    }
  }

  /// Minimizes the native app window while resources remain active.
  void _minimizeWindow() {
    if (!_isInteractionBlocked) _windowController.minimize();
  }

  /// Toggles maximize state while resources remain active.
  void _toggleMaximizeWindow() {
    if (!_isInteractionBlocked) _windowController.toggleMaximize();
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

/// Tracks shutdown state; [none] is an invalid fail-closed sentinel.
enum _ShutdownState {
  /// No valid lifecycle state has been selected.
  none,

  /// The SDK operation gate remains open.
  running,

  /// Cleanup and native close are in progress.
  closing,

  /// Native close failed after SDK resources became terminal.
  closeFailed,
}
