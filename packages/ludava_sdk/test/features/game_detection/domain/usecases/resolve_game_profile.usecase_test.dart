import 'package:ludava_sdk/features/game_catalog/domain/profiles/deadlocked_ps3_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc1_collection_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc3_collection_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/tools_of_destruction_bcus98127_profile.dart';
import 'package:ludava_sdk/features/game_detection/domain/usecases/params/resolve_game_profile.params.dart';
import 'package:ludava_sdk/features/game_detection/domain/usecases/resolve_game_profile.usecase.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Method execute() behaves correctly', () {
    test(
      'Method execute() matches Deadlocked from its observed standalone identity',
      () {
        final profile = DeadlockedPs3Profile.profile;
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: profile.buildId,
            gameTitle: profile.gameName,
            executable: profile.executable,
            executableHash: profile.executableHash,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.supportedGame);
        expect(result.profile, same(profile));
        expect(result.confidence, GameIdentityConfidence.confirmed);
        expect(result.availableFields.map((field) => field.id), ['bolts']);
      },
    );

    test('Method execute() normalizes the measured Deadlocked identity', () {
      final profile = DeadlockedPs3Profile.profile;
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: ' npua80646 ',
          executable: ' eboot.bin ',
          executableHash: ' ${profile.executableHash!.toLowerCase()} ',
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.profile, same(profile));
      expect(result.confidence, GameIdentityConfidence.confirmed);
    });

    test(
      'Method execute() rejects Deadlocked identity with the Collection title ID',
      () {
        final profile = DeadlockedPs3Profile.profile;
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: 'BCUS98282',
            executable: profile.executable,
            executableHash: profile.executableHash,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
      },
    );

    test(
      'Method execute() rejects Deadlocked when its executable name differs',
      () {
        final profile = DeadlockedPs3Profile.profile;
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: profile.buildId,
            executable: 'RC2.ppu.self',
            executableHash: profile.executableHash,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
      },
    );

    test(
      'Method execute() keeps Deadlocked ambiguous without its executable name',
      () {
        final profile = DeadlockedPs3Profile.profile;
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: profile.buildId,
            executable: null,
            executableHash: profile.executableHash,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
      },
    );

    test('Method execute() rejects Deadlocked when its PPU hash differs', () {
      final profile = DeadlockedPs3Profile.profile;
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: profile.buildId,
          executable: profile.executable,
          executableHash: Rc2CollectionProfile.profile.executableHash,
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.uncertain);
    });

    test(
      'Method execute() leaves Deadlocked ambiguous when its PPU hash is missing',
      () {
        final profile = DeadlockedPs3Profile.profile;
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: profile.buildId,
            executable: profile.executable,
            executableHash: null,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
      },
    );

    test('Method execute() matches RC2 from its measured PPU hash', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: 'BCUS98282',
          executable: 'RC2.ppu.self',
          executableHash: Rc2CollectionProfile.profile.executableHash,
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.profile, same(Rc2CollectionProfile.profile));
      expect(result.confidence, GameIdentityConfidence.confirmed);
      expect(
        result.executableHash,
        Rc2CollectionProfile.profile.executableHash,
      );
      expect(result.availableFields.map((field) => field.id), ['bolts']);
    });

    test(
      'Method execute() matches Tools of Destruction from its measured PPU hash',
      () {
        final profile = ToolsOfDestructionBcus98127Profile.profile;
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: profile.buildId,
            executable: profile.executable,
            executableHash: profile.executableHash,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.supportedGame);
        expect(result.profile, same(profile));
        expect(result.confidence, GameIdentityConfidence.confirmed);
        expect(result.availableFields.map((field) => field.id), [
          'bolts',
          'raritanium',
        ]);
      },
    );

    test(
      'Method execute() rejects Tools of Destruction with another PPU hash',
      () {
        final profile = ToolsOfDestructionBcus98127Profile.profile;
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: profile.buildId,
            executable: profile.executable,
            executableHash: DeadlockedPs3Profile.profile.executableHash,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
      },
    );

    test(
      'Method execute() keeps Tools of Destruction ambiguous without its PPU hash',
      () {
        final profile = ToolsOfDestructionBcus98127Profile.profile;
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: profile.buildId,
            executable: profile.executable,
            executableHash: null,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
      },
    );

    test('Method execute() matches each game from its measured PPU hash', () {
      final profiles = [
        Rc1CollectionProfile.profile,
        Rc2CollectionProfile.profile,
        Rc3CollectionProfile.profile,
      ];

      for (final profile in profiles) {
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: 'BCUS98282',
            executable: profile.executable,
            executableHash: profile.executableHash,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.supportedGame);
        expect(result.profile, same(profile));
        expect(result.confidence, GameIdentityConfidence.confirmed);
      }
    });

    test('Method execute() leaves the shared Collection ID ambiguous', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: 'BCUS98282',
          executable: null,
          executableHash: null,
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.uncertain);
      expect(result.gameTitle, 'Ratchet & Clank Collection');
    });

    test('Method execute() keeps RC1 ambiguous without its measured hash', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: 'BCUS98282',
          executable: Rc1CollectionProfile.profile.executable,
          executableHash: null,
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.uncertain);
      expect(Rc1CollectionProfile.profile.executableHash, isNotNull);
    });

    test('Method execute() keeps RC3 ambiguous without its measured hash', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: 'BCUS98282',
          executable: Rc3CollectionProfile.profile.executable,
          executableHash: null,
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.uncertain);
      expect(Rc3CollectionProfile.profile.executableHash, isNotNull);
    });

    test(
      'Method execute() reports a confirmed unknown title as unsupported',
      () {
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: 'UNKNOWN123',
            gameTitle: 'Unregistered game',
            executable: 'GAME.self',
            executableHash: 'PPU-unknown',
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
          executableHash: Rc2CollectionProfile.profile.executableHash,
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
            executableHash: Rc2CollectionProfile.profile.executableHash,
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
          executableHash: ' ppu-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9 ',
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.profile, same(Rc2CollectionProfile.profile));
    });

    test(
      'Method execute() leaves the shared title ID ambiguous for an unknown hash',
      () {
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: 'BCUS98282',
            executable: 'RC2.ppu.self',
            executableHash: 'PPU-unknown',
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
      },
    );

    test(
      'Method execute() keeps a matching hash ambiguous without an executable name',
      () {
        final result = ResolveGameProfileUseCase().execute(
          _params(
            titleId: 'BCUS98282',
            executable: null,
            executableHash: Rc2CollectionProfile.profile.executableHash,
            confidence: GameIdentityConfidence.confirmed,
          ),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
      },
    );

    test('Method execute() rejects a hash paired with another executable', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: 'BCUS98282',
          executable: 'RC1.ppu.self',
          executableHash: Rc2CollectionProfile.profile.executableHash,
          confidence: GameIdentityConfidence.confirmed,
        ),
      );

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.uncertain);
    });

    test('Method execute() records a deliberate manual profile selection', () {
      final result = ResolveGameProfileUseCase().execute(
        _params(
          titleId: 'BCUS98282',
          gameTitle: 'Ratchet & Clank 2',
          executable: 'RC2.ppu.self',
          executableHash: Rc2CollectionProfile.profile.executableHash,
          confidence: GameIdentityConfidence.manuallySelected,
          manualProfileId: Rc3CollectionProfile.id,
        ),
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.profile, same(Rc3CollectionProfile.profile));
      expect(result.confidence, GameIdentityConfidence.manuallySelected);
      expect(result.titleId, Rc3CollectionProfile.profile.buildId);
      expect(result.gameTitle, 'Ratchet & Clank 3');
      expect(result.executable, 'RC3.ppu.self');
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
            executableHash: Rc2CollectionProfile.profile.executableHash,
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
  String? executableHash,
  GameIdentityConfidence confidence = GameIdentityConfidence.confirmed,
  String? manualProfileId,
}) => ResolveGameProfileParams(
  processId: processId,
  titleId: titleId,
  gameTitle: gameTitle,
  executable: executable,
  executableHash: executableHash,
  confidence: confidence,
  manualProfileId: manualProfileId,
  evidenceDescription: 'Current RPCS3 identity evidence.',
);
