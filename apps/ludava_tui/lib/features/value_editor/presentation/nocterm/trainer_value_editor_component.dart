import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/shared/constants/layout_constants.dart';
import 'package:nocterm/nocterm.dart';

/// Edits one field value and applies only a changed, valid value.
class TrainerValueEditorComponent extends StatefulComponent {
  /// Field metadata used to enforce edit and write bounds.
  final GameField field;

  /// Current value, or `null` when the last field read was unavailable.
  final int? currentValue;

  /// Validates and writes an accepted changed value, returning its outcome.
  final GameWriteResult Function(int value) onApply;

  /// Closes the editor after [onApply] returns a verified successful write.
  final void Function()? onApplied;

  /// Cancels editing without applying the text.
  final void Function() onCancel;

  /// Creates the editor for the current value of [field].
  const TrainerValueEditorComponent({
    required this.field,
    required this.currentValue,
    required this.onApply,
    this.onApplied,
    required this.onCancel,
    super.key,
  });

  /// Creates state that owns the unsaved text, cursor, and validation feedback.
  @override
  State<TrainerValueEditorComponent> createState() =>
      _TrainerValueEditorState();
}

class _TrainerValueEditorState extends State<TrainerValueEditorComponent> {
  late final TextEditingController _textController;
  bool _applyAttempted = false;
  bool _feedbackIsSuccess = false;
  String? _feedback;

  /// Initializes the editor text from the latest verified field value.
  @override
  void initState() {
    _textController = TextEditingController(text: _initialText);
  }

  /// Resets temporary edit state when the field or verified value changes.
  @override
  void didUpdateComponent(covariant TrainerValueEditorComponent oldComponent) {
    if (!identical(oldComponent.field, component.field) ||
        oldComponent.currentValue != component.currentValue) {
      _textController.text = _initialText;
      _applyAttempted = false;
      _feedbackIsSuccess = false;
      _feedback = null;
    }
  }

