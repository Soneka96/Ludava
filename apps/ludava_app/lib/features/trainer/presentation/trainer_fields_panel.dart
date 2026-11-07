import 'package:flutter/material.dart';
import 'package:ludava_app/features/trainer/presentation/inline_value_editor.dart';
import 'package:ludava_app/shared/constants/layout_constants.dart';
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
        final compact =
            constraints.maxWidth < AppLayoutConstants.fieldCardBreakpoint;
        return ListView.separated(
          padding: const EdgeInsets.all(AppLayoutConstants.contentInset),
          itemCount: fields.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: AppLayoutConstants.fieldListGap),
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
    final canWrite = _canWrite(profile, field, readResult);
    final accessColor = canWrite ? tokens.success : tokens.textMuted;
    final writeResult = session.lastWriteResult?.fieldId == field.id
        ? session.lastWriteResult
        : null;
    final isEditing =
        editingFieldId == field.id &&
        _hasWriteTarget(profile, field) &&
        (readResult?.succeeded == true || writeResult != null);
    return Container(
      key: ValueKey('trainer-field-${compact ? 'row' : 'card'}-${field.id}'),
      padding: compact
          ? const EdgeInsets.symmetric(
              vertical: AppLayoutConstants.fieldRowVerticalInset,
            )
          : const EdgeInsets.all(AppLayoutConstants.fieldCardInset),
      decoration: BoxDecoration(
        color: compact ? null : tokens.surfaceRaised,
        border: Border.all(color: tokens.outlineSubtle),
        borderRadius: BorderRadius.circular(
          AppLayoutConstants.smallCornerRadius,
        ),
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
            const SizedBox(height: AppLayoutConstants.headerTitleGap),
            Text(
              _accessLabel(canRead, canWrite),
              style: theme.textTheme.bodySmall?.copyWith(color: accessColor),
            ),
          ],
        ),
      ),
      const SizedBox(width: AppLayoutConstants.headerItemGap),
      Expanded(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(child: _buildValue(theme, tokens, readResult, canRead)),
            if (canWrite && !isEditing) ...[
              const SizedBox(width: AppLayoutConstants.headerTitleGap),
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
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Icon(
            Icons.tune_rounded,
            size: AppLayoutConstants.fieldIconSize,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: AppLayoutConstants.headerItemGap),
          Expanded(
            child: Text(
              field.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: AppLayoutConstants.headerItemGap),
          Text(
            _accessLabel(canRead, canWrite),
            style: theme.textTheme.labelMedium?.copyWith(color: accessColor),
          ),
        ],
      ),
      const SizedBox(height: AppLayoutConstants.fieldListGap),
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
              const SizedBox(height: AppLayoutConstants.headerTitleGap),
            ],
          ),
          const SizedBox(width: AppLayoutConstants.headerItemGap),
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
                  const SizedBox(width: AppLayoutConstants.headerTitleGap),
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
        _formatValue(value),
        style:
            (card ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge)
                ?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
      ),
    );
  }

  /// Reports write access only for an approved current session and valid value.
  bool _canWrite(
    GameProfile profile,
    GameField field,
    GameReadResult? readResult,
  ) => _hasWriteTarget(profile, field) && readResult?.succeeded == true;

  /// Reports the SDK's current profile, field, range, and session permissions.
  bool _hasWriteTarget(GameProfile profile, GameField field) =>
      profile.canWrite &&
      field.canWrite &&
      profile.canRead &&
      field.canRead &&
      field.minimumValue != null &&
      field.maximumValue != null &&
      session.selectedProcessId != null &&
      session.memoryBase != null &&
      session.detection?.confidence == GameIdentityConfidence.confirmed;

  /// Returns the profile-derived read/write availability label.
  String _accessLabel(bool canRead, bool canWrite) {
    if (!canRead) return 'Not readable';
    return canWrite ? 'Writable' : 'Read-only';
  }

  /// Groups [value] for display without changing its integer value.
  String _formatValue(int value) {
    final digits = value.toString();
    final formatted = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write(',');
      }
      formatted.write(digits[index]);
    }
    return formatted.toString();
  }
}
