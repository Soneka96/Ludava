/// Holds a guest memory base found in a recent log near an RPCS3 executable.
///
/// The log is a candidate source only; it does not prove that the value belongs
/// to the selected process, so the caller must ask the user to confirm it.
class Rpcs3MemoryBaseCandidate {
  /// Parsed 64-bit guest memory base.
  final int memoryBase;

  /// Full path of the log file containing the candidate.
  final String logPath;

  /// Creates a candidate that still requires user confirmation.
  const Rpcs3MemoryBaseCandidate({
    required this.memoryBase,
    required this.logPath,
  });
}
