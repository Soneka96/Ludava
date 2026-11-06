import 'dart:io';

import 'package:ludava_sdk/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc2_collection_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc1_collection_profile.dart';
import 'package:ludava_sdk/features/game_catalog/domain/profiles/rc3_collection_profile.dart';
import 'package:ludava/features/trainer/presentation/cli/interactive_trainer_cli.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Method run() behaves correctly', () {
    test('Method run() bypasses manual selection for confirmed identity', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..detectionResult = GameDetectionResult(
              status: GameDetectionStatus.supportedGame,
              processId: 42,
              titleId: 'BCUS98282',
              gameTitle: 'Ratchet & Clank 2',
              executable: 'RC2.ppu.self',
              executableHash: Rc2CollectionProfile.profile.executableHash,
              confidence: GameIdentityConfidence.confirmed,
              profile: Rc2CollectionProfile.profile,
              evidenceDescription: 'Unique current-game identity evidence.',
            )
            ..candidate = const Rpcs3MemoryBaseCandidate(
              memoryBase: 0x300000000,
              logPath: r'C:\RPCS3\log\RPCS3.log',
            )
            ..inputs = ['0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.detectionCalls, 1);
      expect(harness.readCommands, hasLength(1));
      expect(
        harness.readCommands.single,
        containsAll(['--game', 'rc2-collection', '--require-current-identity']),
      );
      expect(output.toString(), contains('Ratchet & Clank 2 detected.'));
      expect(output.toString(), isNot(contains('Choose your game:')));
      expect(output.toString(), isNot(contains('Confirm RPCS3 connection')));
      expect(output.toString(), contains('Guest memory base resolved'));
    });

    test(
      'Method run() does not prompt for a missing automatic memory base',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..detectionResult = _confirmedRc2Detection();
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(harness.resolveCalls, 1);
        expect(harness.readCommands, isEmpty);
        expect(
          output.toString(),
          contains('could not verify a guest memory base'),
        );
        expect(
          output.toString(),
          isNot(contains('Enter hexadecimal memory base')),
        );
      },
    );

    test(
      'Method run() keeps log candidates uncertain and offers manual selection',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..detectionResult = GameDetectionResult(
                status: GameDetectionStatus.ambiguous,
                processId: 42,
                titleId: 'BCUS98282',
                gameTitle: 'Ratchet & Clank Collection',
                confidence: GameIdentityConfidence.uncertain,
                evidenceDescription:
                    'Historical log evidence; active game unverified.',
              )
              ..inputs = ['2', '1', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(output.toString(), contains('title candidate (unverified)'));
        expect(output.toString(), contains('Choose a profile manually'));
        expect(
          output.toString(),
          contains('Manual profile: Ratchet & Clank 2'),
        );
        expect(harness.readCommands.single, contains('rc2-collection'));
        expect(
          harness.readCommands.single,
          isNot(contains('--require-current-identity')),
        );
      },
    );

    test(
      'Method run() offers no trainer for a confirmed unsupported title',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..detectionResult = GameDetectionResult(
                status: GameDetectionStatus.unsupportedGame,
                processId: 42,
                titleId: 'UNSUPPORTED',
                gameTitle: 'Unsupported title',
                confidence: GameIdentityConfidence.confirmed,
                evidenceDescription: 'Current title identity was confirmed.',
              )
              ..inputs = ['1', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(output.toString(), contains('Unsupported title'));
        expect(output.toString(), contains('No trainer profile is available'));
        expect(output.toString(), isNot(contains('Choose your game:')));
        expect(harness.resolveCalls, 0);
        expect(harness.commands, isEmpty);
      },
    );

    test('Method run() retries when RPCS3 has no active game identity', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..detectionResults = [
              GameDetectionResult(
                status: GameDetectionStatus.noActiveGame,
                processId: 42,
                confidence: GameIdentityConfidence.none,
                evidenceDescription: 'No active game signal was observed.',
              ),
              _confirmedRc2Detection(),
            ]
            ..candidate = const Rpcs3MemoryBaseCandidate(
              memoryBase: 0x300000000,
              logPath: r'C:\RPCS3\log\RPCS3.log',
            )
            ..inputs = ['1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.detectionCalls, 2);
      expect(harness.resolveCalls, 1);
      expect(output.toString(), contains('No active game was identified'));
      expect(output.toString(), contains('Ratchet & Clank 2 detected.'));
      expect(harness.readCommands.single, contains('rc2-collection'));
    });

    test('Method run() does not ask for a base when no game is active', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..detectionResult = GameDetectionResult(
              status: GameDetectionStatus.noActiveGame,
              processId: 42,
              confidence: GameIdentityConfidence.none,
              evidenceDescription: 'No completed PPU load is present.',
            )
            ..inputs = ['0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.resolveCalls, 0);
      expect(harness.readCommands, isEmpty);
      expect(output.toString(), contains('No active game was identified'));
      expect(
        output.toString(),
        isNot(contains('could not find the memory base automatically')),
      );
      expect(
        output.toString(),
        isNot(contains('Enter hexadecimal memory base')),
      );
    });

    test('Method run() retries unsupported-game detection on request', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..detectionResults = [
              GameDetectionResult(
                status: GameDetectionStatus.unsupportedGame,
                processId: 42,
                titleId: 'UNSUPPORTED',
                gameTitle: 'Unsupported title',
                confidence: GameIdentityConfidence.confirmed,
                evidenceDescription: 'Current title identity was confirmed.',
              ),
              _confirmedRc2Detection(),
            ]
            ..candidate = const Rpcs3MemoryBaseCandidate(
              memoryBase: 0x300000000,
              logPath: r'C:\RPCS3\log\RPCS3.log',
            )
            ..inputs = ['1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.detectionCalls, 2);
      expect(output.toString(), contains('No trainer profile is available'));
      expect(output.toString(), contains('Ratchet & Clank 2 detected.'));
      expect(output.toString(), isNot(contains('Choose your game:')));
    });

    test('Method run() rejects detection evidence for a different process', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..detectionResult = _confirmedRc2Detection(processId: 43)
            ..inputs = ['2', '1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(
        output.toString(),
        contains(
          'Game detection evidence does not match the selected RPCS3 process.',
        ),
      );
      expect(harness.readCommands.single, containsAll(['--pid', '42']));
      expect(harness.readCommands.single, contains('rc2-collection'));
      expect(output.toString(), contains('Manual profile: Ratchet & Clank 2'));
    });

    test('Method run() accepts menu choices with surrounding whitespace', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = [' 1 ', ' 1 ', ' 3 ', ' 3 ', ' 0 '];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.readCommands, hasLength(2));
      expect(
        harness.readCommands.first,
        containsAll(['--game', 'rc1-collection']),
      );
      expect(
        harness.readCommands.last,
        containsAll(['--game', 'rc3-collection']),
      );
      expect(
        output.toString(),
        isNot(contains('Choose one of the listed options.')),
      );
    });

    test('Method run() lists all three Collection games in order', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(
        output.toString(),
        contains('1. Ratchet & Clank — PS3 Collection'),
      );
      expect(
        output.toString(),
        contains('2. Ratchet & Clank 2 — PS3 Collection'),
      );
      expect(
        output.toString(),
        contains('3. Ratchet & Clank 3 — PS3 Collection'),
      );
      expect(harness.readCommands, isEmpty);
    });

    test('Method run() selects the RC1 profile for reading bolts', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['1', '1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.readCommands, hasLength(1));
      expect(
        harness.readCommands.single,
        containsAll(['--game', 'rc1-collection']),
      );
      expect(output.toString(), contains('Manual profile: Ratchet & Clank'));
      expect(output.toString(), contains('  PS3 Collection'));
    });

    test('Method run() selects the RC3 profile for reading bolts', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['3', '1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.readCommands, hasLength(1));
      expect(
        harness.readCommands.single,
        containsAll(['--game', 'rc3-collection']),
      );
      expect(output.toString(), contains('Ratchet & Clank 3'));
      expect(output.toString(), contains('  PS3 Collection'));
    });

    test('Method run() allows writes for confirmed RC1 and RC3 identities', () {
      for (final profile in [
        Rc1CollectionProfile.profile,
        Rc3CollectionProfile.profile,
      ]) {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..detectionResult = _confirmedDetection(profile)
              ..candidate = const Rpcs3MemoryBaseCandidate(
                memoryBase: 0x300000000,
                logPath: r'C:\RPCS3\log\RPCS3.log',
              )
              ..inputs = ['2', '1234', 'y', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(harness.writeCommands, hasLength(1));
        expect(
          harness.writeCommands.single,
          containsAll([
            '--game',
            profile.id,
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

    test(
      'Method run() explains unavailable data for the selected RC3 game',
      () {
        final harness =
            _InteractiveHarness()
              ..processResults = [
                [42],
              ]
              ..readExitCode = 1
              ..inputs = ['3', '1', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(output.toString(), contains('Start Ratchet & Clank 3 in RPCS3'));
        expect(harness.writeCommands, isEmpty);
      },
    );

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
            ..inputs = ['1', '2', '1', '0'];
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
            ..inputs = ['1', '2', '1', '0'];
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
        hasLength(1),
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
            ..inputs = ['2', '2', '1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.metadataProcessIds, [202, 202]);
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
            ..inputs = ['2', '1', '0'];
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
              ..inputs = ['2', '2', 'not-hex', '0x400000000', '0'];
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
            ..inputs = ['2', '3', '1', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.resolveCalls, 2);
      expect(harness.readCommands.single, contains('0x500000000'));
    });

    test(
      'Method run() keeps console output writable after synchronous prompts',
      () {
        final inputs = ['2', '3', '2', '0x400000000', '0'];
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
          runCommand: (arguments, output, _) {
            if (arguments.first == 'read') output.writeln('Value: 0');
            return 0;
          },
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
              ..inputs = ['2', '0'];

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
            ..inputs = [];

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
            ..inputs = ['2', '1'];

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
            ..inputs = ['2', '1', '1', '0'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.readCommands, hasLength(2));
      expect(harness.readValues, 2);
    });

    test(
      'Method run() requires current identity on automatic refresh reads',
      () {
        final harness =
            _confirmedRc2Harness()
              ..boltValues = [500, 999]
              ..readExitCodes = [0, 1]
              ..inputs = ['1', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(harness.readCommands, hasLength(2));
        expect(
          harness.readCommands.first,
          contains('--require-current-identity'),
        );
        expect(
          harness.readCommands.last,
          contains('--require-current-identity'),
        );
        final finalScreen = output.toString().substring(
          output.toString().lastIndexOf('             LUDAVA'),
        );
        expect(finalScreen, contains('Not available'));
        expect(finalScreen, isNot(contains('500')));
      },
    );

    test('Method run() redraws trainer context after refreshing a field', () {
      var clearCalls = 0;
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['2', '1', '1', '0']
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
            ..inputs = ['2', '1', '0'];
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
              ..inputs = ['2', '1', '4', '1', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(output.toString(), contains('Connection Details'));
        expect(output.toString(), contains('RPCS3 process ID: 42'));
        expect(output.toString(), contains('Memory base: 0x300000000'));
        expect(output.toString(), contains('Build ID: BCUS98282'));
        expect(
          output.toString(),
          contains('Game identity: selected manually; unverified'),
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
              ..inputs = ['2', '1', '4', '1', '0'];
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
            ..inputs = ['2', '1', '1', '0'];
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
              ..inputs = ['2', '1', '4', '1', '0'];
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

    test('Method run() keeps manual profile selection read-only', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..inputs = ['2', '1', '2', '1234', 'y', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.readCommands, hasLength(1));
      expect(harness.writeCommands, isEmpty);
      expect(
        output.toString(),
        contains(
          'Writes are disabled until the active game is verified automatically.',
        ),
      );
    });

    test('Method run() does not write when the user cancels confirmation', () {
      final harness =
          _confirmedRc2Harness()..inputs = ['2', '999999', 'n', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.writeCommands, isEmpty);
      expect(harness.readCommands, hasLength(2));
      expect(output.toString(), contains('Change cancelled'));
    });

    test('Method run() rejects an out-of-range value without writing', () {
      final harness = _confirmedRc2Harness()..inputs = ['2', '4294967296', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.writeCommands, isEmpty);
      expect(output.toString(), contains('between 0 and 4,294,967,295'));
    });

    test(
      'Method run() rejects non-numeric and negative values without writing',
      () {
        for (final value in ['not-a-number', '-1']) {
          final harness = _confirmedRc2Harness()..inputs = ['2', value, '0'];
          final output = StringBuffer();

          harness.run(output, StringBuffer());

          expect(harness.writeCommands, isEmpty);
          expect(output.toString(), contains('Enter a bolt value between'));
        }
      },
    );

    test('Method run() does not write when input ends at the value prompt', () {
      final harness = _confirmedRc2Harness()..inputs = ['2'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.writeCommands, isEmpty);
    });

    test('Method run() does not write when input ends at confirmation', () {
      final harness = _confirmedRc2Harness()..inputs = ['2', '999'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.writeCommands, isEmpty);
    });

    test('Method run() confirms a write and refreshes the field afterward', () {
      final harness =
          _confirmedRc2Harness()..inputs = ['2', '999999', 'Y', '0'];
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

    test('Method run() blocks a write when the PPU identity changes', () {
      final harness =
          _confirmedRc2Harness()
            ..detectionResults = [
              _confirmedRc2Detection(),
              _confirmedDetection(Rc1CollectionProfile.profile),
            ]
            ..inputs = ['2', '1234', 'y', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.detectionCalls, 3);
      expect(harness.writeCommands, isEmpty);
      expect(output.toString(), contains('active game or memory base changed'));
      expect(output.toString(), isNot(contains('Bolts updated successfully')));
    });

    test('Method run() blocks a write when the memory base changes', () {
      final harness =
          _confirmedRc2Harness()
            ..candidateByAttempt = [
              const Rpcs3MemoryBaseCandidate(
                memoryBase: 0x300000000,
                logPath: r'C:\RPCS3\log\RPCS3.log',
              ),
              const Rpcs3MemoryBaseCandidate(
                memoryBase: 0x400000000,
                logPath: r'C:\RPCS3\log\RPCS3.log',
              ),
            ]
            ..inputs = ['2', '1234', 'y', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.writeCommands, isEmpty);
      expect(output.toString(), contains('active game or memory base changed'));
      expect(output.toString(), isNot(contains('Bolts updated successfully')));
    });

    test(
      'Method run() blocks a write when RPCS3 restarts before confirmation',
      () {
        final initialStart = DateTime.utc(2026, 11, 5);
        final restartedAt = DateTime.utc(2026, 11, 5, 1);
        final harness =
            _confirmedRc2Harness()
              ..candidateByAttempt = [
                const Rpcs3MemoryBaseCandidate(
                  memoryBase: 0x300000000,
                  logPath: r'C:\RPCS3\log\RPCS3.log',
                ),
                const Rpcs3MemoryBaseCandidate(
                  memoryBase: 0x400000000,
                  logPath: r'C:\RPCS3\log\RPCS3.log',
                ),
              ]
              ..processStartTimes = [
                initialStart,
                initialStart,
                restartedAt,
                restartedAt,
                restartedAt,
              ]
              ..inputs = ['2', '1234', 'y', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(harness.writeCommands, isEmpty);
        expect(
          output.toString(),
          contains('RPCS3 session changed. No write was made.'),
        );
        expect(harness.readCommands, hasLength(3));
      },
    );

    test(
      'Method run() requests re-detection and blocks a write when base revalidation fails',
      () {
        final harness =
            _confirmedRc2Harness()
              ..resolverErrors = [null, Exception('base unavailable')]
              ..inputs = ['2', '1234', 'y', '0'];
        final output = StringBuffer();

        harness.run(output, StringBuffer());

        expect(harness.writeCommands, isEmpty);
        expect(harness.detectionCalls, greaterThanOrEqualTo(3));
        expect(output.toString(), contains('base unavailable'));
        expect(
          output.toString(),
          contains('Could not revalidate the game before writing'),
        );
      },
    );

    test(
      'Method run() reports write failures and still refreshes the field',
      () {
        final harness =
            _confirmedRc2Harness()
              ..writeExitCode = 1
              ..readExitCodes = [0, 0, 1]
              ..writeErrorOutput = 'simulated write error'
              ..readErrorOutput = 'simulated refresh error'
              ..inputs = ['2', '5', 'y', '0'];
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
            _confirmedRc2Harness()
              ..readExitCode = 1
              ..inputs = ['2', '0'];
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
            ..inputs = ['2', '1', '3', '3', '0'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.readCommands, hasLength(2));
    });

    test('Method run() clears the prior field before re-detection', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..boltValues = [111, 333]
            ..inputs = ['2', '1', '5', '3', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.detectionCalls, 2);
      expect(harness.readCommands, hasLength(2));
      expect(harness.readCommands[0], contains('rc2-collection'));
      expect(harness.readCommands[1], contains('rc3-collection'));
      final finalScreen = output.toString().substring(
        output.toString().lastIndexOf('             LUDAVA'),
      );
      expect(finalScreen, contains('333'));
      expect(finalScreen, isNot(contains('111')));
    });

    test('Method run() abandons the prior profile when RPCS3 exits', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
              [],
            ]
            ..inputs = ['2', '1', '5', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(
        output.toString(),
        contains('selected RPCS3 process is no longer running'),
      );
      expect(harness.readCommands, hasLength(1));
      expect(harness.writeCommands, isEmpty);
      expect(output.toString(), contains('RPCS3 was not found'));
    });

    test('Method run() reselects process and base after an RPCS3 restart', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
            ]
            ..detectionResults = [
              _confirmedRc2Detection(),
              _confirmedDetection(Rc3CollectionProfile.profile),
            ]
            ..candidateByAttempt = [
              const Rpcs3MemoryBaseCandidate(
                memoryBase: 0x300000000,
                logPath: r'C:\RPCS3\log\RPCS3.log',
              ),
              const Rpcs3MemoryBaseCandidate(
                memoryBase: 0x400000000,
                logPath: r'C:\RPCS3\log\RPCS3.log',
              ),
            ]
            ..processStartTimes = [
              DateTime.utc(2026, 11, 5),
              DateTime.utc(2026, 11, 5),
              DateTime.utc(2026, 11, 5, 1),
              DateTime.utc(2026, 11, 5, 1),
              DateTime.utc(2026, 11, 5, 1),
            ]
            ..inputs = ['5', '0'];
      final output = StringBuffer();

      harness.run(output, StringBuffer());

      expect(harness.readCommands, hasLength(2));
      expect(harness.readCommands[0], contains('rc2-collection'));
      expect(harness.readCommands[1], contains('rc3-collection'));
      expect(
        output.toString(),
        contains(
          'The RPCS3 process session changed. Select the process and memory base again.',
        ),
      );
      expect(harness.resolveCalls, 2);
    });

    test('Method run() re-evaluates the base after changing processes', () {
      final harness =
          _InteractiveHarness()
            ..processResults = [
              [42],
              [43],
            ]
            ..detectionResults = [
              _confirmedRc2Detection(),
              _confirmedDetection(Rc3CollectionProfile.profile, processId: 43),
            ]
            ..candidateForProcess = (processId) {
              return Rpcs3MemoryBaseCandidate(
                memoryBase: processId == 42 ? 0x300000000 : 0x400000000,
                logPath: r'C:\RPCS3\log\RPCS3.log',
              );
            }
            ..inputs = ['4', '2', '2', '5', 'y', '0'];

      harness.run(StringBuffer(), StringBuffer());

      expect(harness.metadataProcessIds, [42, 42, 43, 43, 43]);
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
              ..inputs = ['2', '1', '0'];
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
  List<DateTime> processStartTimes = [];
  List<String> inputs = [];
  List<GameDetectionResult> detectionResults = [];
  List<Rpcs3MemoryBaseCandidate?> candidateByAttempt = [];
  List<int> metadataProcessIds = [];
  List<List<String>> commands = [];
  int discoveryCalls = 0;
  int detectionCalls = 0;
  GameDetectionResult? detectionResult;
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
  List<Exception?> resolverErrors = [];

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
        final startTimeIndex = metadataProcessIds.length - 1;
        return Rpcs3ProcessMetadata(
          executablePath: r'C:\RPCS3\rpcs3.exe',
          startedAtUtc:
              processStartTimes.isEmpty
                  ? DateTime.utc(2026, 11, 5)
                  : processStartTimes[startTimeIndex < processStartTimes.length
                      ? startTimeIndex
                      : processStartTimes.length - 1],
        );
      },
      resolveMemoryBaseCandidate: (_) {
        final index = resolveCalls++;
        if (resolverErrors.isNotEmpty && index < resolverErrors.length) {
          final indexedError = resolverErrors[index];
          if (indexedError != null) throw indexedError;
        }
        final error = resolverError;
        if (error != null) throw error;
        if (candidateByAttempt.isNotEmpty) {
          return candidateByAttempt[index < candidateByAttempt.length
              ? index
              : candidateByAttempt.length - 1];
        }
        return candidateForProcess?.call(metadataProcessIds.last) ?? candidate;
      },
      detectGame: (processId, _) {
        final index = detectionCalls++;
        if (detectionResults.isNotEmpty) {
          return detectionResults[index < detectionResults.length
              ? index
              : detectionResults.length - 1];
        }
        return detectionResult ??
            GameDetectionResult(
              status: GameDetectionStatus.ambiguous,
              processId: processId,
              confidence: GameIdentityConfidence.none,
              evidenceDescription: 'No current-game identity is verified.',
            );
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

_InteractiveHarness _confirmedRc2Harness() =>
    _InteractiveHarness()
      ..processResults = [
        [42],
      ]
      ..detectionResult = _confirmedRc2Detection()
      ..candidate = const Rpcs3MemoryBaseCandidate(
        memoryBase: 0x300000000,
        logPath: r'C:\RPCS3\log\RPCS3.log',
      );

GameDetectionResult _confirmedRc2Detection({int processId = 42}) =>
    _confirmedDetection(Rc2CollectionProfile.profile, processId: processId);

GameDetectionResult _confirmedDetection(
  GameProfile profile, {
  int processId = 42,
}) => GameDetectionResult(
  status: GameDetectionStatus.supportedGame,
  processId: processId,
  titleId: 'BCUS98282',
  gameTitle: profile.gameName,
  executable: profile.executable,
  executableHash: profile.executableHash,
  confidence: GameIdentityConfidence.confirmed,
  profile: profile,
  evidenceDescription: 'Unique current-game identity evidence.',
);
