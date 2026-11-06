import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc1_collection_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc3_collection_profile.dart';

/// Registers the researched Collection game profiles for shared memory access.
abstract final class GameProfileCatalog {
  static final Map<String, GameProfile> _profiles = Map.unmodifiable({
    Rc1CollectionProfile.id: Rc1CollectionProfile.profile,
    Rc2CollectionProfile.id: Rc2CollectionProfile.profile,
    Rc3CollectionProfile.id: Rc3CollectionProfile.profile,
  });

  /// Profiles registered for command selection in Collection game order.
  static Iterable<GameProfile> get profiles => _profiles.values;

  /// Finds a registered profile by [profileId].
  static GameProfile? find(String profileId) => _profiles[profileId];
}
