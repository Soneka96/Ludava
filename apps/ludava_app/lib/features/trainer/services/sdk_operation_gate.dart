/// One-way guard that blocks new SDK operations during terminal shutdown.
class SdkOperationGate {
  bool _isOpen = true;

  /// Whether new SDK operations may start.
  bool get isOpen => _isOpen;

  /// Closes the gate permanently; repeated closure is safe.
  void close() => _isOpen = false;
}
