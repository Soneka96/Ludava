import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_field_availability.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/inline_value_editor.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_card.dart';
import 'package:ludava_app/features/trainer/presentation/widgets/trainer_field_row.dart';
import 'package:ludava_app/shared/layout/ludava_breakpoints.dart';
import 'package:ludava_app/shared/layout/ludava_dimensions.dart';
import 'package:ludava_app/shared/layout/ludava_spacing.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Renders the current profile's fields as adaptive cards or compact rows.
class TrainerFieldsPanel extends StatelessWidget {
  /// Minimum width that keeps the card hierarchy comfortably readable.
  static const double _minimumCardWidth = 320;

  /// Maximum width that prevents a single card from stretching across the app.
  static const double _maximumCardWidth = 420;

  /// Caps the panel at four columns even when embedded in a wider surface.
  static const int _maximumCardsPerRow = 4;

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

  /// Switches the field arrangement at the shared desktop breakpoint.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < LudavaBreakpoints.fieldCards;
        final availableWidth = constraints.maxWidth - 2 * LudavaSpacing.xl;
        final cardCount =
            ((availableWidth + LudavaSpacing.md) /
                    (_minimumCardWidth + LudavaSpacing.md))
                .floor()
                .clamp(1, _maximumCardsPerRow);
        final cardWidth =
            ((availableWidth - LudavaSpacing.md * (cardCount - 1)) / cardCount)
                .clamp(_minimumCardWidth, _maximumCardWidth)
                .toDouble();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(LudavaSpacing.xl),
          child: Wrap(
            spacing: LudavaSpacing.md,
            runSpacing: LudavaSpacing.md,
            children: [
              for (final field in fields)
                SizedBox(
                  width: compact ? availableWidth : cardWidth,
                  child: _buildField(context, profile, field, compact: compact),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Composes one profile field with its current read and editing state.
  Widget _buildField(
    BuildContext context,
    GameProfile profile,
    GameField field, {
    required bool compact,
  }) {
    final tokens = Theme.of(context).extension<LudavaThemeTokens>()!;
    final readResult = session.readResults[field.id];
    final canRead = profile.canRead && field.canRead;
    final canWrite = TrainerFieldAvailability.canEdit(session, field);
    final writeResult = session.lastWriteResult?.fieldId == field.id
        ? session.lastWriteResult
        : null;
    final isEditing =
        editingFieldId == field.id &&
        TrainerFieldAvailability.hasWriteTarget(session, field);

    return Container(
      key: ValueKey('trainer-field-${field.id}'),
      padding: compact
          ? const EdgeInsets.symmetric(vertical: LudavaSpacing.md)
          : const EdgeInsets.all(LudavaSpacing.lg),
      decoration: BoxDecoration(
        color: compact ? null : tokens.surfaceElevated,
        border: Border.all(color: tokens.borderSubtle),
        borderRadius: BorderRadius.circular(LudavaDimensions.smallCornerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (compact)
            TrainerFieldRow(
              field: field,
              readResult: readResult,
              canRead: canRead,
              canWrite: canWrite,
              isEditing: isEditing,
              onEdit: () => onEditField(field),
            )
          else
            TrainerFieldCard(
              field: field,
              readResult: readResult,
              canRead: canRead,
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
      ),
    );
  }
}
