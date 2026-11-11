import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Defines the live-tested Ratchet & Clank: A Crack in Time US PS3 profile.
abstract final class ACrackInTimeBcus98124Profile {
  /// Stable profile identifier used by commands and the profile catalog.
  static const String id = 'a-crack-in-time-bcus98124';

  /// PPU hash listed for BCUS98124 version 01.00 in the RPCS3 patch database.
  static const String executableHash =
      'PPU-0997e35d2b6738f5cecfda1d76380acca0828365';

  /// Exposes the live-tested Bolts field for this build.
  static final GameProfile profile = GameProfile(
    id: id,
    gameName: 'Ratchet & Clank Future: A Crack in Time',
    buildId: 'BCUS98124',
    executable: 'EBOOT.BIN',
    executableHash: executableHash,
    readStatus: VerificationStatus.verified,
    writeStatus: VerificationStatus.verified,
    fields: {
      'bolts': GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x00e24e68,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        readStatus: VerificationStatus.verified,
        writeStatus: VerificationStatus.verified,
        minimumValue: 0,
        maximumValue: GameMemoryConstants.maxUnsigned32,
      ),
    },
  );
}
