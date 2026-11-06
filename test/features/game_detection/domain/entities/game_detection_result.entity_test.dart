import 'package:ludava/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/game_catalog/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class GameDetectionResult construction', () {
    test(
      'Class GameDetectionResult initializes supported profile evidence',
      () {
        final result = GameDetectionResult(
          status: GameDetectionStatus.supportedGame,
          processId: 42,
          titleId: 'BCUS98282',
          gameTitle: 'Ratchet & Clank 2',
          executable: 'RC2.ppu.self',
          executableHash: 'PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9',
          confidence: GameIdentityConfidence.confirmed,
          profile: Rc2CollectionProfile.profile,
          evidenceDescription: 'Current RPCS3 identity evidence.',
        );

        expect(result.status, GameDetectionStatus.supportedGame);
        expect(result.processId, 42);
        expect(result.titleId, 'BCUS98282');
        expect(result.gameTitle, 'Ratchet & Clank 2');
        expect(result.executable, 'RC2.ppu.self');
        expect(
          result.executableHash,
          'PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9',
        );
        expect(result.confidence, GameIdentityConfidence.confirmed);
        expect(result.profile, same(Rc2CollectionProfile.profile));
        expect(result.evidenceDescription, 'Current RPCS3 identity evidence.');
      },
    );

    test(
      'Class GameDetectionResult rejects a profile for unsupported status',
      () {
        expect(
          () => GameDetectionResult(
            status: GameDetectionStatus.unsupportedGame,
            confidence: GameIdentityConfidence.confirmed,
            profile: Rc2CollectionProfile.profile,
            evidenceDescription: 'Identified unsupported title.',
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      'Class GameDetectionResult rejects supported status without profile',
      () {
        expect(
          () => GameDetectionResult(
            status: GameDetectionStatus.supportedGame,
            confidence: GameIdentityConfidence.confirmed,
            evidenceDescription: 'Unique identity evidence.',
          ),
          throwsArgumentError,
        );
      },
    );

    test('Class GameDetectionResult rejects uncertain supported identity', () {
      expect(
        () => GameDetectionResult(
          status: GameDetectionStatus.supportedGame,
          confidence: GameIdentityConfidence.uncertain,
          profile: Rc2CollectionProfile.profile,
          evidenceDescription: 'Incomplete identity evidence.',
        ),
        throwsArgumentError,
      );
    });

    test('Class GameDetectionResult rejects invalid process identifiers', () {
      for (final processId in [0, -1]) {
        expect(
          () => GameDetectionResult(
            status: GameDetectionStatus.ambiguous,
            processId: processId,
            confidence: GameIdentityConfidence.uncertain,
            evidenceDescription: 'Incomplete identity evidence.',
          ),
          throwsArgumentError,
        );
      }
    });

    test('Class GameDetectionResult accepts a manually selected profile', () {
      final result = GameDetectionResult(
        status: GameDetectionStatus.supportedGame,
        confidence: GameIdentityConfidence.manuallySelected,
        profile: Rc2CollectionProfile.profile,
        evidenceDescription: 'Selected manually.',
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.confidence, GameIdentityConfidence.manuallySelected);
      expect(result.profile, same(Rc2CollectionProfile.profile));
    });
  });

  group('Property availableFields behaves correctly', () {
    test('Property availableFields exposes the selected profile fields', () {
      final result = GameDetectionResult(
        status: GameDetectionStatus.supportedGame,
        confidence: GameIdentityConfidence.confirmed,
        profile: Rc2CollectionProfile.profile,
        evidenceDescription: 'Unique identity evidence.',
      );

      expect(result.availableFields.map((field) => field.id), ['bolts']);
    });

    test('Property availableFields is empty without a supported profile', () {
      final result = GameDetectionResult(
        status: GameDetectionStatus.ambiguous,
        confidence: GameIdentityConfidence.uncertain,
        evidenceDescription: 'Shared title ID only.',
      );

      expect(result.availableFields, isEmpty);
    });
  });
}
