import 'package:ludava_sdk/features/game_catalog/domain/profiles/tools_of_destruction_bcus98127_profile.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Profile ToolsOfDestructionBcus98127Profile configuration', () {
    test(
      'Profile ToolsOfDestructionBcus98127Profile exposes the read-verified Bolts field',
      () {
        final profile = ToolsOfDestructionBcus98127Profile.profile;
        final field = profile.findField('bolts');

        expect(
          ToolsOfDestructionBcus98127Profile.id,
          'tools-of-destruction-bcus98127',
        );
        expect(profile.id, ToolsOfDestructionBcus98127Profile.id);
        expect(
          profile.gameName,
          'Ratchet & Clank Future: Tools of Destruction',
        );
        expect(profile.buildId, 'BCUS98127');
        expect(profile.executable, 'EBOOT.BIN');
        expect(
          profile.executableHash,
          'PPU-c14042df6304d3e420a9917e6f8e5fc05cc38b4c',
        );
        expect(profile.readStatus, VerificationStatus.verified);
        expect(profile.writeStatus, VerificationStatus.researchConfirmed);
        expect(profile.canRead, isTrue);
        expect(profile.canWrite, isTrue);
        expect(profile.fields, hasLength(1));
        expect(field?.id, 'bolts');
        expect(field?.name, 'Bolts');
        expect(field?.guestOffset, 0x101eff3c);
        expect(field?.valueType, MemoryValueType.unsigned32);
        expect(field?.byteOrder, ByteOrder.big);
        expect(field?.readStatus, VerificationStatus.verified);
        expect(field?.writeStatus, VerificationStatus.researchConfirmed);
        expect(field?.minimumValue, 0);
        expect(field?.maximumValue, 0xffffffff);
        expect(field?.canRead, isTrue);
        expect(field?.canWrite, isTrue);
      },
    );
  });
}
