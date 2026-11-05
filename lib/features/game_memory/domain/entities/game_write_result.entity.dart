import 'package:ludava/shared/constants/enums.dart';

/// Contains the outcome and read-back evidence for a game-field write.
class GameWriteResult {
  /// Final status of the attempted write from [GameWriteStatus].
  final GameWriteStatus status;

  /// Identifier of the selected field, if one was resolved.
  final String? fieldId;

  /// Value requested by the user, if one was accepted.
  final int? requestedValue;

  /// Value read back after the write, when a read-back was completed.
  final int? readBackValue;

  /// Native error code when the process API reports one.
  final int? errorCode;

  /// Creates a write result with optional request and read-back details.
  const GameWriteResult({
    required this.status,
    this.fieldId,
    this.requestedValue,
    this.readBackValue,
    this.errorCode,
  });

  /// Whether a write succeeded and the read-back matches the request.
  bool get succeeded =>
      status == GameWriteStatus.success &&
      fieldId?.isNotEmpty == true &&
      requestedValue != null &&
      readBackValue == requestedValue;
}
