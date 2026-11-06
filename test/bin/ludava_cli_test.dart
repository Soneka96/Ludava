import 'dart:io';

import 'package:test/test.dart';

import 'package:ludava/features/game_memory/data/datasources/rpcs3_game_identity_log.datasource.dart';
import 'package:ludava/features/game_memory/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/game_catalog/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava/features/game_memory/presentation/cli/interactive_trainer_cli.dart';
import 'package:ludava/shared/constants/enums.dart';

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

      final exitCode = LudavaCli(
        interactiveCli: interactiveCli,
      ).run([], output: output, errorOutput: errorOutput);

      expect(exitCode, 0);
      expect(output.toString(), contains('LUDAVA'));
      expect(output.toString(), contains('RPCS3 was not found'));
      expect(discoveryCalls, 1);
      expect(errorOutput.toString(), isEmpty);
    });

    test(
      'Method run() rejects interactive mode when input is not a terminal',
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

        final exitCode = LudavaCli(
          interactiveCli: interactiveCli,
        ).run([], output: output, errorOutput: errorOutput);

        expect(exitCode, 2);
        expect(errorOutput.toString(), contains('requires a terminal'));
        expect(discoveryCalls, 0);
      },
    );

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
      expect(output.toString(), contains('current matching PPU identity'));
      expect(output.toString(), contains('Repeat a read to'));
      expect(output.toString(), contains('refresh.'));
      expect(errorOutput.toString(), isEmpty);
      expect(api.openCalls, 0);
    });

    test(
      'Method run() reads the selected field through the generic profile',
      () {
        final output = StringBuffer();
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 42];

        final exitCode = _writeCapableCli(api).run(
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

        expect(exitCode, 0, reason: errorOutput.toString());
        expect(output.toString(), contains('Field: bolts'));
        expect(output.toString(), contains('Value: 42'));
        expect(errorOutput.toString(), isEmpty);
        expect(api.requestedAccess, 0x0010);
        expect(api.readAddress, 0x301329e80);
        expect(api.writeCalls, 0);
        expect(api.closeCalls, 1);
      },
    );

    test('Method run() reports direct read failures and closes the handle', () {
      final output = StringBuffer();
      final api =
          FakeWindowsMemoryApi()
            ..readReturnValue = 0
            ..errorCode = 299;

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run([
        'read',
        '--game',
        'rc2-collection',
        '--field',
        'bolts',
        '--pid',
        '42',
        '--memory-base',
        '0x300000000',
      ], output: output);

      expect(exitCode, 1);
      expect(output.toString(), contains('Status: native memory read failed'));
      expect(output.toString(), contains('Windows error: 299'));
      expect(api.closeCalls, 1);
    });

    test(
      'Method run() reports incomplete direct reads and closes the handle',
      () {
        final output = StringBuffer();
        final api = FakeWindowsMemoryApi()..reportedReadBytes = 2;

        final exitCode = LudavaCli(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
        ).run([
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
        ], output: output);

        expect(exitCode, 1);
        expect(output.toString(), contains('Status: incomplete memory read'));
        expect(api.closeCalls, 1);
      },
    );

    test(
      'Method run() reports an unknown profile before opening a process',
      () {
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi();

        final exitCode = LudavaCli(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
        ).run([
          'read',
          '--game',
          'unknown',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
        ], errorOutput: errorOutput);

        expect(exitCode, 2);
        expect(errorOutput.toString(), contains('Unknown game profile'));
        expect(api.openCalls, 0);
      },
    );

    test(
      'Method run() reports an unavailable field before opening a process',
      () {
        final output = StringBuffer();
        final api = FakeWindowsMemoryApi();

        final exitCode = LudavaCli(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
        ).run([
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'health',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
        ], output: output);

        expect(exitCode, 1);
        expect(
          output.toString(),
          contains('field is not approved for reading'),
        );
        expect(api.openCalls, 0);
      },
    );

    test(
      'Method run() writes bolts and reports a matching native read-back',
      () {
        final output = StringBuffer();
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 50];

        final exitCode = _writeCapableCli(api).run(
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

        expect(exitCode, 0, reason: errorOutput.toString());
        expect(
          output.toString(),
          contains('Profile status: researchConfirmed'),
        );
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
        expect(errorOutput.toString(), isEmpty);
        expect(api.requestedAccess, 0x0038);
        expect(api.writeAddress, 0x301329e80);
        expect(api.writtenBytes, [0, 0, 0, 50]);
        expect(api.readCalls, 2);
        expect(api.readAddress, 0x301329e80);
        expect(api.closeCalls, 1);
      },
    );

    test(
      'Method run() authorizes a direct write from the current PPU hash',
      () {
        final output = StringBuffer();
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 50];
        final cli = _logBackedCli(
          api,
          logContents: '''
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/RC2.ppu.self
SYS: Title: Ratchet & Clank Collection
SYS: Serial: BCUS98282
vm::g_base_addr = 0000000300000000 - 00000003ffffffff
ppu_loader: PPU executable hash: PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9
''',
        );

        final exitCode = cli.run(
          _rc2WriteArguments(),
          output: output,
          errorOutput: errorOutput,
        );

        expect(exitCode, 0);
        expect(
          output.toString(),
          contains('current RPCS3 PPU hash matches this profile'),
        );
        expect(api.writeCalls, 1);
        expect(errorOutput.toString(), isEmpty);
      },
    );

    test(
      'Method run() blocks a direct write when the latest event is a stop',
      () {
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi();
        final cli = _logBackedCli(
          api,
          logContents: '''
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/RC2.ppu.self
SYS: Title: Ratchet & Clank Collection
SYS: Serial: BCUS98282
ppu_loader: PPU executable hash: PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9
sys_process: Process finished
''',
        );

        final exitCode = cli.run(
          _rc2WriteArguments(),
          errorOutput: errorOutput,
        );

        expect(exitCode, 1);
        expect(errorOutput.toString(), contains('Write blocked'));
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test('Method run() blocks a direct write at the Collection menu', () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();
      final cli = _logBackedCli(
        api,
        logContents: '''
SYS: Path: D:/Games/Ratchet & Clank Collection.iso
SYS: Title: Ratchet & Clank Collection
SYS: Serial: BCUS98282
SYS: Elf path: D:/Games/USRDIR/EBOOT.BIN
ppu_loader: PPU executable hash: PPU-673b1ce1b01ce7f42f1787a479f9b83854fa26f5
''',
      );

      final exitCode = cli.run(_rc2WriteArguments(), errorOutput: errorOutput);

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('Write blocked'));
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test(
      'Method run() blocks a direct write when the current log has no game',
      () {
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi();
        final cli = _logBackedCli(api, logContents: 'RPCS3 started');

        final exitCode = cli.run(
          _rc2WriteArguments(),
          errorOutput: errorOutput,
        );

        expect(exitCode, 1);
        expect(errorOutput.toString(), contains('Write blocked'));
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test('Method run() blocks a direct write for an unknown PPU hash', () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();
      final cli = _logBackedCli(
        api,
        logContents: '''
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/Unknown.ppu.self
SYS: Title: Ratchet & Clank Collection
SYS: Serial: BCUS98282
ppu_loader: PPU executable hash: PPU-0000000000000000000000000000000000000000
''',
      );

      final exitCode = cli.run(_rc2WriteArguments(), errorOutput: errorOutput);

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('Write blocked'));
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test(
      'Method run() blocks a direct write when RPCS3 instances share a log',
      () {
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi();
        final cli = _logBackedCli(
          api,
          logContents: '''
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/RC2.ppu.self
SYS: Title: Ratchet & Clank Collection
SYS: Serial: BCUS98282
ppu_loader: PPU executable hash: PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9
''',
          processIds: const [42, 43],
        );

        final exitCode = cli.run(
          _rc2WriteArguments(),
          errorOutput: errorOutput,
        );

        expect(exitCode, 1);
        expect(errorOutput.toString(), contains('Write blocked'));
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test(
      'Method run() blocks a direct write when fresh log candidates are ambiguous',
      () {
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi();
        final cli = _logBackedCli(
          api,
          logContents: '''
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/RC2.ppu.self
SYS: Title: Ratchet & Clank Collection
SYS: Serial: BCUS98282
ppu_loader: PPU executable hash: PPU-8f729e902ad2c7ae0f7f4cbacbfaa17dcb080be9
''',
          includeSecondCandidateLog: true,
        );

        final exitCode = cli.run(
          _rc2WriteArguments(),
          errorOutput: errorOutput,
        );

        expect(exitCode, 1);
        expect(errorOutput.toString(), contains('Write blocked'));
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test(
      'Method run() blocks a direct write when the fresh log is unreadable',
      () {
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi();
        final cli = _logBackedCli(
          api,
          logContents: '',
          readLog: (_) => throw FileSystemException('sharing violation'),
        );

        final exitCode = cli.run(
          _rc2WriteArguments(),
          errorOutput: errorOutput,
        );

        expect(exitCode, 1);
        expect(
          errorOutput.toString(),
          contains('identity could not be checked'),
        );
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test('Method run() blocks a write when identity is unresolved', () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();
      final identity = GameDetectionResult(
        status: GameDetectionStatus.ambiguous,
        processId: 42,
        confidence: GameIdentityConfidence.uncertain,
        evidenceDescription: 'Unknown PPU hash.',
      );

      final exitCode = _writeCapableCli(api, identity: identity).run([
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
      ], errorOutput: errorOutput);

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('Write blocked'));
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test('Method run() blocks an automatic read when identity is stale', () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();
      final identity = GameDetectionResult(
        status: GameDetectionStatus.noActiveGame,
        processId: 42,
        confidence: GameIdentityConfidence.none,
        evidenceDescription: 'The game has stopped.',
      );

      final exitCode = _writeCapableCli(api, identity: identity).run(
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
          '--require-current-identity',
        ],
        output: output,
        errorOutput: errorOutput,
      );

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('Read blocked'));
      expect(api.openCalls, 0);
      expect(api.readCalls, 0);
    });

    test(
      'Method run() blocks an identity-guarded read when metadata fails',
      () {
        final output = StringBuffer();
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi();
        final cli = LudavaCli(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () => [42],
          readProcessMetadata: (_) => throw Exception('metadata unavailable'),
          resolveMemoryBaseCandidate: (_) => null,
        );

        final exitCode = cli.run(
          _rc2ReadArguments(requireCurrentIdentity: true),
          output: output,
          errorOutput: errorOutput,
        );

        expect(exitCode, 1);
        expect(errorOutput.toString(), contains('Read blocked'));
        expect(api.openCalls, 0);
        expect(api.readCalls, 0);
      },
    );

    test(
      'Method run() blocks an identity-guarded read when detection fails',
      () {
        final output = StringBuffer();
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi();
        final cli = LudavaCli(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
          discoverProcessIds: () => [42],
          readProcessMetadata:
              (_) => Rpcs3ProcessMetadata(
                executablePath: r'C:\RPCS3\rpcs3.exe',
                startedAtUtc: DateTime.utc(2026, 11, 5, 10),
              ),
          resolveMemoryBaseCandidate: (_) => null,
          detectGame: (_, _) => throw Exception('log read failed'),
        );

        final exitCode = cli.run(
          _rc2ReadArguments(requireCurrentIdentity: true),
          output: output,
          errorOutput: errorOutput,
        );

        expect(exitCode, 1);
        expect(errorOutput.toString(), contains('Read blocked'));
        expect(api.openCalls, 0);
        expect(api.readCalls, 0);
      },
    );

    test('Method run() blocks a write when the session base has changed', () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = _writeCapableCli(
        api,
        currentMemoryBase: 0x400000000,
      ).run([
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
      ], errorOutput: errorOutput);

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('memory base'));
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test(
      'Method run() blocks a write when the selected process has exited',
      () {
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi();

        final exitCode = _writeCapableCli(api, processIds: const []).run([
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
        ], errorOutput: errorOutput);

        expect(exitCode, 1);
        expect(errorOutput.toString(), contains('Write blocked'));
        expect(api.openCalls, 0);
        expect(api.writeCalls, 0);
      },
    );

    test('Method run() prevents a write when the preliminary read fails', () {
      final output = StringBuffer();
      final api =
          FakeWindowsMemoryApi()
            ..readReturnValue = 0
            ..errorCode = 299;

      final exitCode = _writeCapableCli(api).run([
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
      ], output: output);

      expect(exitCode, 1);
      expect(
        output.toString(),
        contains('Status: preliminary memory read failed'),
      );
      expect(output.toString(), contains('Windows error: 299'));
      expect(api.readCalls, 1);
      expect(api.writeCalls, 0);
      expect(api.closeCalls, 1);
    });

    test(
      'Method run() prevents a write after an incomplete preliminary read',
      () {
        final output = StringBuffer();
        final api = FakeWindowsMemoryApi()..reportedReadBytes = 2;

        final exitCode = _writeCapableCli(api).run([
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
        ], output: output);

        expect(exitCode, 1);
        expect(
          output.toString(),
          contains('Status: preliminary memory read failed'),
        );
        expect(api.readCalls, 1);
        expect(api.writeCalls, 0);
      },
    );

    test(
      'Method run() reports native write failures and closes the handle',
      () {
        final output = StringBuffer();
        final api =
            FakeWindowsMemoryApi()
              ..writeReturnValue = 0
              ..reportedWriteBytes = 0
              ..errorCode = 5;

        final exitCode = _writeCapableCli(api).run([
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
        ], output: output);

        expect(exitCode, 1);
        expect(
          output.toString(),
          contains('Status: native memory write failed'),
        );
        expect(output.toString(), contains('Windows error: 5'));
        expect(api.readCalls, 1);
        expect(api.closeCalls, 1);
      },
    );

    test('Method run() reports partial writes without reading back', () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi()..reportedWriteBytes = 2;

      final exitCode = _writeCapableCli(api).run([
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
      ], output: output);

      expect(exitCode, 1);
      expect(output.toString(), contains('Status: incomplete memory write'));
      expect(api.readCalls, 1);
      expect(api.closeCalls, 1);
    });

    test('Method run() rejects values above uint32 without writing', () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = _writeCapableCli(api).run([
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
      ], output: output);

      expect(exitCode, 1);
      expect(
        output.toString(),
        contains('Status: value is outside the field range'),
      );
      expect(api.writeCalls, 0);
      expect(api.readCalls, 0);
      expect(api.closeCalls, 1);
    });

    test('Method run() reports a read-back mismatch accurately', () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 49];

      final exitCode = _writeCapableCli(api).run([
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
      ], output: output);

      expect(exitCode, 1);
      expect(output.toString(), contains('Status: read-back did not match'));
      expect(output.toString(), contains('Requested value: 50'));
      expect(output.toString(), contains('Read-back value: 49'));
      expect(api.readCalls, 2);
      expect(api.closeCalls, 1);
    });

    test('Method run() reports read-back failures after a complete write', () {
      final output = StringBuffer();
      final api =
          FakeWindowsMemoryApi()
            ..readReturnValues = [1, 0]
            ..errorCode = 299;

      final exitCode = _writeCapableCli(api).run([
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
      ], output: output);

      expect(exitCode, 1);
      expect(output.toString(), contains('Status: write read-back failed'));
      expect(output.toString(), contains('Windows error: 299'));
      expect(api.writeCalls, 1);
      expect(api.readCalls, 2);
      expect(api.closeCalls, 1);
    });

    test('Method run() reports unsupported platforms before opening', () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: false,
        pointerSize: 8,
      ).run([
        'read',
        '--game',
        'rc2-collection',
        '--field',
        'bolts',
        '--pid',
        '42',
        '--memory-base',
        '0x300000000',
      ], errorOutput: errorOutput);

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
      ).run([
        'read',
        '--game',
        'rc2-collection',
        '--field',
        'bolts',
        '--pid',
        '42',
        '--memory-base',
        '0x300000000',
      ], errorOutput: errorOutput);

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('requires 64-bit Windows'));
      expect(api.openCalls, 0);
    });

    test('Method run() reports handle-close failures after a read', () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();
      final api =
          FakeWindowsMemoryApi()
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
      ).run([
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
      ], output: output);

      expect(exitCode, 1);
      expect(output.toString(), contains('field is not approved for writing'));
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test(
      'Method run() reports inaccessible processes with the Windows error',
      () {
        final errorOutput = StringBuffer();
        final api = FakeWindowsMemoryApi(handleAddress: 0)..errorCode = 5;

        final exitCode = LudavaCli(
          api: api.adapter,
          isWindows: true,
          pointerSize: 8,
        ).run([
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
        ], errorOutput: errorOutput);

        expect(exitCode, 1);
        expect(errorOutput.toString(), contains('Windows error 5'));
        expect(api.lastErrorCalls, 1);
      },
    );

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

