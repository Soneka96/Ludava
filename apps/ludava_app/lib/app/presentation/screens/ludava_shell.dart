import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ludava_app/app/presentation/widgets/ludava_window_title_bar.dart';
import 'package:ludava_app/features/connection/presentation/screens/session_connection_body.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_game_header.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
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

  /// Explains a rejected native close while keeping the app noninteractive.
  final String? closeFailure;

  /// Refreshes the selected session or retries process discovery.
  final VoidCallback onRefresh;

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
    this.closeFailure,
    required this.onRefresh,
    required this.onSelectProcess,
    super.key,
  });

  /// Renders the integrated window chrome and compact utility content.
  @override
  Widget build(BuildContext context) => DragToResizeArea(
    resizeEdgeSize: LudavaDimensions.windowResizeHandleSize,
    child: Scaffold(
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: closeFailure != null,
            child: Column(
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
                            ),
                            Expanded(
                              child: SafeArea(
                                child: _buildSessionBody(context),
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
          if (closeFailure case final failure?)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.scrim
                    .withValues(alpha: .72),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(LudavaSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ludava could not close. App actions are disabled.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: LudavaSpacing.sm),
                        Tooltip(
                          message: failure,
                          child: Text(
                            failure,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: LudavaSpacing.md),
                        FilledButton(
                          onPressed: onClose,
                          child: const Text('Retry close'),
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

  /// Shows connection guidance until the SDK resolves a usable memory base.
  Widget _buildSessionBody(BuildContext context) {
    final isReady =
        session.detection?.status == GameDetectionStatus.supportedGame &&
        session.memoryBase != null;
    if (!isReady) {
      return SessionConnectionBody(
        session: session,
        onSelectProcess: onSelectProcess,
      );
    }

    final errorMessage = session.errorMessage;
    return Column(
      children: [
        SizedBox(
          height: LudavaDimensions.sessionFeedbackHeight,
          child: errorMessage == null
              ? null
              : Tooltip(
                  message: errorMessage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LudavaSpacing.lg,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(
          child: TrainerFieldsPanel(
            session: session,
            editingFieldId: editingFieldId,
            onEditField: onEditField,
            onApplyField: onApplyField,
            onCancelEditing: onCancelEditing,
          ),
        ),
      ],
    );
  }
}
