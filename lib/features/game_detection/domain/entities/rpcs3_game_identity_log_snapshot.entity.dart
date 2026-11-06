import 'package:ludava/features/game_detection/domain/entities/rpcs3_game_identity_log_event.entity.dart';

/// Holds identity history and ordered lifecycle observations from one RPCS3 log.
///
/// The title, serial, and boot-path lists preserve history. [events] retains
/// executable loads and process-finished events in their original order.
class Rpcs3GameIdentityLogSnapshot {
  /// Distinct title names found in the log, in first-seen order.
  final List<String> titles;

  /// Distinct serials found in the log, in first-seen order.
  final List<String> serials;

  /// Distinct boot paths found in the log, in first-seen order.
  final List<String> bootPaths;

  /// Completed PPU loads and process-finished events in log order.
  final List<Rpcs3GameIdentityLogEvent> events;

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
    required this.events,
    required this.logPath,
    required this.logModifiedAtUtc,
    required this.processStartedAtUtc,
  });

  /// Creates an immutable snapshot of distinct RPCS3 log values.
  factory Rpcs3GameIdentityLogSnapshot({
    required List<String> titles,
    required List<String> serials,
    required List<String> bootPaths,
    List<Rpcs3GameIdentityLogEvent> events = const [],
    required String logPath,
    required DateTime logModifiedAtUtc,
    required DateTime processStartedAtUtc,
  }) => Rpcs3GameIdentityLogSnapshot._(
    titles: List.unmodifiable(titles),
    serials: List.unmodifiable(serials),
    bootPaths: List.unmodifiable(bootPaths),
    events: List.unmodifiable(events),
    logPath: logPath,
    logModifiedAtUtc: logModifiedAtUtc,
    processStartedAtUtc: processStartedAtUtc,
  );

  /// Whether the log contains more than one distinct identity value.
  bool get hasConflictingIdentity =>
      titles.length > 1 || serials.length > 1 || bootPaths.length > 1;

  /// Latest lifecycle event, or `null` when the log has no game events.
  Rpcs3GameIdentityLogEvent? get latestEvent =>
      events.isEmpty ? null : events.last;
}
