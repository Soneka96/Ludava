import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_access_label.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_value.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Presents one profile field with a clear name, value, capability, and action.
class TrainerFieldCard extends StatelessWidget {
  /// Profile metadata for the current field.
  final GameField field;

  /// Latest SDK read result for the field.
  final GameReadResult? readResult;

  /// Whether the profile permits reading this field.
  final bool canRead;

  /// Whether the current session can apply a write.
  final bool canWrite;

  /// Whether the inline editor is already open.
  final bool isEditing;

  /// Opens the inline editor after presentation eligibility is checked.
  final VoidCallback onEdit;

  /// Creates the wider card presentation of one trainer field.
  const TrainerFieldCard({
    required this.field,
    required this.readResult,
    required this.canRead,
    required this.canWrite,
    required this.isEditing,
    required this.onEdit,
    super.key,
  });

  /// Renders the field name first, then value, capability, and edit action.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: ValueKey('trainer-field-card-${field.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: LudavaDimensions.iconMedium,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: LudavaSpacing.md),
            Expanded(
              child: Text(
                field.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: LudavaSpacing.md),
        Text(
          'Current value',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: LudavaSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: TrainerFieldValue(
            readResult: readResult,
            canRead: canRead,
            prominent: true,
          ),
        ),
        const SizedBox(height: LudavaSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TrainerFieldAccessLabel(canRead: canRead, canWrite: canWrite),
            if (canWrite && !isEditing)
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
          ],
        ),
      ],
    );
  }
}
