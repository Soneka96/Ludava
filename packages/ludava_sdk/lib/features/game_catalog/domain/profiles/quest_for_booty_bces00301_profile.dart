import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Defines the live-tested Ratchet & Clank: Quest for Booty PS3 profile.
abstract final class QuestForBootyBces00301Profile {
  /// Stable profile identifier used by commands and the profile catalog.
  static const String id = 'quest-for-booty-bces00301';

  /// PPU hash listed for BCES00301 in the RPCS3 community patch database.
  static const String executableHash =
      'PPU-f07f7086588a4ea86a28bd768f0cbe710f5b813b';

  /// Exposes the live-tested Bolts field for this build.
  static final GameProfile profile = GameProfile(
    id: id,
    gameName: 'Ratchet & Clank Future: Quest for Booty',
    buildId: 'BCES00301',
    executable: 'EBOOT.BIN',
    executableHash: executableHash,
    fields: {
      'bolts': GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x009ceae4,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        minimumValue: 0,
        maximumValue: GameMemoryConstants.maxUnsigned32,
      ),
    },
  );
}
