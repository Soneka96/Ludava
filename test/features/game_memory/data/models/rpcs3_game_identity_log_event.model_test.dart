import 'package:ludava/features/game_memory/data/models/rpcs3_game_identity_log_event.model.dart';
import 'package:test/test.dart';

void main() {
  group('Class Rpcs3GameIdentityLogEvent construction', () {
    test(
      'Class Rpcs3GameIdentityLogEvent initializes executable load evidence',
      () {
        const event = Rpcs3GameIdentityLogEvent(
          title: 'Ratchet & Clank Collection',
          titleId: 'BCUS98282',
          bootPath: '/dev_bdvd/PS3_GAME/USRDIR/RC2.ppu.self',
          executable: 'RC2.ppu.self',
          executableHash: 'PPU-measured-hash',
        );

        expect(event.title, 'Ratchet & Clank Collection');
        expect(event.titleId, 'BCUS98282');
        expect(event.bootPath, '/dev_bdvd/PS3_GAME/USRDIR/RC2.ppu.self');
        expect(event.executable, 'RC2.ppu.self');
        expect(event.executableHash, 'PPU-measured-hash');
        expect(event.processFinished, isFalse);
        expect(event.nextExecutable, isNull);
      },
    );

    test(
      'Class Rpcs3GameIdentityLogEvent initializes a process finish transition',
      () {
        const event = Rpcs3GameIdentityLogEvent(
          processFinished: true,
          nextExecutable: 'RC3.ppu.self',
        );

        expect(event.processFinished, isTrue);
        expect(event.nextExecutable, 'RC3.ppu.self');
        expect(event.executableHash, isNull);
      },
    );
  });
}
