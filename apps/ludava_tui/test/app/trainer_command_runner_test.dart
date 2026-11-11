import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/app/trainer_command_runner.dart';
import 'package:test/test.dart';

import '../support/fake_windows_memory_api.dart';

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

TrainerCommandRunner _runnerForApi(
  FakeWindowsMemoryApi api, {
  List<int> processIds = const [],
}) => TrainerCommandRunner(
  sdk: LudavaSdk.create(
    profiles: [_syntheticProfile],
    api: api.adapter,
    isWindows: true,
    pointerSize: 8,
    discoverProcessIds: () => processIds,
  ),
);

TrainerCommandRunner _writeCapableCli(
  FakeWindowsMemoryApi api, {
  GameDetectionResult Function(int processId)? currentIdentity,
  Rpcs3MemoryBaseCandidate? Function(Rpcs3ProcessMetadata processMetadata)?
  resolveCurrentBase,
}) => TrainerCommandRunner(
  sdk: LudavaSdk.create(
    profiles: [_syntheticProfile],
    api: api.adapter,
    isWindows: true,
    pointerSize: 8,
    discoverProcessIds: () => const [42],
    readProcessMetadata: (_) => _metadata,
    resolveMemoryBaseCandidate:
        resolveCurrentBase ??
        (_) => const Rpcs3MemoryBaseCandidate(
          memoryBase: 0x300000000,
          logPath: r'C:\RPCS3\log\RPCS3.log',
        ),
    detectGame:
        (processId, _) =>
            currentIdentity?.call(processId) ?? _confirmedIdentity(processId),
  ),
);

GameDetectionResult _confirmedIdentity(int processId) => GameDetectionResult(
  status: GameDetectionStatus.supportedGame,
  processId: processId,
  titleId: _syntheticProfile.buildId,
  gameTitle: _syntheticProfile.gameName,
  executable: _syntheticProfile.executable,
  executableHash: _syntheticProfile.executableHash,
  confidence: GameIdentityConfidence.confirmed,
  profile: _syntheticProfile,
  evidenceDescription: 'Synthetic process metadata for the CLI integration.',
);

final _metadata = Rpcs3ProcessMetadata(
  executablePath: r'C:\RPCS3\rpcs3.exe',
  startedAtUtc: DateTime.utc(2026, 11, 5, 10),
);

List<String> _readArguments({
  String? gameId,
  String fieldId = 'credits',
  int processId = 42,
}) => [
  'read',
  '--game',
  gameId ?? _syntheticProfile.id,
  '--field',
  fieldId,
  '--pid',
  '$processId',
  '--memory-base',
  '0x300000000',
];

