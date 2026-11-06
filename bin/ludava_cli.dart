import 'dart:io';

import 'package:ludava/features/game_detection/data/datasources/rpcs3_game_identity_log.datasource.dart';
import 'package:ludava/features/rpcs3_connection/data/datasources/rpcs3_memory_base_resolver.datasource.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_console.datasource.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_memory_api.dart';
import 'package:ludava/shared/platform/windows_memory_exception.dart';
import 'package:ludava/features/rpcs3_connection/data/datasources/windows_process_discovery.datasource.dart';
import 'package:ludava/features/rpcs3_connection/data/datasources/windows_process_metadata.datasource.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_process_memory.datasource.dart';
import 'package:ludava/features/game_memory/data/repositories/game_memory.repository.dart';
import 'package:ludava/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/game_detection/application/rpcs3_game_detection_workflow.dart';
import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/game_catalog/domain/entities/game_profile.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/features/game_catalog/domain/profiles/game_profile_catalog.dart';
import 'package:ludava/features/game_memory/domain/usecases/params/read_game_field.params.dart';
import 'package:ludava/features/game_memory/domain/usecases/params/write_game_field.params.dart';
import 'package:ludava/features/game_memory/domain/usecases/read_game_field.usecase.dart';
import 'package:ludava/features/game_memory/domain/usecases/write_game_field.usecase.dart';
import 'package:ludava/features/game_memory/presentation/cli/diagnostic_argument_parser.dart';
import 'package:ludava/features/game_memory/presentation/cli/diagnostic_arguments.dart';
import 'package:ludava/features/game_memory/presentation/cli/game_memory_output.dart';
import 'package:ludava/features/game_memory/presentation/cli/interactive_trainer_cli.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Composes the command-line trainer and its Windows data boundary.
class LudavaCli {
  /// Creates the CLI with optional platform, process, and identity test seams.
  LudavaCli({
    WindowsMemoryApi? api,
    bool? isWindows,
    int? pointerSize,
    InteractiveTrainerCli? interactiveCli,
    List<int> Function()? discoverProcessIds,
    Rpcs3ProcessMetadata Function(int processId)? readProcessMetadata,
    Rpcs3MemoryBaseCandidate? Function(Rpcs3ProcessMetadata processMetadata)?
    resolveMemoryBaseCandidate,
    GameDetectionResult Function(
      int processId,
      Rpcs3ProcessMetadata processMetadata,
    )?
    detectGame,
    Rpcs3GameIdentityLogDataSource? gameIdentityLogDataSource,
  }) : _api = api,
       _isWindows = isWindows,
       _pointerSize = pointerSize,
       _interactiveCli = interactiveCli,
       _discoverProcessIds = discoverProcessIds,
       _readProcessMetadata = readProcessMetadata,
       _resolveMemoryBaseCandidate = resolveMemoryBaseCandidate,
       _detectGame = detectGame,
       _gameIdentityLogDataSource = gameIdentityLogDataSource;

  final WindowsMemoryApi? _api;
  final bool? _isWindows;
  final int? _pointerSize;
  final InteractiveTrainerCli? _interactiveCli;
  final List<int> Function()? _discoverProcessIds;
  final Rpcs3ProcessMetadata Function(int processId)? _readProcessMetadata;
  final Rpcs3MemoryBaseCandidate? Function(
    Rpcs3ProcessMetadata processMetadata,
  )?
  _resolveMemoryBaseCandidate;
  final GameDetectionResult Function(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  )?
  _detectGame;
  final Rpcs3GameIdentityLogDataSource? _gameIdentityLogDataSource;

