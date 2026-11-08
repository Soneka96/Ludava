import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

/// Displays a themed informational or error message for an RPCS3 session.
class Rpcs3ConnectionGuidance extends StatelessWidget {
  /// Message selected by the connection screen for the current SDK state.
  final String message;

  /// Whether the message describes a connection or detection failure.
  final bool isError;

  /// Creates guidance without taking ownership of session state or actions.
  const Rpcs3ConnectionGuidance({
    required this.message,
    required this.isError,
    super.key,
  });

  /// Renders the message with semantic theme colors and readable constraints.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    final color = isError ? theme.colorScheme.error : tokens.textMuted;
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
                color: color,
              ),
              const SizedBox(width: LudavaSpacing.md),
              Expanded(child: Text(message, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}
