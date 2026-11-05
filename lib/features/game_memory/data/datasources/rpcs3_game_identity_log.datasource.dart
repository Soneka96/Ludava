import 'dart:convert';
import 'dart:io';

import 'package:ludava/features/game_memory/data/models/rpcs3_game_identity_log_event.model.dart';
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

  static final RegExp _titleLine = RegExp(r'\bSYS:\s*Title:\s*(.+?)\s*$');
  static final RegExp _serialLine = RegExp(r'\bSYS:\s*Serial:\s*(.+?)\s*$');
  static final RegExp _pathLine = RegExp(r'\bSYS:\s*Path:\s*(.+?)\s*$');
  static final RegExp _elfPathLine = RegExp(r'\bSYS:\s*Elf path:\s*(.+?)\s*$');
  static final RegExp _ppuHashLine = RegExp(
    r'\bPPU executable hash:\s*(PPU-[0-9a-fA-F]{40})\b',
  );
  static final RegExp _processFinishedLine = RegExp(
    r'\bsys_process:\s*Process finished(?:\s*->\s*(.+?))?\s*$',
    caseSensitive: false,
  );

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
      final events = _readEvents(logContents);
      snapshots.add(
        Rpcs3GameIdentityLogSnapshot(
          titles: _readValues(logContents, _titleLine),
          serials: _readValues(logContents, _serialLine),
          bootPaths: _readValues(logContents, _pathLine),
          events: events,
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

  List<Rpcs3GameIdentityLogEvent> _readEvents(String contents) {
    final events = <Rpcs3GameIdentityLogEvent>[];
    String? title;
    String? titleId;
    String? bootPath;
    String? executable;
    int? currentEventIndex;

    for (final line in const LineSplitter().convert(contents)) {
      final finished = _processFinishedLine.firstMatch(line);
      if (finished != null) {
        events.add(
          Rpcs3GameIdentityLogEvent(
            processFinished: true,
            nextExecutable: _fileName(finished.group(1)?.trim()),
          ),
        );
        title = null;
        titleId = null;
        bootPath = null;
        executable = null;
        currentEventIndex = null;
        continue;
      }

      final path = _pathLine.firstMatch(line)?.group(1)?.trim();
      if (path != null && path.isNotEmpty) {
        title = null;
        titleId = null;
        bootPath = path;
        executable = _fileName(path);
        currentEventIndex = events.length;
        events.add(
          Rpcs3GameIdentityLogEvent(bootPath: bootPath, executable: executable),
        );
        continue;
      }

      final elfPath = _elfPathLine.firstMatch(line)?.group(1)?.trim();
      if (elfPath != null && elfPath.isNotEmpty) {
        executable = _fileName(elfPath);
        final eventIndex = currentEventIndex;
        if (eventIndex != null) {
          events[eventIndex] = Rpcs3GameIdentityLogEvent(
            title: title,
            titleId: titleId,
            bootPath: bootPath,
            executable: executable,
          );
        } else {
          currentEventIndex = events.length;
          events.add(Rpcs3GameIdentityLogEvent(executable: executable));
        }
        continue;
      }

      final titleValue = _titleLine.firstMatch(line)?.group(1)?.trim();
      if (titleValue != null && titleValue.isNotEmpty) {
        title = titleValue;
        final eventIndex = currentEventIndex;
        if (eventIndex != null) {
          events[eventIndex] = Rpcs3GameIdentityLogEvent(
            title: title,
            titleId: titleId,
            bootPath: bootPath,
            executable: executable,
          );
        }
        continue;
      }

      final serialValue = _serialLine.firstMatch(line)?.group(1)?.trim();
      if (serialValue != null && serialValue.isNotEmpty) {
        titleId = serialValue;
        final eventIndex = currentEventIndex;
        if (eventIndex != null) {
          events[eventIndex] = Rpcs3GameIdentityLogEvent(
            title: title,
            titleId: titleId,
            bootPath: bootPath,
            executable: executable,
          );
        }
        continue;
      }

      final hash = _ppuHashLine.firstMatch(line)?.group(1);
      if (hash != null) {
        final eventIndex = currentEventIndex;
        final event = Rpcs3GameIdentityLogEvent(
          title: title,
          titleId: titleId,
          bootPath: bootPath,
          executable: executable,
          executableHash: hash,
        );
        if (eventIndex == null) {
          currentEventIndex = events.length;
          events.add(event);
        } else {
          events[eventIndex] = event;
        }
      }
    }
    return List.unmodifiable(events);
  }

  String? _fileName(String? path) {
    if (path == null || path.isEmpty) return null;
    return path.replaceAll('\\', '/').split('/').last;
  }

  static DateTime _fileLastModifiedUtc(String path) =>
      File(path).lastModifiedSync().toUtc();

  static bool _fileExistsOnDisk(String path) => File(path).existsSync();
}
