/// Describes the selected RPCS3 process information used for log matching.
class Rpcs3ProcessMetadata {
  /// Full path to the selected process's executable image.
  final String executablePath;

  /// UTC time at which Windows created the selected process.
  final DateTime startedAtUtc;

  /// Creates process metadata used to evaluate related RPCS3 logs.
  const Rpcs3ProcessMetadata({
    required this.executablePath,
    required this.startedAtUtc,
  });
}
