import 'package:ludava/features/game_memory/domain/profiles/rc3_collection_profile.dart';
import 'package:ludava/shared/constants/enums.dart';
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
      expect(profile.executable, isEmpty);
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
