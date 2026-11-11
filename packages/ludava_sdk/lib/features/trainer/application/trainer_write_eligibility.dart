import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/trainer/application/trainer_session_state.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Reports presentation eligibility for writes from an SDK session snapshot.
///
/// This capability only determines whether a frontend may offer editing. The
/// trainer session still revalidates the live process and memory target before
/// every write.
abstract final class TrainerWriteEligibility {
  /// Reports whether [session] and [field] describe a valid current write target.
  static bool hasValidTarget(TrainerSessionState session, GameField field) {
    final profile = session.profile;
    final processId = session.selectedProcessId;
    final detection = session.detection;
    return profile != null &&
        identical(profile.fields[field.id], field) &&
        field.minimumValue != null &&
        field.maximumValue != null &&
        processId != null &&
        session.processIds.contains(processId) &&
        session.processMetadata != null &&
        session.memoryBase != null &&
        detection?.status == GameDetectionStatus.supportedGame &&
        detection?.processId == processId &&
        detection?.confidence == GameIdentityConfidence.confirmed;
  }

  /// Reports whether [field] has a valid target and a successful current read.
  static bool isWriteEligible(TrainerSessionState session, GameField field) =>
      hasValidTarget(session, field) &&
      session.readResults[field.id]?.succeeded == true;
}
