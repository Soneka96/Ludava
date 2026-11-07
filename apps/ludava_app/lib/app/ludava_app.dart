import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:ludava_app/app/ludava_window_title_bar.dart';
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
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppLayoutConstants.contentInset,
                      ),
                      child: _buildSessionSummary(theme),
                    ),
                  ),
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

  /// Shows a basic startup summary until the feature screens are added.
  Widget _buildSessionSummary(ThemeData theme) {
    final state = _session;
    final message = switch (state) {
      TrainerSessionState(:final errorMessage?) => errorMessage,
      TrainerSessionState(selectedProcessId: null, processIds: []) =>
        'RPCS3 was not found. Start RPCS3 to connect.',
      TrainerSessionState(selectedProcessId: null) =>
        'Select an RPCS3 process to continue.',
      TrainerSessionState(selectedProcessId: final processId) =>
        'Connected to RPCS3 (PID $processId).',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ludava',
          key: const ValueKey('ludava-session-heading'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }

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
