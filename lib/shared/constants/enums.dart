/// Verification and value types used throughout Ludava.
library;

/// Describes how much evidence supports an operation.
enum VerificationStatus {
  /// No evidence has been recorded.
  none,

  /// A candidate is available for controlled experimentation.
  experimental,

  /// Owner-confirmed research supports the capability; Ludava has not been live-tested.
  researchConfirmed,

  /// The capability has been independently verified.
  verified,

  /// Evidence shows that the capability must not be used.
  unsupported,
}

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

  /// The profile is not approved for reading.
  unsupportedProfile,

  /// The selected field is missing or not approved for reading.
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

  /// The profile is not approved for writing.
  unsupportedProfile,

  /// The user did not explicitly confirm this write.
  confirmationRequired,

  /// The selected field is missing or not approved for writing.
  unsupportedField,

  /// The requested value is outside the field's allowed range.
  invalidValue,

  /// The profile's address mapping is invalid.
  invalidMapping,

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
