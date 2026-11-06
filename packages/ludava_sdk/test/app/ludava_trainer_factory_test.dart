import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:test/test.dart';

import '../support/fake_windows_memory_api.dart';

void main() {
  group('Method create() behaves correctly', () {
    test(
      'Method create() preserves an injected unavailable memory base',
      () async {
        final api = FakeWindowsMemoryApi();
        final profile = GameProfileCatalog.find('rc2-collection')!;
        final controller =
            LudavaTrainerFactory(
              api: api.adapter,
              isWindows: true,
              pointerSize: 8,
              discoverProcessIds: () => [42],
              readProcessMetadata: (processId) {
                expect(processId, 42);
                return _metadata;
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
          expect(controller.state.processMetadata, same(_metadata));
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
          expect(api.openCalls, 0);
          expect(api.readCalls, 0);
          expect(api.writeCalls, 0);
        } finally {
          await controller.dispose();
        }
      },
    );

    test(
      'Method create() detects a supported game through its injected log source',
      () async {
        var discoveryCalls = 0;
        var logReads = 0;
        final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 19];
        final logDataSource = Rpcs3GameIdentityLogDataSource(
          fileExists: (path) => path == r'C:\RPCS3\log\RPCS3.log',
          lastModifiedUtc: (_) => DateTime.utc(2026, 11, 5, 11),
          readAsString: (_) {
            logReads++;
            return '''
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/RC2.ppu.self
SYS: Title: Ratchet & Clank Collection
SYS: Serial: BCUS98282
ppu_loader: PPU executable hash: PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9
''';
          },
        );
        final controller =
            LudavaTrainerFactory(
              api: api.adapter,
              isWindows: true,
              pointerSize: 8,
              discoverProcessIds: () {
                discoveryCalls++;
                return const [42];
              },
              readProcessMetadata: (_) => _metadata,
              resolveMemoryBaseCandidate:
                  (_) => const Rpcs3MemoryBaseCandidate(
                    memoryBase: 0x300000000,
                    logPath: r'C:\RPCS3\log\RPCS3.log',
                  ),
              gameIdentityLogDataSource: logDataSource,
            ).create();

        try {
          controller.connect();

          expect(
            controller.state.detection?.status,
            GameDetectionStatus.supportedGame,
          );
          expect(
            controller.state.detection?.confidence,
            GameIdentityConfidence.confirmed,
          );
          expect(controller.state.profile?.id, 'rc2-collection');
          expect(controller.state.readResults['bolts']?.value, 19);
          expect(discoveryCalls, greaterThan(1));
          expect(logReads, 2);
          expect(api.readCalls, 1);
          expect(api.closeCalls, 1);
        } finally {
          await controller.dispose();
        }
      },
    );

    test(
      'Method create() connects, reads, writes, verifies, and publishes state',
      () async {
        final api = FakeWindowsMemoryApi();
        final profile = GameProfileCatalog.find('rc2-collection')!;
        final controller =
            _createFactory(
              api,
              currentIdentity: () => _confirmedIdentity(profile),
            ).create();
        final snapshots = <TrainerSessionState>[];
        final verifiedWriteState = Completer<TrainerSessionState>();
        final streamClosed = Completer<void>();
        final subscription = controller.stateChanges.listen((snapshot) {
          snapshots.add(snapshot);
          if (snapshot.readResults['bolts']?.value == 42 &&
              !verifiedWriteState.isCompleted) {
            verifiedWriteState.complete(snapshot);
          }
        }, onDone: streamClosed.complete);

        try {
          controller.connect();

          expect(controller.state.processIds, [42]);
          expect(controller.state.selectedProcessId, 42);
          expect(
            controller.state.detection?.status,
            GameDetectionStatus.supportedGame,
          );
          expect(controller.state.profile?.id, profile.id);
          expect(controller.state.memoryBase, 0x300000000);
          expect(controller.state.readResults['bolts']?.value, 0x01020304);

          api.readBytes = [0, 0, 0, 42];
          final writeResult = controller.writeField('bolts', 42);

          expect(writeResult.status, GameWriteStatus.success);
          expect(writeResult.readBackValue, 42);
          expect(writeResult.succeeded, isTrue);
          expect(controller.state.lastWriteResult, same(writeResult));
          expect(controller.state.readResults['bolts']?.value, 42);
          final publishedWriteState = await verifiedWriteState.future.timeout(
            const Duration(seconds: 1),
          );
          expect(publishedWriteState.selectedProcessId, 42);
          expect(publishedWriteState.lastWriteResult?.readBackValue, 42);
          expect(snapshots.last.readResults['bolts']?.value, 42);
          expect(api.openCalls, 2);
          expect(api.readCalls, 3);
          expect(api.writeCalls, 1);
          expect(api.closeCalls, 2);
          expect(api.requestedAccess, 0x0038);
          expect(api.writeAddress, 0x301329e80);
        } finally {
          await controller.dispose();
          await streamClosed.future.timeout(const Duration(seconds: 1));
          await subscription.cancel();
        }
      },
    );

    test(
      'Method create() rejects values outside the field range before writing',
      () async {
        final api = FakeWindowsMemoryApi();
        final profile = GameProfileCatalog.find('rc2-collection')!;
        final controller =
            _createFactory(
              api,
              currentIdentity: () => _confirmedIdentity(profile),
            ).create();

        try {
          controller.connect();
          final result = controller.writeField('bolts', 0x100000000);

          expect(result.status, GameWriteStatus.invalidValue);
          expect(api.writeCalls, 0);
          expect(api.openCalls, 1);
        } finally {
          await controller.dispose();
        }
      },
    );

    test(
      'Method create() rejects a write when current game identity changes',
      () async {
        final api = FakeWindowsMemoryApi();
        final profile = GameProfileCatalog.find('rc2-collection')!;
        var currentIdentity = _confirmedIdentity(profile);
        final controller =
            _createFactory(
              api,
              currentIdentity: () => currentIdentity,
            ).create();

        try {
          controller.connect();
          currentIdentity = GameDetectionResult(
            status: GameDetectionStatus.noActiveGame,
            processId: 42,
            confidence: GameIdentityConfidence.none,
            evidenceDescription: 'The active game stopped before the write.',
          );
          final result = controller.writeField('bolts', 50);

          expect(result.status, GameWriteStatus.unsupportedProfile);
          expect(controller.state.lastWriteResult, same(result));
          expect(controller.state.selectedProcessId, isNull);
          expect(controller.state.readResults, isEmpty);
          expect(api.writeCalls, 0);
          expect(api.openCalls, 1);
          expect(api.closeCalls, 1);
        } finally {
          await controller.dispose();
        }
      },
    );
  });
}

