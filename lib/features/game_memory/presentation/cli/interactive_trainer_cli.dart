import 'dart:io';

import 'package:ludava/features/game_memory/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/game_memory/domain/profiles/game_profile_catalog.dart';
import 'package:ludava/features/game_memory/presentation/cli/diagnostic_argument_parser.dart';
import 'package:ludava/shared/constants/app_constants.dart';

/// Runs Ludava's interactive RPCS3 and game-memory terminal menus.
class InteractiveTrainerCli {
  /// Creates the interactive CLI with injectable process and command seams.
  InteractiveTrainerCli({
    required List<int> Function() discoverProcessIds,
    required Rpcs3ProcessMetadata Function(int processId) readProcessMetadata,
    required Rpcs3MemoryBaseCandidate? Function(
      Rpcs3ProcessMetadata processMetadata,
    )
    resolveMemoryBaseCandidate,
    required int Function(
      List<String> arguments,
      StringSink output,
      StringSink errorOutput,
    )
    runCommand,
    String? Function()? readLine,
    bool? hasTerminal,
    bool Function()? clearScreen,
    bool clearScreenForInjectedOutput = false,
  }) : _discoverProcessIds = discoverProcessIds,
       _readProcessMetadata = readProcessMetadata,
       _resolveMemoryBaseCandidate = resolveMemoryBaseCandidate,
       _runCommand = runCommand,
       _readLine = readLine ?? stdin.readLineSync,
       _hasTerminal = hasTerminal,
       _clearScreen = clearScreen,
       _clearScreenForInjectedOutput = clearScreenForInjectedOutput;

  static const int _exitGame = 0;
  static const int _changeGame = 1;
  static const int _changeProcess = 2;
  static const int _researchTestedMemoryBase = 0x300000000;

  final List<int> Function() _discoverProcessIds;
  final Rpcs3ProcessMetadata Function(int processId) _readProcessMetadata;
  final Rpcs3MemoryBaseCandidate? Function(Rpcs3ProcessMetadata processMetadata)
  _resolveMemoryBaseCandidate;
  final int Function(
    List<String> arguments,
    StringSink output,
    StringSink errorOutput,
  )
  _runCommand;
  final String? Function() _readLine;
  final bool? _hasTerminal;
  final bool Function()? _clearScreen;
  final bool _clearScreenForInjectedOutput;

  bool _inputEnded = false;
  bool _ownsTerminalOutput = false;
  String? _lastCommandSummary;

  /// Runs the interactive menu and returns its process exit code.
  int run({StringSink? output, StringSink? errorOutput}) {
    final stdoutSink = output ?? stdout;
    final stderrSink = errorOutput ?? stderr;
    _ownsTerminalOutput = output == null || _clearScreenForInjectedOutput;
    _lastCommandSummary = null;
    if (!(_hasTerminal ?? stdin.hasTerminal)) {
      stderrSink.writeln(
        'Interactive mode requires a terminal. Use --help to see commands.',
      );
      return 2;
    }

    while (!_inputEnded) {
      final processId = _selectProcess(stdoutSink, stderrSink);
      if (processId == null) return 0;
      final memoryBase = _selectMemoryBase(processId, stdoutSink, stderrSink);
      if (_inputEnded) return 0;
      if (memoryBase == null) return 0;

      final profiles = GameProfileCatalog.profiles.toList(growable: false);
      var returnToProcessMenu = false;
      while (!_inputEnded && !returnToProcessMenu) {
        final profile = _selectGame(profiles, stdoutSink);
        if (profile == null) return 0;
        final action = _gameMenu(
          processId,
          memoryBase,
          profile,
          stdoutSink,
          stderrSink,
        );
        switch (action) {
          case _exitGame:
            return 0;
          case _changeGame:
            continue;
          case _changeProcess:
            returnToProcessMenu = true;
        }
      }
    }
    return 0;
  }

  int? _selectProcess(StringSink output, StringSink errorOutput) {
    while (!_inputEnded) {
      _beginScreen(output, showHeader: true);
      output.writeln('\nSearching for RPCS3...');
      List<int> processIds;
      try {
        processIds = _discoverProcessIds();
      } on Exception catch (error) {
        errorOutput.writeln(error);
        if (!_askToSearchAgain(output)) return null;
        continue;
      } on UnsupportedError catch (error) {
        errorOutput.writeln(error);
        return null;
      }

      if (processIds.isEmpty) {
        output.writeln('\nRPCS3 was not found.');
        if (!_askToSearchAgain(output)) return null;
        continue;
      }
      if (processIds.length == 1) {
        output.writeln('[OK] RPCS3 detected');
        output.writeln('     Process ID: ${processIds.single}');
        return processIds.single;
      }

      output.writeln('\nSeveral RPCS3 processes were found:');
      for (var index = 0; index < processIds.length; index++) {
        output.writeln('  ${index + 1}. Process ID: ${processIds[index]}');
      }
      output.writeln('  R. Search again');
      output.writeln('  0. Exit');
      final selection = _prompt(output, 'Select an RPCS3 process: ');
      if (selection == null) return null;
      if (selection.toLowerCase() == 'r') continue;
      if (selection == '0') return null;
      final index = int.tryParse(selection);
      if (index == null || index < 1 || index > processIds.length) {
        output.writeln('Choose one of the listed process numbers.');
        continue;
      }
      final selectedProcessId = processIds[index - 1];
      output.writeln('[OK] Selected RPCS3 process $selectedProcessId');
      return selectedProcessId;
    }
    return null;
  }

