import 'package:ludava/features/game_memory/domain/profiles/game_profile_catalog.dart';
import 'package:ludava/features/game_memory/domain/profiles/rc2_collection_profile.dart';
import 'package:test/test.dart';

void main() {
  group('Method find behaves correctly', () {
    test('Method find returns the RC2 profile when its id is registered', () {
      final profile = GameProfileCatalog.find(Rc2CollectionProfile.id);

      expect(profile, same(Rc2CollectionProfile.profile));
    });

    test('Method find returns null when profile id is not registered', () {
      expect(GameProfileCatalog.find('unknown-game'), isNull);
    });
  });

  group('Property profiles behaves correctly', () {
    test('Property profiles exposes the registered profiles', () {
      expect(
          GameProfileCatalog.profiles, contains(Rc2CollectionProfile.profile));
      expect(GameProfileCatalog.profiles, hasLength(1));
    });
  });
}
