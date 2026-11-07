import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_field_availability.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/inline_value_editor.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_row.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Renders the current profile's fields as a scrollable vertical list.
class TrainerFieldsPanel extends StatelessWidget {
  /// Latest immutable state published by the trainer SDK.
  final TrainerSessionState session;

  /// Field currently being edited inline, if any.
  final String? editingFieldId;

  /// Opens the editor for a writable field.
  final ValueChanged<GameField> onEditField;

  /// Invokes the SDK guarded write after an explicit editor action.
  final GameWriteResult Function(String fieldId, int value) onApplyField;

  /// Discards the inline editor draft.
  final VoidCallback onCancelEditing;

  /// Creates field presentations and routes editing actions to the app owner.
  const TrainerFieldsPanel({
    required this.session,
    required this.editingFieldId,
    required this.onEditField,
    required this.onApplyField,
    required this.onCancelEditing,
    super.key,
  });

  /// Displays each SDK field in its own vertically arranged row.
  @override
  Widget build(BuildContext context) {
    final profile = session.profile;
    if (profile == null) return const SizedBox.shrink();
    if (profile.fields.isEmpty) {
      return Center(
        child: Text(
          'No trainer fields are available for this profile.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    final fields = profile.fields.values.toList(growable: false);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: LudavaSpacing.lg,
        vertical: LudavaSpacing.md,
      ),
      itemCount: fields.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: LudavaSpacing.sm),
      itemBuilder: (context, index) {
        final field = fields[index];
        final readResult = session.readResults[field.id];
        final canWrite = TrainerFieldAvailability.canEdit(session, field);
        final writeResult = session.lastWriteResult?.fieldId == field.id
            ? session.lastWriteResult
            : null;
        final isEditing =
            editingFieldId == field.id &&
            TrainerFieldAvailability.hasWriteTarget(session, field);

        return Column(
          key: ValueKey('trainer-field-${field.id}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TrainerFieldRow(
              field: field,
              readResult: readResult,
              canRead: profile.canRead && field.canRead,
              canWrite: canWrite,
              isEditing: isEditing,
              onEdit: () => onEditField(field),
            ),
            if (isEditing)
              InlineValueEditor(
                field: field,
                currentValue: readResult?.succeeded == true
                    ? readResult?.value
                    : null,
                writeResult: writeResult,
                onApply: (value) => onApplyField(field.id, value),
                onCancel: onCancelEditing,
              ),
          ],
        );
      },
    );
  }
}
