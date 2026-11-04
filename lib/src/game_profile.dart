import 'dart:typed_data';

enum CompatibilityStatus { experimental, unsupported }

enum MemoryValueType {
  unsigned32(4);

  const MemoryValueType(this.byteLength);

  final int byteLength;
}

class GameProfile {
  const GameProfile({
    required this.gameName,
    required this.collectionTitleId,
    required this.activeSubgame,
    required this.executable,
    required this.reportedInternalAppId,
    required this.boltGuestOffset,
    required this.boltType,
    required this.boltEndian,
    required this.compatibility,
  });

  final String gameName;
  final String collectionTitleId;
  final String activeSubgame;
  final String executable;
  final String reportedInternalAppId;
  final int boltGuestOffset;
  final MemoryValueType boltType;
  final Endian boltEndian;
  final CompatibilityStatus compatibility;

  bool get canReadExperimentally =>
      compatibility == CompatibilityStatus.experimental;

  bool get canWrite => false;
}

const rc2CollectionExperimentalProfile = GameProfile(
  gameName: 'Ratchet & Clank 2',
  collectionTitleId: 'BCUS98282',
  activeSubgame: 'Ratchet & Clank 2',
  executable: 'RC2.ppu.self',
  reportedInternalAppId: 'NPUA80644',
  boltGuestOffset: 0x01329e80,
  boltType: MemoryValueType.unsigned32,
  boltEndian: Endian.big,
  compatibility: CompatibilityStatus.experimental,
);
