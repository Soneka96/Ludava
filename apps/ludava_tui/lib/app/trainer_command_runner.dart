import 'dart:io';

import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/rpcs3_memory_base_resolver.datasource.dart';
import 'package:ludava_tui/features/diagnostics/data/datasources/windows_console.datasource.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_process_discovery.datasource.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_process_metadata.datasource.dart';
import 'package:ludava_sdk/features/game_detection/application/rpcs3_game_detection_workflow.dart';
import 'package:ludava_tui/features/diagnostics/presentation/cli/diagnostic_argument_parser.dart';
import 'package:ludava_tui/features/diagnostics/presentation/cli/diagnostic_arguments.dart';
import 'package:ludava_tui/features/diagnostics/presentation/cli/game_memory_output.dart';
import 'package:ludava_tui/features/diagnostics/presentation/cli/interactive_trainer_cli.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/features/trainer/presentation/nocterm/trainer_session_component.dart';
import 'package:ludava_tui/shared/terminal/trainer_terminal_backend.dart';
import 'package:nocterm/nocterm.dart' show StdioBackend, runApp, shutdownApp;

/// Runs interactive and diagnostic trainer commands.
class TrainerCommandRunner {
  /// Creates the CLI with optional platform, process, and identity test seams.
  TrainerCommandRunner({
    WindowsMemoryApi? api,
    bool? isWindows,
    int? pointerSize,
    DiagnosticGameMemoryService? diagnosticGameMemoryService,
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
    bool? hasTerminal,
    Future<void> Function(TrainerSessionController sessionController)?
    runNocterm,
  }) : _api = api,
       _isWindows = isWindows,
       _pointerSize = pointerSize,
       _diagnosticGameMemoryService = diagnosticGameMemoryService,
       _hasTerminal = hasTerminal,
       _runNocterm = runNocterm,
       _interactiveCli = interactiveCli,
       _discoverProcessIds = discoverProcessIds,
       _readProcessMetadata = readProcessMetadata,
       _resolveMemoryBaseCandidate = resolveMemoryBaseCandidate,
       _detectGame = detectGame,
       _gameIdentityLogDataSource = gameIdentityLogDataSource;

  final WindowsMemoryApi? _api;
  final bool? _isWindows;
  final int? _pointerSize;
  final DiagnosticGameMemoryService? _diagnosticGameMemoryService;
  final bool? _hasTerminal;
  final Future<void> Function(TrainerSessionController sessionController)?
  _runNocterm;
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

    final result = (_diagnosticGameMemoryService ??
            _createDiagnosticGameMemoryService())
        .execute(
          DiagnosticGameMemoryRequest(
            gameId: options.gameId,
            fieldId: options.fieldId,
            processId: options.processId,
            memoryBase: options.memoryBase,
            action: options.action,
            value: options.value,
            confirmed: options.confirmed,
            requireCurrentIdentity: options.requireCurrentIdentity,
          ),
        );

