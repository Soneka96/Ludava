import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Displays basic RPCS3 process availability separately from game readiness.
class Rpcs3ConnectionIndicator extends StatelessWidget {
  /// Small diameter keeps the connection mark secondary to its label.
  static const double _dotSize = 8;

  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Creates a title-bar connection indicator from the SDK snapshot.
  const Rpcs3ConnectionIndicator({required this.session, super.key});

  /// Renders connection text and its semantic status color.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    final message = _tooltipMessage;
    final color = _statusColor(tokens);

    return Tooltip(
      message: message,
      child: Semantics(
        label: message,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle_rounded, size: _dotSize, color: color),
            const SizedBox(width: LudavaSpacing.sm),
            Text(
              'RPCS3',
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  /// Reports whether the selected process is still in the discovery snapshot.
  bool get _hasSelectedProcess =>
      session.selectedProcessId != null &&
      session.processIds.contains(session.selectedProcessId);

  /// Describes absence, pending selection, or the selected process accurately.
  String get _tooltipMessage {
    if (session.processIds.isEmpty) return 'RPCS3 not detected';
    if (_hasSelectedProcess) {
      return 'RPCS3 connected · process ${session.selectedProcessId}';
    }
    return session.processIds.length == 1
        ? 'RPCS3 detected · awaiting process selection'
        : 'RPCS3 detected · select one of ${session.processIds.length} processes';
  }

  /// Maps discovery state to its semantic status color.
  Color _statusColor(LudavaThemeTokens tokens) {
    if (_hasSelectedProcess) return tokens.success;
    if (session.processIds.isNotEmpty) return tokens.warning;
    return tokens.textMuted;
  }
}
