import 'package:ludava_sdk/shared/constants/enums.dart';

/// Represents the Windows data source's raw write outcome.
class ProcessMemoryWriteModel {
  /// Native status of the write operation.
  final MemoryWriteStatus status;

  /// Number of bytes the native API reports as written.
  final int bytesWritten;

  /// Number of bytes requested from the native API.
  final int requestedBytes;

  /// Native error code when the API reports one.
  final int? errorCode;

  /// Creates a data model with the native transfer counts and status.
  const ProcessMemoryWriteModel({
    required this.status,
    required this.bytesWritten,
    required this.requestedBytes,
    this.errorCode,
  });
}
