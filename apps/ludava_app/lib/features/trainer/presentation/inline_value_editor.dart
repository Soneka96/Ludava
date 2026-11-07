import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludava_app/shared/constants/layout_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Edits one unsigned field value inline and applies only an explicit request.
class InlineValueEditor extends StatefulWidget {
  /// Field metadata used for validation and the user-visible field name.
  final GameField field;

  /// Latest valid value from the SDK, or `null` when the read failed.
  final int? currentValue;

  /// Latest SDK write result for this field, when a write has been attempted.
  final GameWriteResult? writeResult;

  /// Performs the SDK's guarded write for a validated integer value.
  final GameWriteResult Function(int value) onApply;

  /// Discards the draft and closes the inline editor.
  final VoidCallback onCancel;

  /// Creates an inline editor for the current valid SDK value.
  const InlineValueEditor({
    required this.field,
    required this.currentValue,
    required this.writeResult,
    required this.onApply,
    required this.onCancel,
    super.key,
  });

  /// Creates editor state for the local unsaved draft and feedback.
  @override
  State<InlineValueEditor> createState() => _InlineValueEditorState();
}

class _InlineValueEditorState extends State<InlineValueEditor> {
  late final TextEditingController _textController;
  late final FocusNode _inputFocusNode;
  String? _feedback;
  bool _feedbackIsSuccess = false;

