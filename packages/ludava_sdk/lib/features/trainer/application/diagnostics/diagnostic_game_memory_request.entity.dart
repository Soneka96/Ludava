import 'package:ludava_sdk/shared/constants/enums.dart';

/// Describes one read or write requested through the SDK diagnostic boundary.
class DiagnosticGameMemoryRequest {
  /// Selected registered game profile identifier.
  final String gameId;

  /// Selected field identifier within [gameId].
  final String fieldId;

  /// RPCS3 process identifier selected by the caller.
  final int processId;

  /// Session guest-memory base supplied for this operation.
  final int memoryBase;

  /// Operation requested by the caller.
  final GameMemoryAction action;

  /// Value requested for a write operation.
  final int? value;

  /// Whether a write has explicit caller confirmation.
  final bool confirmed;

  /// Whether a read must match current RPCS3 identity evidence.
  final bool requireCurrentIdentity;

  /// Creates a typed diagnostic memory request.
  const DiagnosticGameMemoryRequest({
    required this.gameId,
    required this.fieldId,
    required this.processId,
    required this.memoryBase,
    required this.action,
    this.value,
    this.confirmed = false,
    this.requireCurrentIdentity = false,
  });
}
