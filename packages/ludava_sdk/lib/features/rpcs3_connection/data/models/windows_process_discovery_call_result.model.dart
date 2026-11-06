/// Keeps a Windows API return value with its immediately captured error.
class WindowsProcessDiscoveryCallResult<T> {
  /// The value returned by the native operation.
  final T value;

  /// The error captured for a failed native operation; zero on success.
  final int errorCode;

  /// Creates a result for one Windows process-discovery API call.
  const WindowsProcessDiscoveryCallResult({
    required this.value,
    required this.errorCode,
  });
}
