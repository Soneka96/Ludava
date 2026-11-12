import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Contains a diagnostic operation outcome without frontend-formatted text.
class DiagnosticGameMemoryResult {
  /// Structured orchestration outcome.
  final DiagnosticGameMemoryStatus status;

  /// Resolved profile, or `null` when [status] is [DiagnosticGameMemoryStatus.unknownGame].
  final GameProfile? profile;

  /// Whether current process evidence matched [profile].
  final bool identityConfirmed;

  /// Field read outcome for a read request.
  final GameReadResult? readResult;

  /// Field write outcome for a write request.
  final GameWriteResult? writeResult;

  /// Original platform or collaborator error, when operation orchestration failed.
  final Object? error;

  /// Process-handle cleanup error, independent of a completed memory result.
  final Object? cleanupError;

  /// Creates a structured result for a diagnostic game-memory request.
  const DiagnosticGameMemoryResult({
    required this.status,
    this.profile,
    this.identityConfirmed = false,
    this.readResult,
    this.writeResult,
    this.error,
    this.cleanupError,
  });

  /// Whether the requested read or guarded write completed successfully.
  bool get succeeded =>
      status == DiagnosticGameMemoryStatus.completed &&
      (readResult?.succeeded ?? writeResult?.succeeded ?? false);
}
