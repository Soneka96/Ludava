import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:test/test.dart';

import '../support/fake_windows_memory_api.dart';

LudavaSdk _createSdk(
  FakeWindowsMemoryApi api, {
  required GameProfile profile,
  required GameDetectionResult Function() currentIdentity,
}) => LudavaSdk.create(
  profiles: [profile],
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

final _syntheticProfile = GameProfile(
  id: 'synthetic-profile',
  gameName: 'Synthetic game',
  buildId: 'SYNTHETIC',
  executable: 'SYNTHETIC.self',
  executableHash: 'PPU-1111111111111111111111111111111111111111',
  fields: {
    'credits': GameField(
      id: 'credits',
      name: 'Credits',
      guestOffset: 0x1000,
      valueType: MemoryValueType.unsigned32,
      byteOrder: ByteOrder.big,
      minimumValue: 0,
      maximumValue: 0xffffffff,
    ),
  },
);

final _registeredProfile = GameProfileCatalog.find('rc2-collection')!;

void main() {
  group('Method create() behaves correctly', () {
    test(
      'Method create() does not touch native resources during construction',
      () async {
        final api = FakeWindowsMemoryApi();
        var discoveryCalls = 0;
        var metadataCalls = 0;
        var detectionCalls = 0;
        final sdk = LudavaSdk.create(
          profiles: [_syntheticProfile],
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
            return _confirmedIdentity(_syntheticProfile);
          },
        );

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
      'Method create() shares its profile snapshot across detection, manual selection, and diagnostics',
      () async {
        final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 9];
        final sourceProfiles = [_syntheticProfile];
        final logDataSource = Rpcs3GameIdentityLogDataSource(
          fileExists: (path) => path == r'C:\RPCS3\log\RPCS3.log',
          lastModifiedUtc: (_) => DateTime.utc(2026, 11, 5, 11),
          readAsString:
              (_) => '''
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/SYNTHETIC.self
SYS: Title: Synthetic game
SYS: Serial: SYNTHETIC
ppu_loader: PPU executable hash: PPU-1111111111111111111111111111111111111111
''',
        );
        final sdk = LudavaSdk.create(
          profiles: sourceProfiles,
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
          gameIdentityLogDataSource: logDataSource,
        );
        sourceProfiles.clear();

        try {
          expect(sdk.profiles, [_syntheticProfile]);
          expect(
            () => sdk.profiles.add(_syntheticProfile),
            throwsUnsupportedError,
          );
          sdk.session.connect();

          expect(sdk.session.state.profile?.id, _syntheticProfile.id);
          expect(sdk.session.state.readResults['credits']?.value, 9);
          expect(sdk.session.selectManualProfile(sdk.profiles.single), isTrue);
          expect(
            sdk.session.state.detection?.confidence,
            GameIdentityConfidence.manuallySelected,
          );

          final result = sdk.diagnostics.execute(
            DiagnosticGameMemoryRequest(
              gameId: sdk.profiles.single.id,
              fieldId: 'credits',
              processId: 42,
              memoryBase: 0x300000000,
              action: GameMemoryAction.read,
            ),
          );

          expect(result.succeeded, isTrue);
          expect(result.profile, same(sdk.profiles.single));
          expect(result.readResult?.value, 9);
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
          expect(sdk.session.state.profile?.id, _registeredProfile.id);
          expect(sdk.session.state.readResults['bolts']?.value, 19);
          expect(discoveryCalls, greaterThan(1));
          expect(logReads, 2);
        } finally {
          await sdk.dispose();
        }
      },
    );

    test(
      'Method create() connects, reads, writes, verifies, and publishes state',
      () async {
        final api = FakeWindowsMemoryApi();
        final profile = _syntheticProfile;
        final sdk = _createSdk(
          api,
          profile: profile,
          currentIdentity: () => _confirmedIdentity(profile),
        );
        final snapshots = <TrainerSessionState>[];
        final verifiedWriteState = Completer<TrainerSessionState>();
        final streamClosed = Completer<void>();
        final subscription = sdk.session.stateChanges.listen((snapshot) {
          snapshots.add(snapshot);
          if (snapshot.readResults['credits']?.value == 42 &&
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
          expect(sdk.session.state.readResults['credits']?.value, 0x01020304);

          api.readBytes = [0, 0, 0, 42];
          final writeResult = sdk.session.writeField('credits', 42);

          expect(writeResult.status, GameWriteStatus.success);
          expect(writeResult.readBackValue, 42);
          expect(writeResult.succeeded, isTrue);
          expect(sdk.session.state.lastWriteResult, same(writeResult));
          expect(sdk.session.state.readResults['credits']?.value, 42);
          final publishedWriteState = await verifiedWriteState.future.timeout(
            const Duration(seconds: 1),
          );
          expect(publishedWriteState.selectedProcessId, 42);
          expect(publishedWriteState.lastWriteResult?.readBackValue, 42);
          expect(snapshots.last.readResults['credits']?.value, 42);
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
        final profile = _syntheticProfile;
        final sdk = _createSdk(
          api,
          profile: profile,
          currentIdentity: () => _confirmedIdentity(profile),
        );

        try {
          sdk.session.connect();
          final diagnosticResult = sdk.diagnostics.execute(
            DiagnosticGameMemoryRequest(
              gameId: profile.id,
              fieldId: 'credits',
              processId: 42,
              memoryBase: 0x300000000,
              action: GameMemoryAction.read,
            ),
          );

          expect(sdk.session.state.readResults['credits']?.value, 61);
          expect(diagnosticResult.succeeded, isTrue);
          expect(diagnosticResult.readResult?.value, 61);
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
        final profile = _syntheticProfile;
        var discoveryCalls = 0;
        var metadataCalls = 0;
        var detectionCalls = 0;
        var baseResolutionCalls = 0;
        final sdk = LudavaSdk.create(
          profiles: [profile],
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
          profile: profile,
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
        expect(() => sdk.session.writeField('credits', 42), throwsStateError);
        expect(
          () => sdk.diagnostics.execute(
            DiagnosticGameMemoryRequest(
              gameId: profile.id,
              fieldId: 'credits',
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
          secondRuntime.session.state.readResults['credits']?.value,
          0x01020304,
        );
        final secondDiagnosticResult = secondRuntime.diagnostics.execute(
          DiagnosticGameMemoryRequest(
            gameId: profile.id,
            fieldId: 'credits',
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
