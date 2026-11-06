import 'dart:async';
import 'dart:io';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/features/diagnostics/presentation/cli/diagnostic_argument_parser.dart';
import 'package:ludava_tui/features/diagnostics/presentation/cli/diagnostic_arguments.dart';
import 'package:ludava_tui/features/diagnostics/presentation/cli/game_memory_output.dart';
import 'package:ludava_tui/features/trainer/presentation/nocterm/trainer_session_component.dart';
import 'package:ludava_tui/shared/terminal/trainer_terminal_backend.dart';
import 'package:nocterm/nocterm.dart' show StdioBackend, runApp, shutdownApp;

/// Runs diagnostic commands and starts the Nocterm trainer.
class TrainerCommandRunner {
  /// Creates a runner that owns [sdk] for this command lifecycle.
  TrainerCommandRunner({
    LudavaSdk? sdk,
    bool? hasTerminal,
    Future<void> Function(TrainerSessionController sessionController)?
    runNocterm,
  }) : _sdk = sdk ?? LudavaSdk.create(),
       _hasTerminal = hasTerminal,
       _runNocterm = runNocterm;

  final LudavaSdk _sdk;
  final bool? _hasTerminal;
  final Future<void> Function(TrainerSessionController sessionController)?
  _runNocterm;

  /// Runs one diagnostic command; use [runAsync] to await runtime cleanup.
  int run(
    List<String> arguments, {
    StringSink? output,
    StringSink? errorOutput,
  }) {
    try {
      return _runDiagnostic(
        arguments,
        output: output,
        errorOutput: errorOutput,
      );
    } finally {
      unawaited(_sdk.dispose());
    }
  }

  /// Runs diagnostics or starts Nocterm, then awaits SDK resource cleanup.
  Future<int> runAsync(
    List<String> arguments, {
    StringSink? output,
    StringSink? errorOutput,
  }) async {
    if (arguments.isNotEmpty) {
      try {
        return _runDiagnostic(
          arguments,
          output: output,
          errorOutput: errorOutput,
        );
      } finally {
        await _sdk.dispose();
      }
    }
    try {
      final stderrSink = errorOutput ?? stderr;
      if (!(_hasTerminal ?? (stdin.hasTerminal && stdout.hasTerminal))) {
        stderrSink.writeln('Interactive mode requires a terminal.');
        return 2;
      }
      await (_runNocterm ?? _runNoctermTrainer)(_sdk.session);
      return 0;
    } catch (error) {
      (errorOutput ?? stderr).writeln('Nocterm could not start: $error');
      return 1;
    } finally {
      await _sdk.dispose();
    }
  }

  /// Parses a supported command, delegates operation, and formats its result.
  int _runDiagnostic(
    List<String> arguments, {
    StringSink? output,
    StringSink? errorOutput,
  }) {
    final stdoutSink = output ?? stdout;
    final stderrSink = errorOutput ?? stderr;
    if (arguments.isEmpty) {
      stderrSink.writeln('Interactive mode is started with runAsync.');
      return 2;
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

    final result = _sdk.diagnostics.execute(
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

  /// Runs Nocterm with the runtime's authoritative session capability.
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
}
