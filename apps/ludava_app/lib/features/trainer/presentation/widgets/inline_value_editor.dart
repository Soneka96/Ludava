import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludava_app/shared/constants/ludava_constants.dart';
import 'package:ludava_app/shared/theme/ludava_theme_tokens.dart';
import 'package:ludava_sdk/ludava_sdk.dart';

/// Edits one unsigned field value in-place and applies only explicit requests.
class InlineValueEditor extends StatefulWidget {
  /// Field metadata used to identify the registered write target.
  final GameField field;

  /// Latest SDK value when available, or `null` if the read is unavailable.
  final int? currentValue;

  /// Latest SDK write result for this field, when a write was attempted.
  final GameWriteResult? writeResult;

  /// Delegates the explicit write request to the SDK owner.
  final GameWriteResult Function(int value) onApply;

  /// Leaves edit mode without submitting the draft.
  final VoidCallback onCancel;

  /// Leaves edit mode after the SDK confirms a matching read-back.
  final VoidCallback onApplied;

  /// Creates inline edit controls for the current field value.
  const InlineValueEditor({
    required this.field,
    required this.currentValue,
    required this.writeResult,
    required this.onApply,
    required this.onCancel,
    required this.onApplied,
    super.key,
  });

  /// Creates state for the local draft and fixed-size validation feedback.
  @override
  State<InlineValueEditor> createState() => _InlineValueEditorState();
}

class _InlineValueEditorState extends State<InlineValueEditor> {
  late final TextEditingController _textController;
  late final FocusNode _inputFocusNode;
  late int? _startingValue;
  String? _feedback;
  bool _submissionInProgress = false;
  bool _actionPendingThisFrame = false;

  /// Initializes the draft from the latest SDK value without writing.
  @override
  void initState() {
    super.initState();
    _startingValue = widget.currentValue;
    final initialText = widget.currentValue?.toString() ?? '';
    _textController = TextEditingController.fromValue(
      TextEditingValue(
        text: initialText,
        selection: TextSelection.collapsed(offset: initialText.length),
      ),
    );
    _inputFocusNode = FocusNode(debugLabel: 'Ludava numeric value');
    _inputFocusNode.addListener(_placeCaretAtEndOnInitialFocus);
  }