  /// Disposes the text controller owned by this editor.
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Renders the current value, editable text, and apply/cancel feedback.
  @override
  Component build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < NoctermLayoutConstants.minimumMenuWidth ||
          constraints.maxHeight < NoctermLayoutConstants.fixedEditorRows) {
        return const Center(
          child: Text(
            'Terminal too small. Enlarge the window to use Ludava.',
            style: TextStyle(color: Colors.yellow),
          ),
        );
      }
      return Focusable(
        focused: true,
        onKeyEvent: _handleEditorShortcut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EDIT ${component.field.name.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text('Current value: ${_formattedCurrentValue}'),
              const SizedBox(height: 1),
              TextField(
                controller: _textController,
                focused: _canEdit,
                enabled: _canEdit,
                readOnly: !_canEdit,
                width: 28,
                maxLines: 1,
                onChanged: _handleTextChanged,
                onSubmitted: (_) => _apply(),
                onKeyEvent: _preserveCursorAfterDelete,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.green,
                decoration: InputDecoration(
                  border: BoxBorder.all(color: Colors.gray),
                  focusedBorder: BoxBorder.all(color: Colors.green),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 1),
                ),
              ),
              const SizedBox(height: 1),
              if (!_canEdit)
                Text(
                  _disabledReason,
                  style: const TextStyle(color: Colors.yellow),
                ),
              const Text('Enter Apply   Esc Cancel'),
              if (_feedback case final feedback?)
                Text(
                  feedback,
                  style: TextStyle(
                    color: _feedbackIsSuccess ? Colors.green : Colors.yellow,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  /// Whether the current field has a readable value and approved write range.
  bool get _canEdit =>
      component.field.canRead &&
      component.field.canWrite &&
      component.currentValue != null &&
      component.field.minimumValue != null &&
      component.field.maximumValue != null;

  /// Explains why the editor cannot accept input.
  String get _disabledReason {
    if (component.currentValue == null || !component.field.canRead) {
      return 'Current value unavailable.';
    }
    if (!component.field.canWrite) return 'This field is read-only.';
    return 'This field has no approved value range.';
  }

  /// Returns the ungrouped starting value for the text buffer.
  String get _initialText =>
      component.field.canRead ? component.currentValue?.toString() ?? '' : '';

  /// Formats the displayed current value while preserving the raw edit text.
  String get _formattedCurrentValue {
    final value = component.field.canRead ? component.currentValue : null;
    return value == null ? 'Unavailable' : _formatNumber(value);
  }

  /// Handles cancellation without forwarding Escape to the text field.
  bool _handleEditorShortcut(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.escape) {
      component.onCancel();
      return true;
    }
    return false;
  }

  /// Preserves the cursor when Nocterm's Delete handling moves it to the end.
  bool _preserveCursorAfterDelete(KeyboardEvent event) {
    if (event.logicalKey != LogicalKey.delete || !_canEdit) return false;
    final selection = _textController.selection;
    if (!selection.isCollapsed) return false;

    final text = _textController.text;
    final cursor = selection.extentOffset.clamp(0, text.length);
    if (cursor == text.length) return true;

    // Nocterm 0.9.0 resets the cursor to the end when Delete changes text.
    // Keep using its controller and selection APIs while preserving the
    // pre-delete cursor position for this one key operation.
    final followingText = text.substring(cursor);
    final nextCodePoint = followingText.runes.first;
    final removedLength = String.fromCharCode(nextCodePoint).length;
    _textController.text =
        text.substring(0, cursor) + text.substring(cursor + removedLength);
    _textController.selection = TextSelection.collapsed(offset: cursor);
    return true;
  }

  /// Clears stale feedback after the user changes the proposed value.
  void _handleTextChanged(String value) {
    if (_applyAttempted || _feedback != null) {
      setState(() {
        _applyAttempted = false;
        _feedbackIsSuccess = false;
        _feedback = null;
      });
    }
  }

  /// Validates the edit and dispatches at most one apply attempt.
  void _apply() {
    if (!_canEdit || _applyAttempted) return;
    final text = _textController.text;
    if (text.isEmpty) {
      setState(() => _feedback = 'Enter a value.');
      return;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(text)) {
      setState(() => _feedback = 'Enter digits only.');
      return;
    }
    final value = int.tryParse(text);
    if (value == null) {
      setState(() => _feedback = 'The value is too large.');
      return;
    }
    final minimum = component.field.minimumValue;
    final maximum = component.field.maximumValue;
    if (minimum == null || maximum == null) {
      setState(() => _feedback = 'This field has no approved value range.');
      return;
    }
    if (value < minimum || value > maximum) {
      setState(
        () =>
            _feedback =
                'Enter a value from ${_formatNumber(minimum)} to '
                '${_formatNumber(maximum)}.',
      );
      return;
    }
    if (value == component.currentValue) {
      setState(() => _feedback = 'The value is unchanged.');
      return;
    }

    setState(() => _applyAttempted = true);
    late final GameWriteResult result;
    try {
      result = component.onApply(value);
    } catch (error) {
      setState(() {
        _feedback = 'Write failed: $error';
        _feedbackIsSuccess = false;
      });
      return;
    }
    setState(() {
      _feedback = _feedbackFor(result);
      _feedbackIsSuccess = result.succeeded;
    });
    if (result.succeeded) component.onApplied?.call();
  }

  /// Converts [result] into concise feedback for the editor.
  String _feedbackFor(GameWriteResult result) {
    if (result.succeeded) {
      return 'Verified value: ${_formatNumber(result.readBackValue!)}';
    }
    return switch (result.status) {
      GameWriteStatus.none => 'No value was applied.',
      GameWriteStatus.unsupportedProfile || GameWriteStatus.unsupportedField =>
        'This field is not approved for writing.',
      GameWriteStatus.confirmationRequired => 'The write was not authorized.',
      GameWriteStatus.invalidValue => 'The value is outside the allowed range.',
      GameWriteStatus.invalidMapping => 'The field address is unavailable.',
      GameWriteStatus.preliminaryReadFailed =>
        'The current value could not be checked. No write was made.',
      GameWriteStatus.writeFailed => 'The write failed.',
      GameWriteStatus.incompleteWrite => 'The write was incomplete.',
      GameWriteStatus.readBackFailed =>
        'The written value could not be verified.',
      GameWriteStatus.readBackMismatch => 'The written value did not verify.',
      GameWriteStatus.invalidWriteResult => 'The write result was invalid.',
      GameWriteStatus.success => 'The written value could not be verified.',
    };
  }

  /// Groups [value] for presentation without changing the stored integer.
  String _formatNumber(int value) {
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
