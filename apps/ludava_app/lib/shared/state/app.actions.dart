/// Requests the app middleware to initialize its owned resources.
class InitializeAppAction {
  /// Creates an initialization request.
  const InitializeAppAction();
}

/// Requests terminal application shutdown and collects cleanup attempts.
class ShutdownRequestedAction {
  final List<Future<void>> _cleanupFutures = [];

  /// Creates a shutdown request with no registered cleanup attempts.
  ShutdownRequestedAction();

  /// Registers [cleanup] for the shutdown coordinator to await.
  void addCleanup(Future<void> cleanup) => _cleanupFutures.add(cleanup);

  /// Awaits every registered cleanup and surfaces all failure messages.
  Future<void> waitForCleanup() async {
    final failures = <Object>[];
    await Future.wait<void>(
      _cleanupFutures.map((cleanup) async {
        try {
          await cleanup;
        } on Object catch (error) {
          failures.add(error);
        }
      }),
    );
    if (failures.isNotEmpty) {
      throw StateError(
        'Shutdown cleanup failed: ${failures.map((error) => error.toString()).join('; ')}',
      );
    }
  }
}
