import 'package:ludava_sdk/features/game_catalog/domain/profiles/deadlocked_ps3_profile.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Property profile behaves correctly', () {
    test(
      'Property profile exposes the observed Deadlocked identity and verified Bolts field',
      () {
        final profile = DeadlockedPs3Profile.profile;
        final field = profile.findField('bolts');

        expect(DeadlockedPs3Profile.id, 'deadlocked-ps3');
        expect(profile.id, DeadlockedPs3Profile.id);
        expect(profile.gameName, 'Ratchet: Deadlocked');
        expect(profile.buildId, 'NPUA80646');
        expect(profile.executable, 'EBOOT.BIN');
        expect(
          profile.executableHash,
          'PPU-c44d700265e50dfe49054c1703f8fea668cc33b9',
        );
        expect(profile.readStatus, VerificationStatus.verified);
        expect(profile.writeStatus, VerificationStatus.verified);
        expect(profile.canRead, isTrue);
        expect(profile.canWrite, isTrue);
        expect(profile.fields, hasLength(1));
        expect(field?.id, 'bolts');
        expect(field?.name, 'Bolts');
        expect(field?.guestOffset, 0x009c32e8);
        expect(field?.valueType, MemoryValueType.unsigned32);
        expect(field?.byteOrder, ByteOrder.big);
        expect(field?.readStatus, VerificationStatus.verified);
        expect(field?.writeStatus, VerificationStatus.verified);
        expect(field?.minimumValue, 0);
        expect(field?.maximumValue, 0xffffffff);
        expect(field?.canRead, isTrue);
        expect(field?.canWrite, isTrue);
      },
    );

    test('Property profile keeps its field map immutable', () {
      final profile = DeadlockedPs3Profile.profile;
      final field = profile.findField('bolts')!;

      expect(() => profile.fields['other'] = field, throwsUnsupportedError);
    });
  });
}
