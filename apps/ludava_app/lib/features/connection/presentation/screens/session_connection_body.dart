import 'package:flutter/material.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_connection_guidance.dart';
import 'package:ludava_app/features/connection/presentation/widgets/rpcs3_process_picker.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Shows process choice or concise guidance for the latest session state.
class SessionConnectionBody extends StatelessWidget {
  /// Process IDs available for explicit selection.
  final List<int> processIds;

  /// Currently selected RPCS3 process ID.
  final int? selectedProcessId;

  /// Current SDK detection result.
  final GameDetectionResult? detection;

  /// Whether the current session has a usable guest memory base.
  final bool hasMemoryBase;

  /// Current session error, when one is available.
  final String? errorMessage;

  /// Selects an RPCS3 process through the SDK session capability.
  final ValueChanged<int> onSelectProcess;

  /// Creates connection guidance from selected SDK presentation values.
  const SessionConnectionBody({
    required this.processIds,
    required this.selectedProcessId,
    required this.detection,
    required this.hasMemoryBase,
    required this.errorMessage,
    required this.onSelectProcess,
    super.key,
  });

  /// Selects the process picker or an SDK-derived session message.
  @override
  Widget build(BuildContext context) {
    if (selectedProcessId == null && processIds.length > 1) {
      return Rpcs3ProcessPicker(
        processIds: processIds,
        onSelectProcess: onSelectProcess,
      );
    }
    return Rpcs3ConnectionGuidance(
      message: errorMessage ?? _messageForState,
      isError:
          errorMessage != null ||
          detection?.status == GameDetectionStatus.failed,
    );
  }

  /// Maps SDK detection outcomes to direct user guidance.
  String get _messageForState {
    if (selectedProcessId == null && processIds.isEmpty) {
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
        'The active game could not be verified. Select Refresh to try again.',
      ),
      GameDetectionStatus.failed => _evidenceMessage(
        detection?.evidenceDescription,
        'Game detection failed. Select Refresh to try again.',
      ),
      GameDetectionStatus.supportedGame when !hasMemoryBase =>
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
