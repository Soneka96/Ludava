import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Defines the Ratchet & Clank 3 PS3 Collection bolt [GameProfile].
abstract final class Rc3CollectionProfile {
  /// Identifier used by interactive and diagnostic commands.
  static const String id = 'rc3-collection';

  /// PPU hash measured in RPCS3 0.0.43-20565-eee3f0f7.
  static const String executableHash =
      'PPU-56a8d02d516d82e5c1d39a4f7b3c9f83e350ab61';

  /// Owner-confirmed bolt mapping and measured Collection executable identity.
  static final GameProfile profile = GameProfile(
    id: id,
    gameName: 'Ratchet & Clank 3',
    buildId: 'BCUS98282',
    executable: 'RC3.ppu.self',
    executableHash: executableHash,
    fields: {
      'bolts': GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x00c1edac,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        minimumValue: 0,
        maximumValue: GameMemoryConstants.maxUnsigned32,
      ),
    },
  );
}
