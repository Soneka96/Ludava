/// Describes whether a previously selected write target is still current.
class TrainerWriteValidationResult {
  /// Whether the target is safe to pass to the guarded write command.
  final bool isAuthorized;

  /// Whether the selected RPCS3 process is no longer available.
  final bool processUnavailable;

  /// Whether the selected RPCS3 process session has changed.
  final bool processSessionChanged;

  /// User-facing reason when current-target validation rejects the write.
  final String? rejectionMessage;

  /// Creates the result of one current write-target validation.
  const TrainerWriteValidationResult({
    required this.isAuthorized,
    this.processUnavailable = false,
    this.processSessionChanged = false,
    this.rejectionMessage,
  });
}
