import 'dart:convert';
import 'dart:io';

import 'package:ludava/features/game_memory/domain/entities/rpcs3_memory_base_candidate.entity.dart';
import 'package:ludava/features/game_memory/domain/entities/rpcs3_process_metadata.entity.dart';

/// Finds a recent guest memory base in log files beside the selected RPCS3 app.
class Rpcs3MemoryBaseResolverDataSource {
  /// Creates a resolver with optional file system seams for deterministic tests.
  Rpcs3MemoryBaseResolverDataSource({
    DateTime Function(String path)? lastModifiedUtc,
    String Function(String path)? readAsString,
    bool Function(String path)? fileExists,
  }) : _lastModifiedUtc = lastModifiedUtc ?? _fileLastModifiedUtc,
       _readAsString = readAsString ?? _fileReadAsString,
       _fileExists = fileExists ?? _fileExistsOnDisk;

  static const int _maxNativeAddress = 0x7fffffffffffffff;
  static final RegExp _memoryBaseLine = RegExp(
    r'\bvm::g_base_addr\s*=\s*(?:0[xX])?([0-9a-fA-F]{1,16})\b',
  );

  final DateTime Function(String path) _lastModifiedUtc;
  final String Function(String path) _readAsString;
  final bool Function(String path) _fileExists;

  /// Returns the first fresh log candidate tied by path to [processMetadata].
  ///
  /// Candidate logs are searched in the executable directory's `log` folder,
  /// then beside the executable. A log older than process start is ignored.
  /// The returned value must still be confirmed by the user.
  Rpcs3MemoryBaseCandidate? resolveCandidate(
    Rpcs3ProcessMetadata processMetadata,
  ) {
    final executableDirectory =
        File(processMetadata.executablePath).parent.path;
    final logPaths = [
      '$executableDirectory${Platform.pathSeparator}log${Platform.pathSeparator}RPCS3.log',
      '$executableDirectory${Platform.pathSeparator}RPCS3.log',
    ];

    for (final logPath in logPaths) {
      if (!_fileExists(logPath)) continue;
      try {
        if (_lastModifiedUtc(logPath).isBefore(processMetadata.startedAtUtc)) {
          continue;
        }
        final bases = _parseMemoryBases(_readAsString(logPath));
        if (bases == null) continue;
        if (bases.length != 1) return null;
        return Rpcs3MemoryBaseCandidate(
          memoryBase: bases.single,
          logPath: logPath,
        );
      } on FileSystemException {
        // A log can disappear or become unreadable between the file checks.
        continue;
      }
    }
    return null;
  }

  static Set<int>? _parseMemoryBases(String logContents) {
    var foundBaseLine = false;
    final bases = <int>{};
    for (final line in const LineSplitter().convert(logContents)) {
      if (!line.contains('vm::g_base_addr')) continue;
      foundBaseLine = true;
      final match = _memoryBaseLine.firstMatch(line);
      if (match == null) return {};
      final base = int.tryParse(match.group(1)!, radix: 16);
      if (base == null || base <= 0 || base > _maxNativeAddress) return {};
      bases.add(base);
    }
    return foundBaseLine ? bases : null;
  }

  static DateTime _fileLastModifiedUtc(String path) =>
      File(path).lastModifiedSync().toUtc();

  static String _fileReadAsString(String path) => File(path).readAsStringSync();

  static bool _fileExistsOnDisk(String path) => File(path).existsSync();
}
