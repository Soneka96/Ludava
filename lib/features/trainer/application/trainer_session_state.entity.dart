import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';

/// Immutable, structured state for a trainer session.
class TrainerSessionState {
  /// RPCS3 process identifiers found during the last connection check.
  final List<int> processIds;

  /// Currently selected RPCS3 process identifier, if any.
  final int? selectedProcessId;

  /// Metadata identifying the selected process session, if available.
  final Rpcs3ProcessMetadata? processMetadata;

  /// Current game identity result, if detection has run.
  final GameDetectionResult? detection;

  /// Memory base resolved for the selected process session, if available.
  final int? memoryBase;

  /// Last structured read outcome for each profile field.
  final Map<String, GameReadResult> readResults;

  /// Outcome of the most recent requested field write.
  final GameWriteResult? lastWriteResult;

  /// Technical or validation error suitable for presentation to the user.
  final String? errorMessage;

  /// Creates a state snapshot and protects its collections from mutation.
  TrainerSessionState({
    List<int> processIds = const [],
    this.selectedProcessId,
    this.processMetadata,
    this.detection,
    this.memoryBase,
    Map<String, GameReadResult> readResults = const {},
    this.lastWriteResult,
    this.errorMessage,
  }) : processIds = List.unmodifiable(processIds),
       readResults = Map.unmodifiable(readResults);

  /// Selected profile, or `null` when the current identity is unresolved.
  GameProfile? get profile => detection?.profile;
}
