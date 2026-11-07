import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ludava_app/app/ludava_window_controller.dart';
import 'package:ludava_app/app/ludava_window_title_bar.dart';
import 'package:ludava_app/features/connection/presentation/session_connection_body.dart';
import 'package:ludava_app/features/game_header/presentation/trainer_game_header.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_fields_panel.dart';
import 'package:ludava_app/shared/layout/ludava_dimensions.dart';
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
  String? _editingFieldId;
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
        resizeEdgeSize: LudavaDimensions.windowResizeHandleSize,
        child: Scaffold(
          body: Column(
            children: [
              LudavaWindowTitleBar(
                onMinimize: _minimizeWindow,
                onToggleMaximize: _toggleMaximizeWindow,
                onClose: _closeWindow,
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: LudavaDimensions.maximumContentWidth,
                    ),
                    child: SizedBox.expand(
                      child: Column(
                        children: [
                          TrainerGameHeader(
                            session: _session,
                            onRefresh: _refreshSession,
                            onRedetect: _redetectSession,
                          ),
                          Expanded(
                            child: SafeArea(
                              child:
                                  _session.detection?.status ==
                                      GameDetectionStatus.supportedGame
                                  ? TrainerFieldsPanel(
                                      session: _session,
                                      editingFieldId: _editingFieldId,
                                      onEditField: _editField,
                                      onApplyField: _applyField,
                                      onCancelEditing: _cancelFieldEdit,
                                    )
                                  : SessionConnectionBody(
                                      session: _session,
                                      onSelectProcess: _selectProcess,
                                    ),
                            ),
                          ),
                        ],
                      ),
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

  /// Opens the inline editor only for a currently approved field and target.
  void _editField(GameField field) {
    if (!_canEditField(_session, field.id)) return;
    setState(() => _editingFieldId = field.id);
  }

  /// Calls the SDK's guarded field-write operation after explicit Apply.
  GameWriteResult _applyField(String fieldId, int value) =>
      _sdk.session.writeField(fieldId, value);

  /// Discards the active draft without performing a write.
  void _cancelFieldEdit() => setState(() => _editingFieldId = null);

  /// Applies state updates while the root widget remains mounted.
  void _handleStateChanged(TrainerSessionState state) {
    if (_shuttingDown || !mounted) return;
    var editingFieldId = _editingFieldId;
    if (editingFieldId != null &&
        (!_sameSession(_session, state) ||
            !_hasWriteTarget(state, editingFieldId) ||
            (state.readResults[editingFieldId]?.succeeded != true &&
                state.lastWriteResult?.fieldId != editingFieldId))) {
      editingFieldId = null;
    }
    setState(() {
      _session = state;
      _editingFieldId = editingFieldId;
    });
  }

  /// Checks confirmed identity, profile/field permissions, and field bounds.
  bool _hasWriteTarget(TrainerSessionState state, String fieldId) {
    final profile = state.profile;
    final field = profile?.findField(fieldId);
    return profile != null &&
        profile.canRead &&
        profile.canWrite &&
        field != null &&
        field.canRead &&
        field.canWrite &&
        field.minimumValue != null &&
        field.maximumValue != null &&
        state.selectedProcessId != null &&
        state.memoryBase != null &&
        state.detection?.confidence == GameIdentityConfidence.confirmed;
  }

  /// Checks that [first] and [second] describe the same SDK write target.
  bool _sameSession(TrainerSessionState first, TrainerSessionState second) =>
      first.selectedProcessId == second.selectedProcessId &&
      first.processMetadata?.startedAtUtc ==
          second.processMetadata?.startedAtUtc &&
      first.detection?.status == second.detection?.status &&
      first.detection?.confidence == second.detection?.confidence &&
      first.profile?.id == second.profile?.id &&
      first.detection?.executableHash == second.detection?.executableHash &&
      first.memoryBase == second.memoryBase;

  /// Checks the currently displayed read result before opening an editor.
  bool _canEditField(TrainerSessionState state, String fieldId) =>
      _hasWriteTarget(state, fieldId) &&
      state.readResults[fieldId]?.succeeded == true;

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
