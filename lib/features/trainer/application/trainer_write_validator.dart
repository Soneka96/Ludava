import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/trainer/application/trainer_write_validation_result.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Revalidates process session, game identity, and memory base before a write.
class TrainerWriteValidator {
  /// Creates the validator with current RPCS3 evidence readers.
  TrainerWriteValidator({
    required List<int> Function() discoverProcessIds,
    required Rpcs3ProcessMetadata Function(int processId) readProcessMetadata,
    required Rpcs3MemoryBaseCandidate? Function(
      Rpcs3ProcessMetadata processMetadata,
    )
    resolveMemoryBaseCandidate,
    required GameDetectionResult? Function(
      int processId,
      Rpcs3ProcessMetadata processMetadata,
    )
    detectGame,
  }) : _discoverProcessIds = discoverProcessIds,
       _readProcessMetadata = readProcessMetadata,
       _resolveMemoryBaseCandidate = resolveMemoryBaseCandidate,
       _detectGame = detectGame;

  final List<int> Function() _discoverProcessIds;
  final Rpcs3ProcessMetadata Function(int processId) _readProcessMetadata;
  final Rpcs3MemoryBaseCandidate? Function(Rpcs3ProcessMetadata processMetadata)
  _resolveMemoryBaseCandidate;
  final GameDetectionResult? Function(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  )
  _detectGame;

  /// Authorizes [selectedDetection] only while all current evidence still matches.
  TrainerWriteValidationResult validate({
    required int processId,
    required int memoryBase,
    required GameProfile profile,
    required GameDetectionResult selectedDetection,
    required DateTime? selectedProcessStartedAtUtc,
  }) {
    try {
      final processIds = _discoverProcessIds();
      if (!processIds.contains(processId)) {
        return const TrainerWriteValidationResult(
          isAuthorized: false,
          processUnavailable: true,
          rejectionMessage: 'RPCS3 stopped. No write was made.',
        );
      }

      final currentMetadata = _readProcessMetadata(processId);
      if (selectedProcessStartedAtUtc == null ||
          currentMetadata.startedAtUtc != selectedProcessStartedAtUtc) {
        return const TrainerWriteValidationResult(
          isAuthorized: false,
          processSessionChanged: true,
          rejectionMessage: 'The RPCS3 session changed. No write was made.',
        );
      }

      final currentDetection = _detectGame(processId, currentMetadata);
      final currentBase = _resolveMemoryBaseCandidate(currentMetadata);
      final identityStillMatches =
          currentDetection?.processId == processId &&
          currentDetection?.status == GameDetectionStatus.supportedGame &&
          currentDetection?.confidence == GameIdentityConfidence.confirmed &&
          currentDetection?.profile?.id == profile.id &&
          currentDetection?.executableHash == selectedDetection.executableHash;
      if (!identityStillMatches || currentBase?.memoryBase != memoryBase) {
        return const TrainerWriteValidationResult(
          isAuthorized: false,
          rejectionMessage:
              'The active game or memory base changed. No write was made; re-detect before continuing.',
        );
      }
      return const TrainerWriteValidationResult(isAuthorized: true);
    } on Exception catch (error) {
      return TrainerWriteValidationResult(
        isAuthorized: false,
        rejectionMessage:
            'Could not revalidate the game before writing. No write was made: $error',
      );
    } on UnsupportedError catch (error) {
      return TrainerWriteValidationResult(
        isAuthorized: false,
        rejectionMessage:
            'Could not revalidate the game before writing. No write was made: $error',
      );
    }
  }
}
