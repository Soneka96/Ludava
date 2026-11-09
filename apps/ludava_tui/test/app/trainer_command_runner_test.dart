import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/app/trainer_command_runner.dart';
import 'package:test/test.dart';

import '../support/fake_windows_memory_api.dart';

/// One registered profile is used only to cover the CLI-to-SDK boundary.
final _registeredProfile = GameProfileCatalog.find('rc2-collection')!;

TrainerCommandRunner _runnerForApi(
  FakeWindowsMemoryApi api, {
  List<int> processIds = const [],
}) => TrainerCommandRunner(
  sdk: LudavaSdk.create(
    api: api.adapter,
    isWindows: true,
    pointerSize: 8,
    discoverProcessIds: () => processIds,
  ),
);

TrainerCommandRunner _writeCapableCli(
  FakeWindowsMemoryApi api, {
  bool? hasTerminal,
  Future<void> Function(TrainerSessionController session)? runNocterm,
}) => TrainerCommandRunner(
  sdk: LudavaSdk.create(
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
    detectGame: (processId, _) => _confirmedIdentity(processId),
  ),
  hasTerminal: hasTerminal,
  runNocterm: runNocterm,
);

GameDetectionResult _confirmedIdentity(int processId) => GameDetectionResult(
  status: GameDetectionStatus.supportedGame,
  processId: processId,
  titleId: _registeredProfile.buildId,
  gameTitle: _registeredProfile.gameName,
  executable: _registeredProfile.executable,
  executableHash: _registeredProfile.executableHash,
  confidence: GameIdentityConfidence.confirmed,
  profile: _registeredProfile,
  evidenceDescription: 'Synthetic process metadata for the CLI integration.',
);

final _metadata = Rpcs3ProcessMetadata(
  executablePath: r'C:\RPCS3\rpcs3.exe',
  startedAtUtc: DateTime.utc(2026, 11, 5, 10),
);

List<String> _readArguments({String? gameId}) => [
  'read',
  '--game',
  gameId ?? _registeredProfile.id,
  '--field',
  'bolts',
  '--pid',
  '42',
  '--memory-base',
  '0x300000000',
];

List<String> _writeArguments() => [
  'write',
  '--game',
  _registeredProfile.id,
  '--field',
  'bolts',
  '--pid',
  '42',
  '--memory-base',
  '0x300000000',
  '--value',
  '50',
  '--confirm-write',
];

