import 'package:ludava/features/game_detection/data/datasources/rpcs3_game_identity_log.datasource.dart';
import 'package:ludava/features/game_detection/domain/entities/game_detection_result.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:ludava/app/trainer_command_runner.dart';
import 'package:ludava/features/trainer/presentation/cli/interactive_trainer_cli.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_memory_api.dart';

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
           );

  final TrainerCommandRunner _commandRunner;

  /// Runs one CLI command and returns its process exit code.
  int run(
    List<String> arguments, {
    StringSink? output,
    StringSink? errorOutput,
  }) => _commandRunner.run(arguments, output: output, errorOutput: errorOutput);
}
