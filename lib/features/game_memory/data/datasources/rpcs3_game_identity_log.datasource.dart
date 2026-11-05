import 'dart:convert';
import 'dart:io';

import 'package:ludava/features/game_memory/data/models/rpcs3_game_identity_log_snapshot.model.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_rpcs3_log.datasource.dart';
import 'package:ludava/features/game_memory/domain/entities/rpcs3_process_metadata.entity.dart';

/// Reads candidate title and boot-path observations from RPCS3 logs.
///
/// Log contents are historical observations, not proof of the active game.
class Rpcs3GameIdentityLogDataSource {
  /// Creates a reader with optional file system seams for deterministic tests.
  Rpcs3GameIdentityLogDataSource({
    DateTime Function(String path)? lastModifiedUtc,
    String Function(String path)? readAsString,
    bool Function(String path)? fileExists,
  }) : _lastModifiedUtc =
           lastModifiedUtc ??
           Rpcs3GameIdentityLogDataSource._fileLastModifiedUtc,
       _readAsString = readAsString ?? WindowsRpcs3LogDataSource().read,
       _fileExists =
           fileExists ?? Rpcs3GameIdentityLogDataSource._fileExistsOnDisk;

  static final RegExp _titleLine = RegExp(r'\bTitle:\s*(.+?)\s*$');
  static final RegExp _serialLine = RegExp(r'\bSerial:\s*(.+?)\s*$');
  static final RegExp _pathLine = RegExp(r'\bPath:\s*(.+?)\s*$');

  final DateTime Function(String path) _lastModifiedUtc;
  final String Function(String path) _readAsString;
  final bool Function(String path) _fileExists;

  /// Reads logs at candidate locations newer than [processMetadata]'s start.
  ///
  /// Every returned snapshot remains historical and must not be treated as a
  /// confirmed active-game identity.
  List<Rpcs3GameIdentityLogSnapshot> readCandidates(
    Rpcs3ProcessMetadata processMetadata,
  ) {
    final executableDirectory =
        File(processMetadata.executablePath).parent.path;
    final logPaths = [
      '$executableDirectory${Platform.pathSeparator}log${Platform.pathSeparator}RPCS3.log',
      '$executableDirectory${Platform.pathSeparator}RPCS3.log',
    ];
    final snapshots = <Rpcs3GameIdentityLogSnapshot>[];

    for (final logPath in logPaths) {
      if (!_fileExists(logPath)) continue;
      final modifiedAt = _lastModifiedUtc(logPath).toUtc();
      if (modifiedAt.isBefore(processMetadata.startedAtUtc)) continue;
      final logContents = _readAsString(logPath);
      snapshots.add(
        Rpcs3GameIdentityLogSnapshot(
          titles: _readValues(logContents, _titleLine),
          serials: _readValues(logContents, _serialLine),
          bootPaths: _readValues(logContents, _pathLine),
          logPath: logPath,
          logModifiedAtUtc: modifiedAt,
          processStartedAtUtc: processMetadata.startedAtUtc,
        ),
      );
    }
    return List.unmodifiable(snapshots);
  }

  List<String> _readValues(String contents, RegExp pattern) {
    final values = <String>{};
    for (final line in LineSplitter().convert(contents)) {
      final value = pattern.firstMatch(line)?.group(1)?.trim();
      if (value != null && value.isNotEmpty) values.add(value);
    }
    return values.toList(growable: false);
  }

  static DateTime _fileLastModifiedUtc(String path) =>
      File(path).lastModifiedSync().toUtc();

  static bool _fileExistsOnDisk(String path) => File(path).existsSync();
}
