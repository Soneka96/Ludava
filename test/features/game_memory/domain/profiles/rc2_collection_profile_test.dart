import 'package:ludava/features/game_memory/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Profile Rc2CollectionProfile configuration', () {
    test('Profile Rc2CollectionProfile exposes the experimental bolt field',
        () {
      final profile = Rc2CollectionProfile.profile;
      final field = profile.findField('bolts');

      expect(Rc2CollectionProfile.id, 'rc2-collection');
      expect(profile.id, Rc2CollectionProfile.id);
      expect(profile.gameName, 'Ratchet & Clank 2');
      expect(profile.buildId, 'BCUS98282');
      expect(profile.executable, 'RC2.ppu.self');
      expect(profile.readStatus, VerificationStatus.experimental);
      expect(profile.writeStatus, VerificationStatus.none);
      expect(profile.canRead, isTrue);
      expect(profile.canWrite, isFalse);
      expect(field?.guestOffset, 0x01329e80);
      expect(field?.valueType, MemoryValueType.unsigned32);
      expect(field?.byteOrder, ByteOrder.big);
      expect(field?.readStatus, VerificationStatus.experimental);
      expect(field?.canWrite, isFalse);
    });
  });
}
