import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc3_collection_profile.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Profile Rc3CollectionProfile configuration', () {
    test('Profile Rc3CollectionProfile exposes the researched bolt field', () {
      final profile = Rc3CollectionProfile.profile;
      final field = profile.findField('bolts');

      expect(Rc3CollectionProfile.id, 'rc3-collection');
      expect(profile.id, Rc3CollectionProfile.id);
      expect(profile.gameName, 'Ratchet & Clank 3');
      expect(profile.buildId, 'BCUS98282');
      expect(profile.executable, 'RC3.ppu.self');
      expect(
        profile.executableHash,
        'PPU-56a8d02d516d82e5c1d39a4f7b3c9f83e350ab61',
      );
      expect(profile.readStatus, VerificationStatus.experimental);
      expect(profile.writeStatus, VerificationStatus.researchConfirmed);
      expect(profile.canRead, isTrue);
      expect(profile.canWrite, isTrue);
      expect(profile.fields, hasLength(1));
      expect(field?.guestOffset, 0x00c1edac);
      expect(field?.valueType, MemoryValueType.unsigned32);
      expect(field?.byteOrder, ByteOrder.big);
      expect(field?.readStatus, VerificationStatus.experimental);
      expect(field?.writeStatus, VerificationStatus.researchConfirmed);
      expect(field?.minimumValue, 0);
      expect(field?.maximumValue, 0xffffffff);
      expect(field?.canRead, isTrue);
      expect(field?.canWrite, isTrue);
    });
  });
}
