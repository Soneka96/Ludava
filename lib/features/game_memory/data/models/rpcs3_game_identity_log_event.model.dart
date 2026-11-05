/// Describes a pending or completed PPU load, or a guest process finish event.
class Rpcs3GameIdentityLogEvent {
  /// Title observed for the executable, when RPCS3 logged one.
  final String? title;

  /// Title identifier observed for the executable, when RPCS3 logged one.
  final String? titleId;

  /// Boot path observed for the executable, when RPCS3 logged one.
  final String? bootPath;

  /// Executable filename associated with the event, when known.
  final String? executable;

  /// PPU executable hash logged after the executable was loaded.
  final String? executableHash;

  /// Whether this event records the guest process finishing.
  final bool processFinished;

  /// Exit-spawn target when a process finish requested another executable.
  final String? nextExecutable;

  /// Creates an immutable executable-load or process-finish observation.
  const Rpcs3GameIdentityLogEvent({
    this.title,
    this.titleId,
    this.bootPath,
    this.executable,
    this.executableHash,
    this.processFinished = false,
    this.nextExecutable,
  });
}
