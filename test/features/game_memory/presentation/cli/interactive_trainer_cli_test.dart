import 'dart:io';

import 'package:ludava/features/game_memory/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/game_memory/presentation/cli/interactive_trainer_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Method run() behaves correctly', () {
    test('Method run() lists all three Collection games in order', () {
      final harness = _InteractiveHarness()
        ..processResults = [[42]]
        ..inputs = ['1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(output.toString(), contains('1. Ratchet & Clank — PS3 Collection'));
      expect(output.toString(), contains('2. Ratchet & Clank 2 — PS3 Collection'));
      expect(output.toString(), contains('3. Ratchet & Clank 3 — PS3 Collection'));
      expect(harness.readCommands, isEmpty);
    });

    test('Method run() selects the RC1 profile for reading bolts', () {
      final harness = _InteractiveHarness()
        ..processResults = [[42]]
        ..inputs = ['1', '1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.readCommands, hasLength(1));
      expect(harness.readCommands.single, containsAll(['--game', 'rc1-collection']));
      expect(output.toString(), contains('  Ratchet & Clank\n'));
      expect(output.toString(), contains('  PS3 Collection'));
    });

    test('Method run() selects the RC3 profile for reading bolts', () {
      final harness = _InteractiveHarness()
        ..processResults = [[42]]
        ..inputs = ['1', '3', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.readCommands, hasLength(1));
      expect(harness.readCommands.single, containsAll(['--game', 'rc3-collection']));
      expect(output.toString(), contains('Ratchet & Clank 3'));
      expect(output.toString(), contains('  PS3 Collection'));
    });

    test('Method run() routes RC1 and RC3 bolt changes to selected profiles', () {
      for (final selection in ['1', '3']) {
        final harness = _InteractiveHarness()
          ..processResults = [[42]]
          ..inputs = ['1', selection, '2', '1234', 'y', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(harness.writeCommands, hasLength(1));
        expect(
          harness.writeCommands.single,
          containsAll([
            '--game',
            'rc$selection-collection',
            '--field',
            'bolts',
            '--value',
            '1234',
            '--confirm-write',
          ]),
        );
        expect(output.toString(), contains('Bolts updated successfully'));
      }
    });

    test('Method run() explains unavailable data for the selected RC3 game', () {
      final harness = _InteractiveHarness()
        ..processResults = [[42]]
        ..readExitCode = 1
        ..inputs = ['1', '3', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(output.toString(), contains('Start Ratchet & Clank 3 in RPCS3'));
      expect(harness.writeCommands, isEmpty);
    });

    test('Method run() rejects non-terminal input without discovering', () {
      final harness = _InteractiveHarness()..hasTerminal = false;
      final output = StringBuffer();
      final errorOutput = StringBuffer();

      final exitCode = harness.run(output, errorOutput);

      expect(exitCode, 2);
      expect(errorOutput.toString(), contains('requires a terminal'));
      expect(harness.discoveryCalls, 0);
    });

    test('Method run() offers a retry when RPCS3 is not found', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [],
              [42],
            ]
            ..inputs = ['1', '1', '2', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.discoveryCalls, 2);
      expect(output.toString(), contains('RPCS3 was not found'));
      expect(harness.readCommands, hasLength(1));
      expect(harness.readCommands.single, contains('0x300000000'));
    });

    test('Method run() retries process discovery after an exception', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..discoveryError = Exception('temporary discovery issue')
            ..inputs = ['1', '1', '2', '0'];
      final errorOutput = StringBuffer();

      harness.run(StringBuffer(), errorOutput);

      expect(harness.discoveryCalls, 2);
      expect(errorOutput.toString(), contains('temporary discovery issue'));
      expect(harness.readCommands, hasLength(1));
    });

    test('Method run() reports unsupported process discovery and exits', () {
      final harness =
          _InteractiveHarness()
            ..unsupportedDiscoveryError = UnsupportedError(
              'process discovery is unavailable',
            );
      final errorOutput = StringBuffer();

      final exitCode = harness.run(StringBuffer(), errorOutput);

      expect(exitCode, 0);
      expect(harness.discoveryCalls, 1);
      expect(
        errorOutput.toString(),
        contains('process discovery is unavailable'),
      );
      expect(harness.commands, isEmpty);
    });

    test('Method run() clears each menu screen and redraws after retry', () {
      var clearCalls = 0;
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['3', '0']
            ..clearScreen = () {
              clearCalls++;
              return true;
            };
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(clearCalls, 3);
      expect(
        output.toString(),
        isNot(contains('----------------------------------------')),
      );
      expect(
        'Ludava could not find the memory base automatically'.allMatches(
          output.toString(),
        ),
        hasLength(2),
      );
    });

    test(
      'Method run() uses a separator when screen clearing is unavailable',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..inputs = ['0']
              ..clearScreen = () => false;
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(
          output.toString(),
          contains('----------------------------------------'),
        );
      },
    );

    test('Method run() asks the user to select among multiple processes', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [101, 202],
            ]
            ..inputs = ['2', '1', '2', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.metadataProcessIds, [202]);
      expect(harness.readCommands.single, containsAll(['--pid', '202']));
      expect(output.toString(), contains('Several RPCS3 processes'));
    });

    test('Method run() confirms a recent log candidate before using it', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..candidate = const Rpcs3MemoryBaseCandidate(
              memoryBase: 0x400000000,
              logPath: r'C:\RPCS3\log\RPCS3.log',
            )
            ..inputs = ['1', '2', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.readCommands.single, contains('0x400000000'));
      expect(output.toString(), contains('may belong to another RPCS3'));
    });

    test(
      'Method run() accepts a manual hexadecimal base after invalid input',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..inputs = ['2', 'not-hex', '0x400000000', '2', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(harness.readCommands.single, contains('0x400000000'));
        expect(output.toString(), contains('Invalid memory base'));
      },
    );

    test('Method run() retries memory-base detection when requested', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..candidateByAttempt = [
              null,
              const Rpcs3MemoryBaseCandidate(
                memoryBase: 0x500000000,
                logPath: r'C:\RPCS3\log\RPCS3.log',
              ),
            ]
            ..inputs = ['3', '1', '2', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.resolveCalls, 2);
      expect(harness.readCommands.single, contains('0x500000000'));
    });

    test(
      'Method run() keeps console output writable after synchronous prompts',
      () {
        final inputs = ['3', '2', '0x400000000', '0'];
        var resolveCalls = 0;
        final cli = InteractiveTrainerCli(
          discoverProcessIds: () => [42],
          readProcessMetadata:
              (_) => Rpcs3ProcessMetadata(
                executablePath: r'C:\RPCS3\rpcs3.exe',
                startedAtUtc: DateTime.utc(2026, 11, 5),
              ),
          resolveMemoryBaseCandidate: (_) {
            resolveCalls++;
            return null;
          },
          runCommand:
              (_, __, ___) =>
                  throw StateError(
                    'The test exits before reading game memory.',
                  ),
          readLine: () => inputs.removeAt(0),
          hasTerminal: true,
        );

        final exitCode = cli.run();

        expect(exitCode, 0);
        expect(resolveCalls, 2);
        expect(inputs, isEmpty);
      },
    );

    test(
      'Method run() exits cleanly when memory-base selection is cancelled',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..inputs = ['0'];

        final exitCode = harness.run(StringBuffer(), StringBuffer());

        expect(exitCode, 0);
        expect(harness.commands, isEmpty);
      },
    );

    test(
      'Method run() exits cleanly when input ends during base selection',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ];

        final exitCode = harness.run(StringBuffer(), StringBuffer());

        expect(exitCode, 0);
        expect(harness.commands, isEmpty);
      },
    );

    test('Method run() exits cleanly when input ends at game selection', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1'];

      final exitCode = harness.run(StringBuffer(), StringBuffer());

      expect(exitCode, 0);
      expect(harness.commands, isEmpty);
    });

    test('Method run() exits cleanly when input ends at the game menu', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '2'];

      final exitCode = harness.run(StringBuffer(), StringBuffer());

      expect(exitCode, 0);
      expect(harness.readCommands, hasLength(1));
      expect(harness.writeCommands, isEmpty);
    });

    test('Method run() performs a new memory read when refreshing', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '2', '1', '0'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.readCommands, hasLength(2));
      expect(harness.readValues, 2);
    });

    test('Method run() redraws trainer context after refreshing a field', () {
      var clearCalls = 0;
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '2', '1', '0']
            ..clearScreen = () {
              clearCalls++;
              return true;
            };
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(clearCalls, 5);
      expect(output.toString(), contains('Connected to RPCS3'));
      expect(output.toString(), contains('  102'));
      expect(output.toString(), contains('Bolts refreshed.'));
    });

    test('Method run() keeps developer details off the game screen', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..boltValues = [293930]
            ..inputs = ['1', '2', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      final rendered = output.toString();
      final gameScreenStart = rendered.lastIndexOf('             LUDAVA');
      final gameScreen = rendered.substring(gameScreenStart);
      expect(gameScreen, contains('Ratchet & Clank 2'));
      expect(gameScreen, contains('PS3 Collection'));
      expect(gameScreen, contains('293,930'));
      expect(gameScreen, contains('1. Refresh bolts'));
      expect(gameScreen, contains('4. Connection details'));
      expect(gameScreen, isNot(contains('rc2-collection')));
      expect(gameScreen, isNot(contains('BCUS98282')));
      expect(gameScreen, isNot(contains('Process ID')));
      expect(gameScreen, isNot(contains('Memory base')));
      expect(gameScreen, isNot(contains('Profile status')));
    });

    test(
      'Method run() keeps process and runtime details in the advanced screen',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..inputs = ['1', '2', '4', '1', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(output.toString(), contains('Connection Details'));
        expect(output.toString(), contains('RPCS3 process ID: 42'));
        expect(output.toString(), contains('Memory base: 0x300000000'));
        expect(output.toString(), contains('Build ID: BCUS98282'));
        expect(
          output.toString(),
          contains('cannot confirm the active game or build'),
        );
      },
    );

    test(
      'Method run() explains unavailable game data without assuming the cause',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..omitReadValue = true
              ..inputs = ['1', '2', '4', '1', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(output.toString(), contains('RPCS3 process found'));
        expect(output.toString(), contains('  Not available'));
        expect(output.toString(), contains('Game data is not available.'));
        expect(output.toString(), contains('Start Ratchet & Clank 2 in RPCS3'));
        expect(output.toString(), contains('then select Refresh bolts.'));
        expect(output.toString(), contains('check Connection details.'));
        expect(output.toString(), contains('Connection Details'));
        expect(
          output.toString(),
          contains('Last read: The value could not be read.'),
        );
        expect(output.toString(), isNot(contains('  101')));
      },
    );

    test('Method run() refreshes after an initial field read fails', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..readExitCodes = [1, 0]
            ..boltValues = [0, 110]
            ..inputs = ['1', '2', '1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.readCommands, hasLength(2));
      expect(harness.writeCommands, isEmpty);
      expect(output.toString(), contains('Game data is not available.'));
      expect(output.toString(), contains('Bolts refreshed.'));
      expect(output.toString(), contains('  110'));
    });

    test(
      'Method run() explains an initial read failure in connection details',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..readExitCode = 1
              ..inputs = ['1', '2', '4', '1', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(output.toString(), contains('Game data is not available.'));
        expect(output.toString(), contains('Start Ratchet & Clank 2 in RPCS3'));
        expect(output.toString(), contains('If the game is already running'));
        expect(output.toString(), contains('Connection Details'));
        expect(
          output.toString(),
          contains('Last read: The memory read failed.'),
        );
      },
    );

    test('Method run() does not write when the user cancels confirmation', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '2', '2', '999999', 'n', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.writeCommands, isEmpty);
      expect(harness.readCommands, hasLength(2));
      expect(output.toString(), contains('Change cancelled'));
    });

    test('Method run() rejects an out-of-range value without writing', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '2', '2', '4294967296', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.writeCommands, isEmpty);
      expect(output.toString(), contains('between 0 and 4,294,967,295'));
    });

    test(
      'Method run() rejects non-numeric and negative values without writing',
      () {
        for (final value in ['not-a-number', '-1']) {
          final harness =
              _InteractiveHarness()
                ..processResults = [
                  [42],
                ]
                ..inputs = ['1', '2', '2', value, '0'];
          final output = StringBuffer();

          harness.run(output, StringBuffer());

          expect(harness.writeCommands, isEmpty);
          expect(output.toString(), contains('Enter a bolt value between'));
        }
      },
    );

    test('Method run() does not write when input ends at the value prompt', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '2', '2'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.writeCommands, isEmpty);
    });

    test('Method run() does not write when input ends at confirmation', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '2', '2', '999'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.writeCommands, isEmpty);
    });

    test('Method run() confirms a write and refreshes the field afterward', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '2', '2', '999999', 'Y', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.writeCommands, hasLength(1));
      expect(
        harness.writeCommands.single,
        containsAll(['--value', '999999', '--confirm-write']),
      );
      expect(harness.readCommands, hasLength(3));
      expect(output.toString(), contains('Bolts updated successfully'));
      expect(output.toString(), contains('999,999'));
    });

    test(
      'Method run() reports write failures and still refreshes the field',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..writeExitCode = 1
              ..readExitCodes = [0, 0, 1]
              ..writeErrorOutput = 'simulated write error'
              ..readErrorOutput = 'simulated refresh error'
              ..inputs = ['1', '2', '2', '5', 'y', '0'];
        final output = StringBuffer();
        final errorOutput = StringBuffer();

        harness.run(output, errorOutput);

        expect(output.toString(), contains('Could not update bolts'));
        expect(
          output.toString(),
          contains('The confirmed value did not match'),
        );
        expect(output.toString(), contains('Game data is not available.'));
        expect(errorOutput.toString(), contains('simulated write error'));
        expect(errorOutput.toString(), contains('simulated refresh error'));
        expect(harness.readCommands, hasLength(3));
      },
    );

    test(
      'Method run() cancels a write when the current value cannot be read',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..readExitCode = 1
              ..inputs = ['1', '2', '2', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(harness.writeCommands, isEmpty);
        expect(output.toString(), contains('Bolts could not be read'));
      },
    );

    test('Method run() returns to game selection when requested', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '2', '3', '3', '0'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.readCommands, hasLength(2));
    });

    test('Method run() re-evaluates the base after changing processes', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
              [43],
            ]
            ..candidateForProcess = (processId) {
              return Rpcs3MemoryBaseCandidate(
                memoryBase: processId == 42 ? 0x300000000 : 0x400000000,
                logPath: r'C:\RPCS3\log\RPCS3.log',
              );
            }
            ..inputs = ['1', '2', '4', '2', '1', '2', '2', '5', 'y', '0'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.metadataProcessIds, [42, 43]);
      expect(harness.readCommands[0], contains('0x300000000'));
      expect(harness.readCommands[1], contains('0x400000000'));
      expect(harness.writeCommands.single, containsAll(['--pid', '43']));
      expect(harness.writeCommands.single, contains('0x400000000'));
    });

    test(
      'Method run() handles a process that exits before metadata lookup',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..metadataError = Exception('process exited before lookup')
              ..readExitCode = 1
              ..inputs = ['1', '2', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(output.toString(), contains('may have exited'));
        expect(harness.readCommands.single, contains('0x300000000'));
      },
    );

    test('Method run() reports locked log access and keeps base choices', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..resolverError = FileSystemException(
              'sharing violation',
              r'C:\RPCS3\log\RPCS3.log',
              const OSError('Sharing violation', 32),
            )
            ..inputs = ['1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(output.toString(), contains('or its log'));
      expect(output.toString(), contains('sharing violation'));
      expect(
        output.toString(),
        contains('Use the suggested base (confirm for this session)'),
      );
      expect(harness.commands, isEmpty);
    });
  });
}

