import 'package:flutter/material.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_process_picker.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Shows process choice or concise guidance for the latest session state.
class SessionConnectionBody extends StatelessWidget {
  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Selects an RPCS3 process through the SDK session capability.
  final ValueChanged<int> onSelectProcess;

  /// Creates the connection guidance for [session].
  const SessionConnectionBody({
    required this.session,
    required this.onSelectProcess,
    super.key,
  });

  /// Selects the process picker or an SDK-derived session message.
  @override
  Widget build(BuildContext context) {
    if (session.selectedProcessId == null && session.processIds.length > 1) {
      return Rpcs3ProcessPicker(
        processIds: session.processIds,
        onSelectProcess: onSelectProcess,
      );
    }
    return _buildMessage(context);
  }

  /// Renders actionable guidance without inventing trainer fields.
  Widget _buildMessage(BuildContext context) {
    final theme = Theme.of(context);
    final isError =
        session.errorMessage != null ||
        session.detection?.status == GameDetectionStatus.failed;
    final message = session.errorMessage ?? _messageForState;
    return Padding(
      padding: const EdgeInsets.all(LudavaSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ConnectionDimensions.contentMaxWidth,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                color: isError
                    ? theme.colorScheme.error
                    : theme.extension<LudavaThemeTokens>()!.textMuted,
              ),
              const SizedBox(width: LudavaSpacing.md),
              Expanded(child: Text(message, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }

  /// Maps SDK detection outcomes to direct user guidance.
  String get _messageForState {
    final detection = session.detection;
    if (session.selectedProcessId == null && session.processIds.isEmpty) {
      return 'RPCS3 was not found. Start RPCS3, then select Refresh.';
    }
    return switch (detection?.status) {
      GameDetectionStatus.rpcs3NotRunning =>
        'RPCS3 was not found. Start RPCS3, then select Refresh.',
      GameDetectionStatus.noActiveGame =>
        'No active game was detected. Start a supported game in RPCS3.',
      GameDetectionStatus.unsupportedGame =>
        '${detection?.gameTitle ?? 'This game'} is not supported by Ludava.',
      GameDetectionStatus.ambiguous => _evidenceMessage(
        detection?.evidenceDescription,
        'The active game could not be verified. Select Re-detect to try again.',
      ),
      GameDetectionStatus.failed => _evidenceMessage(
        detection?.evidenceDescription,
        'Game detection failed. Select Re-detect to try again.',
      ),
      GameDetectionStatus.supportedGame when session.memoryBase == null =>
        'The game was detected, but its session memory base is unavailable.',
      GameDetectionStatus.supportedGame => 'The game session is ready.',
      GameDetectionStatus.none ||
      null => 'Connect to RPCS3 to detect the active game.',
    };
  }

  /// Uses SDK evidence when available, with [fallback] for empty evidence.
  String _evidenceMessage(String? evidence, String fallback) =>
      evidence == null || evidence.trim().isEmpty ? fallback : evidence;
}
