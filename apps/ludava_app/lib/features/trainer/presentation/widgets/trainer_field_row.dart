import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_access_label.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_value.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Presents one profile field's name, access, value, and action in a row.
class TrainerFieldRow extends StatelessWidget {
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

  /// Creates the single-row presentation of one trainer field.
  const TrainerFieldRow({
    required this.field,
    required this.readResult,
    required this.canRead,
    required this.canWrite,
    required this.isEditing,
    required this.onEdit,
    super.key,
  });

  /// Keeps field identity separate from its value and edit action.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: ValueKey('trainer-field-row-${field.id}'),
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                field.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: LudavaSpacing.xs),
              TrainerFieldAccessLabel(canRead: canRead, canWrite: canWrite),
            ],
          ),
        ),
        const SizedBox(width: LudavaSpacing.md),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: TrainerFieldValue(
                  readResult: readResult,
                  canRead: canRead,
                ),
              ),
              if (canWrite && !isEditing) ...[
                const SizedBox(width: LudavaSpacing.xs),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
