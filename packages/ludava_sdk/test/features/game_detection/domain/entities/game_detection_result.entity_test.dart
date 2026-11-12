import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

GameProfile _profile() => GameProfile(
  id: 'synthetic-profile',
  gameName: 'Synthetic game',
  buildId: 'TEST00001',
  executable: 'SYNTHETIC.self',
  executableHash: 'PPU-synthetic-hash',
  fields: {
    'credits': GameField(
      id: 'credits',
      name: 'Credits',
      guestOffset: 0x1000,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
    ),
  },
);

void main() {
  group('Class GameDetectionResult construction', () {
    test(
      'Class GameDetectionResult rejects a profile for unsupported status',
      () {
        expect(
          () => GameDetectionResult(
            status: GameDetectionStatus.unsupportedGame,
            confidence: GameIdentityConfidence.confirmed,
            profile: _profile(),
            evidenceDescription: 'Synthetic unsupported identity.',
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
            evidenceDescription: 'Synthetic identity.',
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
          profile: _profile(),
          evidenceDescription: 'Incomplete synthetic evidence.',
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
            evidenceDescription: 'Incomplete synthetic evidence.',
          ),
          throwsArgumentError,
        );
      }
    });

    test('Class GameDetectionResult accepts a manual profile selection', () {
      final profile = _profile();
      final result = GameDetectionResult(
        status: GameDetectionStatus.supportedGame,
        confidence: GameIdentityConfidence.manuallySelected,
        profile: profile,
        evidenceDescription: 'Synthetic manual selection.',
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.confidence, GameIdentityConfidence.manuallySelected);
      expect(result.profile, same(profile));
    });
  });

  group('Property availableFields behaves correctly', () {
    test('Property availableFields exposes the selected profile fields', () {
      final result = GameDetectionResult(
        status: GameDetectionStatus.supportedGame,
        confidence: GameIdentityConfidence.confirmed,
        profile: _profile(),
        evidenceDescription: 'Synthetic identity.',
      );

      expect(result.availableFields.map((field) => field.id), ['credits']);
    });

    test('Property availableFields is empty without a supported profile', () {
      final result = GameDetectionResult(
        status: GameDetectionStatus.ambiguous,
        confidence: GameIdentityConfidence.uncertain,
        evidenceDescription: 'Synthetic identity lacks a unique match.',
      );

      expect(result.availableFields, isEmpty);
    });
  });
}
