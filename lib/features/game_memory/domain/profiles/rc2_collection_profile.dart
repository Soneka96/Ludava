import 'package:ludava/features/game_memory/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_profile.entity.dart';
import 'package:ludava/shared/constants/app_constants.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Defines the experimental Ratchet & Clank 2 Collection [GameProfile].
abstract final class Rc2CollectionProfile {
  /// Profile identifier used by the CLI.
  static const String id = 'rc2-collection';

  /// PPU hash measured in RPCS3 0.0.43-20565-eee3f0f7.
  static const String executableHash =
      'PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9';

  /// Experimental profile with a PPU hash measured in the owner-tested build.
  static final GameProfile profile = GameProfile(
    id: id,
    gameName: 'Ratchet & Clank 2',
    buildId: 'BCUS98282',
    executable: 'RC2.ppu.self',
    executableHash: executableHash,
    readStatus: VerificationStatus.experimental,
    writeStatus: VerificationStatus.researchConfirmed,
    fields: {
      'bolts': GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x01329e80,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus: VerificationStatus.experimental,
        writeStatus: VerificationStatus.researchConfirmed,
        minimumValue: 0,
        maximumValue: GameMemoryConstants.maxUnsigned32,
      ),
    },
  );
}