/// Creates a factory with deterministic current-session evidence and memory.
LudavaTrainerFactory _createFactory(
  FakeWindowsMemoryApi api, {
  required GameDetectionResult Function() currentIdentity,
}) => LudavaTrainerFactory(
  api: api.adapter,
  isWindows: true,
  pointerSize: 8,
  discoverProcessIds: () => const [42],
  readProcessMetadata: (_) => _metadata,
  resolveMemoryBaseCandidate:
      (_) => const Rpcs3MemoryBaseCandidate(
        memoryBase: 0x300000000,
        logPath: r'C:\RPCS3\log\RPCS3.log',
      ),
  detectGame: (_, __) => currentIdentity(),
);

/// Builds confirmed identity evidence for [profile] and process 42.
GameDetectionResult _confirmedIdentity(GameProfile profile) =>
    GameDetectionResult(
      status: GameDetectionStatus.supportedGame,
      processId: 42,
      titleId: profile.buildId,
      gameTitle: profile.gameName,
      executable: profile.executable,
      executableHash: profile.executableHash,
      confidence: GameIdentityConfidence.confirmed,
      profile: profile,
      evidenceDescription: 'Injected confirmed identity for the factory test.',
    );

final _metadata = Rpcs3ProcessMetadata(
  executablePath: r'C:\RPCS3\rpcs3.exe',
  startedAtUtc: DateTime.utc(2026, 11, 5, 10),
);
