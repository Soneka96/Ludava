import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc1_collection_profile.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Profile Rc1CollectionProfile configuration', () {
    test('Profile Rc1CollectionProfile exposes the researched bolt field', () {
      final profile = Rc1CollectionProfile.profile;
      final field = profile.findField('bolts');

      expect(Rc1CollectionProfile.id, 'rc1-collection');
      expect(profile.id, Rc1CollectionProfile.id);
      expect(profile.gameName, 'Ratchet & Clank');
      expect(profile.buildId, 'BCUS98282');
      expect(profile.executable, 'RC1.ppu.self');
      expect(
        profile.executableHash,
        'PPU-3de6ba9344eb2079d5afda4552e831826af4bd09',
      );
      expect(profile.readStatus, VerificationStatus.experimental);
      expect(profile.writeStatus, VerificationStatus.researchConfirmed);
      expect(profile.canRead, isTrue);
      expect(profile.canWrite, isTrue);
      expect(profile.fields, hasLength(1));
      expect(field?.guestOffset, 0x009bc3a0);
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
