import 'dart:io';

import 'package:ludava_sdk/features/game_detection/domain/entities/rpcs3_game_identity_log_snapshot.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava_sdk/features/game_detection/domain/usecases/params/resolve_game_profile.params.dart';
import 'package:ludava_sdk/features/game_detection/domain/usecases/resolve_game_profile.usecase.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';

/// Coordinates RPCS3 session evidence and resolves the current supported game.
class Rpcs3GameDetectionWorkflow {
  /// Creates the workflow with process and current-session log readers.
  Rpcs3GameDetectionWorkflow({
    required List<int> Function() discoverProcessIds,
    required Rpcs3ProcessMetadata Function(int processId) readProcessMetadata,
    required List<Rpcs3GameIdentityLogSnapshot> Function(
      Rpcs3ProcessMetadata processMetadata,
    )
    readIdentityLogCandidates,
  }) : _discoverProcessIds = discoverProcessIds,
       _readProcessMetadata = readProcessMetadata,
       _readIdentityLogCandidates = readIdentityLogCandidates;

  static const String _collectionMenuPpuHash =
      'PPU-673b1ce1b01ce7f42f1787a479f9b83854fa26f5';

  final List<int> Function() _discoverProcessIds;
  final Rpcs3ProcessMetadata Function(int processId) _readProcessMetadata;
  final List<Rpcs3GameIdentityLogSnapshot> Function(
    Rpcs3ProcessMetadata processMetadata,
  )
  _readIdentityLogCandidates;

  /// Detects a game only when fresh evidence belongs to the selected session.
  GameDetectionResult detect(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  ) {
    final processIds = _discoverProcessIds();
    if (!processIds.contains(processId)) {
      return GameDetectionResult(
        status: GameDetectionStatus.rpcs3NotRunning,
        processId: processId,
        confidence: GameIdentityConfidence.none,
        evidenceDescription: 'The selected RPCS3 process is no longer running.',
      );
    }

    final selectedDirectory =
        File(processMetadata.executablePath).parent.absolute.path.toLowerCase();
    for (final otherProcessId in processIds) {
      if (otherProcessId == processId) continue;
      try {
        final otherMetadata = _readProcessMetadata(otherProcessId);
        final otherDirectory =
            File(
              otherMetadata.executablePath,
            ).parent.absolute.path.toLowerCase();
        if (otherDirectory == selectedDirectory) {
          return _ambiguousDetection(
            processId,
            'Multiple RPCS3 processes share the selected log directory.',
          );
        }
      } on Exception catch (error) {
        return _ambiguousDetection(
          processId,
          'Another RPCS3 process could not be distinguished: $error',
        );
      } on UnsupportedError catch (error) {
        return _ambiguousDetection(
          processId,
          'Another RPCS3 process could not be distinguished: $error',
        );
      }
    }

    final snapshots = _readIdentityLogCandidates(processMetadata);
    if (snapshots.length > 1) {
      return _ambiguousDetection(
        processId,
        'Multiple fresh RPCS3 logs were found for the selected process.',
      );
    }
    if (snapshots.isEmpty) {
      return _ambiguousDetection(
        processId,
        'No fresh RPCS3 log could be tied to the selected process session.',
      );
    }

    final snapshot = snapshots.single;
    final event = snapshot.latestEvent;
    if (event == null &&
        snapshot.titles.isEmpty &&
        snapshot.serials.isEmpty &&
        snapshot.bootPaths.isEmpty) {
      return GameDetectionResult(
        status: GameDetectionStatus.noActiveGame,
        processId: processId,
        confidence: GameIdentityConfidence.none,
        evidenceDescription: 'The current process log has no game-load event.',
      );
    }
    if (event?.processFinished == true ||
        event?.executableHash == _collectionMenuPpuHash) {
      return GameDetectionResult(
        status: GameDetectionStatus.noActiveGame,
        processId: processId,
        titleId: event?.titleId,
        gameTitle: event?.title,
        executable: event?.executable,
        executableHash: event?.executableHash,
        confidence: GameIdentityConfidence.none,
        evidenceDescription:
            'The latest RPCS3 lifecycle event shows the game stopped or the Collection menu loaded.',
      );
    }
    if (event?.executableHash == null) {
      return _ambiguousDetection(
        processId,
        'The latest RPCS3 boot has not produced a complete PPU hash yet.',
      );
    }

    return ResolveGameProfileUseCase().execute(
      ResolveGameProfileParams(
        processId: processId,
        titleId: event?.titleId,
        gameTitle: event?.title,
        executable: event?.executable,
        executableHash: event?.executableHash,
        confidence: GameIdentityConfidence.confirmed,
        evidenceDescription:
            'The latest complete PPU load and lifecycle state were read from the selected process session log.',
      ),
    );
  }

  GameDetectionResult _ambiguousDetection(
    int processId,
    String evidenceDescription,
  ) => GameDetectionResult(
    status: GameDetectionStatus.ambiguous,
    processId: processId,
    confidence: GameIdentityConfidence.uncertain,
    evidenceDescription: evidenceDescription,
  );
}
