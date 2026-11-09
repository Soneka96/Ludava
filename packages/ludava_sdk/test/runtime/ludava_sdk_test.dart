import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:test/test.dart';

import '../support/fake_windows_memory_api.dart';

LudavaSdk _createSdk(
  FakeWindowsMemoryApi api, {
  required GameDetectionResult Function() currentIdentity,
}) => LudavaSdk.create(
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
      evidenceDescription: 'Injected confirmed identity for the runtime test.',
    );

final _metadata = Rpcs3ProcessMetadata(
  executablePath: r'C:\RPCS3\rpcs3.exe',
  startedAtUtc: DateTime.utc(2026, 11, 5, 10),
);

final _registeredProfile = GameProfileCatalog.find('rc2-collection')!;

void main() {
  group('Method create() behaves correctly', () {
    test(
      'Method create() exposes typed capabilities without native operations',
      () async {
        final api = FakeWindowsMemoryApi();
        var discoveryCalls = 0;
        var metadataCalls = 0;
        var detectionCalls = 0;
        final sdk = LudavaSdk.create(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () {
            discoveryCalls++;
            return const [];
          },
          readProcessMetadata: (_) {
            metadataCalls++;
            return _metadata;
          },
          detectGame: (_, __) {
            detectionCalls++;
            return _confirmedIdentity(_registeredProfile);
          },
        );

        expect(sdk.session, isA<TrainerSessionController>());
        expect(sdk.diagnostics, isA<DiagnosticGameMemoryService>());
        expect(api.openCalls, 0);
        expect(api.readCalls, 0);
        expect(api.writeCalls, 0);
        expect(discoveryCalls, 0);
        expect(metadataCalls, 0);
        expect(detectionCalls, 0);

        await sdk.dispose();
      },
    );

    test(
      'Method create() wires diagnostic operations to runtime collaborators',
      () async {
        final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 61];
        final profile = _registeredProfile;
        final sdk = LudavaSdk.create(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () => const [42],
          readProcessMetadata: (_) => _metadata,
          detectGame: (_, __) => _confirmedIdentity(profile),
        );

        try {
          final result = sdk.diagnostics.execute(
            DiagnosticGameMemoryRequest(
              gameId: profile.id,
              fieldId: 'bolts',
              processId: 42,
              memoryBase: 0x300000000,
              action: GameMemoryAction.read,
            ),
          );

          expect(result.succeeded, isTrue);
          expect(result.readResult?.value, 61);
          expect(result.identityConfirmed, isTrue);
          expect(api.openCalls, 1);
          expect(api.readCalls, 1);
          expect(api.closeCalls, 1);
        } finally {
          await sdk.dispose();
        }
      },
    );

    test(
      'Method create() preserves an injected unavailable memory base',
      () async {
        final api = FakeWindowsMemoryApi();
        final profile = _registeredProfile;
        final sdk = LudavaSdk.create(
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
        );
        try {
          sdk.session.connect();

          expect(sdk.session.state.processIds, [42]);
          expect(sdk.session.state.selectedProcessId, 42);
          expect(sdk.session.state.processMetadata, same(_metadata));
          expect(
            sdk.session.state.detection?.status,
            GameDetectionStatus.supportedGame,
          );
          expect(sdk.session.selectProcess(42), isTrue);
          sdk.session.refresh();
          sdk.session.redetect();
          expect(sdk.session.state.memoryBase, isNull);
          expect(sdk.session.state.readResults, isEmpty);
          expect(
            sdk.session.writeField('bolts', 1).status,
            GameWriteStatus.unsupportedProfile,
          );
          expect(api.openCalls, 0);
          expect(api.readCalls, 0);
          expect(api.writeCalls, 0);
        } finally {
          await sdk.dispose();
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
        final sdk = LudavaSdk.create(
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
        );

        try {
          sdk.session.connect();

          expect(
            sdk.session.state.detection?.status,
            GameDetectionStatus.supportedGame,
          );
          expect(
            sdk.session.state.detection?.confidence,
            GameIdentityConfidence.confirmed,
          );
          expect(
            sdk.session.state.profile,
            same(sdk.session.state.detection?.profile),
          );
          expect(sdk.session.state.readResults['bolts']?.value, 19);
          expect(discoveryCalls, greaterThan(1));
          expect(logReads, 2);
          expect(api.readCalls, 1);
          expect(api.closeCalls, 1);
        } finally {
          await sdk.dispose();
        }
      },
    );

    test(
      'Method create() connects, reads, writes, verifies, and publishes state',
      () async {
        final api = FakeWindowsMemoryApi();
        final profile = _registeredProfile;
        final sdk = _createSdk(
          api,
          currentIdentity: () => _confirmedIdentity(profile),
        );
        final snapshots = <TrainerSessionState>[];
        final verifiedWriteState = Completer<TrainerSessionState>();
        final streamClosed = Completer<void>();
        final subscription = sdk.session.stateChanges.listen((snapshot) {
          snapshots.add(snapshot);
          if (snapshot.readResults['bolts']?.value == 42 &&
              !verifiedWriteState.isCompleted) {
            verifiedWriteState.complete(snapshot);
          }
        }, onDone: streamClosed.complete);

        try {
          sdk.session.connect();

          expect(sdk.session.state.processIds, [42]);
          expect(sdk.session.state.selectedProcessId, 42);
          expect(
            sdk.session.state.detection?.status,
            GameDetectionStatus.supportedGame,
          );
          expect(sdk.session.state.profile?.id, profile.id);
          expect(sdk.session.state.memoryBase, 0x300000000);
          expect(sdk.session.state.readResults['bolts']?.value, 0x01020304);

          api.readBytes = [0, 0, 0, 42];
          final writeResult = sdk.session.writeField('bolts', 42);

          expect(writeResult.status, GameWriteStatus.success);
          expect(writeResult.readBackValue, 42);
          expect(writeResult.succeeded, isTrue);
          expect(sdk.session.state.lastWriteResult, same(writeResult));
          expect(sdk.session.state.readResults['bolts']?.value, 42);
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
          await sdk.dispose();
          await streamClosed.future.timeout(const Duration(seconds: 1));
          await subscription.cancel();
        }
      },
    );

    test(
      'Method create() shares feature-owned memory operations with diagnostics',
      () async {
        final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 61];
        final profile = _registeredProfile;
        final sdk = _createSdk(
          api,
          currentIdentity: () => _confirmedIdentity(profile),
        );

        try {
          sdk.session.connect();
          final diagnosticResult = sdk.diagnostics.execute(
            DiagnosticGameMemoryRequest(
              gameId: profile.id,
              fieldId: 'bolts',
              processId: 42,
              memoryBase: 0x300000000,
              action: GameMemoryAction.read,
            ),
          );

          expect(sdk.session.state.readResults['bolts']?.value, 61);
          expect(diagnosticResult.readResult?.value, 61);
          expect(api.openCalls, 2);
          expect(api.readCalls, 2);
          expect(api.writeCalls, 0);
          expect(api.closeCalls, 2);
        } finally {
          await sdk.dispose();
        }
      },
    );

    test(
      'Method create() rejects values outside the field range before writing',
      () async {
        final api = FakeWindowsMemoryApi();
        final profile = _registeredProfile;
        final sdk = _createSdk(
          api,
          currentIdentity: () => _confirmedIdentity(profile),
        );

        try {
          sdk.session.connect();
          final result = sdk.session.writeField('bolts', 0x100000000);

          expect(result.status, GameWriteStatus.invalidValue);
          expect(api.writeCalls, 0);
          expect(api.openCalls, 1);
        } finally {
          await sdk.dispose();
        }
      },
    );

    test(
      'Method create() rejects a write when current game identity changes',
      () async {
        final api = FakeWindowsMemoryApi();
        final profile = _registeredProfile;
        var currentIdentity = _confirmedIdentity(profile);
        final sdk = _createSdk(api, currentIdentity: () => currentIdentity);

        try {
          sdk.session.connect();
          currentIdentity = GameDetectionResult(
            status: GameDetectionStatus.noActiveGame,
            processId: 42,
            confidence: GameIdentityConfidence.none,
            evidenceDescription: 'The active game stopped before the write.',
          );
          final result = sdk.session.writeField('bolts', 50);

          expect(result.status, GameWriteStatus.unsupportedProfile);
          expect(sdk.session.state.lastWriteResult, same(result));
          expect(sdk.session.state.selectedProcessId, isNull);
          expect(sdk.session.state.readResults, isEmpty);
          expect(api.writeCalls, 0);
          expect(api.openCalls, 1);
          expect(api.closeCalls, 1);
        } finally {
          await sdk.dispose();
        }
      },
    );

    test(
      'Method create() keeps session state independent across runtimes',
      () async {
        final first = LudavaSdk.create(discoverProcessIds: () => const [1, 2]);
        final second = LudavaSdk.create(
          discoverProcessIds: () => const [3, 4, 5],
        );
        try {
          first.session.connect();
          second.session.connect();

          expect(first.session.state.processIds, [1, 2]);
          expect(second.session.state.processIds, [3, 4, 5]);
          expect(
            first.session.state.processIds,
            isNot(same(second.session.state.processIds)),
          );
        } finally {
          await first.dispose();
          await second.dispose();
        }
      },
    );
  });

  group('Method dispose() behaves correctly', () {
    test(
      'Method dispose() rejects retained capabilities as disposal starts',
      () async {
        final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 41];
        final profile = _registeredProfile;
        var discoveryCalls = 0;
        var metadataCalls = 0;
        var detectionCalls = 0;
        var baseResolutionCalls = 0;
        final sdk = LudavaSdk.create(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () {
            discoveryCalls++;
            return const [42];
          },
          readProcessMetadata: (_) {
            metadataCalls++;
            return _metadata;
          },
          resolveMemoryBaseCandidate: (_) {
            baseResolutionCalls++;
            return const Rpcs3MemoryBaseCandidate(
              memoryBase: 0x300000000,
              logPath: r'C:\RPCS3\log\RPCS3.log',
            );
          },
          detectGame: (_, __) {
            detectionCalls++;
            return _confirmedIdentity(profile);
          },
        );
        final snapshots = <TrainerSessionState>[];
        final streamClosed = Completer<void>();
        final subscription = sdk.session.stateChanges.listen(
          snapshots.add,
          onDone: streamClosed.complete,
        );
        sdk.session.connect();
        await Future<void>.delayed(Duration.zero);
        final finalState = sdk.session.state;
        final snapshotCount = snapshots.length;
        final readCalls = api.readCalls;
        final writeCalls = api.writeCalls;
        final initialDiscoveryCalls = discoveryCalls;
        final initialMetadataCalls = metadataCalls;
        final initialDetectionCalls = detectionCalls;
        final initialBaseCalls = baseResolutionCalls;

        final secondApi = FakeWindowsMemoryApi();
        final secondRuntime = _createSdk(
          secondApi,
          currentIdentity: () => _confirmedIdentity(profile),
        );

        subscription.pause();
        final firstDisposal = sdk.dispose();
        final pendingDisposal = sdk.dispose();
        var disposalCompleted = false;
        firstDisposal.then((_) => disposalCompleted = true);
        final secondDisposal = sdk.dispose();
        expect(secondDisposal, same(firstDisposal));
        expect(pendingDisposal, same(firstDisposal));
        expect(disposalCompleted, isFalse);

        expect(sdk.session.connect, throwsStateError);
        expect(() => sdk.session.selectProcess(42), throwsStateError);
        expect(
          () => sdk.session.selectManualProfile(profile),
          throwsStateError,
        );
        expect(sdk.session.refresh, throwsStateError);
        expect(sdk.session.redetect, throwsStateError);
        expect(() => sdk.session.writeField('bolts', 42), throwsStateError);
        expect(
          () => sdk.diagnostics.execute(
            DiagnosticGameMemoryRequest(
              gameId: profile.id,
              fieldId: 'bolts',
              processId: 42,
              memoryBase: 0x300000000,
              action: GameMemoryAction.read,
            ),
          ),
          throwsStateError,
        );
        expect(sdk.session.state, same(finalState));
        expect(snapshots, hasLength(snapshotCount));
        expect(discoveryCalls, initialDiscoveryCalls);
        expect(metadataCalls, initialMetadataCalls);
        expect(detectionCalls, initialDetectionCalls);
        expect(baseResolutionCalls, initialBaseCalls);
        expect(api.readCalls, readCalls);
        expect(api.writeCalls, writeCalls);

        subscription.resume();
        await firstDisposal;
        await streamClosed.future.timeout(const Duration(seconds: 1));
        expect(sdk.session.state, same(finalState));
        expect(snapshots, hasLength(snapshotCount));
        await subscription.cancel();
        await expectLater(sdk.session.stateChanges, emitsDone);

        secondRuntime.session.connect();
        expect(secondRuntime.session.state.selectedProcessId, 42);
        expect(
          secondRuntime.session.state.readResults['bolts']?.value,
          0x01020304,
        );
        final secondDiagnosticResult = secondRuntime.diagnostics.execute(
          DiagnosticGameMemoryRequest(
            gameId: profile.id,
            fieldId: 'bolts',
            processId: 42,
            memoryBase: 0x300000000,
            action: GameMemoryAction.read,
          ),
        );
        expect(secondDiagnosticResult.succeeded, isTrue);
        expect(secondDiagnosticResult.readResult?.value, 0x01020304);
        expect(secondApi.readCalls, 2);
        expect(secondApi.writeCalls, 0);
        await secondRuntime.dispose();
      },
    );
  });
}

/// Creates a runtime with deterministic current-session evidence and memory.