  /// Populates the draft from the current SDK value without writing.
  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.currentValue?.toString() ?? '',
    );
    _inputFocusNode = FocusNode(debugLabel: 'Ludava numeric value');
  }

  /// Resets drafts on new values and reports new SDK write outcomes.
  @override
  void didUpdateWidget(covariant InlineValueEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final writeResultChanged = !_sameWriteResult(
      oldWidget.writeResult,
      widget.writeResult,
    );
    if (writeResultChanged) {
      final result = widget.writeResult;
      if (result?.fieldId == widget.field.id) {
        _showWriteResult(result!);
      }
      return;
    }
    if (oldWidget.field.id != widget.field.id ||
        oldWidget.currentValue != widget.currentValue) {
      _textController.text = widget.currentValue?.toString() ?? '';
      _feedback = null;
      _feedbackIsSuccess = false;
    }
  }

  /// Releases the input controller owned by this editor.
  @override
  void dispose() {
    _textController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// Renders the current value, numeric draft, validation, and explicit actions.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    final validationMessage = _validationMessage;
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Container(
        margin: const EdgeInsets.only(top: AppLayoutConstants.fieldListGap),
        padding: const EdgeInsets.all(AppLayoutConstants.fieldCardInset),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.borderSubtle),
          borderRadius: BorderRadius.circular(
            AppLayoutConstants.smallCornerRadius,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit ${widget.field.name}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppLayoutConstants.headerTitleGap),
            Text(
              'Current value: ${_formatValue(widget.currentValue)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textMuted,
              ),
            ),
            const SizedBox(height: AppLayoutConstants.headerItemGap),
            TextField(
              key: ValueKey('inline-editor-input-${widget.field.id}'),
              controller: _textController,
              focusNode: _inputFocusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'New ${widget.field.name}',
                helperText: _rangeDescription,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: tokens.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: tokens.focus),
                ),
              ),
              onChanged: (_) => setState(() {
                _feedback = null;
                _feedbackIsSuccess = false;
              }),
              onSubmitted: (_) => _apply(),
            ),
            if (validationMessage != null) ...[
              const SizedBox(height: AppLayoutConstants.headerTitleGap),
              Text(
                validationMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (_feedback case final message?) ...[
              const SizedBox(height: AppLayoutConstants.headerTitleGap),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _feedbackIsSuccess
                      ? tokens.success
                      : theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppLayoutConstants.headerItemGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppLayoutConstants.headerItemGap),
                FilledButton(
                  onPressed: validationMessage == null ? _apply : null,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the value draft error, if it is empty, malformed, or out of range.
  String? get _validationMessage {
    final minimum = widget.field.minimumValue;
    final maximum = widget.field.maximumValue;
    if (widget.currentValue == null) {
      return 'The current value is unavailable. Refresh before editing.';
    }
    if (minimum == null || maximum == null) {
      return 'This field has no approved value range.';
    }
    final draft = _textController.text;
    if (draft.isEmpty) return 'Enter a whole number.';
    final value = int.tryParse(draft);
    if (value == null) return 'Enter a whole number.';
    if (value < minimum || value > maximum) {
      return 'Enter a value from ${_formatValue(minimum)} to ${_formatValue(maximum)}.';
    }
    return null;
  }

  /// Describes the profile's inclusive range in the editor helper text.
  String get _rangeDescription {
    final minimum = widget.field.minimumValue;
    final maximum = widget.field.maximumValue;
    if (minimum == null || maximum == null) {
      return 'No approved value range is available.';
    }
    return 'Allowed: ${_formatValue(minimum)}–${_formatValue(maximum)}';
  }

  /// Applies a valid draft only after the user selects Apply or presses Enter.
  void _apply() {
    final validationMessage = _validationMessage;
    if (validationMessage != null) {
      setState(() {
        _feedback = validationMessage;
        _feedbackIsSuccess = false;
      });
      return;
    }
    final value = int.tryParse(_textController.text);
    if (value == null) return;
    final result = widget.onApply(value);
    setState(() => _showWriteResult(result));
  }

  /// Updates feedback from an SDK result, using read-back data for success.
  void _showWriteResult(GameWriteResult result) {
    _feedback = _writeMessage(result);
    _feedbackIsSuccess = result.succeeded;
    if (result.succeeded) {
      _textController.text = result.readBackValue!.toString();
    }
  }

  /// Returns a user-facing explanation of the typed SDK write result.
  String _writeMessage(GameWriteResult result) {
    if (result.succeeded) {
      return 'Applied and verified: ${_formatValue(result.readBackValue)}';
    }
    return switch (result.status) {
      GameWriteStatus.none => 'No value was written.',
      GameWriteStatus.unsupportedProfile => 'This profile is read-only.',
      GameWriteStatus.confirmationRequired => 'The write was not authorized.',
      GameWriteStatus.unsupportedField => 'This field is read-only.',
      GameWriteStatus.invalidValue => 'The value is outside the allowed range.',
      GameWriteStatus.invalidMapping => 'The field mapping is unavailable.',
      GameWriteStatus.preliminaryReadFailed =>
        'The current value could not be checked. No write was made.',
      GameWriteStatus.writeFailed =>
        result.errorCode == null
            ? 'The write failed.'
            : 'The write failed with system error ${result.errorCode}.',
      GameWriteStatus.incompleteWrite => 'The write was incomplete.',
      GameWriteStatus.readBackFailed =>
        'The written value could not be verified.',
      GameWriteStatus.readBackMismatch =>
        'The written value did not match the verified value.',
      GameWriteStatus.invalidWriteResult =>
        'The SDK returned an invalid write result.',
      GameWriteStatus.success => 'The written value could not be verified.',
    };
  }

  /// Applies on Enter and cancels the inline edit on Escape.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onCancel();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          _inputFocusNode.hasFocus) {
        _apply();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Reports whether [first] and [second] describe the same write result.
  bool _sameWriteResult(GameWriteResult? first, GameWriteResult? second) =>
      identical(first, second) ||
      (first != null &&
          second != null &&
          first.status == second.status &&
          first.fieldId == second.fieldId &&
          first.requestedValue == second.requestedValue &&
          first.readBackValue == second.readBackValue &&
          first.errorCode == second.errorCode);

  /// Formats a verified or bounded value without converting it to a double.
  String _formatValue(int? value) {
    if (value == null) return 'Unavailable';
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