class _InteractiveHarness {
  List<List<int>> processResults = [];
  List<String> inputs = [];
  List<Rpcs3MemoryBaseCandidate?> candidateByAttempt = [];
  List<int> metadataProcessIds = [];
  List<List<String>> commands = [];
  int discoveryCalls = 0;
  int resolveCalls = 0;
  int readValues = 0;
  List<int> boltValues = [];
  bool omitReadValue = false;
  int readExitCode = 0;
  List<int> readExitCodes = [];
  int writeExitCode = 0;
  String readErrorOutput = '';
  String writeErrorOutput = '';
  bool hasTerminal = true;
  Exception? discoveryError;
  UnsupportedError? unsupportedDiscoveryError;
  bool Function()? clearScreen;
  Rpcs3MemoryBaseCandidate? candidate;
  Rpcs3MemoryBaseCandidate? Function(int processId)? candidateForProcess;
  Exception? metadataError;
  Exception? resolverError;

  List<List<String>> get readCommands =>
      commands.where((arguments) => arguments.first == 'read').toList();

  List<List<String>> get writeCommands =>
      commands.where((arguments) => arguments.first == 'write').toList();

  int run(StringBuffer output, StringBuffer errorOutput) =>
      _cli().run(output: output, errorOutput: errorOutput);

