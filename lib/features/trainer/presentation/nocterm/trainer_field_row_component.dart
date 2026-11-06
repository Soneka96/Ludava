import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:nocterm/nocterm.dart';

/// Renders a field's selection, name, and latest readable value.
class TrainerFieldRowComponent extends StatelessComponent {
  /// Zero-based row position used for the displayed shortcut number.
  final int index;

  /// Field metadata represented by this row.
  final GameField field;

  /// Latest read result, or `null` when no read is available.
  final GameReadResult? readResult;

  /// Whether the row is currently selected.
  final bool selected;

  /// Creates a row for [field] and its current [readResult].
  const TrainerFieldRowComponent({
    required this.index,
    required this.field,
    required this.readResult,
    required this.selected,
    super.key,
  });

  /// Renders the field label, selected marker, and verified value.
  @override
  Component build(BuildContext context) {
    final result = readResult;
    final value =
        result?.succeeded == true && result?.value != null
            ? _formatNumber(result!.value!)
            : 'Unavailable';
    return Row(
      children: [
        Text(selected ? '❯ ' : '  '),
        Text('${index + 1}. ${field.name}'),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: selected ? Colors.green : null,
            fontWeight: selected ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  /// Groups [value] for display without changing its numeric meaning.
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
