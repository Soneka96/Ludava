import 'package:ludava/features/game_memory/domain/usecases/params/resolve_game_profile.params.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class ResolveGameProfileParams construction', () {
    test('Class ResolveGameProfileParams initializes runtime evidence', () {
      const params = ResolveGameProfileParams(
        processId: 42,
        titleId: 'BCUS98282',
        gameTitle: 'Ratchet & Clank Collection',
        executable: 'RC2.ppu.self',
        confidence: GameIdentityConfidence.confirmed,
        evidenceDescription: 'Current RPCS3 identity evidence.',
      );

      expect(params.processId, 42);
      expect(params.titleId, 'BCUS98282');
      expect(params.gameTitle, 'Ratchet & Clank Collection');
      expect(params.executable, 'RC2.ppu.self');
      expect(params.confidence, GameIdentityConfidence.confirmed);
      expect(params.manualProfileId, isNull);
      expect(params.evidenceDescription, 'Current RPCS3 identity evidence.');
    });
  });
}
