import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_window_title_bar.dart';
import 'package:ludava_app/features/connection/presentation/screens/session_connection_body.dart';
import 'package:ludava_app/features/game_header/presentation/trainer_game_header.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/shared/layout/ludava_dimensions.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:window_manager/window_manager.dart';

/// Composes the title bar, game header, and active connection or trainer body.
class LudavaShell extends StatelessWidget {
  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Field currently being edited, if any.
  final String? editingFieldId;

  /// Opens the editor for a writable field.
  final ValueChanged<GameField> onEditField;

  /// Applies an explicitly requested field value through the SDK owner.
  final GameWriteResult Function(String fieldId, int value) onApplyField;

  /// Discards the current editor draft.
  final VoidCallback onCancelEditing;

  /// Minimizes the native window.
  final VoidCallback onMinimize;

  /// Toggles the native window between maximized and restored states.
  final VoidCallback onToggleMaximize;

  /// Current maximized state reported by the native window manager.
  final ValueListenable<bool> isMaximized;

  /// Closes the native window.
  final VoidCallback onClose;

  /// Refreshes the selected session or retries process discovery.
  final VoidCallback onRefresh;

  /// Re-detects the selected game or retries process discovery.
  final VoidCallback onRedetect;

  /// Selects an RPCS3 process through the SDK session.
  final ValueChanged<int> onSelectProcess;

  /// Creates the app shell around a supplied SDK snapshot and actions.
  const LudavaShell({
    required this.session,
    required this.editingFieldId,
    required this.onEditField,
    required this.onApplyField,
    required this.onCancelEditing,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.isMaximized,
    required this.onClose,
    required this.onRefresh,
    required this.onRedetect,
    required this.onSelectProcess,
    super.key,
  });

  /// Renders the integrated window chrome and width-constrained content.
  @override
  Widget build(BuildContext context) => DragToResizeArea(
    resizeEdgeSize: LudavaDimensions.windowResizeHandleSize,
    child: Scaffold(
      body: Column(
        children: [
          LudavaWindowTitleBar(
            session: session,
            isMaximized: isMaximized,
            onMinimize: onMinimize,
            onToggleMaximize: onToggleMaximize,
            onClose: onClose,
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
                        session: session,
                        onRefresh: onRefresh,
                        onRedetect: onRedetect,
                      ),
                      Expanded(
                        child: SafeArea(
                          child:
                              session.detection?.status ==
                                  GameDetectionStatus.supportedGame
                              ? TrainerFieldsPanel(
                                  session: session,
                                  editingFieldId: editingFieldId,
                                  onEditField: onEditField,
                                  onApplyField: onApplyField,
                                  onCancelEditing: onCancelEditing,
                                )
                              : SessionConnectionBody(
                                  session: session,
                                  onSelectProcess: onSelectProcess,
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
  );
}