LudavaCli _writeCapableCli(
  FakeWindowsMemoryApi api, {
  GameDetectionResult? identity,
  int? currentMemoryBase = 0x300000000,
  List<int> processIds = const [42],
}) => LudavaCli(
  api: api.adapter,
  isWindows: true,
  pointerSize: 8,
  discoverProcessIds: () => processIds,
  readProcessMetadata:
      (_) => Rpcs3ProcessMetadata(
        executablePath: r'C:\RPCS3\rpcs3.exe',
        startedAtUtc: DateTime.utc(2026, 11, 5, 10),
      ),
  resolveMemoryBaseCandidate:
      (_) =>
          currentMemoryBase == null
              ? null
              : Rpcs3MemoryBaseCandidate(
                memoryBase: currentMemoryBase,
                logPath: r'C:\RPCS3\log\RPCS3.log',
              ),
  detectGame:
      (processId, _) =>
          identity ??
          GameDetectionResult(
            status: GameDetectionStatus.supportedGame,
            processId: processId,
            titleId: Rc2CollectionProfile.profile.buildId,
            gameTitle: Rc2CollectionProfile.profile.gameName,
            executable: Rc2CollectionProfile.profile.executable,
            executableHash: Rc2CollectionProfile.profile.executableHash,
            confidence: GameIdentityConfidence.confirmed,
            profile: Rc2CollectionProfile.profile,
            evidenceDescription:
                'Measured PPU identity for the selected process.',
          ),
);

