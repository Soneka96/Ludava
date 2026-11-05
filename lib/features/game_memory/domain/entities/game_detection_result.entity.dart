import 'package:ludava/features/game_memory/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_profile.entity.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Describes RPCS3 game detection and any matching Ludava profile.
class GameDetectionResult {
  /// Detection outcome, kept separate from runtime memory availability.
  final GameDetectionStatus status;

  /// Process identifier when a specific RPCS3 process was checked.
  final int? processId;

  /// Identified game's stable title identifier when available.
  final String? titleId;

  /// Identified game's display title when available.
  final String? gameTitle;

  /// Active executable name when available.
  final String? executable;

  /// Evidence confidence, including whether a profile was chosen manually.
  final GameIdentityConfidence confidence;

  /// Matching profile, or `null` when no supported profile was selected.
  final GameProfile? profile;

  /// Short source/evidence description suitable for diagnostics.
  final String evidenceDescription;

  GameDetectionResult._({
    required this.status,
    required this.processId,
    required this.titleId,
    required this.gameTitle,
    required this.executable,
    required this.confidence,
    required this.profile,
    required this.evidenceDescription,
  });

  /// Creates a detection result and validates its profile/process pairing.
  factory GameDetectionResult({
    required GameDetectionStatus status,
    int? processId,
    String? titleId,
    String? gameTitle,
    String? executable,
    required GameIdentityConfidence confidence,
    GameProfile? profile,
    required String evidenceDescription,
  }) {
    if (processId != null && processId <= 0) {
      throw ArgumentError.value(processId, 'processId', 'must be positive');
    }
    if ((status == GameDetectionStatus.supportedGame) != (profile != null)) {
      throw ArgumentError.value(
        profile,
        'profile',
        'must be supplied exactly when a supported game was matched',
      );
    }
    if (status == GameDetectionStatus.supportedGame &&
        confidence != GameIdentityConfidence.confirmed &&
        confidence != GameIdentityConfidence.manuallySelected) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'a supported profile requires confirmed or manual identity',
      );
    }
    return GameDetectionResult._(
      status: status,
      processId: processId,
      titleId: titleId,
      gameTitle: gameTitle,
      executable: executable,
      confidence: confidence,
      profile: profile,
      evidenceDescription: evidenceDescription,
    );
  }

  /// Fields described by the selected profile, or an empty iterable.
  Iterable<GameField> get availableFields =>
      profile?.fields.values ?? const <GameField>[];
}
