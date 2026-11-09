import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ludava_app/injection_container.dart' show sl;
import 'package:ludava_app/features/trainer/presentation/state/trainer_fields_view_model.dart';
import 'package:ludava_app/features/trainer/presentation/state/trainer_selectors.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_row.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/state/app_state.dart';

/// Connects the SDK-driven field list to Redux with generic presentation rows.
class TrainerFieldsPanelConnector extends StatelessWidget {
  /// Creates the connected trainer field list.
  const TrainerFieldsPanelConnector({super.key});

  /// Selects one list-level view model and keeps generated rows unconnected.
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, TrainerFieldsViewModel>(
        distinct: true,
        converter: (store) => sl<TrainerFieldsViewModel>(param1: store),
        builder: (context, viewModel) {
          final state = viewModel.state;
          final session = TrainerSelectors.session(state);
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
          final fields = TrainerSelectors.fields(state);
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
              final readResult = TrainerSelectors.readResult(state, field);
              return TrainerFieldRow(
                key: ValueKey(field.id),
                field: field,
                readResult: readResult,
                currentValue: readResult?.succeeded == true
                    ? readResult?.value
                    : null,
                writeResult: TrainerSelectors.writeResult(state, field),
                canRead: TrainerSelectors.canRead(state, field),
                canWrite: TrainerSelectors.canEdit(state, field),
                isEditing: TrainerSelectors.isEditing(state, field),
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
