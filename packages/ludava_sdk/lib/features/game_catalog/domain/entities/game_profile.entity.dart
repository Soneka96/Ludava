import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';

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

  /// Fields mapped for this profile, keyed by their stable identifier.
  final Map<String, GameField> fields;

  GameProfile._({
    required this.id,
    required this.gameName,
    required this.buildId,
    required this.executable,
    required this.executableHash,
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
      fields: Map.unmodifiable(fields),
    );
  }

  /// Finds a field by [fieldId].
  GameField? findField(String fieldId) => fields[fieldId];
}
