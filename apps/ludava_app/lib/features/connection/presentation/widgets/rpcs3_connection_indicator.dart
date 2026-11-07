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
    final connected = session.processIds.isNotEmpty;
    final status = connected ? 'Connected' : 'Disconnected';
    final message = 'RPCS3 $status';
    final color = connected ? tokens.success : tokens.textMuted;

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
              message,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