  /// Runs one command and returns its process exit code.
  int run(
    List<String> arguments, {
    StringSink? output,
    StringSink? errorOutput,
  }) {
    final stdoutSink = output ?? stdout;
    final stderrSink = errorOutput ?? stderr;
    if (arguments.isEmpty) {
      return (_interactiveCli ?? _createInteractiveCli()).run(
        output: output,
        errorOutput: errorOutput,
      );
    }
    if (arguments.length == 1 && arguments.single == '--help') {
      stdoutSink.writeln(DiagnosticArgumentParser.usage);
      return 0;
    }

    late final DiagnosticArguments options;
    try {
      options = DiagnosticArgumentParser.parse(arguments);
    } on FormatException catch (error) {
      stderrSink.writeln(error.message);
      stderrSink.writeln(DiagnosticArgumentParser.usage);
      return 2;
    }

    final profile = GameProfileCatalog.find(options.gameId);
    if (profile == null) {
      stderrSink.writeln('Unknown game profile: ${options.gameId}');
      return 2;
    }

    final isWrite = options.action == GameMemoryAction.write;
    final field = profile.findField(options.fieldId);
    if (isWrite) {
      if (!profile.canWrite) {
        stdoutSink.writeln(
          GameMemoryOutput.writeResult(
            profile,
            GameWriteResult(
              status: GameWriteStatus.unsupportedProfile,
              fieldId: options.fieldId,
              requestedValue: options.value,
            ),
          ),
        );
        return 1;
      }
      if (field == null || !field.canWrite) {
        stdoutSink.writeln(
          GameMemoryOutput.writeResult(
            profile,
            GameWriteResult(
              status: GameWriteStatus.unsupportedField,
              fieldId: options.fieldId,
              requestedValue: options.value,
            ),
          ),
        );
        return 1;
      }
    } else {
      if (field == null || !field.canRead) {
        stdoutSink.writeln(
          GameMemoryOutput.readResult(
            profile,
            GameReadResult(
              status: GameReadStatus.unsupportedField,
              fieldId: options.fieldId,
            ),
          ),
        );
        return 1;
      }
      if (!profile.canRead) {
        stdoutSink.writeln(
          GameMemoryOutput.readResult(
            profile,
            GameReadResult(
              status: GameReadStatus.unsupportedProfile,
              fieldId: options.fieldId,
            ),
          ),
        );
        return 1;
      }
    }

    Rpcs3ProcessMetadata? processMetadata;
    GameDetectionResult? gameIdentity;
    try {
      if (_findRpcs3ProcessIds().contains(options.processId)) {
        processMetadata = _readMetadata(options.processId);
        gameIdentity = _detectCurrentGame(options.processId, processMetadata);
      }
    } on Exception catch (error) {
      if (isWrite) {
        stderrSink.writeln(
          'Write blocked: RPCS3 identity could not be checked: $error',
        );
        return 1;
      }
    } on UnsupportedError catch (error) {
      if (isWrite) {
        stderrSink.writeln(
          'Write blocked: RPCS3 identity could not be checked: $error',
        );
        return 1;
      }
    }

    final identityConfirmed = _identityMatchesProfile(
      gameIdentity,
      options.processId,
      profile,
    );
    if (isWrite && !identityConfirmed) {
      stderrSink.writeln(
        'Write blocked: current RPCS3 game identity does not match ${profile.id}.',
      );
      return 1;
    }
    if (options.requireCurrentIdentity && !identityConfirmed) {
      stderrSink.writeln(
        'Read blocked: current RPCS3 game identity does not match ${profile.id}.',
      );
      return 1;
    }
    if (isWrite) {
      Rpcs3MemoryBaseCandidate? currentBase;
      try {
        final metadata = processMetadata;
        if (metadata != null) {
          currentBase = _resolveBaseCandidate(metadata);
        }
      } on Exception catch (error) {
        stderrSink.writeln(
          'Write blocked: current RPCS3 memory base could not be checked: $error',
        );
        return 1;
      } on UnsupportedError catch (error) {
        stderrSink.writeln(
          'Write blocked: current RPCS3 memory base could not be checked: $error',
        );
        return 1;
      }
      if (currentBase == null || currentBase.memoryBase != options.memoryBase) {
        stderrSink.writeln(
          'Write blocked: the supplied memory base does not match the current RPCS3 session.',
        );
        return 1;
      }
    }

    WindowsProcessMemoryDataSource? dataSource;
    var exitCode = 0;
    try {
      dataSource = WindowsProcessMemoryDataSource.open(
        options.processId,
        api: _api,
        isWindows: _isWindows,
        pointerSize: _pointerSize,
        allowWrites: isWrite,
      );
      final repository = GameMemoryRepository(dataSource);
      if (isWrite) {
        final result = WriteGameFieldUseCase(repository).execute(
          WriteGameFieldParams(
            profile: profile,
            fieldId: options.fieldId,
            memoryBase: options.memoryBase,
            value: options.value!,
            confirmed: options.confirmed,
          ),
        );
        stdoutSink.writeln(
          GameMemoryOutput.writeResult(
            profile,
            result,
            identityConfirmed: identityConfirmed,
          ),
        );
        if (!result.succeeded) exitCode = 1;
      } else {
        final result = ReadGameFieldUseCase(repository).execute(
          ReadGameFieldParams(
            profile: profile,
            fieldId: options.fieldId,
            memoryBase: options.memoryBase,
          ),
        );
        stdoutSink.writeln(
          GameMemoryOutput.readResult(
            profile,
            result,
            identityConfirmed: identityConfirmed,
          ),
        );
        if (!result.succeeded) exitCode = 1;
      }
    } on WindowsMemoryException catch (error) {
      stderrSink.writeln(error);
      exitCode = 1;
    } on UnsupportedError catch (error) {
      stderrSink.writeln(error);
      exitCode = 1;
    } finally {
      try {
        dataSource?.close();
      } on WindowsMemoryException catch (error) {
        stderrSink.writeln(error);
        exitCode = 1;
      }
    }
    return exitCode;
  }

