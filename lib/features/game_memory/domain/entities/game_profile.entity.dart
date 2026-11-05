import 'package:ludava/features/game_memory/domain/entities/game_field.entity.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Describes one game build and the [GameField] values mapped for it.
class GameProfile {
  /// Stable profile identifier used by commands and the profile catalog.
  final String id;

  /// Display name of the game.
  final String gameName;

  /// Exact edition or build identifier.
  final String buildId;

  /// Expected executable name when known.
  final String executable;

  /// Measured RPCS3 PPU executable hash required for automatic matching.
  final String? executableHash;

  /// Evidence status for reading this build from [VerificationStatus].
  final VerificationStatus readStatus;

  /// Evidence status for writing this build from [VerificationStatus].
  final VerificationStatus writeStatus;

  /// Fields mapped for this profile, keyed by their stable identifier.
  final Map<String, GameField> fields;

  GameProfile._({
    required this.id,
    required this.gameName,
    required this.buildId,
    required this.executable,
    required this.executableHash,
    required this.readStatus,
    required this.writeStatus,
    required this.fields,
  });

  /// Creates a profile and takes an immutable snapshot of [fields].
  ///
  /// Each map key must match its [GameField.id].
  factory GameProfile({
    required String id,
    required String gameName,
    required String buildId,
    required String executable,
    String? executableHash,
    required VerificationStatus readStatus,
    VerificationStatus writeStatus = VerificationStatus.none,
    Map<String, GameField> fields = const {},
  }) {
    if (fields.entries.any((entry) => entry.key != entry.value.id)) {
      throw ArgumentError.value(
        fields,
        'fields',
        'map keys must match field identifiers',
      );
    }
    return GameProfile._(
      id: id,
      gameName: gameName,
      buildId: buildId,
      executable: executable,
      executableHash: executableHash,
      readStatus: readStatus,
      writeStatus: writeStatus,
      fields: Map.unmodifiable(fields),
    );
  }

  /// Whether recorded evidence permits reading this profile.
  bool get canRead =>
      readStatus == VerificationStatus.experimental ||
      readStatus == VerificationStatus.verified;

  /// Whether recorded evidence permits writing this profile.
  bool get canWrite =>
      writeStatus == VerificationStatus.researchConfirmed ||
      writeStatus == VerificationStatus.verified;

  /// Finds a field by [fieldId].
  GameField? findField(String fieldId) => fields[fieldId];
}
