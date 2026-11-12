/// Memory operation and value types used throughout Ludava.
library;

/// Describes a value's binary representation.
enum MemoryValueType {
  /// No usable value type has been selected.
  none,

  /// An unsigned 32-bit integer.
  unsigned32;

  /// Byte length of this value representation, or `null` for [none].
  int? get byteLength => switch (this) {
    MemoryValueType.none => null,
    MemoryValueType.unsigned32 => 4,
  };
}

/// Describes the byte order used to encode a value.
enum ByteOrder {
  /// No byte order has been selected.
  none,

  /// Most significant byte comes first.
  big,

  /// Least significant byte comes first.
  little,
}

/// Describes the outcome of reading bytes from a process.
enum MemoryReadStatus {
  /// No read has been attempted.
  none,

  /// The native API returned every requested byte.
  complete,

  /// The native API reported a failure.
  nativeFailure,

  /// The native API returned fewer bytes than requested.
  partial,

  /// The requested address is outside the supported range.
  invalidAddress,

  /// The requested byte count is invalid.
  invalidRequest,

  /// The native API reported an impossible byte count.
  invalidByteCount,
}

/// Describes a requested game-memory command.
enum GameMemoryAction {
  /// No command was selected.
  none,

  /// Read one profiled field.
  read,

  /// Write one profiled field.
  write,
}

/// Describes how a diagnostic game-memory request ended.
enum DiagnosticGameMemoryStatus {
  /// No diagnostic operation has been selected.
  none,

  /// The requested field operation completed successfully.
  completed,

  /// The game identifier does not match a registered profile.
  unknownGame,

  /// The request is incomplete or uses an unsupported operation.
  invalidRequest,

  /// Current identity was required but does not match the selected profile.
  identityMismatch,

  /// Current process identity could not be checked for a write.
  identityCheckFailed,

  /// The current RPCS3 memory base does not match the requested base.
  memoryBaseMismatch,

  /// The current RPCS3 memory base could not be checked.
  memoryBaseCheckFailed,

  /// The selected field operation was rejected or did not succeed.
  memoryOperationFailed,

  /// Opening, using, or closing the native process boundary failed.
  nativeFailure,

  /// The operation result is available, but closing its process handle failed.
  cleanupFailed,
}

/// Describes the outcome of writing bytes to a process.
enum MemoryWriteStatus {
  /// No write has been attempted.
  none,

  /// The native API wrote every requested byte.
  complete,

  /// The native API reported a failure.
  nativeFailure,

  /// The native API wrote fewer bytes than requested.
  partial,

  /// The requested address is outside the supported range.
  invalidAddress,

  /// The requested byte count is invalid.
  invalidRequest,

  /// The native API reported an impossible byte count.
  invalidByteCount,
}

/// Describes the outcome of reading a game field.
enum GameReadStatus {
  /// No read has been attempted.
  none,

  /// The field was read and decoded successfully.
  success,

  /// The selected profile is unsupported for the requested operation.
  unsupportedProfile,

  /// The selected field is missing from the profile.
  unsupportedField,

  /// The profile's address mapping is invalid.
  invalidMapping,

  /// The native process read failed.
  readFailed,

  /// The native API returned only part of the field.
  incompleteRead,

  /// The native read result was internally inconsistent.
  invalidReadResult,
}

/// Describes the outcome of writing a game field.
enum GameWriteStatus {
  /// No write has been attempted.
  none,

  /// The value was written and matched the read-back value.
  success,

  /// The selected profile does not match the current game session.
  unsupportedProfile,

  /// The user did not explicitly confirm this write.
  confirmationRequired,

  /// The selected field is missing from the profile.
  unsupportedField,

  /// The requested value is outside the field's allowed range.
  invalidValue,

  /// The profile's address mapping is invalid.
  invalidMapping,

  /// The selected field could not be completely read before writing.
  preliminaryReadFailed,

  /// The native process write failed.
  writeFailed,

  /// The native API wrote fewer bytes than requested.
  incompleteWrite,

  /// Reading back the written value failed or was incomplete.
  readBackFailed,

  /// The written value did not match the value read back from memory.
  readBackMismatch,

  /// The native write result was internally inconsistent.
  invalidWriteResult,
}

/// Describes the outcome of checking the current RPCS3 game identity.
enum GameDetectionStatus {
  /// Detection has not run or no meaningful outcome is available.
  none,

  /// No RPCS3 process is available.
  rpcs3NotRunning,

  /// RPCS3 is running without an identified active game.
  noActiveGame,

  /// A game was identified, but Ludava has no matching profile.
  unsupportedGame,

  /// A supported game profile was matched.
  supportedGame,

  /// Available identity evidence is incomplete or conflicting.
  ambiguous,

  /// Detection could not complete because of a technical error.
  failed,
}

/// Describes the confidence and origin of an RPCS3 game identity.
enum GameIdentityConfidence {
  /// No identity evidence is available.
  none,

  /// Evidence exists but does not uniquely establish the active game.
  uncertain,

  /// Current runtime evidence uniquely establishes the active game.
  confirmed,

  /// The user deliberately selected a profile without runtime verification.
  manuallySelected,
}
