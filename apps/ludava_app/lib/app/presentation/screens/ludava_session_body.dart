import 'package:flutter/material.dart';
import 'package:ludava_app/features/connection/presentation/screens/session_connection_body.dart';
import 'package:ludava_app/features/trainer/presentation/screens/trainer_fields_panel.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Composes connection guidance or the ready trainer fields and feedback.
class LudavaSessionBody extends StatelessWidget {
  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Field currently being edited, if any.
  final String? editingFieldId;

  /// Selects an RPCS3 process through the SDK session capability.
  final ValueChanged<int> onSelectProcess;

  /// Opens the editor for a writable field.
  final ValueChanged<GameField> onEditField;

  /// Applies an explicitly requested field value through the SDK owner.
  final GameWriteResult Function(String fieldId, int value) onApplyField;

  /// Discards the current editor draft.
  final VoidCallback onCancelEditing;

  /// Creates the session composition from one SDK snapshot and its actions.
  const LudavaSessionBody({
    required this.session,
    required this.editingFieldId,
    required this.onSelectProcess,
    required this.onEditField,
    required this.onApplyField,
    required this.onCancelEditing,
    super.key,
  });

  /// Selects connection guidance or composes trainer feedback and fields.
  @override
  Widget build(BuildContext context) {
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
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          key: const ValueKey('session-feedback-region'),
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
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
