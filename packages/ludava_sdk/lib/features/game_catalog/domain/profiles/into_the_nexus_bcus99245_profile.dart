import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Defines the US PS3 Into the Nexus profile observed in RPCS3.
abstract final class IntoTheNexusBcus99245Profile {
  /// Stable profile identifier used by commands and the profile catalog.
  static const String id = 'into-the-nexus-bcus99245';

  /// PPU hash observed for the active EBOOT.BIN in RPCS3 0.0.43-20607.
  static const String executableHash =
      'PPU-8cb9b75e489362559db2d8a2c65cd93ebe2e4037';

  /// Exposes the Bolts counter for this executable.
  static final GameProfile profile = GameProfile(
    id: id,
    gameName: 'Ratchet & Clank: Into the Nexus',
    buildId: 'BCUS99245',
    executable: 'EBOOT.BIN',
    executableHash: executableHash,
    readStatus: VerificationStatus.verified,
    writeStatus: VerificationStatus.researchConfirmed,
    fields: {
      'bolts': GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x4aefbc3c,
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
