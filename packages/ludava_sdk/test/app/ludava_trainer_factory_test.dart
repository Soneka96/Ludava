import 'dart:io';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('Method create() behaves correctly', () {
    test(
      'Method create() preserves an injected unavailable memory base',
      () async {
        final temporaryDirectory = await Directory.systemTemp.createTemp(
          'ludava-trainer-factory-',
        );
        final logDirectory = Directory(
          '${temporaryDirectory.path}${Platform.pathSeparator}log',
        );
        await logDirectory.create();
        await File(
          '${logDirectory.path}${Platform.pathSeparator}RPCS3.log',
        ).writeAsString('vm::g_base_addr = 0x300000000');
        final profile = GameProfileCatalog.find('rc2-collection')!;
        final metadata = Rpcs3ProcessMetadata(
          executablePath:
              '${temporaryDirectory.path}${Platform.pathSeparator}rpcs3.exe',
          startedAtUtc: DateTime.utc(2000),
        );
        final controller =
            LudavaTrainerFactory(
              discoverProcessIds: () => [42],
              readProcessMetadata: (processId) {
                expect(processId, 42);
                return metadata;
              },
              resolveMemoryBaseCandidate: (_) => null,
              detectGame:
                  (processId, _) => GameDetectionResult(
                    status: GameDetectionStatus.supportedGame,
                    processId: processId,
                    titleId: profile.buildId,
                    gameTitle: profile.gameName,
                    executable: profile.executable,
                    executableHash: profile.executableHash,
                    confidence: GameIdentityConfidence.confirmed,
                    profile: profile,
                    evidenceDescription: 'Injected confirmed identity.',
                  ),
            ).create();
        try {
          controller.connect();

          expect(controller.state.processIds, [42]);
          expect(controller.state.selectedProcessId, 42);
          expect(controller.state.processMetadata, same(metadata));
          expect(
            controller.state.detection?.status,
            GameDetectionStatus.supportedGame,
          );
          expect(controller.selectProcess(42), isTrue);
          controller.refresh();
          controller.redetect();
          expect(controller.state.memoryBase, isNull);
          expect(controller.state.readResults, isEmpty);
          expect(
            controller.writeField('bolts', 1).status,
            GameWriteStatus.unsupportedProfile,
          );
          expect(
            GameProfileCatalog.profiles.map((profile) => profile.id),
            containsAll(['rc1-collection', 'rc2-collection', 'rc3-collection']),
          );
        } finally {
          await controller.dispose();
          await temporaryDirectory.delete(recursive: true);
        }
      },
    );
  });
}
