import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_fields_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_row.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/state/app_state.dart';

/// Renders the Redux-driven profile fields as a scrollable vertical list.
class TrainerFieldsPanel extends StatelessWidget {
  /// Creates the connected trainer fields panel.
  const TrainerFieldsPanel({super.key});

  /// Connects one field list while leaving generic rows independent of Redux.
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, TrainerFieldsViewModel>(
        distinct: true,
        converter: (store) => sl<TrainerFieldsViewModel>(param1: store),
        builder: (context, viewModel) {
          if (!viewModel.hasProfile) return const SizedBox.shrink();
          if (viewModel.fields.isEmpty) {
            return Center(
              child: Text(
                'No trainer fields are available for this profile.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          final fields = viewModel.fields;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: LudavaSpacing.lg,
              vertical: LudavaSpacing.md,
            ),
            itemCount: fields.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: LudavaSpacing.sm),
            itemBuilder: (context, index) {
              final row = fields[index];
              final field = row.field;
              final readResult = row.readResult;
              return TrainerFieldRow(
                key: ValueKey(field.id),
                field: field,
                readResult: readResult,
                currentValue: readResult?.succeeded == true
                    ? readResult?.value
                    : null,
                writeResult: row.writeResult,
                canWrite: row.canWrite,
                isEditing: row.isEditing,
                onEdit: () => viewModel.onEditField(field.id),
                onApply: (value) => viewModel.onApplyField(field.id, value),
                onCancel: viewModel.onCancelEditing,
                onApplied: viewModel.onCancelEditing,
              );
            },
          );
        },
      );
}
