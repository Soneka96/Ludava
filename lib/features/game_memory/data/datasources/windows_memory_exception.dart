/// Describes a failed Windows process-memory operation.
class WindowsMemoryException implements Exception {
  /// Name of the Windows operation that failed.
  final String operation;

  /// Native process ID when the failure occurred while opening it.
  final int? processId;

  /// Windows error code captured immediately after the failed API call.
  final int errorCode;

  /// Creates an exception with the operation and native error details.
  const WindowsMemoryException({
    required this.operation,
    required this.errorCode,
    this.processId,
  });

  /// Formats the failed operation and captured Windows error.
  @override
  String toString() {
    final process = processId == null ? '' : ' for process $processId';
    return '$operation$process failed (Windows error $errorCode).';
  }
}
