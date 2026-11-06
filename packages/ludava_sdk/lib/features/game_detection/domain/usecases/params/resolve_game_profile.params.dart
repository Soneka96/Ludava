import 'package:ludava_sdk/shared/constants/enums.dart';

/// Supplies runtime identity evidence or a deliberate profile selection.
class ResolveGameProfileParams {
  /// Process identifier associated with the evidence, when available.
  final int? processId;

  /// Stable title identifier observed for the active game.
  final String? titleId;

  /// Display title observed for the active game.
  final String? gameTitle;

  /// Active executable name observed for the game.
  final String? executable;

  /// Measured PPU executable hash observed for the game.
  final String? executableHash;

  /// Confidence assigned by the identity source.
  final GameIdentityConfidence confidence;

  /// Profile identifier supplied only for deliberate manual selection.
  final String? manualProfileId;

  /// Source and evidence description for diagnostics.
  final String evidenceDescription;

  /// Creates profile-resolution input from runtime or manual evidence.
  const ResolveGameProfileParams({
    this.processId,
    this.titleId,
    this.gameTitle,
    this.executable,
    this.executableHash,
    required this.confidence,
    this.manualProfileId,
    required this.evidenceDescription,
  });
}
