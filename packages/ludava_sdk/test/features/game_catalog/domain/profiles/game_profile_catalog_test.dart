import 'package:ludava_sdk/features/game_catalog/domain/profiles/game_profile_catalog.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc1_collection_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc3_collection_profile.dart';
import 'package:test/test.dart';

void main() {
  group('Method find() behaves correctly', () {
    test('Method find() returns each registered Collection game profile', () {
      expect(
        GameProfileCatalog.find(Rc1CollectionProfile.id),
        same(Rc1CollectionProfile.profile),
      );
      expect(
        GameProfileCatalog.find(Rc2CollectionProfile.id),
        same(Rc2CollectionProfile.profile),
      );
      expect(
        GameProfileCatalog.find(Rc3CollectionProfile.id),
        same(Rc3CollectionProfile.profile),
      );
    });

    test('Method find() returns null when profile id is not registered', () {
      expect(GameProfileCatalog.find('unknown-game'), isNull);
    });
  });

  group('Property profiles behaves correctly', () {
    test('Property profiles exposes all three Collection games in order', () {
      expect(
        GameProfileCatalog.profiles.map((profile) => profile.id).toList(),
        [
          Rc1CollectionProfile.id,
          Rc2CollectionProfile.id,
          Rc3CollectionProfile.id,
        ],
      );
    });
  });
}
