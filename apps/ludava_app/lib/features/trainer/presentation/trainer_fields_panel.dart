import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_field_availability.dart';
import 'package:ludava_app/features/trainer/presentation/inline_value_editor.dart';
import 'package:ludava_app/features/trainer/presentation/trainer_value_formatter.dart';
import 'package:ludava_app/shared/layout/ludava_breakpoints.dart';
import 'package:ludava_app/shared/layout/ludava_dimensions.dart';
import 'package:ludava_app/shared/layout/ludava_spacing.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Renders the current profile's fields as adaptive cards or compact rows.
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
        return ListView.separated(
          padding: const EdgeInsets.all(LudavaSpacing.xl),
          itemCount: fields.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: LudavaSpacing.md),
          itemBuilder: (context, index) =>
              _buildField(context, profile, fields[index], compact: compact),
        );
      },
    );
  }

  /// Builds one field from its profile metadata and latest SDK read result.
  Widget _buildField(
    BuildContext context,
    GameProfile profile,
    GameField field, {
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    final readResult = session.readResults[field.id];
    final canRead = profile.canRead && field.canRead;
    final canWrite = TrainerFieldAvailability.canEdit(session, field);
    final accessColor = canWrite ? tokens.success : tokens.textMuted;
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
          compact
              ? _buildCompactRow(
                  theme,
                  tokens,
                  field,
                  readResult,
                  canRead,
                  canWrite,
                  accessColor,
                  isEditing,
                )
              : _buildCard(
                  theme,
                  tokens,
                  field,
                  readResult,
                  canRead,
                  canWrite,
                  accessColor,
                  isEditing,
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

  /// Arranges the field name, access state, and value in a narrow row.
  Widget _buildCompactRow(
    ThemeData theme,
    LudavaThemeTokens tokens,
    GameField field,
    GameReadResult? readResult,
    bool canRead,
    bool canWrite,
    Color accessColor,
    bool isEditing,
  ) => Row(
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
            Text(
              _accessLabel(canRead, canWrite),
              style: theme.textTheme.bodySmall?.copyWith(color: accessColor),
            ),
          ],
        ),
      ),
      const SizedBox(width: LudavaSpacing.md),
      Expanded(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(child: _buildValue(theme, tokens, readResult, canRead)),
            if (canWrite && !isEditing) ...[
              const SizedBox(width: LudavaSpacing.xs),
              TextButton(
                onPressed: () => onEditField(field),
                child: const Text('Edit'),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  /// Arranges metadata and a proportional value in a content-height card.
  Widget _buildCard(
    ThemeData theme,
    LudavaThemeTokens tokens,
    GameField field,
    GameReadResult? readResult,
    bool canRead,
    bool canWrite,
    Color accessColor,
    bool isEditing,
  ) => Column(
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
          const SizedBox(width: LudavaSpacing.md),
          Text(
            _accessLabel(canRead, canWrite),
            style: theme.textTheme.labelMedium?.copyWith(color: accessColor),
          ),
        ],
      ),
      const SizedBox(height: LudavaSpacing.md),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current value',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textMuted,
                ),
              ),
              const SizedBox(height: LudavaSpacing.xs),
            ],
          ),
          const SizedBox(width: LudavaSpacing.md),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: _buildValue(
                    theme,
                    tokens,
                    readResult,
                    canRead,
                    card: true,
                  ),
                ),
                if (canWrite && !isEditing) ...[
                  const SizedBox(width: LudavaSpacing.xs),
                  TextButton.icon(
                    onPressed: () => onEditField(field),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ],
  );

  /// Displays a grouped integer or a clear unavailable/read-failed state.
  Widget _buildValue(
    ThemeData theme,
    LudavaThemeTokens tokens,
    GameReadResult? readResult,
    bool canRead, {
    bool card = false,
  }) {
    final value = readResult?.succeeded == true ? readResult?.value : null;
    if (!canRead || value == null) {
      final failed = readResult?.status == GameReadStatus.readFailed;
      return Text(
        failed ? 'Read failed' : 'Unavailable',
        textAlign: TextAlign.right,
        style: (card ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)
            ?.copyWith(
              color: failed ? theme.colorScheme.error : tokens.textMuted,
            ),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        TrainerValueFormatter.format(value),
        style:
            (card ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge)
                ?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
      ),
    );
  }

  /// Returns the profile-derived read/write availability label.
  String _accessLabel(bool canRead, bool canWrite) {
    if (!canRead) return 'Not readable';
    return canWrite ? 'Writable' : 'Read-only';
  }
}
