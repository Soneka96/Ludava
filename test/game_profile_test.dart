import 'dart:typed_data';

import 'package:ludava/src/game_profile.dart';
import 'package:test/test.dart';

void main() {
  test('describes the RC2 Collection bolt field as experimental and read-only',
      () {
    final profile = rc2CollectionExperimentalProfile;

    expect(profile.collectionTitleId, 'BCUS98282');
    expect(profile.activeSubgame, 'Ratchet & Clank 2');
    expect(profile.executable, 'RC2.ppu.self');
    expect(profile.reportedInternalAppId, 'NPUA80644');
    expect(profile.boltGuestOffset, 0x01329e80);
    expect(profile.boltType, MemoryValueType.unsigned32);
    expect(profile.boltType.byteLength, 4);
    expect(profile.boltEndian, Endian.big);
    expect(profile.compatibility, CompatibilityStatus.experimental);
    expect(profile.canReadExperimentally, isTrue);
    expect(profile.canWrite, isFalse);
  });

  test('does not treat an unsupported profile as experimentally readable', () {
    const profile = GameProfile(
      gameName: 'Unknown game',
      collectionTitleId: 'UNKNOWN',
      activeSubgame: 'Unknown',
      executable: 'unknown.self',
      reportedInternalAppId: 'UNKNOWN',
      boltGuestOffset: 0,
      boltType: MemoryValueType.unsigned32,
      boltEndian: Endian.big,
      compatibility: CompatibilityStatus.unsupported,
    );

    expect(profile.canReadExperimentally, isFalse);
    expect(profile.canWrite, isFalse);
  });
}
