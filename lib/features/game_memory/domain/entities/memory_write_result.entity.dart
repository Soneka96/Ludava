import 'package:ludava/shared/constants/enums.dart';

/// Contains the byte-transfer outcome for a process-memory write.
class MemoryWriteResult {
  /// Status reported for the byte write.
  final MemoryWriteStatus status;

  /// Number of bytes reported as written.
  final int bytesWritten;

  /// Number of bytes requested.
  final int requestedBytes;

  /// Native error code when the process API reports one.
  final int? errorCode;

  /// Creates a result with the native transfer counts and status.
  const MemoryWriteResult({
    required this.status,
    required this.bytesWritten,
    required this.requestedBytes,
    this.errorCode,
  });

  /// Whether the status and counts describe a full non-empty write.
  bool get isComplete =>
      status == MemoryWriteStatus.complete &&
      requestedBytes > 0 &&
      bytesWritten == requestedBytes;
}
