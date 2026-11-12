import 'package:ludava_sdk/features/game_catalog/domain/entities/game_field.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/usecases/params/resolve_game_profile.params.dart';
import 'package:ludava_sdk/features/game_detection/domain/usecases/resolve_game_profile.usecase.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

GameField _field({String id = 'credits', int guestOffset = 0x1000}) =>
    GameField(
      id: id,
      name: id,
      guestOffset: guestOffset,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
    );

GameProfile _profile({
  String id = 'synthetic-alpha',
  String gameName = 'Synthetic Alpha',
  String buildId = 'TEST00001',
  String executable = 'ALPHA.self',
  String? executableHash = 'PPU-synthetic-alpha',
  Map<String, GameField>? fields,
}) => GameProfile(
  id: id,
  gameName: gameName,
  buildId: buildId,
  executable: executable,
  executableHash: executableHash,
  fields: fields ?? {'credits': _field()},
);

List<GameProfile> _profiles() => [
  _profile(),
  _profile(
    id: 'synthetic-beta',
    gameName: 'Synthetic Beta',
    executable: 'BETA.self',
    executableHash: 'PPU-synthetic-beta',
  ),
];

ResolveGameProfileUseCase _createResolver({Iterable<GameProfile>? profiles}) =>
    ResolveGameProfileUseCase(profiles: profiles ?? _profiles());

ResolveGameProfileParams _params({
  int? processId = 42,
  String? titleId = 'TEST00001',
  String? gameTitle = 'Synthetic title',
  String? executable = 'ALPHA.self',
  String? executableHash = 'PPU-synthetic-alpha',
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
  evidenceDescription: 'Synthetic current-process identity evidence.',
);

void main() {
  group('Method execute() behaves correctly', () {
    test('Method execute() matches normalized title, executable, and hash', () {
      final profiles = _profiles();
      final result = _createResolver(profiles: profiles).execute(
        _params(
          titleId: ' test00001 ',
          executable: ' alpha.SELF ',
          executableHash: ' ppu-synthetic-alpha ',
        ),
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.profile, same(profiles.first));
      expect(result.confidence, GameIdentityConfidence.confirmed);
      expect(result.availableFields.map((field) => field.id), ['credits']);
    });

    test('Method execute() disambiguates profiles sharing a title id', () {
      final profiles = _profiles();
      final result = _createResolver(profiles: profiles).execute(
        _params(executable: 'BETA.self', executableHash: 'PPU-synthetic-beta'),
      );

      expect(result.status, GameDetectionStatus.supportedGame);
      expect(result.profile, same(profiles[1]));
    });

    test(
      'Method execute() leaves a shared title ambiguous without an executable',
      () {
        final result = _createResolver().execute(
          _params(executable: null, executableHash: null),
        );

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
        expect(result.confidence, GameIdentityConfidence.uncertain);
      },
    );

    test('Method execute() leaves a shared title ambiguous without a hash', () {
      final result = _createResolver().execute(_params(executableHash: null));

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.uncertain);
    });

    test('Method execute() rejects a mismatched executable hash', () {
      final result = _createResolver().execute(
        _params(executableHash: 'PPU-unregistered-hash'),
      );

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.uncertain);
    });

    test('Method execute() rejects a hash paired with another executable', () {
      final result = _createResolver().execute(
        _params(executable: 'BETA.self'),
      );

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
    });

    test(
      'Method execute() reports an unknown confirmed title as unsupported',
      () {
        final result = _createResolver().execute(
          _params(
            titleId: 'UNKNOWN001',
            gameTitle: 'Synthetic unregistered title',
          ),
        );

        expect(result.status, GameDetectionStatus.unsupportedGame);
        expect(result.profile, isNull);
        expect(result.gameTitle, 'Synthetic unregistered title');
        expect(result.availableFields, isEmpty);
      },
    );

    test('Method execute() leaves missing or blank title ids ambiguous', () {
      for (final titleId in [null, '  ']) {
        final result = _createResolver().execute(_params(titleId: titleId));

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
      }
    });

    test('Method execute() does not match uncertain identity evidence', () {
      final result = _createResolver().execute(
        _params(confidence: GameIdentityConfidence.uncertain),
      );

      expect(result.status, GameDetectionStatus.ambiguous);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.uncertain);
    });

    test(
      'Method execute() reports ambiguous when injected identities collide',
      () {
        final profile = _profile();
        final duplicate = _profile(
          id: 'synthetic-duplicate',
          gameName: 'Synthetic Duplicate',
        );
        final result = _createResolver(
          profiles: [profile, duplicate],
        ).execute(_params());

        expect(result.status, GameDetectionStatus.ambiguous);
        expect(result.profile, isNull);
      },
    );

    test(
      'Method execute() records a manual selection from the injected profiles',
      () {
        final profiles = _profiles();
        final result = _createResolver(profiles: profiles).execute(
          _params(
            confidence: GameIdentityConfidence.manuallySelected,
            manualProfileId: profiles[1].id,
          ),
        );

        expect(result.status, GameDetectionStatus.supportedGame);
        expect(result.profile, same(profiles[1]));
        expect(result.confidence, GameIdentityConfidence.manuallySelected);
        expect(result.titleId, profiles[1].buildId);
        expect(result.gameTitle, profiles[1].gameName);
        expect(result.executable, profiles[1].executable);
      },
    );

    test('Method execute() rejects an unknown manual selection', () {
      final result = _createResolver().execute(
        _params(
          confidence: GameIdentityConfidence.manuallySelected,
          manualProfileId: 'not-injected',
        ),
      );

      expect(result.status, GameDetectionStatus.failed);
      expect(result.profile, isNull);
      expect(result.confidence, GameIdentityConfidence.manuallySelected);
    });

    test('Method execute() rejects a missing manual selection', () {
      final result = _createResolver().execute(
        _params(confidence: GameIdentityConfidence.manuallySelected),
      );

      expect(result.status, GameDetectionStatus.failed);
      expect(result.profile, isNull);
    });

    test('Method execute() rejects invalid process identifiers', () {
      for (final processId in [0, -1]) {
        final result = _createResolver().execute(_params(processId: processId));

        expect(result.status, GameDetectionStatus.failed);
        expect(result.processId, isNull);
        expect(result.profile, isNull);
      }
    });
  });
}
