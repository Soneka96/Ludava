import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Root Flutter presentation for one owned [LudavaSdk] runtime.
class LudavaApp extends StatefulWidget {
  /// Optional SDK instance, primarily used to provide deterministic test state.
  final LudavaSdk? sdk;

  /// Creates the application and optionally accepts its owned [sdk].
  const LudavaApp({this.sdk, super.key});

  /// Creates state that owns the SDK runtime and its state subscription.
  @override
  State<LudavaApp> createState() => _LudavaAppState();
}

class _LudavaAppState extends State<LudavaApp> {
  late final LudavaSdk _sdk;
  late TrainerSessionState _session;
  StreamSubscription<TrainerSessionState>? _stateSubscription;
  bool _shuttingDown = false;

  /// Creates the SDK once, observes its snapshot, then requests connection.
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ludava',
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildSessionSummary(),
          ),
        ),
      ),
    ),
  );

  /// Shows a basic startup summary until the feature screens are added.
  Widget _buildSessionSummary() {
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
        Text('LUDAVA', style: Theme.of(context).textTheme.headlineMedium),
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
