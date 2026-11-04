import 'dart:io';

import 'package:ludava/src/bolt_service.dart';
import 'package:ludava/src/game_profile.dart';
import 'package:ludava/src/process_memory.dart';

const _maxAddress = 0x7fffffffffffffff;

class DiagnosticArguments {
  const DiagnosticArguments(
      {required this.processId, required this.memoryBase});

  final int processId;
  final int memoryBase;
}

DiagnosticArguments parseDiagnosticArguments(List<String> arguments) {
  int? processId;
  int? memoryBase;
  for (var index = 0; index < arguments.length; index += 2) {
    final option = arguments[index];
    if (index + 1 >= arguments.length ||
        arguments[index + 1].startsWith('--')) {
      throw FormatException('$option requires a value.');
    }
    final value = arguments[index + 1];
    switch (option) {
      case '--pid':
        if (processId != null || !RegExp(r'^\d+$').hasMatch(value)) {
          throw const FormatException(
              '--pid requires one positive decimal process ID.');
        }
        processId = int.tryParse(value);
        if (processId == null || processId <= 0 || processId > 0xffffffff) {
          throw const FormatException(
              '--pid must be between 1 and 4294967295.');
        }
      case '--memory-base':
        if (memoryBase != null ||
            !RegExp(r'^0[xX][0-9a-fA-F]+$').hasMatch(value)) {
          throw const FormatException(
            '--memory-base requires one hexadecimal value prefixed with 0x.',
          );
        }
        memoryBase = int.tryParse(value.substring(2), radix: 16);
        if (memoryBase == null || memoryBase < 0 || memoryBase > _maxAddress) {
          throw const FormatException(
              '--memory-base is outside the supported address range.');
        }
      default:
        throw FormatException('Unknown option: $option');
    }
  }
  if (processId == null || memoryBase == null) {
    throw const FormatException('Both --pid and --memory-base are required.');
  }
  return DiagnosticArguments(processId: processId, memoryBase: memoryBase);
}

String formatDiagnosticResult(BoltReadResult result) {
  final lines = [
    'RC2 bolt diagnostic (EXPERIMENTAL; active build is not verified)',
  ];
  switch (result.status) {
    case BoltReadStatus.success:
      if (result.boltCount == null) {
        lines.add('Status: invalid diagnostic result');
      } else {
        lines.add('Status: read complete');
        lines.add('Bolt count: ${result.boltCount}');
      }
    case BoltReadStatus.unsupportedProfile:
      lines.add('Status: unsupported profile');
    case BoltReadStatus.invalidMapping:
      lines.add('Status: invalid memory mapping');
    case BoltReadStatus.readFailed:
      lines.add('Status: native memory read failed');
    case BoltReadStatus.incompleteRead:
      lines.add('Status: incomplete memory read');
    case BoltReadStatus.invalidReadResult:
      lines.add('Status: invalid memory read result');
  }
  if (result.errorCode != null) lines.add('Windows error: ${result.errorCode}');
  return lines.join('\n');
}

const usage =
    '''Usage: dart run bin/rc2_bolts.dart --pid <decimal PID> --memory-base <0xHEX>

Reads exactly the experimental RC2 Collection bolt field. The supplied memory base
must come from the intended RPCS3 session. PID and memory base do not verify game
identity or build compatibility. This diagnostic is read-only.''';

int runDiagnostic(
  List<String> arguments, {
  WindowsProcessMemory Function(int processId)? openProcess,
  StringSink? output,
  StringSink? errorOutput,
}) {
  final stdoutSink = output ?? stdout;
  final stderrSink = errorOutput ?? stderr;
  if (arguments.length == 1 && arguments.single == '--help') {
    stdoutSink.writeln(usage);
    return 0;
  }

  late final DiagnosticArguments options;
  try {
    options = parseDiagnosticArguments(arguments);
  } on FormatException catch (error) {
    stderrSink.writeln(error.message);
    stderrSink.writeln(usage);
    return 2;
  }

  WindowsProcessMemory? processMemory;
  var resultCode = 0;
  try {
    processMemory =
        (openProcess ?? WindowsProcessMemory.open)(options.processId);
    final result = BoltService(processMemory).readBolts(
      profile: rc2CollectionExperimentalProfile,
      memoryBase: options.memoryBase,
    );
    stdoutSink.writeln(formatDiagnosticResult(result));
    if (!result.succeeded) resultCode = 1;
  } on ProcessMemoryOpenException catch (error) {
    stderrSink.writeln(error);
    resultCode = 1;
  } on ProcessMemoryException catch (error) {
    stderrSink.writeln(error);
    resultCode = 1;
  } on UnsupportedError catch (error) {
    stderrSink.writeln(error);
    resultCode = 1;
  } finally {
    try {
      processMemory?.close();
    } on ProcessMemoryException catch (error) {
      stderrSink.writeln(error);
      resultCode = 1;
    }
  }
  return resultCode;
}

void main(List<String> arguments) {
  exitCode = runDiagnostic(arguments);
}