  InteractiveTrainerCli _createInteractiveCli() => InteractiveTrainerCli(
    discoverProcessIds: _findRpcs3ProcessIds,
    readProcessMetadata: _readMetadata,
    resolveMemoryBaseCandidate: _resolveBaseCandidate,
    detectGame: _detectCurrentGame,
    runCommand:
        (arguments, output, errorOutput) =>
            run(arguments, output: output, errorOutput: errorOutput),
    clearScreen: WindowsConsoleDataSource().clearScreen,
  );

  List<int> _findRpcs3ProcessIds() =>
      _discoverProcessIds?.call() ??
      WindowsProcessDiscoveryDataSource().findRpcs3ProcessIds();

  Rpcs3ProcessMetadata _readMetadata(int processId) =>
      _readProcessMetadata?.call(processId) ??
      WindowsProcessMetadataDataSource().read(processId);

  Rpcs3MemoryBaseCandidate? _resolveBaseCandidate(
    Rpcs3ProcessMetadata processMetadata,
  ) =>
      _resolveMemoryBaseCandidate?.call(processMetadata) ??
      Rpcs3MemoryBaseResolverDataSource().resolveCandidate(processMetadata);

  GameDetectionResult _detectCurrentGame(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  ) =>
      _detectGame?.call(processId, processMetadata) ??
      _detectGameFromLog(processId, processMetadata);

  GameDetectionResult _detectGameFromLog(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  ) => Rpcs3GameDetectionWorkflow(
    discoverProcessIds: _findRpcs3ProcessIds,
    readProcessMetadata: _readMetadata,
    readIdentityLogCandidates:
        (metadata) =>
            (_gameIdentityLogDataSource ?? Rpcs3GameIdentityLogDataSource())
                .readCandidates(metadata),
  ).detect(processId, processMetadata);

  bool _identityMatchesProfile(
    GameDetectionResult? identity,
    int processId,
    GameProfile profile,
  ) =>
      identity?.processId == processId &&
      identity?.status == GameDetectionStatus.supportedGame &&
      identity?.confidence == GameIdentityConfidence.confirmed &&
      identity?.profile?.id == profile.id &&
      profile.executableHash != null &&
      identity?.executableHash?.toLowerCase() ==
          profile.executableHash!.toLowerCase();
}
