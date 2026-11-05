import 'package:ludava/features/game_memory/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_profile.entity.dart';
import 'package:ludava/shared/constants/app_constants.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Defines the experimental Ratchet & Clank 2 Collection [GameProfile].
abstract final class Rc2CollectionProfile {
  /// Profile identifier used by the CLI.
  static const String id = 'rc2-collection';

  /// Experimental profile; live RC2 testing occurred, but exact-build
  /// compatibility is unknown.
  static final GameProfile profile = GameProfile(
    id: id,
    gameName: 'Ratchet & Clank 2',
    buildId: 'BCUS98282',
    executable: 'RC2.ppu.self',
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
