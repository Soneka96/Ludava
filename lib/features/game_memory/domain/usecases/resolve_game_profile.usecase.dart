import 'package:ludava/features/game_memory/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_memory/domain/profiles/game_profile_catalog.dart';
import 'package:ludava/features/game_memory/domain/usecases/params/resolve_game_profile.params.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Resolves confirmed game identity evidence to a registered profile.
class ResolveGameProfileUseCase {
  /// Resolves [params] against Ludava's registered game profiles.
  GameDetectionResult execute(ResolveGameProfileParams params) {
    final processId = params.processId;
    if (processId != null && processId <= 0) {
      return _result(
        params,
        status: GameDetectionStatus.failed,
        confidence: GameIdentityConfidence.none,
        evidenceDescription: 'Invalid RPCS3 process identifier.',
      );
    }

    if (params.confidence == GameIdentityConfidence.manuallySelected) {
      final profile =
          params.manualProfileId == null
              ? null
              : GameProfileCatalog.find(params.manualProfileId!);
      if (profile == null) {
        return _result(
          params,
          status: GameDetectionStatus.failed,
          confidence: GameIdentityConfidence.manuallySelected,
          evidenceDescription: 'The manually selected profile is unknown.',
        );
      }
      return _result(
        params,
        status: GameDetectionStatus.supportedGame,
        confidence: GameIdentityConfidence.manuallySelected,
        profile: profile,
        titleId: profile.buildId,
        gameTitle: profile.gameName,
        executable: profile.executable,
      );
    }

    if (params.confidence != GameIdentityConfidence.confirmed) {
      return _result(
        params,
        status: GameDetectionStatus.ambiguous,
        confidence: GameIdentityConfidence.uncertain,
      );
    }

    final titleId = _normalize(params.titleId);
    if (titleId == null) {
      return _result(
        params,
        status: GameDetectionStatus.ambiguous,
        confidence: GameIdentityConfidence.uncertain,
      );
    }

    final candidates = GameProfileCatalog.profiles
        .where((profile) => _normalize(profile.buildId) == titleId)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return _result(
        params,
        status: GameDetectionStatus.unsupportedGame,
        confidence: GameIdentityConfidence.confirmed,
      );
    }

    final executable = _normalize(params.executable);
    final executableHash = _normalize(params.executableHash);
    if (executable == null || executableHash == null) {
      return _result(
        params,
        status: GameDetectionStatus.ambiguous,
        confidence: GameIdentityConfidence.uncertain,
      );
    }

    final matches = candidates
        .where(
          (profile) =>
              _normalize(profile.executable) == executable &&
              _normalize(profile.executableHash) == executableHash,
        )
        .toList(growable: false);
    if (matches.length != 1) {
      return _result(
        params,
        status: GameDetectionStatus.ambiguous,
        confidence: GameIdentityConfidence.uncertain,
      );
    }

    final profile = matches.single;
    return _result(
      params,
      status: GameDetectionStatus.supportedGame,
      confidence: GameIdentityConfidence.confirmed,
      profile: profile,
      titleId: profile.buildId,
      gameTitle: profile.gameName,
      executable: profile.executable,
      executableHash: params.executableHash,
    );
  }

  GameDetectionResult _result(
    ResolveGameProfileParams params, {
    required GameDetectionStatus status,
    required GameIdentityConfidence confidence,
    GameProfile? profile,
    String? titleId,
    String? gameTitle,
    String? executable,
    String? executableHash,
    String? evidenceDescription,
  }) => GameDetectionResult(
    status: status,
    processId:
        params.processId != null && params.processId! <= 0
            ? null
            : params.processId,
    titleId: titleId ?? params.titleId,
    gameTitle: gameTitle ?? params.gameTitle,
    executable: executable ?? params.executable,
    executableHash: executableHash ?? params.executableHash,
    confidence: confidence,
    profile: profile,
    evidenceDescription: evidenceDescription ?? params.evidenceDescription,
  );

  String? _normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