    final profile = result.profile;
    switch (result.status) {
      case DiagnosticGameMemoryStatus.unknownGame:
        stderrSink.writeln('Unknown game profile: ${options.gameId}');
        return 2;
      case DiagnosticGameMemoryStatus.identityMismatch:
        final operation =
            options.action == GameMemoryAction.write ? 'Write' : 'Read';
        stderrSink.writeln(
          '$operation blocked: current RPCS3 game identity does not match ${options.gameId}.',
        );
        return 1;
      case DiagnosticGameMemoryStatus.identityCheckFailed:
        stderrSink.writeln(
          'Write blocked: RPCS3 identity could not be checked: ${result.error}',
        );
        return 1;
      case DiagnosticGameMemoryStatus.memoryBaseMismatch:
        stderrSink.writeln(
          'Write blocked: the supplied memory base does not match the current RPCS3 session.',
        );
        return 1;
      case DiagnosticGameMemoryStatus.memoryBaseCheckFailed:
        stderrSink.writeln(
          'Write blocked: current RPCS3 memory base could not be checked: ${result.error}',
        );
        return 1;
      case DiagnosticGameMemoryStatus.nativeFailure:
        stderrSink.writeln(result.error ?? 'Diagnostic memory access failed.');
        return 1;
      case DiagnosticGameMemoryStatus.invalidRequest:
      case DiagnosticGameMemoryStatus.none:
        stderrSink.writeln('Invalid diagnostic memory request.');
        return 2;
      case DiagnosticGameMemoryStatus.cleanupFailed:
      case DiagnosticGameMemoryStatus.completed:
      case DiagnosticGameMemoryStatus.memoryOperationFailed:
        if (profile == null) {
          stderrSink.writeln('Diagnostic operation returned no game profile.');
          return 1;
        }
        if (result.readResult case final readResult?) {
          stdoutSink.writeln(
            GameMemoryOutput.readResult(
              profile,
              readResult,
              identityConfirmed: result.identityConfirmed,
            ),
          );
        } else if (result.writeResult case final writeResult?) {
          stdoutSink.writeln(
            GameMemoryOutput.writeResult(
              profile,
              writeResult,
              identityConfirmed: result.identityConfirmed,
            ),
          );
        } else {
          stderrSink.writeln('Diagnostic operation returned no field result.');
          return 1;
        }
        if (result.cleanupError != null) {
          stderrSink.writeln(result.cleanupError);
        }
        return result.succeeded ? 0 : 1;
    }
  }

  /// Runs diagnostic commands or starts the Nocterm app for no arguments.
  Future<int> runAsync(
    List<String> arguments, {
    StringSink? output,
    StringSink? errorOutput,
  }) async {
    if (arguments.isNotEmpty) {
      return run(arguments, output: output, errorOutput: errorOutput);
    }
    final stderrSink = errorOutput ?? stderr;
    if (!(_hasTerminal ?? (stdin.hasTerminal && stdout.hasTerminal))) {
      stderrSink.writeln('Interactive mode requires a terminal.');
      return 2;
    }
    TrainerSessionController? sessionController;
    try {
      sessionController = _createTrainerSessionController();
      await (_runNocterm ?? _runNoctermTrainer)(sessionController);
      return 0;
    } catch (error) {
      stderrSink.writeln('Nocterm could not start: $error');
      return 1;
    } finally {
      await sessionController?.dispose();
    }
  }

  /// Creates the diagnostic interactive CLI with application boundaries.
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

  /// Builds the reusable SDK service for CLI diagnostic operations.
  DiagnosticGameMemoryService _createDiagnosticGameMemoryService() =>
      DiagnosticGameMemoryService(
        api: _api,
        isWindows: _isWindows,
        pointerSize: _pointerSize,
        discoverProcessIds: _findRpcs3ProcessIds,
        readProcessMetadata: _readMetadata,
        resolveMemoryBaseCandidate: _resolveBaseCandidate,
        detectGame: _detectCurrentGame,
        gameIdentityLogDataSource: _gameIdentityLogDataSource,
      );

  /// Runs the terminal application until its shutdown action completes.
  Future<void> _runNoctermTrainer(
    TrainerSessionController sessionController,
  ) async {
    await runApp(
      TrainerSessionComponent(
        sessionController: sessionController,
        onQuit: shutdownApp,
      ),
      enableHotReload: false,
      backend: TrainerTerminalBackend.forPlatform(
        StdioBackend.new,
        windows: Platform.isWindows,
      ),
    );
  }

  /// Composes the reusable trainer workflow with platform adapters.
  TrainerSessionController _createTrainerSessionController() =>
      LudavaTrainerFactory(
        api: _api,
        isWindows: _isWindows,
        pointerSize: _pointerSize,
        discoverProcessIds: _findRpcs3ProcessIds,
        readProcessMetadata: _readMetadata,
        resolveMemoryBaseCandidate: _resolveBaseCandidate,
        detectGame: _detectCurrentGame,
        gameIdentityLogDataSource: _gameIdentityLogDataSource,
      ).create();

  /// Uses the injected discovery seam or the Windows process adapter.
  List<int> _findRpcs3ProcessIds() =>
      _discoverProcessIds?.call() ??
      WindowsProcessDiscoveryDataSource().findRpcs3ProcessIds();

  /// Uses the injected metadata seam or the Windows metadata adapter.
  Rpcs3ProcessMetadata _readMetadata(int processId) =>
      _readProcessMetadata?.call(processId) ??
      WindowsProcessMetadataDataSource().read(processId);

  /// Resolves the current session base through its injected or native adapter.
  Rpcs3MemoryBaseCandidate? _resolveBaseCandidate(
    Rpcs3ProcessMetadata processMetadata,
  ) =>
      _resolveMemoryBaseCandidate?.call(processMetadata) ??
      Rpcs3MemoryBaseResolverDataSource().resolveCandidate(processMetadata);

  /// Uses injected detection behavior or the configured RPCS3 workflow.
  GameDetectionResult _detectCurrentGame(
    int processId,
    Rpcs3ProcessMetadata processMetadata,
  ) =>
      _detectGame?.call(processId, processMetadata) ??
      _detectGameFromLog(processId, processMetadata);

  /// Builds the game-detection workflow from current process log evidence.
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
}
