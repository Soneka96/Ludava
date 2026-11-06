import 'package:ludava_sdk/ludava_sdk.dart';

/// Parsed command-line arguments for one game-memory operation.
class DiagnosticArguments {
  /// Requested operation.
  final GameMemoryAction action;

  /// Registered game profile identifier.
  final String gameId;

  /// Field identifier within the selected profile.
  final String fieldId;

  /// Windows process identifier.
  final int processId;

  /// Session-specific hexadecimal guest-memory base.
  final int memoryBase;

  /// Requested write value, present only for a write operation.
  final int? value;

  /// Whether the user explicitly confirmed the write command.
  final bool confirmed;

  /// Whether a read requires current process and profile identity evidence.
  final bool requireCurrentIdentity;

  /// Creates parsed arguments for one game-memory operation.
  const DiagnosticArguments({
    required this.action,
    required this.gameId,
    required this.fieldId,
    required this.processId,
    required this.memoryBase,
    required this.confirmed,
    this.requireCurrentIdentity = false,
    this.value,
  });
}
