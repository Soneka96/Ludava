import 'dart:io';

import 'package:ludava/features/game_memory/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/game_memory/presentation/cli/interactive_trainer_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Method run() behaves correctly', () {
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
            ..inputs = ['1', '1', '1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.discoveryCalls, 2);
      expect(output.toString(), contains('RPCS3 was not found'));
      expect(harness.readCommands, hasLength(1));
      expect(harness.readCommands.single, contains('0x300000000'));
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
        'Could not confirm the RPCS3 memory base'.allMatches(output.toString()),
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
            ..inputs = ['2', '1', '1', '0'];
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
            ..inputs = ['1', '1', '0'];
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
              ..inputs = ['2', 'not-hex', '0x400000000', '1', '0'];
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
            ..inputs = ['3', '1', '1', '0'];
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
            ..inputs = ['1', '1'];

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
            ..inputs = ['1', '1', '1', '0'];

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
            ..inputs = ['1', '1', '1', '0']
            ..clearScreen = () {
              clearCalls++;
              return true;
            };
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(clearCalls, 5);
      expect(output.toString(), contains('RPCS3 process selected: PID 42'));
      expect(output.toString(), contains('Memory base: 0x300000000'));
      expect(output.toString(), contains('Value: 102'));
    });

    test('Method run() does not write when the user cancels confirmation', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '1', '2', '999999', 'n', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.writeCommands, isEmpty);
      expect(harness.readCommands, hasLength(2));
      expect(output.toString(), contains('Write cancelled'));
    });

    test('Method run() rejects an out-of-range value without writing', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '1', '2', '4294967296', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.writeCommands, isEmpty);
      expect(output.toString(), contains('between 0 and 4294967295'));
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
                ..inputs = ['1', '1', '2', value, '0'];
          final output = StringBuffer();

          harness.run(output, StringBuffer());

          expect(harness.writeCommands, isEmpty);
          expect(output.toString(), contains('Enter a value between'));
        }
      },
    );

    test('Method run() does not write when input ends at the value prompt', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '1', '2'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.writeCommands, isEmpty);
    });

    test('Method run() does not write when input ends at confirmation', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '1', '2', '999'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.writeCommands, isEmpty);
    });

    test('Method run() confirms a write and refreshes the field afterward', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '1', '2', '999999', 'Y', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.writeCommands, hasLength(1));
      expect(
        harness.writeCommands.single,
        containsAll(['--value', '999999', '--confirm-write']),
      );
      expect(harness.readCommands, hasLength(3));
      expect(output.toString(), contains('does not verify that this process'));
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
              ..inputs = ['1', '1', '2', '5', 'y', '0'];
        final output = StringBuffer();
        final errorOutput = StringBuffer();

        harness.run(output, errorOutput);

        expect(output.toString(), contains('Status: read-back did not match'));
        expect(
          output.toString(),
          contains('Status: native memory read failed'),
        );
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
              ..inputs = ['1', '1', '2', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(harness.writeCommands, isEmpty);
        expect(output.toString(), contains('fresh value could not be read'));
      },
    );

    test('Method run() returns to game selection when requested', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '1', '3', '1', '0'];

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
            ..inputs = ['1', '1', '4', '1', '1', '2', '5', 'y', '0'];

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
              ..inputs = ['1', '1', '0'];
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
        contains('Use this base for the current session'),
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
  int readExitCode = 0;
  List<int> readExitCodes = [];
  int writeExitCode = 0;
  String readErrorOutput = '';
  String writeErrorOutput = '';
  bool hasTerminal = true;
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
          output.writeln(
            exitCode == 0
                ? 'Value: ${100 + readNumber}'
                : 'Status: native memory read failed',
          );
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
