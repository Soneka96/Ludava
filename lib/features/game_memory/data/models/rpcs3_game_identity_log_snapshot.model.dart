/// Holds identity fields observed in one RPCS3 log file.
///
/// Values may include prior game loads from the same emulator log and do not
/// prove which game is active now.
class Rpcs3GameIdentityLogSnapshot {
  /// Distinct title names found in the log, in first-seen order.
  final List<String> titles;

  /// Distinct serials found in the log, in first-seen order.
  final List<String> serials;

  /// Distinct boot paths found in the log, in first-seen order.
  final List<String> bootPaths;

  /// Candidate log location inspected by the data source.
  final String logPath;

  /// Log file modification time observed during inspection.
  final DateTime logModifiedAtUtc;

  /// Selected process creation time used to reject older log files.
  final DateTime processStartedAtUtc;

  Rpcs3GameIdentityLogSnapshot._({
    required this.titles,
    required this.serials,
    required this.bootPaths,
    required this.logPath,
    required this.logModifiedAtUtc,
    required this.processStartedAtUtc,
  });

  /// Creates an immutable snapshot of distinct RPCS3 log values.
  factory Rpcs3GameIdentityLogSnapshot({
    required List<String> titles,
    required List<String> serials,
    required List<String> bootPaths,
    required String logPath,
    required DateTime logModifiedAtUtc,
    required DateTime processStartedAtUtc,
  }) => Rpcs3GameIdentityLogSnapshot._(
    titles: List.unmodifiable(titles),
    serials: List.unmodifiable(serials),
    bootPaths: List.unmodifiable(bootPaths),
    logPath: logPath,
    logModifiedAtUtc: logModifiedAtUtc,
    processStartedAtUtc: processStartedAtUtc,
  );

  /// Whether the log contains more than one distinct identity value.
  bool get hasConflictingIdentity =>
      titles.length > 1 || serials.length > 1 || bootPaths.length > 1;
}
