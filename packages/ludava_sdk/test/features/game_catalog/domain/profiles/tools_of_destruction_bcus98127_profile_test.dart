import 'package:ludava_sdk/features/game_catalog/domain/profiles/tools_of_destruction_bcus98127_profile.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Profile ToolsOfDestructionBcus98127Profile special mapping', () {
    test(
      'Profile ToolsOfDestructionBcus98127Profile preserves both researched fields',
      () {
        final profile = ToolsOfDestructionBcus98127Profile.profile;
        final bolts = profile.findField('bolts');
        final raritanium = profile.findField('raritanium');

        expect(profile.id, ToolsOfDestructionBcus98127Profile.id);
        expect(profile.buildId, 'BCUS98127');
        expect(profile.executable, 'EBOOT.BIN');
        expect(
          profile.executableHash,
          'PPU-c14042df6304d3e420a9917e6f8e5fc05cc38b4c',
        );
        expect(profile.readStatus, VerificationStatus.verified);
        expect(profile.writeStatus, VerificationStatus.researchConfirmed);
        expect(profile.fields.keys, containsAll(['bolts', 'raritanium']));

        expect(bolts?.name, 'Bolts');
        expect(bolts?.guestOffset, 0x101eff3c);
        expect(bolts?.valueType, MemoryValueType.unsigned32);
        expect(bolts?.byteOrder, ByteOrder.big);
        expect(bolts?.readStatus, VerificationStatus.verified);
        expect(bolts?.writeStatus, VerificationStatus.researchConfirmed);
        expect(bolts?.minimumValue, 0);
        expect(bolts?.maximumValue, GameMemoryConstants.maxUnsigned32);
        expect(raritanium?.name, 'Raritanium');
        expect(raritanium?.guestOffset, 0x101eff40);
        expect(raritanium?.valueType, MemoryValueType.unsigned32);
        expect(raritanium?.byteOrder, ByteOrder.big);
        expect(raritanium?.readStatus, VerificationStatus.verified);
        expect(raritanium?.writeStatus, VerificationStatus.researchConfirmed);
        expect(raritanium?.minimumValue, 0);
        expect(raritanium?.maximumValue, GameMemoryConstants.maxUnsigned32);
      },
    );
  });
}
