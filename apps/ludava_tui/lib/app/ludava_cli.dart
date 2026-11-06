import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/app/trainer_command_runner.dart';

/// Composes the SDK runtime and TUI command runner for an executable entry point.
class LudavaCli {
  /// Creates the CLI with an optional runtime and terminal test seam.
  LudavaCli({
    LudavaSdk? sdk,
    bool? hasTerminal,
    Future<void> Function(TrainerSessionController sessionController)?
    runNocterm,
    TrainerCommandRunner? commandRunner,
  }) : _commandRunner =
           commandRunner ??
           TrainerCommandRunner(
             sdk: sdk,
             hasTerminal: hasTerminal,
             runNocterm: runNocterm,
           );

  final TrainerCommandRunner _commandRunner;

  /// Runs one CLI command and returns its process exit code.
  int run(
    List<String> arguments, {
    StringSink? output,
    StringSink? errorOutput,
  }) => _commandRunner.run(arguments, output: output, errorOutput: errorOutput);

  /// Runs diagnostics or launches Nocterm and awaits runtime cleanup.
  Future<int> runAsync(
    List<String> arguments, {
    StringSink? output,
    StringSink? errorOutput,
  }) => _commandRunner.runAsync(
    arguments,
    output: output,
    errorOutput: errorOutput,
  );
}
