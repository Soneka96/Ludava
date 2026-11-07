import 'package:flutter/material.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';

/// Shows readable and writable field capability with text and an icon.
class TrainerFieldAccessLabel extends StatelessWidget {
  /// Whether the current profile can read this field.
  final bool canRead;

  /// Whether the current session can apply a write to this field.
  final bool canWrite;

  /// Creates a concise field-access label.
  const TrainerFieldAccessLabel({
    required this.canRead,
    required this.canWrite,
    super.key,
  });

  /// Renders capability text and a matching semantic icon.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    final color = canWrite
        ? tokens.success
        : canRead
        ? tokens.textMuted
        : tokens.textDisabled;
    final icon = canWrite
        ? Icons.edit_outlined
        : canRead
        ? Icons.visibility_outlined
        : Icons.block_outlined;
    final label = !canRead
        ? 'Not readable'
        : canWrite
        ? 'Writable'
        : 'Read-only';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: LudavaDimensions.iconSmall, color: color),
        const SizedBox(width: LudavaSpacing.xs),
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color)),
      ],
    );
  }
}
