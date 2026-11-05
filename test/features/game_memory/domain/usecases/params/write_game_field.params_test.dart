import 'package:ludava/features/game_memory/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava/features/game_memory/domain/usecases/params/write_game_field.params.dart';
import 'package:test/test.dart';

void main() {
  group('Class WriteGameFieldParams construction', () {
    test('Class WriteGameFieldParams initializes request and gates', () {
      final params = WriteGameFieldParams(
        profile: Rc2CollectionProfile.profile,
        fieldId: 'bolts',
        memoryBase: 0x300000000,
        value: 42,
        confirmed: true,
      );

      expect(params.profile.id, 'rc2-collection');
      expect(params.fieldId, 'bolts');
      expect(params.memoryBase, 0x300000000);
      expect(params.value, 42);
      expect(params.confirmed, isTrue);
    });
  });
}
