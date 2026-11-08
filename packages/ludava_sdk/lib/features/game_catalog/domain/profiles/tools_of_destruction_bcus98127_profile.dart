import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Defines the read-verified Tools of Destruction BCUS98127 [GameProfile].
abstract final class ToolsOfDestructionBcus98127Profile {
  /// Stable profile identifier used by commands and the profile catalog.
  static const String id = 'tools-of-destruction-bcus98127';

  /// PPU hash observed in RPCS3 0.0.43-20573.
  static const String executableHash =
      'PPU-c14042df6304d3e420a9917e6f8e5fc05cc38b4c';

  /// Exposes the Bolts field verified by a Ludava read for the observed build.
  static final GameProfile profile = GameProfile(
    id: id,
    gameName: 'Ratchet & Clank Future: Tools of Destruction',
    buildId: 'BCUS98127',
    executable: 'EBOOT.BIN',
    executableHash: executableHash,
    readStatus: VerificationStatus.verified,
    writeStatus: VerificationStatus.researchConfirmed,
    fields: {
      'bolts': GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x101eff3c,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus: VerificationStatus.verified,
        writeStatus: VerificationStatus.researchConfirmed,
        minimumValue: 0,
        maximumValue: GameMemoryConstants.maxUnsigned32,
      ),
    },
  );
}