List<String> _writeArguments() => [
  'write',
  '--game',
  _syntheticProfile.id,
  '--field',
  'credits',
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

    test('Method runAsync() routes a diagnostic read to the SDK', () async {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 42];
      final sdk = LudavaSdk.create(
        profiles: [_syntheticProfile],
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
      expect(output.toString(), isNotEmpty);
      expect(api.readCalls, 1);
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
      'Method runAsync() maps identity mismatch and identity-check failure to write errors',
      () async {
        final mismatchErrors = StringBuffer();
        final mismatchApi = FakeWindowsMemoryApi();
        final mismatchExitCode = await _writeCapableCli(
          mismatchApi,
          currentIdentity:
              (processId) => GameDetectionResult(
                status: GameDetectionStatus.noActiveGame,
                processId: processId,
                confidence: GameIdentityConfidence.none,
                evidenceDescription: 'No active synthetic game.',
              ),
        ).runAsync(_writeArguments(), errorOutput: mismatchErrors);

        expect(mismatchExitCode, 1);
        expect(
          mismatchErrors.toString(),
          contains('current RPCS3 game identity does not match'),
        );
        expect(mismatchApi.openCalls, 0);
        expect(mismatchApi.writeCalls, 0);

        final checkErrors = StringBuffer();
        final checkApi = FakeWindowsMemoryApi();
        final checkExitCode = await _writeCapableCli(
          checkApi,
          currentIdentity: (_) => throw Exception('identity check failed'),
        ).runAsync(_writeArguments(), errorOutput: checkErrors);

        expect(checkExitCode, 1);
        expect(
          checkErrors.toString(),
          contains('identity could not be checked'),
        );
        expect(checkErrors.toString(), contains('identity check failed'));
        expect(checkApi.openCalls, 0);
        expect(checkApi.writeCalls, 0);
      },
    );

    test(
      'Method runAsync() maps memory-base mismatch and check failure to write errors',
      () async {
        final mismatchErrors = StringBuffer();
        final mismatchApi = FakeWindowsMemoryApi();
        final mismatchExitCode = await _writeCapableCli(
          mismatchApi,
          resolveCurrentBase:
              (_) => const Rpcs3MemoryBaseCandidate(
                memoryBase: 0x300000001,
                logPath: r'C:\RPCS3\log\RPCS3.log',
              ),
        ).runAsync(_writeArguments(), errorOutput: mismatchErrors);

        expect(mismatchExitCode, 1);
        expect(
          mismatchErrors.toString(),
          contains('does not match the current RPCS3 session'),
        );
        expect(mismatchApi.openCalls, 0);
        expect(mismatchApi.writeCalls, 0);

        final checkErrors = StringBuffer();
        final checkApi = FakeWindowsMemoryApi();
        final checkExitCode = await _writeCapableCli(
          checkApi,
          resolveCurrentBase: (_) => throw Exception('base check failed'),
        ).runAsync(_writeArguments(), errorOutput: checkErrors);

        expect(checkExitCode, 1);
        expect(
          checkErrors.toString(),
          contains('memory base could not be checked'),
        );
        expect(checkErrors.toString(), contains('base check failed'));
        expect(checkApi.openCalls, 0);
        expect(checkApi.writeCalls, 0);
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
        expect(output.toString(), isNotEmpty);
        expect(errorOutput.toString(), isEmpty);
        expect(api.writeCalls, 1);
      },
    );

    test(
      'Method runAsync() returns an operational failure for an incomplete write',
      () async {
        final output = StringBuffer();
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi()..reportedWriteBytes = 2;

        final exitCode = await _writeCapableCli(
          api,
        ).runAsync(_writeArguments(), output: output, errorOutput: errorOutput);

        expect(exitCode, 1);
        expect(output.toString(), isNotEmpty);
        expect(errorOutput.toString(), isEmpty);
      },
    );

    test(
      'Method runAsync() returns cleanup failures on stderr with an operational exit code',
      () async {
        final output = StringBuffer();
        final errorOutput = StringBuffer();
        final api =
            FakeWindowsMemoryApi()
              ..readBytes = [0, 0, 0, 42]
              ..closeReturnValue = 0;

        final exitCode = await _runnerForApi(
          api,
        ).runAsync(_readArguments(), output: output, errorOutput: errorOutput);

        expect(exitCode, 1);
        expect(output.toString(), isNotEmpty);
        expect(errorOutput.toString(), contains('Windows error 5'));
      },
    );

    test(
      'Method runAsync() disposes the SDK after a diagnostic memory failure',
      () async {
        final api = FakeWindowsMemoryApi(handleAddress: 0)..errorCode = 5;
        final sdk = LudavaSdk.create(
          profiles: [_syntheticProfile],
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
      },
    );

    test('Method runAsync() launches Nocterm for no arguments', () async {
      var launchCalls = 0;
      TrainerSessionController? launchedSession;
      final sdk = LudavaSdk.create(profiles: [_syntheticProfile]);
      final closed = Completer<void>();
      final runner = TrainerCommandRunner(
        sdk: sdk,
        hasTerminal: true,
        runNocterm: (session) async {
          launchCalls++;
          launchedSession = session;
          session.stateChanges.listen((_) {}, onDone: closed.complete);
        },
      );

      final exitCode = await runner.runAsync([]);
      await closed.future.timeout(const Duration(seconds: 1));

      expect(exitCode, 0);
      expect(launchCalls, 1);
      expect(identical(launchedSession, sdk.session), isTrue);
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
  });
}