  int? _selectMemoryBase(
    int processId,
    StringSink output,
    StringSink errorOutput,
  ) {
    Rpcs3MemoryBaseCandidate? candidate;
    while (!_inputEnded) {
      _beginScreen(output);
      candidate = null;
      try {
        final metadata = _readProcessMetadata(processId);
        candidate = _resolveMemoryBaseCandidate(metadata);
      } on Exception catch (error) {
        output.writeln(
          'Could not inspect RPCS3 process $processId or its log: $error',
        );
        output.writeln(
          'The process may have exited, access may be denied, or its log may be locked.',
        );
      } on UnsupportedError catch (error) {
        errorOutput.writeln(error);
        return null;
      }

      if (candidate == null) {
        output.writeln(
          '\nCould not confirm the RPCS3 memory base automatically.',
        );
        output.writeln(
          'Research-tested base: ${_formatMemoryBase(_researchTestedMemoryBase)}',
        );
        output.writeln('1. Use this base for the current session');
        output.writeln('2. Enter another hexadecimal base');
        output.writeln('3. Retry detection');
        output.writeln('0. Cancel');
      } else {
        output.writeln('\nRPCS3 log candidate: ${candidate.logPath}');
        output.writeln(
          'Candidate memory base: ${_formatMemoryBase(candidate.memoryBase)}',
        );
        output.writeln(
          'The log may belong to another RPCS3 instance; confirm before use.',
        );
        output.writeln('1. Use this candidate for the current session');
        output.writeln('2. Enter another hexadecimal base');
        output.writeln('3. Retry detection');
        output.writeln('0. Cancel');
      }

      final selection = _prompt(output, 'Select an option: ');
      if (selection == null || selection == '0') return null;
      switch (selection) {
        case '1':
          return candidate?.memoryBase ?? _researchTestedMemoryBase;
        case '2':
          final manualBase = _readManualMemoryBase(output);
          if (manualBase != null) return manualBase;
        case '3':
          continue;
        default:
          output.writeln('Choose one of the listed options.');
      }
    }
    return null;
  }

  int? _readManualMemoryBase(StringSink output) {
    while (!_inputEnded) {
      final input = _prompt(output, 'Enter hexadecimal memory base: ');
      if (input == null) return null;
      try {
        return DiagnosticArgumentParser.parseMemoryBase(input.trim());
      } on FormatException catch (error) {
        output.writeln('Invalid memory base: ${error.message}');
      }
    }
    return null;
  }

  GameProfile? _selectGame(List<GameProfile> profiles, StringSink output) {
    _beginScreen(output);
    output.writeln('\nSelect a game:');
    for (var index = 0; index < profiles.length; index++) {
      final profile = profiles[index];
      output.writeln(
        '  ${index + 1}. ${profile.gameName} — ${profile.buildId}',
      );
    }
    output.writeln('  0. Exit');
    while (!_inputEnded) {
      final selection = _prompt(output, 'Select a game: ');
      if (selection == null || selection == '0') return null;
      final index = int.tryParse(selection);
      if (index == null || index < 1 || index > profiles.length) {
        output.writeln('Choose one of the listed game numbers.');
        continue;
      }
      return profiles[index - 1];
    }
    return null;
  }