LudavaCli _logBackedCli(
  FakeWindowsMemoryApi api, {
  required String logContents,
  List<int> processIds = const [42],
  bool includeSecondCandidateLog = false,
  String Function(String path)? readLog,
}) => LudavaCli(
  api: api.adapter,
  isWindows: true,
  pointerSize: 8,
  discoverProcessIds: () => processIds,
  readProcessMetadata:
      (_) => Rpcs3ProcessMetadata(
        executablePath: r'C:\RPCS3\rpcs3.exe',
        startedAtUtc: DateTime.utc(2026, 11, 5, 10),
      ),
  resolveMemoryBaseCandidate:
      (_) => const Rpcs3MemoryBaseCandidate(
        memoryBase: 0x300000000,
        logPath: r'C:\RPCS3\log\RPCS3.log',
      ),
  gameIdentityLogDataSource: Rpcs3GameIdentityLogDataSource(
    fileExists:
        (path) =>
            path == r'C:\RPCS3\log\RPCS3.log' ||
            (includeSecondCandidateLog && path == r'C:\RPCS3\RPCS3.log'),
    lastModifiedUtc: (_) => DateTime.utc(2026, 11, 5, 10, 1),
    readAsString: readLog ?? (_) => logContents,
  ),
);

List<String> _rc2WriteArguments() => const [
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
];

List<String> _rc2ReadArguments({bool requireCurrentIdentity = false}) => [
  'read',
  '--game',
  'rc2-collection',
  '--field',
  'bolts',
  '--pid',
  '42',
  '--memory-base',
  '0x300000000',
  if (requireCurrentIdentity) '--require-current-identity',
];
