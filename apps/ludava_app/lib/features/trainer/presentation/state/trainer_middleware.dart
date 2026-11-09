import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer.actions.dart';
import 'package:ludava_app/features/trainer/services/sdk_operation_gate.dart';
import 'package:ludava_app/features/trainer/services/trainer_sdk_capability.dart';
import 'package:ludava_app/injection_container.dart';
import 'package:ludava_app/shared/state/app.actions.dart';
import 'package:ludava_app/shared/state/app_state.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:redux/redux.dart';

/// Owns Flutter's single observation of the authoritative SDK session.
class TrainerMiddleware extends MiddlewareClass<AppState> {
  /// Creates middleware that resolves its SDK capability through [sl].
  TrainerMiddleware();

  StreamSubscription<TrainerSessionState>? _subscription;
  Future<void>? _cleanupFuture;
  bool _initialized = false;
  bool _shutdownStarted = false;

  /// Passes [action] through before handling trainer-owned operations.
  @override
  dynamic call(Store<AppState> store, dynamic action, NextDispatcher next) {
    next(action);
    switch (action) {
      case InitializeAppAction():
        _initialize(store);
      case RefreshTrainerAction():
        _refreshTrainer(store.state);
      case SelectRpcs3ProcessAction(:final processId):
        _selectProcess(processId);
      case ShutdownRequestedAction():
        _shutdown(action);
    }
  }

  /// Starts observation once, subscribes before connecting, and respects the gate.
  void _initialize(Store<AppState> store) {
    if (_initialized || _shutdownStarted || !sl<SdkOperationGate>().isOpen) {
      return;
    }
    try {
      _subscription = sl<TrainerSdkCapability>().stateChanges.listen((session) {
        if (!_shutdownStarted) {
          store.dispatch(TrainerSessionChangedAction(session));
        }
      }, onError: _handleStreamError);
      _initialized = true;
    } on Object catch (error, stackTrace) {
      _reportError(error, stackTrace, 'while observing trainer session state');
      return;
    }
    _connectTrainer();
  }

  /// Refreshes the selected SDK process or discovers one when none is selected.
  void _refreshTrainer(AppState state) {
    if (!sl<SdkOperationGate>().isOpen || _shutdownStarted) return;
    final capability = sl<TrainerSdkCapability>();
    if (state.trainer.session.selectedProcessId == null) {
      _runCommand(capability.connect, 'while discovering RPCS3');
    } else {
      _runCommand(capability.refresh, 'while refreshing the trainer session');
    }
  }

  /// Selects [processId] through the SDK when the operation gate is open.
  void _selectProcess(int processId) {
    if (!sl<SdkOperationGate>().isOpen || _shutdownStarted) return;
    final capability = sl<TrainerSdkCapability>();
    try {
      capability.selectProcess(processId);
    } on Object catch (error, stackTrace) {
      _reportError(error, stackTrace, 'while selecting an RPCS3 process');
    }
  }

  /// Starts discovery after session observation is active.
  void _connectTrainer() {
    if (!sl<SdkOperationGate>().isOpen || _shutdownStarted) return;
    final capability = sl<TrainerSdkCapability>();
    _runCommand(capability.connect, 'while discovering RPCS3');
  }

  /// Runs a synchronous SDK command and reports unexpected exceptions.
  void _runCommand(void Function() command, String context) {
    try {
      command();
    } on Object catch (error, stackTrace) {
      _reportError(error, stackTrace, context);
    }
  }

  /// Cancels observation once and registers its future with [action].
  void _shutdown(ShutdownRequestedAction action) {
    final existingCleanup = _cleanupFuture;
    if (existingCleanup != null) {
      _registerCleanup(action, existingCleanup);
      return;
    }
    _shutdownStarted = true;
    final subscription = _subscription;
    _subscription = null;
    Future<void> cleanup;
    try {
      cleanup = subscription?.cancel() ?? Future<void>.value();
    } on Object catch (error, stackTrace) {
      cleanup = Future<void>.error(error, stackTrace);
    }
    _cleanupFuture = cleanup;
    _registerCleanup(action, cleanup);
  }

  /// Registers cleanup and converts a registration error into another attempt.
  void _registerCleanup(ShutdownRequestedAction action, Future<void> cleanup) {
    try {
      action.addCleanup(cleanup);
    } on Object catch (error, stackTrace) {
      final registrationFailure = Future<void>.error(error, stackTrace);
      try {
        action.addCleanup(cleanup);
        action.addCleanup(registrationFailure);
      } on Object catch (registrationError, registrationStackTrace) {
        registrationFailure.then<void>(
          (_) {},
          onError: (Object futureError, StackTrace futureStackTrace) {
            _reportError(
              futureError,
              futureStackTrace,
              'while registering session cleanup',
            );
          },
        );
        _reportError(
          registrationError,
          registrationStackTrace,
          'while registering session cleanup',
        );
      }
    }
  }

  /// Reports an asynchronous SDK observation error without reconnecting.
  void _handleStreamError(Object error, StackTrace stackTrace) =>
      _reportError(error, stackTrace, 'while observing trainer session state');

  /// Reports [error] with [context] at the middleware operation boundary.
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
