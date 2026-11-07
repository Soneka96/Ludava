import 'package:ludava_sdk/ludava_sdk.dart';

/// Calculates visible write availability for trainer presentation.
abstract final class TrainerFieldAvailability {
  /// Reports whether the session still has a fully approved write target.
  static bool hasWriteTarget(TrainerSessionState session, GameField field) {
    final profile = session.profile;
    return profile != null &&
        profile.canRead &&
        profile.canWrite &&
        field.canRead &&
        field.canWrite &&
        field.minimumValue != null &&
        field.maximumValue != null &&
        session.selectedProcessId != null &&
        session.memoryBase != null &&
        session.detection?.confidence == GameIdentityConfidence.confirmed;
  }

  /// Reports whether a writable field also has a successful current read.
  static bool canEdit(TrainerSessionState session, GameField field) =>
      hasWriteTarget(session, field) &&
      session.readResults[field.id]?.succeeded == true;
}
