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
  static const int _returnToGame = 3;
  static const int _researchTestedMemoryBase = 0x300000000;
  static const String _collectionTitleId = 'BCUS98282';

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
  int? _boltCount;
  String? _boltReadError;
  String? _lastFeedback;

  /// Runs the interactive menu and returns its process exit code.
  int run({StringSink? output, StringSink? errorOutput}) {
    final stdoutSink = output ?? stdout;
    final stderrSink = errorOutput ?? stderr;
    _ownsTerminalOutput = output == null || _clearScreenForInjectedOutput;
    _inputEnded = false;
    _boltCount = null;
    _boltReadError = null;
    _lastFeedback = null;
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
        output.writeln('RPCS3 is ready.');
        return processIds.single;
      }

      output.writeln('\nSeveral RPCS3 processes were found:');
      for (var index = 0; index < processIds.length; index++) {
        output.writeln('  ${index + 1}. RPCS3 process (${processIds[index]})');
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
      output.writeln('RPCS3 process selected.');
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
      output.writeln('Confirm RPCS3 connection');
      candidate = null;
      try {
        final metadata = _readProcessMetadata(processId);
        candidate = _resolveMemoryBaseCandidate(metadata);
      } on Exception catch (error) {
        output.writeln('Could not check the RPCS3 process or its log: $error');
        output.writeln(
          'The process may have exited, access may be denied, or its log may be locked.',
        );
      } on UnsupportedError catch (error) {
        errorOutput.writeln(error);
        return null;
      }

      if (candidate == null) {
        output.writeln(
          '\nLudava could not find the memory base automatically.',
        );
        output.writeln(
          'Suggested base for this session: ${_formatMemoryBase(_researchTestedMemoryBase)}',
        );
        output.writeln('1. Use the suggested base (confirm for this session)');
        output.writeln('2. Enter another hexadecimal base');
        output.writeln('3. Retry detection');
        output.writeln('0. Cancel');
      } else {
        output.writeln('\nA memory base was found in an RPCS3 log.');
        output.writeln(
          'Candidate memory base: ${_formatMemoryBase(candidate.memoryBase)}',
        );
        output.writeln(
          'The log may belong to another RPCS3 instance. Confirm before use.',
        );
        output.writeln('1. Use this base (confirm for this session)');
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
    output.writeln('\nChoose your game:');
    for (var index = 0; index < profiles.length; index++) {
      final profile = profiles[index];
      output.writeln('  ${index + 1}. ${_gameTitle(profile)}');
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
    _runRead(processId, memoryBase, profile, field, errorOutput);
    _lastFeedback = null;
    while (!_inputEnded) {
      _beginScreen(output);
      _writeGameScreen(output, profile);
      final feedback = _lastFeedback;
      if (feedback != null) output.writeln('\n$feedback');
      output.writeln('\n1. Refresh bolts');
      output.writeln('2. Change bolts');
      output.writeln('3. Change game');
      output.writeln('4. Connection details');
      output.writeln('0. Exit');
      final selection = _prompt(output, 'Select an option: ');
      if (selection == null || selection == '0') return _exitGame;
      switch (selection) {
        case '1':
          final refreshed = _runRead(
            processId,
            memoryBase,
            profile,
            field,
            errorOutput,
          );
          _lastFeedback =
              refreshed ? 'Bolts refreshed.' : 'Bolts could not be read.';
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
          final detailsAction = _connectionDetails(
            processId,
            memoryBase,
            profile,
            field,
            output,
          );
          if (detailsAction == _changeProcess || detailsAction == _exitGame) {
            return detailsAction;
          }
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
    if (!_runRead(processId, memoryBase, profile, field, errorOutput)) {
      _lastFeedback = 'Bolts could not be read. Change cancelled.';
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
      _lastFeedback =
          'Enter a bolt value between ${_formatNumber(minimum)} and ${_formatNumber(maximum)}.';
      return;
    }

    output.writeln('You are changing bolts in ${_gameTitle(profile)}.');
    output.writeln(
      'Ludava cannot verify which game or build is running. Check Connection details.',
    );
    final confirmation = _prompt(
      output,
      'Change bolts to ${_formatNumber(value)}? (Y/N): ',
    );
    if (confirmation == null || confirmation.toLowerCase() != 'y') {
      _lastFeedback = 'Change cancelled. Your bolts were not changed.';
      return;
    }

    output.writeln('Writing...');
    _runCommandAndDisplay([
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
    ], errorOutput);
    _runRead(processId, memoryBase, profile, field, errorOutput);
  }

  bool _runRead(
    int processId,
    int memoryBase,
    GameProfile profile,
    GameField field,
    StringSink errorOutput,
  ) => _runCommandAndDisplay([
    'read',
    '--game',
    profile.id,
    '--field',
    field.id,
    '--pid',
    '$processId',
    '--memory-base',
    _formatMemoryBase(memoryBase),
  ], errorOutput);

  bool _runCommandAndDisplay(List<String> arguments, StringSink errorOutput) {
    final commandOutput = StringBuffer();
    final commandError = StringBuffer();
    final exitCode = _runCommand(arguments, commandOutput, commandError);
    if (commandError.isNotEmpty) {
      errorOutput.writeln(commandError.toString().trimRight());
    }
    if (arguments.first == 'read') {
      if (exitCode == 0) {
        final match = RegExp(
          r'Value: (\d+)',
        ).firstMatch(commandOutput.toString());
        _boltCount = int.tryParse(match?.group(1) ?? '');
        _boltReadError =
            _boltCount == null ? 'The value could not be read.' : null;
      } else {
        _boltCount = null;
        _boltReadError = _friendlyError(commandOutput.toString());
      }
    } else if (arguments.first == 'write') {
      _lastFeedback =
          exitCode == 0
              ? 'Bolts updated successfully. The new value was confirmed.'
              : 'Could not update bolts. ${_friendlyError(commandOutput.toString())}';
    }
    return exitCode == 0;
  }

  void _writeGameScreen(StringSink output, GameProfile profile) {
    output.writeln('================================');
    output.writeln('             LUDAVA');
    output.writeln('================================');
    output.writeln();
    output.writeln(
      '  ${_boltCount == null ? 'RPCS3 process found' : 'Connected to RPCS3'}',
    );
    output.writeln();
    output.writeln('  ${profile.gameName}');
    if (profile.buildId == _collectionTitleId) {
      output.writeln('  PS3 Collection');
    }
    output.writeln();
    output.writeln('  BOLTS');
    final count = _boltCount;
    output.writeln(
      '  ${count == null ? 'Not available' : _formatNumber(count)}',
    );
    if (count == null) {
      output.writeln();
      output.writeln('  Game data is not available.');
      output.writeln('  Start ${profile.gameName} in RPCS3,');
      output.writeln('  then select Refresh bolts.');
      output.writeln('  If the game is already running,');
      output.writeln('  check Connection details.');
    }
    output.writeln();
    output.writeln('--------------------------------');
  }

  int _connectionDetails(
    int processId,
    int memoryBase,
    GameProfile profile,
    GameField field,
    StringSink output,
  ) {
    while (!_inputEnded) {
      _beginScreen(output);
      output.writeln('Connection Details');
      output.writeln('------------------');
      output.writeln('Game profile: ${profile.gameName} (${profile.id})');
      output.writeln('Build ID: ${profile.buildId}');
      output.writeln('RPCS3 process ID: $processId');
      output.writeln('Memory base: ${_formatMemoryBase(memoryBase)}');
      output.writeln(
        'Bolts guest offset: ${_formatMemoryBase(field.guestOffset)}',
      );
      output.writeln();
      output.writeln(
        'Runtime verification: Ludava cannot confirm the active game or build.',
      );
      final readError = _boltReadError;
      if (_boltCount == null && readError != null) {
        output.writeln('Last read: $readError');
      }
      output.writeln('1. Return to the trainer');
      output.writeln('2. Change RPCS3 process');
      output.writeln('0. Exit');
      final selection = _prompt(output, 'Choose an option: ');
      if (selection == null || selection == '0') return _exitGame;
      if (selection == '1') return _returnToGame;
      if (selection == '2') return _changeProcess;
      output.writeln('Choose one of the listed options.');
    }
    return _exitGame;
  }

  String _friendlyError(String commandOutput) {
    final status = RegExp(r'Status: (.+)').firstMatch(commandOutput)?.group(1);
    if (status == null || status.isEmpty)
      return 'Check the error details above.';
    return switch (status) {
      'native memory read failed' => 'The memory read failed.',
      'incomplete memory read' => 'The memory read was incomplete.',
      'preliminary memory read failed' =>
        'The current value could not be read, so no write was attempted.',
      'native memory write failed' => 'The memory write failed.',
      'incomplete memory write' => 'The memory write was incomplete.',
      'read-back did not match the requested value' ||
      'read-back did not match' => 'The confirmed value did not match.',
      'write read-back failed' => 'The written value could not be confirmed.',
      'invalid memory mapping' => 'The memory location could not be used.',
      _ => status,
    };
  }

  String _gameTitle(GameProfile profile) =>
      profile.buildId == _collectionTitleId
          ? '${profile.gameName} — PS3 Collection'
          : profile.gameName;

  String _formatNumber(int value) {
    final digits = value.toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
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
      output.writeln('========================================');
    }
  }

  String _formatMemoryBase(int memoryBase) =>
      '0x${memoryBase.toRadixString(16)}';
}
