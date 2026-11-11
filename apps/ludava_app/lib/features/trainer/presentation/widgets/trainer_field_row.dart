import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/inline_value_editor.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_value.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Presents one profile field's name, current value, and conditional edit action.
class TrainerFieldRow extends StatelessWidget {
  /// Profile metadata for the current field.
  final GameField field;

  /// Latest SDK read result for the field.
  final GameReadResult? readResult;

  /// Current SDK value provided to the editor when the field is being edited.
  final int? currentValue;

  /// Latest SDK write outcome for this field, if one has been attempted.
  final GameWriteResult? writeResult;

  /// Whether the inline editor is already open for this field.
  final bool isEditing;

  /// Opens the inline editor for an exact successful numeric read.
  final VoidCallback onEdit;

  /// Delegates an explicit edit submission to the trainer controller.
  final GameWriteResult Function(int value) onApply;

  /// Leaves edit mode without writing the draft.
  final VoidCallback onCancel;

  /// Leaves edit mode after the SDK verifies a matching read-back.
  final VoidCallback onApplied;

  /// Creates one fixed-height horizontal row for a trainer field.
  const TrainerFieldRow({
    required this.field,
    required this.readResult,
    required this.currentValue,
    required this.writeResult,
    required this.isEditing,
    required this.onEdit,
    required this.onApply,
    required this.onCancel,
    required this.onApplied,
    super.key,
  });

  /// Keeps the field name, value, and Edit action on one horizontal line.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      key: ValueKey('trainer-field-row-${field.id}'),
      height: LudavaDimensions.minimumInteractiveTarget,
      child: Row(
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
            child: isEditing
                ? InlineValueEditor(
                    field: field,
                    currentValue: currentValue,
                    writeResult: writeResult,
                    onApply: onApply,
                    onCancel: onCancel,
                    onApplied: onApplied,
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TrainerFieldValue(
                            fieldId: field.id,
                            readResult: readResult,
                          ),
                        ),
                      ),
                      if (_hasReadableValue)
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
          ),
        ],
      ),
    );
  }

  /// Reports whether this row has an exact successful numeric read.
  bool get _hasReadableValue =>
      readResult?.fieldId == field.id &&
      readResult?.succeeded == true &&
      readResult?.value != null;
}