  /// Preserves changed drafts across reads and shows SDK write failures.
  @override
  void didUpdateWidget(covariant InlineValueEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameFieldMapping(oldWidget.field, widget.field)) {
      _startingValue = widget.currentValue;
      final newText = widget.currentValue?.toString() ?? '';
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      _feedback = null;
    }
    if (!_sameWriteResult(oldWidget.writeResult, widget.writeResult)) {
      final result = widget.writeResult;
      if (result?.fieldId == widget.field.id && !result!.succeeded) {
        _feedback = _writeFailureMessage(result);
      }
    }
  }

  /// Releases the input controller and focus node owned by this editor.
  @override
  void dispose() {
    _inputFocusNode.removeListener(_placeCaretAtEndOnInitialFocus);
    _textController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// Renders the draft and fixed-size Apply and Cancel icon controls.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<LudavaThemeTokens>()!;
    final hasFeedback = _feedback != null;
    final decorationTheme = theme.inputDecorationTheme;
    final normalBorder =
        decorationTheme.enabledBorder ??
        decorationTheme.border ??
        OutlineInputBorder(borderSide: BorderSide(color: tokens.borderDefault));
    final feedbackBorder =
        decorationTheme.errorBorder ??
        normalBorder.copyWith(
          borderSide: BorderSide(color: theme.colorScheme.error),
        );
    final focusedBorder = hasFeedback
        ? decorationTheme.focusedErrorBorder ?? feedbackBorder
        : decorationTheme.focusedBorder ??
              normalBorder.copyWith(
                borderSide: BorderSide(color: tokens.focus),
              );
    final input = SizedBox(
      height: LudavaDimensions.minimumInteractiveTarget,
      child: TextField(
        key: ValueKey('inline-editor-input-${widget.field.id}'),
        controller: _textController,
        focusNode: _inputFocusNode,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: _handleTextChanged,
        onSubmitted: (_) => _submit(),
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Value',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LudavaSpacing.sm,
            vertical: LudavaSpacing.xs,
          ),
          border: normalBorder,
          enabledBorder: hasFeedback ? feedbackBorder : normalBorder,
          focusedBorder: focusedBorder,
          errorBorder: feedbackBorder,
          focusedErrorBorder: focusedBorder,
        ),
      ),
    );

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Row(
        children: [
          Expanded(
            child: Tooltip(message: _feedback ?? '', child: input),
          ),
          SizedBox(
            width: LudavaDimensions.minimumInteractiveTarget,
            height: LudavaDimensions.minimumInteractiveTarget,
            child: IconButton(
              tooltip: 'Apply ${widget.field.name}',
              onPressed: _submit,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.check_rounded),
            ),
          ),
          SizedBox(
            width: LudavaDimensions.minimumInteractiveTarget,
            height: LudavaDimensions.minimumInteractiveTarget,
            child: IconButton(
              tooltip: 'Cancel editing ${widget.field.name}',
              onPressed: widget.onCancel,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the current presentation-oriented input validation error.
  String? get _validationMessage {
    final draft = _textController.text;
    if (draft.isEmpty) return 'Enter a whole number.';
    final value = int.tryParse(draft);
    if (value == null) return 'Enter a whole number.';
    return null;
  }

  /// Clears stale failure feedback when the draft changes.
  void _handleTextChanged(String value) {
    if (_feedback == null) return;
    setState(() => _feedback = null);
  }

  /// Routes button and keyboard submissions through one same-frame guard.
  void _submit() {
    if (_actionPendingThisFrame || _submissionInProgress) return;
    _actionPendingThisFrame = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actionPendingThisFrame = false;
    });
    _apply();
  }

  /// Applies a valid draft or shows fixed-size error feedback through a tooltip.
  void _apply() {
    if (_submissionInProgress) return;
    final validationMessage = _validationMessage;
    if (validationMessage != null) {
      setState(() => _feedback = validationMessage);
      return;
    }
    final value = int.tryParse(_textController.text);
    if (value == null) return;

    if (value == _startingValue) {
      widget.onApplied();
      return;
    }

    _submissionInProgress = true;
    late final GameWriteResult result;
    try {
      result = widget.onApply(value);
    } catch (error) {
      _submissionInProgress = false;
      if (!mounted) return;
      setState(() => _feedback = 'Write failed: $error');
      return;
    }
    _submissionInProgress = false;
    if (result.succeeded) {
      widget.onApplied();
      return;
    }
    if (!mounted) return;
    setState(() => _feedback = _writeFailureMessage(result));
  }

  /// Places the initial caret after the prefilled value exactly once.
  void _placeCaretAtEndOnInitialFocus() {
    if (!_inputFocusNode.hasFocus) return;
    _inputFocusNode.removeListener(_placeCaretAtEndOnInitialFocus);
    final text = _textController.text;
    _textController.selection = TextSelection.collapsed(offset: text.length);
  }

  /// Converts a typed SDK failure into tooltip feedback without visible text.
  String _writeFailureMessage(
    GameWriteResult result,
  ) => switch (result.status) {
    GameWriteStatus.none => 'No value was written.',
    GameWriteStatus.unsupportedProfile =>
      'The current game identity or session is unavailable.',
    GameWriteStatus.confirmationRequired => 'The write was not authorized.',
    GameWriteStatus.unsupportedField =>
      'The selected field is not registered in the current profile.',
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
    GameWriteStatus.invalidWriteResult => 'The SDK returned an invalid result.',
    GameWriteStatus.success => 'The written value could not be verified.',
  };

  /// Cancels on Escape and submits Enter only while the text field is focused.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onCancel();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          _inputFocusNode.hasFocus) {
        _submit();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Reports whether [first] and [second] represent the same SDK result.
  bool _sameWriteResult(GameWriteResult? first, GameWriteResult? second) =>
      identical(first, second) ||
      (first != null &&
          second != null &&
          first.status == second.status &&
          first.fieldId == second.fieldId &&
          first.requestedValue == second.requestedValue &&
          first.readBackValue == second.readBackValue &&
          first.errorCode == second.errorCode);

  /// Reports whether both fields describe the same captured edit target.
  bool _sameFieldMapping(GameField first, GameField second) =>
      first.id == second.id &&
      first.guestOffset == second.guestOffset &&
      first.valueType == second.valueType &&
      first.byteOrder == second.byteOrder;
}
