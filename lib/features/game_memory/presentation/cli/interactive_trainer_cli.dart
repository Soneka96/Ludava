import 'dart:io';

import 'package:ludava/features/game_memory/domain/entities/game_field.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/game_memory/domain/profiles/game_profile_catalog.dart';
import 'package:ludava/features/game_memory/domain/usecases/params/resolve_game_profile.params.dart';
import 'package:ludava/features/game_memory/domain/usecases/resolve_game_profile.usecase.dart';
import 'package:ludava/features/game_memory/presentation/cli/diagnostic_argument_parser.dart';
import 'package:ludava/shared/constants/app_constants.dart';
import 'package:ludava/shared/constants/enums.dart';

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
    GameDetectionResult Function(
      int processId,
      Rpcs3ProcessMetadata processMetadata,
    )?
    detectGame,
    String? Function()? readLine,
    bool? hasTerminal,
    bool Function()? clearScreen,
    bool clearScreenForInjectedOutput = false,
  }) : _discoverProcessIds = discoverProcessIds,
       _readProcessMetadata = readProcessMetadata,
       _resolveMemoryBaseCandidate = resolveMemoryBaseCandidate,
       _runCommand = runCommand,
       _detectGame = detectGame,
       _readLine = readLine ?? stdin.readLineSync,
       _hasTerminal = hasTerminal,
       _clearScreen = clearScreen,
       _clearScreenForInjectedOutput = clearScreenForInjectedOutput;

  static const int _exitGame = 0;
  static const int _changeGame = 1;
  static const int _changeProcess = 2;
  static const int _returnToGame = 3;
  static const int _redetectGame = 4;
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
  final GameDetectionResult Function(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  )?
  _detectGame;
  final String? Function() _readLine;
  final bool? _hasTerminal;
  final bool Function()? _clearScreen;
  final bool _clearScreenForInjectedOutput;

  bool _inputEnded = false;
  bool _ownsTerminalOutput = false;
  int? _boltCount;
  String? _boltReadError;
  String? _lastFeedback;
  Rpcs3ProcessMetadata? _selectedProcessMetadata;
  bool _processSessionChanged = false;
  bool _processUnavailable = false;
  bool _retryDetectionRequested = false;

  /// Runs the interactive menu and returns its process exit code.
  int run({StringSink? output, StringSink? errorOutput}) {
    final stdoutSink = output ?? stdout;
    final stderrSink = errorOutput ?? stderr;
    _ownsTerminalOutput = output == null || _clearScreenForInjectedOutput;
    _inputEnded = false;
    _boltCount = null;
    _boltReadError = null;
    _lastFeedback = null;
    _selectedProcessMetadata = null;
    _processSessionChanged = false;
    _processUnavailable = false;
    _retryDetectionRequested = false;
    if (!(_hasTerminal ?? stdin.hasTerminal)) {
      stderrSink.writeln(
        'Interactive mode requires a terminal. Use --help to see commands.',
      );
      return 2;
    }

    while (!_inputEnded) {
      final processId = _selectProcess(stdoutSink, stderrSink);
      if (processId == null) return 0;
      final profiles = GameProfileCatalog.profiles.toList(growable: false);
      var gameSelection = _selectGameForProcess(
        processId,
        profiles,
        stdoutSink,
      );
      if (gameSelection == null) {
        if (_processSessionChanged || _processUnavailable) {
          _processSessionChanged = false;
          _processUnavailable = false;
          _selectedProcessMetadata = null;
          continue;
        }
        return 0;
      }
      final memoryBase = _selectMemoryBase(
        processId,
        stdoutSink,
        stderrSink,
        automaticIdentity:
            gameSelection.confidence == GameIdentityConfidence.confirmed,
      );
      if (_inputEnded) return 0;
      if (memoryBase == null) {
        if (_processSessionChanged || _processUnavailable) {
          _processSessionChanged = false;
          _processUnavailable = false;
          _selectedProcessMetadata = null;
          continue;
        }
        return 0;
      }

      var returnToProcessMenu = false;
      while (!_inputEnded && !returnToProcessMenu) {
        final action = _gameMenu(
          processId,
          memoryBase,
          gameSelection!,
          stdoutSink,
          stderrSink,
        );
        switch (action) {
          case _exitGame:
            return 0;
          case _changeGame:
            _boltCount = null;
            _boltReadError = null;
            _lastFeedback = null;
            final profile = _selectGame(profiles, stdoutSink);
            if (profile == null) return 0;
            gameSelection = _manualGameSelection(processId, profile);
            continue;
          case _redetectGame:
            _boltCount = null;
            _boltReadError = null;
            _lastFeedback = null;
            gameSelection = _selectGameForProcess(
              processId,
              profiles,
              stdoutSink,
              refreshProcess: true,
            );
            if (gameSelection == null) {
              if (_processSessionChanged || _processUnavailable) {
                returnToProcessMenu = true;
                _processSessionChanged = false;
                _processUnavailable = false;
                continue;
              }
              return 0;
            }
            continue;
          case _changeProcess:
            _boltCount = null;
            _boltReadError = null;
            _lastFeedback = null;
            _selectedProcessMetadata = null;
            _retryDetectionRequested = false;
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
    StringSink errorOutput, {
    required bool automaticIdentity,
  }) {
    Rpcs3MemoryBaseCandidate? candidate;
    while (!_inputEnded) {
      _beginScreen(output);
      output.writeln(
        automaticIdentity
            ? 'Resolving RPCS3 guest memory base'
            : 'Confirm RPCS3 connection',
      );
      candidate = null;
      try {
        final selectedStart = _selectedProcessMetadata?.startedAtUtc;
        final metadata = _readProcessMetadata(processId);
        if (selectedStart != null && metadata.startedAtUtc != selectedStart) {
          output.writeln(
            'The RPCS3 process session changed. Select the process and memory base again.',
          );
          _processSessionChanged = true;
          _selectedProcessMetadata = null;
          return null;
        }
        _selectedProcessMetadata = metadata;
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

      if (automaticIdentity && candidate != null) {
        output.writeln('Guest memory base resolved for this RPCS3 session.');
        return candidate.memoryBase;
      }
      if (automaticIdentity && candidate == null) {
        output.writeln(
          'Ludava could not verify a guest memory base for this RPCS3 session.',
        );
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

  GameDetectionResult? _selectGameForProcess(
    int processId,
    List<GameProfile> profiles,
    StringSink output, {
    bool refreshProcess = false,
  }) {
    while (!_inputEnded) {
      _processSessionChanged = false;
      _processUnavailable = false;
      var processMetadata = _selectedProcessMetadata;
      final previousStart = processMetadata?.startedAtUtc;
      if (refreshProcess) {
        List<int> processIds;
        try {
          processIds = _discoverProcessIds();
        } on Exception catch (error) {
          output.writeln('Could not refresh RPCS3 detection: $error');
          _processUnavailable = true;
          return null;
        } on UnsupportedError catch (error) {
          output.writeln('Could not refresh RPCS3 detection: $error');
          _processUnavailable = true;
          return null;
        }
        if (!processIds.contains(processId)) {
          output.writeln('The selected RPCS3 process is no longer running.');
          _processUnavailable = true;
          return null;
        }
      }

      if (refreshProcess || processMetadata == null) {
        try {
          processMetadata = _readProcessMetadata(processId);
        } on Exception catch (error) {
          return _chooseFromDetection(
            GameDetectionResult(
              status: GameDetectionStatus.failed,
              processId: processId,
              confidence: GameIdentityConfidence.none,
              evidenceDescription:
                  'Could not read RPCS3 process metadata: $error',
            ),
            processId,
            profiles,
            output,
          );
        } on UnsupportedError catch (error) {
          return _chooseFromDetection(
            GameDetectionResult(
              status: GameDetectionStatus.failed,
              processId: processId,
              confidence: GameIdentityConfidence.none,
              evidenceDescription:
                  'Could not read RPCS3 process metadata: $error',
            ),
            processId,
            profiles,
            output,
          );
        }
        if (refreshProcess &&
            previousStart != null &&
            processMetadata.startedAtUtc != previousStart) {
          output.writeln(
            'The RPCS3 process session changed. Select the process and memory base again.',
          );
          _processSessionChanged = true;
          _selectedProcessMetadata = null;
          return null;
        }
        _selectedProcessMetadata = processMetadata;
      }

      GameDetectionResult result;
      try {
        result =
            _detectGame?.call(processId, processMetadata) ??
            GameDetectionResult(
              status: GameDetectionStatus.ambiguous,
              processId: processId,
              confidence: GameIdentityConfidence.none,
              evidenceDescription:
                  'No current-game identity provider is available.',
            );
      } on Exception catch (error) {
        result = GameDetectionResult(
          status: GameDetectionStatus.failed,
          processId: processId,
          confidence: GameIdentityConfidence.none,
          evidenceDescription: 'Game detection failed: $error',
        );
      } on UnsupportedError catch (error) {
        result = GameDetectionResult(
          status: GameDetectionStatus.failed,
          processId: processId,
          confidence: GameIdentityConfidence.none,
          evidenceDescription: 'Game detection failed: $error',
        );
      }
      if (result.processId != processId) {
        result = GameDetectionResult(
          status: GameDetectionStatus.failed,
          processId: processId,
          confidence: GameIdentityConfidence.none,
          evidenceDescription:
              'Game detection evidence does not match the selected RPCS3 process.',
        );
      }
      final selection = _chooseFromDetection(
        result,
        processId,
        profiles,
        output,
      );
      if (_retryDetectionRequested) {
        _retryDetectionRequested = false;
        refreshProcess = true;
        continue;
      }
      return selection;
    }
    return null;
  }

  GameDetectionResult? _chooseFromDetection(
    GameDetectionResult result,
    int processId,
    List<GameProfile> profiles,
    StringSink output,
  ) {
    if (result.status == GameDetectionStatus.supportedGame &&
        result.confidence == GameIdentityConfidence.confirmed) {
      output.writeln('${result.gameTitle} detected.');
      output.writeln('Trainer profile matched: ${result.profile!.id}.');
      return result;
    }
    _writeDetectionSummary(output, result);
    if (result.status == GameDetectionStatus.rpcs3NotRunning) {
      _processUnavailable = true;
      return null;
    }
    if (result.status == GameDetectionStatus.unsupportedGame &&
        result.confidence == GameIdentityConfidence.confirmed) {
      output.writeln('No trainer profile is available for this game.');
      output.writeln('1. Retry detection');
      output.writeln('0. Exit');
      _retryDetectionRequested = _prompt(output, 'Select an option: ') == '1';
      return null;
    }
    if (result.status == GameDetectionStatus.noActiveGame) {
      output.writeln('No active game was identified.');
      output.writeln('1. Retry detection');
      output.writeln('0. Exit');
      _retryDetectionRequested = _prompt(output, 'Select an option: ') == '1';
      return null;
    }

    output.writeln('Choose a profile manually to continue:');
    final profile = _selectGame(profiles, output);
    if (profile == null) return null;
    return _manualGameSelection(processId, profile);
  }

  GameDetectionResult _manualGameSelection(
    int processId,
    GameProfile profile,
  ) => ResolveGameProfileUseCase().execute(
    ResolveGameProfileParams(
      processId: processId,
      confidence: GameIdentityConfidence.manuallySelected,
      manualProfileId: profile.id,
      evidenceDescription:
          'The user selected this profile manually; the active game was not verified.',
    ),
  );

  void _writeDetectionSummary(StringSink output, GameDetectionResult result) {
    output.writeln('\nDetecting game...');
    final title = result.gameTitle;
    final confirmedUnsupported =
        result.status == GameDetectionStatus.unsupportedGame &&
        result.confidence == GameIdentityConfidence.confirmed;
    if (confirmedUnsupported && title != null) {
      output.writeln('Game identified: $title');
    } else if (title != null) {
      output.writeln('RPCS3 log title candidate (unverified): $title');
    }
    final titleId = result.titleId;
    if (titleId != null) {
      output.writeln(
        confirmedUnsupported
            ? 'Title ID: $titleId'
            : 'Title ID candidate: $titleId',
      );
    }
    if (!confirmedUnsupported) {
      output.writeln(
        'Ludava could not verify the active game from current evidence.',
      );
    }
    output.writeln('Detection: ${result.evidenceDescription}');
  }

  int _gameMenu(
    int processId,
    int memoryBase,
    GameDetectionResult detection,
    StringSink output,
    StringSink errorOutput,
  ) {
    final profile = detection.profile!;
    final field = profile.findField('bolts');
    if (field == null) {
      output.writeln('This profile does not define the bolts field.');
      return _changeGame;
    }
    _runRead(
      processId,
      memoryBase,
      profile,
      field,
      errorOutput,
      requireCurrentIdentity:
          detection.confidence == GameIdentityConfidence.confirmed,
    );
    _lastFeedback = null;
    while (!_inputEnded) {
      _beginScreen(output);
      _writeGameScreen(output, detection);
      final feedback = _lastFeedback;
      if (feedback != null) output.writeln('\n$feedback');
      output.writeln('\n1. Refresh bolts');
      output.writeln('2. Change bolts');
      output.writeln('3. Change game');
      output.writeln('4. Connection details');
      output.writeln('5. Re-detect game');
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
            requireCurrentIdentity:
                detection.confidence == GameIdentityConfidence.confirmed,
          );
          _lastFeedback =
              refreshed ? 'Bolts refreshed.' : 'Bolts could not be read.';
        case '2':
          _setFieldValue(
            processId,
            memoryBase,
            profile,
            field,
            detection,
            output,
            errorOutput,
          );
          if (_processSessionChanged || _processUnavailable) {
            return _changeProcess;
          }
          if (_retryDetectionRequested) {
            _retryDetectionRequested = false;
            return _redetectGame;
          }
        case '3':
          return _changeGame;
        case '4':
          final detailsAction = _connectionDetails(
            processId,
            memoryBase,
            profile,
            field,
            detection,
            output,
          );
          if (detailsAction == _changeProcess || detailsAction == _exitGame) {
            return detailsAction;
          }
        case '5':
          return _redetectGame;
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
    GameDetectionResult detection,
    StringSink output,
    StringSink errorOutput,
  ) {
    if (detection.confidence != GameIdentityConfidence.confirmed) {
      _lastFeedback =
          'Writes are disabled until the active game is verified automatically.';
      return;
    }
    if (!_runRead(
      processId,
      memoryBase,
      profile,
      field,
      errorOutput,
      requireCurrentIdentity: true,
    )) {
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
    output.writeln(_identityDisclosure(detection.confidence));
    final confirmation = _prompt(
      output,
      'Change bolts to ${_formatNumber(value)}? (Y/N): ',
    );
    if (confirmation == null || confirmation.toLowerCase() != 'y') {
      _lastFeedback = 'Change cancelled. Your bolts were not changed.';
      return;
    }

    if (!_validateCurrentWriteTarget(
      processId,
      memoryBase,
      profile,
      detection,
      output,
    )) {
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
    _runRead(
      processId,
      memoryBase,
      profile,
      field,
      errorOutput,
      requireCurrentIdentity: true,
    );
  }

  bool _validateCurrentWriteTarget(
    int processId,
    int memoryBase,
    GameProfile profile,
    GameDetectionResult selectedDetection,
    StringSink output,
  ) {
    void reject(String message) {
      _boltCount = null;
      _boltReadError = 'The current game identity is not verified.';
      _lastFeedback = message;
      output.writeln('\n$message');
      _retryDetectionRequested = true;
    }

    try {
      final processIds = _discoverProcessIds();
      if (!processIds.contains(processId)) {
        _processUnavailable = true;
        reject('RPCS3 stopped. No write was made.');
        return false;
      }

      final currentMetadata = _readProcessMetadata(processId);
      final selectedStartedAt = _selectedProcessMetadata?.startedAtUtc;
      if (selectedStartedAt == null ||
          currentMetadata.startedAtUtc != selectedStartedAt) {
        _processSessionChanged = true;
        reject('The RPCS3 session changed. No write was made.');
        return false;
      }

      final currentDetection = _detectGame?.call(processId, currentMetadata);
      final currentBase = _resolveMemoryBaseCandidate(currentMetadata);
      final identityStillMatches =
          currentDetection?.processId == processId &&
          currentDetection?.status == GameDetectionStatus.supportedGame &&
          currentDetection?.confidence == GameIdentityConfidence.confirmed &&
          currentDetection?.profile?.id == profile.id &&
          currentDetection?.executableHash == selectedDetection.executableHash;
      if (!identityStillMatches || currentBase?.memoryBase != memoryBase) {
        reject(
          'The active game or memory base changed. No write was made; re-detect before continuing.',
        );
        return false;
      }
      return true;
    } on Exception catch (error) {
      reject(
        'Could not revalidate the game before writing. No write was made: $error',
      );
      return false;
    } on UnsupportedError catch (error) {
      reject(
        'Could not revalidate the game before writing. No write was made: $error',
      );
      return false;
    }
  }

  bool _runRead(
    int processId,
    int memoryBase,
    GameProfile profile,
    GameField field,
    StringSink errorOutput, {
    bool requireCurrentIdentity = false,
  }) {
    final arguments = [
      'read',
      '--game',
      profile.id,
      '--field',
      field.id,
      '--pid',
      '$processId',
      '--memory-base',
      _formatMemoryBase(memoryBase),
    ];
    if (requireCurrentIdentity) {
      arguments.add('--require-current-identity');
    }
    return _runCommandAndDisplay(arguments, errorOutput);
  }

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

  void _writeGameScreen(StringSink output, GameDetectionResult detection) {
    final profile = detection.profile!;
    output.writeln('================================');
    output.writeln('             LUDAVA');
    output.writeln('================================');
    output.writeln();
    output.writeln(
      '  ${_boltCount == null ? 'RPCS3 process found' : 'Connected to RPCS3'}',
    );
    output.writeln();
    output.writeln(
      detection.confidence == GameIdentityConfidence.manuallySelected
          ? '  Manual profile: ${profile.gameName}'
          : '  Detected game: ${profile.gameName}',
    );
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
    GameDetectionResult detection,
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
      output.writeln('Game identity: ${_identityLabel(detection.confidence)}');
      output.writeln('Detection status: ${detection.status.name}');
      output.writeln('Detection evidence: ${detection.evidenceDescription}');
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

  String _identityLabel(
    GameIdentityConfidence confidence,
  ) => switch (confidence) {
    GameIdentityConfidence.confirmed => 'automatically identified',
    GameIdentityConfidence.manuallySelected => 'selected manually; unverified',
    GameIdentityConfidence.none ||
    GameIdentityConfidence.uncertain => 'unresolved',
  };

  String _identityDisclosure(GameIdentityConfidence confidence) =>
      confidence == GameIdentityConfidence.manuallySelected
          ? 'This profile was selected manually; Ludava cannot verify the active game or build.'
          : 'The current PPU identity was rechecked before this write. Compatibility with other builds is not established.';

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
    return input?.trim();
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
