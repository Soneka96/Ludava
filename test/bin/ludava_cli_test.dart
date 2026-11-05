import 'package:test/test.dart';

import 'package:ludava/features/game_memory/presentation/cli/interactive_trainer_cli.dart';

import '../../bin/ludava_cli.dart';
import '../support/fake_windows_memory_api.dart';

void main() {
  group('Method run() behaves correctly', () {
    test('Method run() starts the interactive menu without arguments', () {
      var discoveryCalls = 0;
      final interactiveCli = InteractiveTrainerCli(
        discoverProcessIds: () {
          discoveryCalls++;
          return const [];
        },
        readProcessMetadata: (_) => throw StateError('no process selected'),
        resolveMemoryBaseCandidate: (_) => null,
        runCommand: (_, __, ___) => 0,
        readLine: () => '0',
        hasTerminal: true,
      );
      final output = StringBuffer();
      final errorOutput = StringBuffer();

      final exitCode = LudavaCli(interactiveCli: interactiveCli).run(
        [],
        output: output,
        errorOutput: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.toString(), contains('LUDAVA'));
      expect(output.toString(), contains('RPCS3 was not found'));
      expect(discoveryCalls, 1);
      expect(errorOutput.toString(), isEmpty);
    });

    test('Method run() rejects interactive mode when input is not a terminal',
        () {
      var discoveryCalls = 0;
      final interactiveCli = InteractiveTrainerCli(
        discoverProcessIds: () {
          discoveryCalls++;
          return const [];
        },
        readProcessMetadata: (_) => throw StateError('not reached'),
        resolveMemoryBaseCandidate: (_) => null,
        runCommand: (_, __, ___) => 0,
        readLine: () => throw StateError('must not read input'),
        hasTerminal: false,
      );
      final output = StringBuffer();
      final errorOutput = StringBuffer();

      final exitCode = LudavaCli(interactiveCli: interactiveCli).run(
        [],
        output: output,
        errorOutput: errorOutput,
      );

      expect(exitCode, 2);
      expect(errorOutput.toString(), contains('requires a terminal'));
      expect(discoveryCalls, 0);
    });

    test('Method run() prints help without opening a process', () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(['--help'], output: output, errorOutput: errorOutput);

      expect(exitCode, 0);
      expect(
        output.toString(),
        contains('No arguments starts the interactive trainer'),
      );
      expect(output.toString(), contains('bin/ludava.dart read'));
      expect(output.toString(), contains('Ludava does not'));
      expect(output.toString(), contains('verify the active game build'));
      expect(output.toString(), contains('Repeat the read command to refresh'));
      expect(errorOutput.toString(), isEmpty);
      expect(api.openCalls, 0);
    });

    test('Method run() reads the selected field through the generic profile',
        () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 42];

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
        ],
        output: output,
        errorOutput: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.toString(), contains('Field: bolts'));
      expect(output.toString(), contains('Value: 42'));
      expect(errorOutput.toString(), isEmpty);
      expect(api.requestedAccess, 0x0010);
      expect(api.readAddress, 0x301329e80);
      expect(api.writeCalls, 0);
      expect(api.closeCalls, 1);
    });

    test('Method run() reports an unknown profile before opening a process',
        () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'read',
          '--game',
          'unknown',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
        ],
        errorOutput: errorOutput,
      );

      expect(exitCode, 2);
      expect(errorOutput.toString(), contains('Unknown game profile'));
      expect(api.openCalls, 0);
    });

    test('Method run() reports an unavailable field before opening a process',
        () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'health',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
        ],
        output: output,
      );

      expect(exitCode, 1);
      expect(output.toString(), contains('field is not approved for reading'));
      expect(api.openCalls, 0);
    });

    test('Method run() writes bolts and reports a matching native read-back',
        () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 50];

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'write',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
          '--value',
          '50',
          '--confirm-write',
        ],
        output: output,
        errorOutput: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.toString(), contains('Profile status: researchConfirmed'));
      expect(output.toString(), contains('Requested value: 50'));
      expect(output.toString(), contains('Read-back value: 50'));
      expect(
          output.toString(), contains('Status: write and read-back complete'));
      expect(output.toString(), contains('does not verify the active game'));
      expect(errorOutput.toString(), isEmpty);
      expect(api.requestedAccess, 0x0038);
      expect(api.writeAddress, 0x301329e80);
      expect(api.writtenBytes, [0, 0, 0, 50]);
      expect(api.readCalls, 1);
      expect(api.readAddress, 0x301329e80);
      expect(api.closeCalls, 1);
    });

    test('Method run() reports native write failures and closes the handle',
        () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi()
        ..writeReturnValue = 0
        ..reportedWriteBytes = 0
        ..errorCode = 5;

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'write',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
          '--value',
          '50',
          '--confirm-write',
        ],
        output: output,
      );

      expect(exitCode, 1);
      expect(output.toString(), contains('Status: native memory write failed'));
      expect(output.toString(), contains('Windows error: 5'));
      expect(api.readCalls, 0);
      expect(api.closeCalls, 1);
    });

    test('Method run() reports partial writes without reading back', () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi()..reportedWriteBytes = 2;

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'write',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
          '--value',
          '50',
          '--confirm-write',
        ],
        output: output,
      );

      expect(exitCode, 1);
      expect(output.toString(), contains('Status: incomplete memory write'));
      expect(api.readCalls, 0);
      expect(api.closeCalls, 1);
    });

    test('Method run() rejects values above uint32 without writing', () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'write',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
          '--value',
          '4294967296',
          '--confirm-write',
        ],
        output: output,
      );

      expect(exitCode, 1);
      expect(output.toString(),
          contains('Status: value is outside the field range'));
      expect(api.writeCalls, 0);
      expect(api.readCalls, 0);
      expect(api.closeCalls, 1);
    });

    test('Method run() reports a read-back mismatch accurately', () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 49];

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'write',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
          '--value',
          '50',
          '--confirm-write',
        ],
        output: output,
      );

      expect(exitCode, 1);
      expect(output.toString(), contains('Status: read-back did not match'));
      expect(output.toString(), contains('Requested value: 50'));
      expect(output.toString(), contains('Read-back value: 49'));
      expect(api.readCalls, 1);
      expect(api.closeCalls, 1);
    });

    test('Method run() reports read-back failures after a complete write', () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi()
        ..readReturnValue = 0
        ..errorCode = 299;

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'write',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
          '--value',
          '50',
          '--confirm-write',
        ],
        output: output,
      );

      expect(exitCode, 1);
      expect(output.toString(), contains('Status: write read-back failed'));
      expect(output.toString(), contains('Windows error: 299'));
      expect(api.writeCalls, 1);
      expect(api.readCalls, 1);
      expect(api.closeCalls, 1);
    });

    test('Method run() reports unsupported platforms before opening', () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: false,
        pointerSize: 8,
      ).run(
        [
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
        ],
        errorOutput: errorOutput,
      );

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('Windows only'));
      expect(api.openCalls, 0);
      expect(api.closeCalls, 0);
    });

    test('Method run() reports unsupported pointer sizes before opening', () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 4,
      ).run(
        [
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
        ],
        errorOutput: errorOutput,
      );

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('requires 64-bit Windows'));
      expect(api.openCalls, 0);
    });

    test('Method run() reports handle-close failures after a read', () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi()
        ..readBytes = [0, 0, 0, 42]
        ..closeReturnValue = 0
        ..errorCode = 6;

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
        ],
        output: output,
        errorOutput: errorOutput,
      );

      expect(exitCode, 1);
      expect(output.toString(), contains('Value: 42'));
      expect(errorOutput.toString(), contains('CloseHandle'));
      expect(errorOutput.toString(), contains('Windows error 6'));
      expect(api.closeCalls, 1);
    });

    test('Method run() rejects unsupported write fields before opening', () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'write',
          '--game',
          'rc2-collection',
          '--field',
          'health',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
          '--value',
          '50',
          '--confirm-write',
        ],
        output: output,
      );

      expect(exitCode, 1);
      expect(output.toString(), contains('field is not approved for writing'));
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test('Method run() reports inaccessible processes with the Windows error',
        () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi(handleAddress: 0)..errorCode = 5;

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
        ],
        errorOutput: errorOutput,
      );

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('Windows error 5'));
      expect(api.lastErrorCalls, 1);
    });

    test('Method run() returns an argument error before opening a process', () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(['read', '--pid', '42'], errorOutput: errorOutput);

      expect(exitCode, 2);
      expect(errorOutput.toString(), contains('--game, --field, --pid'));
      expect(api.openCalls, 0);
    });
  });
}
