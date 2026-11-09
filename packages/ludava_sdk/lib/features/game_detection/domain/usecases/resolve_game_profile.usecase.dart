import 'package:ludava_sdk/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/game_profile_catalog.dart';
import 'package:ludava_sdk/features/game_detection/domain/usecases/params/resolve_game_profile.params.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Resolves a confirmed title, executable name, and measured hash to a profile.
class ResolveGameProfileUseCase {
  /// Creates the resolver with [profiles], defaulting to registered profiles.
  ResolveGameProfileUseCase({Iterable<GameProfile>? profiles})
    : _profiles = List<GameProfile>.unmodifiable(
        profiles ?? GameProfileCatalog.profiles,
      );

  /// Immutable profile view used for automatic matching and manual selection.
  final List<GameProfile> _profiles;

  /// Resolves [params] against this resolver's configured profile view.
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
      final profile = _findProfile(params.manualProfileId);
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

    final candidates = _profiles
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

  /// Finds a profile in the same catalog view used by automatic matching.
  GameProfile? _findProfile(String? profileId) {
    if (profileId == null) return null;
    for (final profile in _profiles) {
      if (profile.id == profileId) return profile;
    }
    return null;
  }

  /// Builds a detection result while retaining unoverridden evidence.
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

  /// Trims an identity value and normalizes it for case-insensitive matching.
  String? _normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
