import 'package:ludava/features/game_memory/presentation/cli/diagnostic_arguments.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Parses and validates the generic Ludava CLI arguments.
abstract final class DiagnosticArgumentParser {
  /// Usage text for the supported commands.
  static const String usage = '''Usage:
  dart run bin/ludava.dart read --game <id> --field <id> --pid <PID> --memory-base <0xHEX>
  dart run bin/ludava.dart write --game <id> --field <id> --pid <PID> --memory-base <0xHEX> --value <integer> --confirm-write

Select the process, profile, and session guest base manually. Ludava does not
verify the active game build. RC2 bolts use owner-confirmed research and remain
unverified against a live Ludava session. Repeat the read command to refresh.''';

  /// Parses a read or write command and rejects missing, duplicate, or invalid options.
  static DiagnosticArguments parse(List<String> arguments) {
    if (arguments.isEmpty) {
      throw const FormatException('A read or write command is required.');
    }
    final action = switch (arguments.first) {
      'read' => GameMemoryAction.read,
      'write' => GameMemoryAction.write,
      _ => throw FormatException('Unknown command: ${arguments.first}'),
    };

    String? gameId;
    String? fieldId;
    int? processId;
    int? memoryBase;
    int? value;
    var confirmed = false;
    final seenOptions = <String>{};

    for (var index = 1; index < arguments.length; index++) {
      final option = arguments[index];
      if (!seenOptions.add(option)) {
        throw FormatException('Duplicate option: $option');
      }
      if (option == '--confirm-write') {
        confirmed = true;
        continue;
      }
      if (index + 1 >= arguments.length ||
          arguments[index + 1].startsWith('--')) {
        throw FormatException('$option requires a value.');
      }
      final optionValue = arguments[++index];
      switch (option) {
        case '--game':
          gameId = _requiredText(optionValue, option);
        case '--field':
          fieldId = _requiredText(optionValue, option);
        case '--pid':
          processId = _parseProcessId(optionValue);
        case '--memory-base':
          memoryBase = _parseMemoryBase(optionValue);
        case '--value':
          value = _parseInteger(optionValue, option);
        default:
          throw FormatException('Unknown option: $option');
      }
    }

    if (gameId == null ||
        fieldId == null ||
        processId == null ||
        memoryBase == null) {
      throw const FormatException(
        '--game, --field, --pid, and --memory-base are required.',
      );
    }
    if (action == GameMemoryAction.read && (value != null || confirmed)) {
      throw const FormatException('Read commands do not accept write options.');
    }
    if (action == GameMemoryAction.write && (value == null || !confirmed)) {
      throw const FormatException(
        'Write commands require --value and --confirm-write.',
      );
    }
    return DiagnosticArguments(
      action: action,
      gameId: gameId,
      fieldId: fieldId,
      processId: processId,
      memoryBase: memoryBase,
      value: value,
      confirmed: confirmed,
    );
  }

  static String _requiredText(String value, String option) {
    if (value.trim().isEmpty) {
      throw FormatException('$option requires a non-empty value.');
    }
    return value;
  }

  static int _parseProcessId(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      throw const FormatException('--pid requires a positive decimal integer.');
    }
    final processId = int.tryParse(value);
    if (processId == null || processId <= 0 || processId > 0xffffffff) {
      throw const FormatException('--pid must be between 1 and 4294967295.');
    }
    return processId;
  }

  static int _parseMemoryBase(String value) {
    if (!RegExp(r'^0[xX][0-9a-fA-F]+$').hasMatch(value)) {
      throw const FormatException(
        '--memory-base requires a hexadecimal value prefixed with 0x.',
      );
    }
    final memoryBase = int.tryParse(value.substring(2), radix: 16);
    if (memoryBase == null || memoryBase < 0) {
      throw const FormatException(
          '--memory-base is outside the address range.');
    }
    return memoryBase;
  }

  static int _parseInteger(String value, String option) {
    final parsed = int.tryParse(value);
    if (parsed == null) throw FormatException('$option requires an integer.');
    return parsed;
  }
}
