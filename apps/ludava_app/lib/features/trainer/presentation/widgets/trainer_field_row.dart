import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_access_label.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_value.dart';
import 'package:ludava_app/shared/layout/ludava_spacing.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Presents the same field facts as a compact, single-line row.
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

  /// Creates the compact row presentation of one trainer field.
  const TrainerFieldRow({
    required this.field,
    required this.readResult,
    required this.canRead,
    required this.canWrite,
    required this.isEditing,
    required this.onEdit,
    super.key,
  });

  /// Renders the field name, permission, value, and action at narrow widths.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: ValueKey('trainer-field-row-${field.id}'),
      children: [
        Expanded(
          flex: 3,
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
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: TrainerFieldValue(
                  readResult: readResult,
                  canRead: canRead,
                  prominent: false,
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