  InteractiveTrainerCli _cli() {
    return InteractiveTrainerCli(
      discoverProcessIds: () {
        final index = discoveryCalls++;
        final unsupportedError = unsupportedDiscoveryError;
        if (unsupportedError != null) throw unsupportedError;
        final error = discoveryError;
        if (error != null) {
          discoveryError = null;
          throw error;
        }
        if (processResults.isEmpty) return const [];
        return processResults[index < processResults.length
            ? index
            : processResults.length - 1];
      },
      readProcessMetadata: (processId) {
        metadataProcessIds.add(processId);
        final error = metadataError;
        if (error != null) throw error;
        return Rpcs3ProcessMetadata(
          executablePath: r'C:\RPCS3\rpcs3.exe',
          startedAtUtc: DateTime.utc(2026, 11, 5),
        );
      },
      resolveMemoryBaseCandidate: (_) {
        final index = resolveCalls++;
        final error = resolverError;
        if (error != null) throw error;
        if (candidateByAttempt.isNotEmpty) {
          return candidateByAttempt[index < candidateByAttempt.length
              ? index
              : candidateByAttempt.length - 1];
        }
        return candidateForProcess?.call(metadataProcessIds.last) ?? candidate;
      },
      runCommand: (arguments, output, errorOutput) {
        commands.add(arguments);
        if (arguments.first == 'read') {
          final readNumber = ++readValues;
          final exitCode =
              readNumber <= readExitCodes.length
                  ? readExitCodes[readNumber - 1]
                  : readExitCode;
          if (exitCode != 0) {
            output.writeln('Status: native memory read failed');
          } else if (!omitReadValue) {
            output.writeln(
              'Value: ${boltValues.length >= readNumber ? boltValues[readNumber - 1] : 100 + readNumber}',
            );
          }
          if (exitCode != 0 && readErrorOutput.isNotEmpty) {
            errorOutput.writeln(readErrorOutput);
          }
          return exitCode;
        }
        output.writeln(
          writeExitCode == 0
              ? 'Status: write and read-back complete'
              : 'Status: read-back did not match',
        );
        if (writeExitCode != 0 && writeErrorOutput.isNotEmpty) {
          errorOutput.writeln(writeErrorOutput);
        }
        return writeExitCode;
      },
      readLine: () => inputs.isEmpty ? null : inputs.removeAt(0),
      hasTerminal: hasTerminal,
      clearScreen: clearScreen,
      clearScreenForInjectedOutput: clearScreen != null,
    );
  }
}
