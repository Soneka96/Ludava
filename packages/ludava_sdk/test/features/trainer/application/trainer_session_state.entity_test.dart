import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava_sdk/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava_sdk/features/trainer/application/trainer_session_state.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Class TrainerSessionState construction', () {
    test(
      'Class TrainerSessionState initializes immutable snapshots and no profile',
      () {
        final processes = [42];
        final reads = <String, GameReadResult>{
          'bolts': const GameReadResult(
            status: GameReadStatus.success,
            fieldId: 'bolts',
            value: 100,
          ),
        };

        final state = TrainerSessionState(
          processIds: processes,
          readResults: reads,
          lastWriteResult: const GameWriteResult(status: GameWriteStatus.none),
        );
        processes.add(43);
        reads.clear();

        expect(state.processIds, [42]);
        expect(state.readResults['bolts']?.value, 100);
        expect(state.profile, isNull);
        expect(() => state.processIds.add(44), throwsUnsupportedError);
        expect(() => state.readResults.clear(), throwsUnsupportedError);
      },
    );
  });

  group('Property profile behaves correctly', () {
    test('Property profile returns the detected profile', () {
      final profile = GameProfile(
        id: 'synthetic',
        gameName: 'Synthetic Game',
        buildId: 'TEST00000',
        executable: 'TEST.self',
        readStatus: VerificationStatus.verified,
      );
      final state = TrainerSessionState(
        detection: GameDetectionResult(
          status: GameDetectionStatus.supportedGame,
          processId: 42,
          confidence: GameIdentityConfidence.confirmed,
          profile: profile,
          evidenceDescription: 'Synthetic identity.',
        ),
      );

      expect(state.profile, same(profile));
    });
  });
}
