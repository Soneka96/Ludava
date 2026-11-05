import 'dart:io';

import 'package:ludava/features/game_memory/data/datasources/windows_memory_api.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_memory_exception.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_process_memory.datasource.dart';
import 'package:ludava/features/game_memory/data/repositories/game_memory.repository.dart';
import 'package:ludava/features/game_memory/domain/entities/game_read_result.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/game_write_result.entity.dart';
import 'package:ludava/features/game_memory/domain/profiles/game_profile_catalog.dart';
import 'package:ludava/features/game_memory/domain/usecases/params/read_game_field.params.dart';
import 'package:ludava/features/game_memory/domain/usecases/params/write_game_field.params.dart';
import 'package:ludava/features/game_memory/domain/usecases/read_game_field.usecase.dart';
import 'package:ludava/features/game_memory/domain/usecases/write_game_field.usecase.dart';
import 'package:ludava/features/game_memory/presentation/cli/diagnostic_argument_parser.dart';
import 'package:ludava/features/game_memory/presentation/cli/diagnostic_arguments.dart';
import 'package:ludava/features/game_memory/presentation/cli/game_memory_output.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Composes the command-line trainer and its Windows data boundary.
class LudavaCli {
  /// Creates the CLI with optional platform and native API test seams.
  LudavaCli({
    WindowsMemoryApi? api,
    bool? isWindows,
    int? pointerSize,
  })  : _api = api,
        _isWindows = isWindows,
        _pointerSize = pointerSize;

  final WindowsMemoryApi? _api;
  final bool? _isWindows;
  final int? _pointerSize;

  /// Runs one command and returns its process exit code.
  int run(
    List<String> arguments, {
    StringSink? output,
    StringSink? errorOutput,
  }) {
    final stdoutSink = output ?? stdout;
    final stderrSink = errorOutput ?? stderr;
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
        stdoutSink.writeln(GameMemoryOutput.writeResult(profile, result));
        if (!result.succeeded) exitCode = 1;
      } else {
        final result = ReadGameFieldUseCase(repository).execute(
          ReadGameFieldParams(
            profile: profile,
            fieldId: options.fieldId,
            memoryBase: options.memoryBase,
          ),
        );
        stdoutSink.writeln(GameMemoryOutput.readResult(profile, result));
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
}
