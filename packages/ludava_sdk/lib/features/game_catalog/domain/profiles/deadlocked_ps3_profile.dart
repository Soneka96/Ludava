import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/shared/constants/app_constants.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Defines the standalone Ratchet: Deadlocked PS3 [GameProfile].
abstract final class DeadlockedPs3Profile {
  /// Stable profile identifier used by commands and the profile catalog.
  static const String id = 'deadlocked-ps3';

  /// PPU hash observed in RPCS3 0.0.43-20567-6a59542f.
  static const String executableHash =
      'PPU-c44d700265e50dfe49054c1703f8fea668cc33b9';

  /// Bolts mapping for the measured live game build.
  static final GameProfile profile = GameProfile(
    id: id,
    gameName: 'Ratchet: Deadlocked',
    buildId: 'NPUA80646',
    executable: 'EBOOT.BIN',
    executableHash: executableHash,
    fields: {
      'bolts': GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x009c32e8,
        valueType: MemoryValueType.unsigned32,
        byteOrder: ByteOrder.big,
        minimumValue: 0,
        maximumValue: GameMemoryConstants.maxUnsigned32,
      ),
    },
  );
}
