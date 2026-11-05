import 'package:ludava/features/game_memory/domain/profiles/rc1_collection_profile.dart';
import 'package:ludava/features/game_memory/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava/features/game_memory/domain/profiles/rc3_collection_profile.dart';
import 'package:ludava/features/game_memory/domain/usecases/params/resolve_game_profile.params.dart';
import 'package:ludava/features/game_memory/domain/usecases/resolve_game_profile.usecase.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Method execute() behaves correctly', () {
    test('Method execute() matches RC2 from a unique current executable', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: 'BCUS98282',
          executable: 'RC2.ppu.self',
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.profile, same(Rc2CollectionProfile.profile));
      expect(result.confidence, GameIdentityConfidence.confirmed);
      expect(result.availableFields.map((field) => field.id), ['bolts']);
    });

    test('Method execute() leaves the shared Collection ID ambiguous', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: 'BCUS98282',
          executable: null,
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.uncertain);
      expect(result.gameTitle, 'Ratchet & Clank Collection');
    });

    test(
      'Method execute() keeps RC1 ambiguous without an established executable',
      () {
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: 'BCUS98282',
            executable: null,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
        expect(Rc1CollectionProfile.profile.executable, isEmpty);
      },
    );

    test(
      'Method execute() keeps RC3 ambiguous without an established executable',
      () {
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: 'BCUS98282',
            executable: null,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
        expect(Rc3CollectionProfile.profile.executable, isEmpty);
      },
    );

    test(
      'Method execute() reports a confirmed unknown title as unsupported',
      () {
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: 'UNKNOWN123',
            gameTitle: 'Unregistered game',
            executable: 'GAME.self',
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.unsupportedGame);
        expect(result.profile, isNull);
        expect(result.gameTitle, 'Unregistered game');
        expect(result.availableFields, isEmpty);
      },
    );

    test('Method execute() does not match uncertain identity signals', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: 'BCUS98282',
          executable: 'RC2.ppu.self',
          confidence: GameIdentityConfidence.uncertain,
        ),
      );

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.uncertain);
    });

    test('Method execute() leaves missing or blank title IDs ambiguous', () {
      for (final titleId in [null, '  ']) {
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: titleId,
            executable: 'RC2.ppu.self',
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
      }
    });

    test('Method execute() normalizes confirmed identity values', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: ' bcus98282 ',
          executable: ' rc2.PPU.SELF ',
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.profile, same(Rc2CollectionProfile.profile));
    });

    test('Method execute() records a deliberate manual profile selection', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          confidence: GameIdentityConfidence.manuallySelected,
          manualProfileId: Rc3CollectionProfile.id,
        ),
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.profile, same(Rc3CollectionProfile.profile));
      expect(result.confidence, GameIdentityConfidence.manuallySelected);
      expect(result.gameTitle, 'Ratchet & Clank 3');
    });

    test('Method execute() rejects an unknown manual profile selection', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          confidence: GameIdentityConfidence.manuallySelected,
          manualProfileId: 'not-registered',
        ),
      );

      expect(result.status, GameDetectionStatus.failed);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.manuallySelected);
    });

    test('Method execute() rejects a missing manual profile selection', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(confidence: GameIdentityConfidence.manuallySelected),
      );

      expect(result.status, GameDetectionStatus.failed);
      expect(result.profile, isNull);
    });

    test('Method execute() rejects invalid process identifiers', () {
      for (final processId in [0, -1]) {
        final result = ResolveGameProfileUseCase().execute(
          _params(
            processId: processId,
            titleId: 'BCUS98282',
            executable: 'RC2.ppu.self',
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.failed);
        expect(result.processId, isNull);
        expect(result.profile, isNull);
      }
    });
  });
}

ResolveGameProfileParams _params({
  int? processId = 42,
  String? titleId = 'BCUS98282',
  String? gameTitle = 'Ratchet & Clank Collection',
  String? executable,
  GameIdentityConfidence confidence = GameIdentityConfidence.confirmed,
  String? manualProfileId,
}) => ResolveGameProfileParams(
  processId: processId,
  titleId: titleId,
  gameTitle: gameTitle,
  executable: executable,
  confidence: confidence,
  manualProfileId: manualProfileId,
  evidenceDescription: 'Current RPCS3 identity evidence.',
);
