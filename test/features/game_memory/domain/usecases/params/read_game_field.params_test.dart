import 'package:ludava/features/game_catalog/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava/features/game_memory/domain/usecases/params/read_game_field.params.dart';
import 'package:test/test.dart';

void main() {
  group('Class ReadGameFieldParams construction', () {
    test('Class ReadGameFieldParams initializes profile and selection', () {
      final params = ReadGameFieldParams(
        profile: Rc2CollectionProfile.profile,
        fieldId: 'bolts',
        memoryBase: 0x300000000,
      );

      expect(params.profile.id, 'rc2-collection');
      expect(params.fieldId, 'bolts');
      expect(params.memoryBase, 0x300000000);
    });
  });
}
