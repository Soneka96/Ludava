import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:ludava_app/app/ludava_window_title_bar.dart';
import 'package:ludava_app/features/connection/presentation/session_connection_body.dart';
import 'package:ludava_app/features/game_header/presentation/trainer_game_header.dart';
import 'package:ludava_app/shared/constants/layout_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:window_manager/window_manager.dart';

/// Root Flutter presentation for one owned [LudavaSdk] runtime.
class LudavaApp extends StatefulWidget {
  /// Optional SDK instance, primarily used to provide deterministic test state.
  final LudavaSdk? sdk;

  /// Optional native window controller for tests and desktop composition.
  final LudavaWindowController? windowController;

  /// Optional theme override for deterministic presentation tests.
  final ThemeData? theme;

  /// Creates the application and optionally accepts owned runtime seams.
  const LudavaApp({this.sdk, this.windowController, this.theme, super.key});

  /// Creates state that owns the SDK runtime and its state subscription.
  @override
  State<LudavaApp> createState() => _LudavaAppState();
}

class _LudavaAppState extends State<LudavaApp> {
  late final LudavaSdk _sdk;
  late final LudavaWindowController _windowController;
  late TrainerSessionState _session;
  StreamSubscription<TrainerSessionState>? _stateSubscription;
  bool _shuttingDown = false;

  /// Creates the SDK once, observes its snapshot, then requests connection.
  @override
  void initState() {
    super.initState();
    _windowController = widget.windowController ?? LudavaWindowController();
    _windowController.configure();
    _sdk = widget.sdk ?? LudavaSdk.create();
    _session = _sdk.session.state;
    _stateSubscription = _sdk.session.stateChanges.listen(_handleStateChanged);
    _sdk.session.connect();
  }

  /// Cancels observation and asynchronously releases the owned SDK runtime.
  @override
  void dispose() {
    _shuttingDown = true;
    unawaited(_disposeResources());
    super.dispose();
  }

  /// Renders the current connection summary from the latest SDK snapshot.
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? LudavaTheme.graphiteAndTeal;
    return MaterialApp(
      title: 'Ludava',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: DragToResizeArea(
        resizeEdgeSize: AppLayoutConstants.resizeHandleSize,
        child: Scaffold(
          body: Column(
            children: [
              LudavaWindowTitleBar(
                onMinimize: _minimizeWindow,
                onToggleMaximize: _toggleMaximizeWindow,
                onClose: _closeWindow,
              ),
              Expanded(
                child: Column(
                  children: [
                    TrainerGameHeader(
                      session: _session,
                      onRefresh: _refreshSession,
                      onRedetect: _redetectSession,
                    ),
                    Expanded(
                      child: SafeArea(
                        child: SessionConnectionBody(
                          session: _session,
                          onSelectProcess: _selectProcess,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Minimizes the current native application window when it is available.
  void _minimizeWindow() => _windowController.minimize();

  /// Toggles the current native window between maximized and restored sizes.
  void _toggleMaximizeWindow() => _windowController.toggleMaximize();

  /// Closes the current native application window when it is available.
  void _closeWindow() => _windowController.close();

  /// Requests SDK discovery again, or refreshes the selected session.
  void _refreshSession() {
    if (_session.selectedProcessId == null) {
      _sdk.session.connect();
    } else {
      _sdk.session.refresh();
    }
  }

  /// Re-detects the selected session or retries discovery when unselected.
  void _redetectSession() {
    if (_session.selectedProcessId == null) {
      _sdk.session.connect();
    } else {
      _sdk.session.redetect();
    }
  }

  /// Selects an RPCS3 process through the SDK session capability.
  void _selectProcess(int processId) => _sdk.session.selectProcess(processId);

  /// Applies state updates while the root widget remains mounted.
  void _handleStateChanged(TrainerSessionState state) {
    if (_shuttingDown || !mounted) return;
    setState(() => _session = state);
  }

  /// Stops the subscription before awaiting SDK resource disposal.
  Future<void> _disposeResources() async {
    final subscription = _stateSubscription;
    _stateSubscription = null;
    final cancellation = subscription?.cancel();
    final disposal = _sdk.dispose();
    try {
      await Future.wait<void>([?cancellation, disposal]);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'ludava_app',
          context: ErrorDescription('while disposing the Ludava SDK runtime'),
        ),
      );
    }
  }
}
