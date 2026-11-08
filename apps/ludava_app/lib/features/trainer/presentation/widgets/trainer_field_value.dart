import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_value_formatter.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Renders a field's current value or an explicit unavailable state.
class TrainerFieldValue extends StatelessWidget {
  /// Latest SDK read result for this profile field.
  final GameReadResult? readResult;

  /// Whether the profile permits reading this field.
  final bool canRead;

  /// Creates a current value label for one profile row.
  const TrainerFieldValue({
    required this.readResult,
    required this.canRead,
    super.key,
  });

  /// Fits large integer values without altering their exact representation.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    final value = readResult?.succeeded == true ? readResult?.value : null;
    if (!canRead || value == null) {
      final failed = readResult?.status == GameReadStatus.readFailed;
      return Text(
        failed ? 'Read failed' : 'Unavailable',
        textAlign: TextAlign.right,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: failed ? theme.colorScheme.error : tokens.textMuted,
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        TrainerValueFormatter.format(value),
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 14,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