  int _gameMenu(
    int processId,
    int memoryBase,
    GameProfile profile,
    StringSink output,
    StringSink errorOutput,
  ) {
    final field = profile.findField('bolts');
    if (field == null) {
      output.writeln('This profile does not define the bolts field.');
      return _changeGame;
    }
    final initialReadSucceeded = _runRead(
      processId,
      memoryBase,
      profile,
      field,
      output,
      errorOutput,
    );
    while (!_inputEnded) {
      _beginScreen(output);
      output.writeln('========================================');
      output.writeln('       ${profile.gameName}');
      output.writeln('          ${profile.buildId}');
      output.writeln('========================================');
      output.writeln('RPCS3 process selected: PID $processId');
      output.writeln('Memory base: ${_formatMemoryBase(memoryBase)}');
      output.writeln(
        'Runtime identity is unverified; the selected process may not be running ${profile.gameName}.',
      );
      output.writeln(
        'Memory access: ${initialReadSucceeded ? 'available' : 'not available'}',
      );
      final commandSummary = _lastCommandSummary;
      if (commandSummary != null && commandSummary.isNotEmpty) {
        output.writeln(commandSummary);
      }
      output.writeln('\n1. Refresh ${field.name}');
      output.writeln('2. Set ${field.name}');
      output.writeln('3. Change Game');
      output.writeln('4. Change RPCS3 Process');
      output.writeln('0. Exit');
      final selection = _prompt(output, 'Select an option: ');
      if (selection == null || selection == '0') return _exitGame;
      switch (selection) {
        case '1':
          _runRead(processId, memoryBase, profile, field, output, errorOutput);
        case '2':
          _setFieldValue(
            processId,
            memoryBase,
            profile,
            field,
            output,
            errorOutput,
          );
        case '3':
          return _changeGame;
        case '4':
          return _changeProcess;
        default:
          output.writeln('Choose one of the listed options.');
      }
    }
    return _exitGame;
  }

  void _setFieldValue(
    int processId,
    int memoryBase,
    GameProfile profile,
    GameField field,
    StringSink output,
    StringSink errorOutput,
  ) {
    if (!_runRead(processId, memoryBase, profile, field, output, errorOutput)) {
      output.writeln('A fresh value could not be read; write cancelled.');
      return;
    }

    final input = _prompt(
      output,
      'Enter new ${field.name.toLowerCase()} value: ',
    );
    if (input == null) return;
    final value = int.tryParse(input.trim());
    if (value == null || !_isWithinFieldRange(value, field)) {
      final minimum = field.minimumValue ?? 0;
      final maximum = field.maximumValue ?? GameMemoryConstants.maxUnsigned32;
      output.writeln('Enter a value between $minimum and $maximum.');
      return;
    }

    output.writeln(
      'Write target: ${profile.gameName}, RPCS3 PID $processId, base ${_formatMemoryBase(memoryBase)}.',
    );
    output.writeln(
      'Ludava does not verify that this process is running the selected game.',
    );
    final confirmation = _prompt(output, 'Apply $value ${field.name}? (Y/N): ');
    if (confirmation == null || confirmation.toLowerCase() != 'y') {
      output.writeln('Write cancelled.');
      return;
    }

    output.writeln('Writing...');
    _runCommandAndDisplay(
      [
        'write',
        '--game',
        profile.id,
        '--field',
        field.id,
        '--pid',
        '$processId',
        '--memory-base',
        _formatMemoryBase(memoryBase),
        '--value',
        '$value',
        '--confirm-write',
      ],
      output,
      errorOutput,
    );
    _runRead(processId, memoryBase, profile, field, output, errorOutput);
  }

  bool _runRead(
    int processId,
    int memoryBase,
    GameProfile profile,
    GameField field,
    StringSink output,
    StringSink errorOutput,
  ) => _runCommandAndDisplay(
    [
      'read',
      '--game',
      profile.id,
      '--field',
      field.id,
      '--pid',
      '$processId',
      '--memory-base',
      _formatMemoryBase(memoryBase),
    ],
    output,
    errorOutput,
  );

  bool _runCommandAndDisplay(
    List<String> arguments,
    StringSink output,
    StringSink errorOutput,
  ) {
    final commandOutput = StringBuffer();
    final commandError = StringBuffer();
    final exitCode = _runCommand(arguments, commandOutput, commandError);
    _lastCommandSummary = commandOutput.toString().trimRight();
    if (commandOutput.isNotEmpty)
      output.writeln(commandOutput.toString().trimRight());
    if (commandError.isNotEmpty) {
      errorOutput.writeln(commandError.toString().trimRight());
    }
    return exitCode == 0;
  }

  bool _isWithinFieldRange(int value, GameField field) {
    if (value < (field.minimumValue ?? 0) ||
        value > (field.maximumValue ?? GameMemoryConstants.maxUnsigned32)) {
      return false;
    }
    return value <= GameMemoryConstants.maxUnsigned32;
  }

  bool _askToSearchAgain(StringSink output) {
    output.writeln('1. Search again');
    output.writeln('0. Exit');
    return _prompt(output, 'Select an option: ') == '1';
  }

  String? _prompt(StringSink output, String prompt) {
    output.write(prompt);
    final input = _readLine();
    if (input == null) _inputEnded = true;
    return input;
  }

  void _beginScreen(StringSink output, {bool showHeader = false}) {
    var cleared = false;
    if (_ownsTerminalOutput) cleared = _clearScreen?.call() ?? false;
    if (!cleared) output.writeln('\n----------------------------------------');
    if (showHeader) {
      output.writeln('               LUDAVA');
      output.writeln('          Game Memory Trainer');
      output.writeln('========================================');
    }
  }

  String _formatMemoryBase(int memoryBase) =>
      '0x${memoryBase.toRadixString(16)}';
}
