import 'package:ludava/app/trainer_command_runner.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava/features/trainer/presentation/cli/interactive_trainer_cli.dart';

/// Composes the trainer command runner for the executable entry point.
class LudavaCli {
  /// Creates the application composition root with optional test seams.
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
    bool? hasTerminal,
    Future<void> Function(TrainerSessionController sessionController)?
    runNocterm,
    TrainerCommandRunner? commandRunner,
  }) : _commandRunner =
           commandRunner ??
           TrainerCommandRunner(
             api: api,
             isWindows: isWindows,
             pointerSize: pointerSize,
             interactiveCli: interactiveCli,
             discoverProcessIds: discoverProcessIds,
             readProcessMetadata: readProcessMetadata,
             resolveMemoryBaseCandidate: resolveMemoryBaseCandidate,
             detectGame: detectGame,
             gameIdentityLogDataSource: gameIdentityLogDataSource,
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

  /// Runs diagnostic commands or launches Nocterm for the default invocation.
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
