import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_value.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Presents one profile field's name, current value, and conditional edit action.
class TrainerFieldRow extends StatelessWidget {
  /// Profile metadata for the current field.
  final GameField field;

  /// Latest SDK read result for the field.
  final GameReadResult? readResult;

  /// Whether the profile permits reading this field.
  final bool canRead;

  /// Whether the current session can apply a write.
  final bool canWrite;

  /// Whether the inline editor is already open for this field.
  final bool isEditing;

  /// Opens the inline editor after presentation eligibility is checked.
  final VoidCallback onEdit;

  /// Creates one fixed-height horizontal row for a trainer field.
  const TrainerFieldRow({
    required this.field,
    required this.readResult,
    required this.canRead,
    required this.canWrite,
    required this.isEditing,
    required this.onEdit,
    super.key,
  });

  /// Keeps the field name, value, and Edit action on one horizontal line.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: LudavaDimensions.minimumInteractiveTarget,
      child: Row(
        key: ValueKey('trainer-field-row-${field.id}'),
        children: [
          Expanded(
            flex: 4,
            child: Tooltip(
              message: field.name,
              child: Text(
                field.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          const SizedBox(width: LudavaSpacing.sm),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: TrainerFieldValue(
                readResult: readResult,
                canRead: canRead,
              ),
            ),
          ),
          if (canWrite && !isEditing)
            SizedBox(
              width: LudavaDimensions.minimumInteractiveTarget,
              height: LudavaDimensions.minimumInteractiveTarget,
              child: IconButton(
                tooltip: 'Edit ${field.name}',
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
        ],
      ),
    );
  }
}
