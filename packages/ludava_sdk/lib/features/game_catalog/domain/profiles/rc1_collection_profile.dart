import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Defines the Ratchet & Clank 1 PS3 Collection bolt [GameProfile].
abstract final class Rc1CollectionProfile {
  /// Identifier used by interactive and diagnostic commands.
  static const String id = 'rc1-collection';

  /// PPU hash measured in RPCS3 0.0.43-20565-eee3f0f7.
  static const String executableHash =
      'PPU-3de6ba9344eb2079d5afda4552e831826af4bd09';

  /// Bolt mapping and measured Collection executable identity.
  static final GameProfile profile = GameProfile(
    id: id,
    gameName: 'Ratchet & Clank',
    buildId: 'BCUS98282',
    executable: 'RC1.ppu.self',
    executableHash: executableHash,
    fields: {
      'bolts': GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x009bc3a0,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        minimumValue: 0,
        maximumValue: GameMemoryConstants.maxUnsigned32,
      ),
    },
  );
}
