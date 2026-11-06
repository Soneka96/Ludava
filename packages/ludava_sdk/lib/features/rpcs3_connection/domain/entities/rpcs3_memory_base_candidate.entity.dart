/// Holds a guest memory base found in a fresh log near an RPCS3 executable.
///
/// The caller must associate the log with the selected process session and
/// reject conflicting base candidates before using [memoryBase].
class Rpcs3MemoryBaseCandidate {
  /// Parsed 64-bit guest memory base.
  final int memoryBase;

  /// Full path of the log file containing the candidate.
  final String logPath;

  /// Creates a base candidate from one RPCS3 log.
  const Rpcs3MemoryBaseCandidate({
    required this.memoryBase,
    required this.logPath,
  });
}
