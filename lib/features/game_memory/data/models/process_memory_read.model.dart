import 'package:ludava/shared/constants/enums.dart';

/// Represents the Windows data source's raw read outcome.
class ProcessMemoryReadModel {
  /// Native status of the read operation.
  final MemoryReadStatus status;

  /// Bytes copied from the target process.
  final List<int> bytes;

  /// Number of bytes the native API reports as read.
  final int bytesRead;

  /// Number of bytes requested from the native API.
  final int requestedBytes;

  /// Native error code when the API reports one.
  final int? errorCode;

  /// Creates a data model with an immutable snapshot of [bytes].
  ProcessMemoryReadModel({
    required this.status,
    required List<int> bytes,
    required this.bytesRead,
    required this.requestedBytes,
    this.errorCode,
  }) : bytes = List.unmodifiable(bytes);
}
