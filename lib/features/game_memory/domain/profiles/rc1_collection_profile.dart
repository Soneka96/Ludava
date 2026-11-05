import 'package:ludava/features/game_memory/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_profile.entity.dart';
import 'package:ludava/shared/constants/app_constants.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Defines the Ratchet & Clank 1 PS3 Collection bolt [GameProfile].
abstract final class Rc1CollectionProfile {
  /// Identifier used by interactive and diagnostic commands.
  static const String id = 'rc1-collection';

  /// Owner-confirmed RatchetHax bolt mapping; Ludava live validation is pending.
  ///
  /// The Collection shares title ID BCUS98282 across three games. Its active
  /// subgame and exact executable build are not automatically identified.
  static final GameProfile profile = GameProfile(
    id: id,
    gameName: 'Ratchet & Clank',
    buildId: 'BCUS98282',
    executable: '', // Exact active PPU SELF was not established by research.
    readStatus: VerificationStatus.experimental,
    writeStatus: VerificationStatus.researchConfirmed,
    fields: {
      'bolts': GameField(
        id: 'bolts',
        name: 'Bolts',
        guestOffset: 0x009bc3a0,
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
