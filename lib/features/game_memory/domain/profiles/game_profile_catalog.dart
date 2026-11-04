import 'package:ludava/features/game_memory/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_memory/domain/profiles/rc2_collection_profile.dart';

/// Registers the game profiles supported by the shared memory reader.
abstract final class GameProfileCatalog {
  static final Map<String, GameProfile> _profiles = Map.unmodifiable({
    Rc2CollectionProfile.id: Rc2CollectionProfile.profile,
  });

  /// Profiles registered for command selection.
  static Iterable<GameProfile> get profiles => _profiles.values;

  /// Finds a registered profile by [profileId].
  static GameProfile? find(String profileId) => _profiles[profileId];
}
