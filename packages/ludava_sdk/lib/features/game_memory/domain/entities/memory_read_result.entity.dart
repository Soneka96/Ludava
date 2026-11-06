import 'package:ludava_sdk/shared/constants/enums.dart';

/// Contains the byte-transfer outcome required to decode a game field.
class MemoryReadResult {
  /// Status reported for the byte read.
  final MemoryReadStatus status;

  /// Bytes returned by the process-memory boundary.
  final List<int> bytes;

  /// Number of bytes reported as read.
  final int bytesRead;

  /// Number of bytes requested.
  final int requestedBytes;

  /// Native error code when the process API reports one.
  final int? errorCode;

  MemoryReadResult._({
    required this.status,
    required this.bytes,
    required this.bytesRead,
    required this.requestedBytes,
    required this.errorCode,
  });

  /// Creates a result with an immutable snapshot of [bytes].
  factory MemoryReadResult({
    required MemoryReadStatus status,
    required List<int> bytes,
    required int bytesRead,
    required int requestedBytes,
    int? errorCode,
  }) =>
      MemoryReadResult._(
        status: status,
        bytes: List.unmodifiable(bytes),
        bytesRead: bytesRead,
        requestedBytes: requestedBytes,
        errorCode: errorCode,
      );

  /// Whether the status, byte count, and buffer all describe a full read.
  bool get isComplete =>
      status == MemoryReadStatus.complete &&
      requestedBytes > 0 &&
      bytesRead == requestedBytes &&
      bytes.length == requestedBytes;
}