void main() {
  group('Method runAsync() behaves correctly', () {
    test('Method runAsync() prints help without opening a process', () async {
      final output = StringBuffer();
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = await _runnerForApi(
        api,
      ).runAsync(['--help'], output: output, errorOutput: errorOutput);

      expect(exitCode, 0);
      expect(
        output.toString(),
        contains('No arguments starts the Nocterm trainer'),
      );
      expect(output.toString(), contains('current matching PPU identity'));
      expect(errorOutput.toString(), isEmpty);
      expect(api.openCalls, 0);
    });

    test('Method runAsync() delegates a diagnostic read to the SDK', () async {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 42];
      final sdk = LudavaSdk.create(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        discoverProcessIds: () => const [],
      );
      final closed = Completer<void>();
      sdk.session.stateChanges.listen((_) {}, onDone: closed.complete);

      final exitCode = await TrainerCommandRunner(
        sdk: sdk,
      ).runAsync(_readArguments(), output: output);
      await closed.future.timeout(const Duration(seconds: 1));

      expect(exitCode, 0);
      expect(output.toString(), contains('Field: bolts'));
      expect(output.toString(), contains('Value: 42'));
      expect(output.toString(), contains('manual or unverified'));
      expect(api.openCalls, 1);
      expect(api.readCalls, 1);
      expect(api.writeCalls, 0);
      expect(api.closeCalls, 1);
    });

    test(
      'Method runAsync() maps an unknown game to a CLI argument error',
      () async {
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi();
        final exitCode = await _runnerForApi(api).runAsync(
          _readArguments(gameId: 'unregistered-synthetic-profile'),
          errorOutput: errorOutput,
        );

        expect(exitCode, 2);
        expect(errorOutput.toString(), contains('Unknown game profile'));
        expect(api.openCalls, 0);
      },
    );

    test(
      'Method runAsync() rejects invalid arguments before discovery',
      () async {
        var discoveryCalls = 0;
        final errorOutput = StringBuffer();
        final runner = TrainerCommandRunner(
          sdk: LudavaSdk.create(
            discoverProcessIds: () {
              discoveryCalls++;
              return const [];
            },
          ),
        );

        final exitCode = await runner.runAsync([
          'read',
          '--pid',
          '42',
        ], errorOutput: errorOutput);

        expect(exitCode, 2);
        expect(errorOutput.toString(), contains('--game, --field, --pid'));
        expect(discoveryCalls, 0);
      },
    );

    test(
      'Method runAsync() writes a confirmed field and reports SDK read-back',
      () async {
        final output = StringBuffer();
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 50];

        final exitCode = await _writeCapableCli(
          api,
        ).runAsync(_writeArguments(), output: output, errorOutput: errorOutput);

        expect(exitCode, 0, reason: errorOutput.toString());
        expect(output.toString(), contains('Requested value: 50'));
        expect(output.toString(), contains('Read-back value: 50'));
        expect(
          output.toString(),
          contains('Status: write and read-back complete'),
        );
        expect(
          output.toString(),
          contains('current RPCS3 PPU hash matches this profile'),
        );
        expect(api.writeCalls, 1);
        expect(api.readCalls, 2);
        expect(api.closeCalls, 1);
      },
    );

    test(
      'Method runAsync() disposes the SDK after a diagnostic memory failure',
      () async {
        final api = FakeWindowsMemoryApi(handleAddress: 0)..errorCode = 5;
        final sdk = LudavaSdk.create(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () => const [],
        );
        final closed = Completer<void>();
        sdk.session.stateChanges.listen((_) {}, onDone: closed.complete);
        final errorOutput = StringBuffer();

        final exitCode = await TrainerCommandRunner(
          sdk: sdk,
        ).runAsync(_readArguments(), errorOutput: errorOutput);
        await closed.future.timeout(const Duration(seconds: 1));

        expect(exitCode, 1);
        expect(errorOutput.toString(), contains('Windows error 5'));
        expect(api.openCalls, 1);
        expect(api.readCalls, 0);
      },
    );

    test('Method runAsync() launches Nocterm for no arguments', () async {
      var launchCalls = 0;
      final closed = Completer<void>();
      final runner = TrainerCommandRunner(
        hasTerminal: true,
        runNocterm: (session) async {
          launchCalls++;
          session.stateChanges.listen((_) {}, onDone: closed.complete);
        },
      );

      final exitCode = await runner.runAsync([]);
      await closed.future.timeout(const Duration(seconds: 1));

      expect(exitCode, 0);
      expect(launchCalls, 1);
    });

    test(
      'Method runAsync() rejects interactive startup without a terminal',
      () async {
        var launchCalls = 0;
        final errorOutput = StringBuffer();
        final sdk = LudavaSdk.create();
        final closed = Completer<void>();
        sdk.session.stateChanges.listen((_) {}, onDone: closed.complete);

        final exitCode = await TrainerCommandRunner(
          sdk: sdk,
          hasTerminal: false,
          runNocterm: (_) async => launchCalls++,
        ).runAsync([], errorOutput: errorOutput);
        await closed.future.timeout(const Duration(seconds: 1));

        expect(exitCode, 2);
        expect(launchCalls, 0);
        expect(
          errorOutput.toString(),
          contains('Interactive mode requires a terminal'),
        );
      },
    );

    test(
      'Method runAsync() reports startup failures and disposes the SDK',
      () async {
        final errorOutput = StringBuffer();
        final sdk = LudavaSdk.create();
        final closed = Completer<void>();
        sdk.session.stateChanges.listen((_) {}, onDone: closed.complete);
        final exitCode = await TrainerCommandRunner(
          sdk: sdk,
          hasTerminal: true,
          runNocterm: (_) async => throw StateError('backend failed'),
        ).runAsync([], errorOutput: errorOutput);
        await closed.future.timeout(const Duration(seconds: 1));

        expect(exitCode, 1);
        expect(errorOutput.toString(), contains('Nocterm could not start'));
        expect(errorOutput.toString(), contains('backend failed'));
      },
    );

    test(
      'Method runAsync() connects the Nocterm session to SDK memory operations',
      () async {
        final api = FakeWindowsMemoryApi();
        GameWriteResult? writeResult;

        final exitCode = await _writeCapableCli(
          api,
          hasTerminal: true,
          runNocterm: (session) async {
            session.connect();
            expect(session.state.readResults['bolts']?.value, 0x01020304);
            writeResult = session.writeField('bolts', 42);
          },
        ).runAsync([]);

        expect(exitCode, 0);
        expect(writeResult?.status, GameWriteStatus.readBackMismatch);
        expect(api.openCalls, 2);
        expect(api.readCalls, 3);
        expect(api.writeCalls, 1);
        expect(api.closeCalls, 2);
      },
    );
  });
}
