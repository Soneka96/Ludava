import 'dart:io';

import 'package:ludava/features/game_memory/data/datasources/rpcs3_game_identity_log.datasource.dart';
import 'package:ludava/features/game_memory/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:test/test.dart';

void main() {
  group('Method readCandidates() behaves correctly', () {
    test('Method readCandidates() parses distinct log identity values', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
        contents: {
          paths.logDirectory: '''
0:00:01 SYS: Path: D:/Games/BCUS98282/PS3_GAME/USRDIR/EBOOT.BIN
0:00:02 SYS: Title: Ratchet & Clank Collection
0:00:02 SYS: Serial: BCUS98282
0:00:03 SYS: Title: Ratchet & Clank Collection
0:00:03 SYS: Serial: BCUS98282
''',
        },
      );

      final snapshots = source.readCandidates(_LogTestData.metadata());

      expect(snapshots, hasLength(1));
      expect(snapshots.single.titles, ['Ratchet & Clank Collection']);
      expect(snapshots.single.serials, ['BCUS98282']);
      expect(snapshots.single.bootPaths, [
        'D:/Games/BCUS98282/PS3_GAME/USRDIR/EBOOT.BIN',
      ]);
      expect(snapshots.single.logPath, paths.logDirectory);
      expect(snapshots.single.hasConflictingIdentity, isFalse);
    });

    test(
      'Method readCandidates() ignores logs older than the selected process',
      () {
        final paths = _LogTestData.paths();
        final source = _LogTestData.source(
          modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 10, 59)},
          contents: {paths.logDirectory: 'SYS: Serial: BCUS98282'},
        );

        expect(source.readCandidates(_LogTestData.metadata()), isEmpty);
      },
    );

    test('Method readCandidates() accepts a log modified at process start', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 11)},
        contents: {paths.logDirectory: 'SYS: Serial: BCUS98282'},
      );

      expect(source.readCandidates(_LogTestData.metadata()).single.serials, [
        'BCUS98282',
      ]);
    });

    test(
      'Method readCandidates() checks the second path after a stale log',
      () {
        final paths = _LogTestData.paths();
        final source = _LogTestData.source(
          modifiedAt: {
            paths.logDirectory: DateTime.utc(2026, 11, 5, 10, 59),
            paths.executableDirectory: DateTime.utc(2026, 11, 5, 12),
          },
          contents: {
            paths.logDirectory: 'SYS: Serial: STALE001',
            paths.executableDirectory: 'SYS: Serial: BCUS98282',
          },
        );

        final snapshots = source.readCandidates(_LogTestData.metadata());

        expect(snapshots, hasLength(1));
        expect(snapshots.single.logPath, paths.executableDirectory);
        expect(snapshots.single.serials, ['BCUS98282']);
      },
    );

    test('Method readCandidates() preserves conflicting log history', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
        contents: {
          paths.logDirectory: '''
SYS: Title: First title
SYS: Serial: FIRST001
SYS: Title: Second title
SYS: Serial: SECOND002
''',
        },
      );

      final snapshot = source.readCandidates(_LogTestData.metadata()).single;

      expect(snapshot.titles, ['First title', 'Second title']);
      expect(snapshot.serials, ['FIRST001', 'SECOND002']);
      expect(snapshot.hasConflictingIdentity, isTrue);
    });

    test(
      'Method readCandidates() preserves value order and ignores blanks',
      () {
        final paths = _LogTestData.paths();
        final blankTitle = 'SYS: Title: ${String.fromCharCode(32)}';
        final source = _LogTestData.source(
          modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
          contents: {
            paths.logDirectory: [
              'SYS: Title: First title',
              blankTitle,
              'SYS: Title: Second title',
              'SYS: Serial: FIRST001',
              'SYS: Serial: SECOND002',
            ].join('\n'),
          },
        );

        final snapshot = source.readCandidates(_LogTestData.metadata()).single;

        expect(snapshot.titles, ['First title', 'Second title']);
        expect(snapshot.serials, ['FIRST001', 'SECOND002']);
      },
    );

    test('Method readCandidates() returns both fresh candidate log paths', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {
          paths.logDirectory: DateTime.utc(2026, 11, 5, 12),
          paths.executableDirectory: DateTime.utc(2026, 11, 5, 12),
        },
        contents: {
          paths.logDirectory: 'SYS: Serial: BCUS98282',
          paths.executableDirectory: 'SYS: Serial: NPUA80644',
        },
      );

      final snapshots = source.readCandidates(_LogTestData.metadata());

      expect(snapshots, hasLength(2));
      expect(snapshots.map((snapshot) => snapshot.logPath), [
        paths.logDirectory,
        paths.executableDirectory,
      ]);
      expect(snapshots.map((snapshot) => snapshot.serials.single), [
        'BCUS98282',
        'NPUA80644',
      ]);
      expect(() => snapshots.clear(), throwsUnsupportedError);
    });

    test(
      'Method readCandidates() returns an empty list when logs are absent',
      () {
        final source = _LogTestData.source();

        expect(source.readCandidates(_LogTestData.metadata()), isEmpty);
      },
    );

    test('Method readCandidates() preserves an empty identity snapshot', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
        contents: {paths.logDirectory: 'SYS: No game identity fields'},
      );

      final snapshot = source.readCandidates(_LogTestData.metadata()).single;

      expect(snapshot.titles, isEmpty);
      expect(snapshot.serials, isEmpty);
      expect(snapshot.bootPaths, isEmpty);
    });

    test(
      'Method readCandidates() propagates errors reading a candidate log',
      () {
        final paths = _LogTestData.paths();
        final source = _LogTestData.source(
          modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
          contents: {paths.logDirectory: ''},
          readAsString: (_) => throw FileSystemException('access denied'),
        );

        expect(
          () => source.readCandidates(_LogTestData.metadata()),
          throwsA(isA<FileSystemException>()),
        );
      },
    );

    test(
      'Method readCandidates() propagates errors checking log freshness',
      () {
        final paths = _LogTestData.paths();
        final source = Rpcs3GameIdentityLogDataSource(
          fileExists: (path) => path == paths.logDirectory,
          lastModifiedUtc: (_) => throw FileSystemException('access denied'),
          readAsString: (_) => 'SYS: Serial: BCUS98282',
        );

        expect(
          () => source.readCandidates(_LogTestData.metadata()),
          throwsA(isA<FileSystemException>()),
        );
      },
    );
  });
}

abstract final class _LogTestData {
  static final DateTime _processStartedAt = DateTime.utc(2026, 11, 5, 11);

  static Rpcs3ProcessMetadata metadata() => Rpcs3ProcessMetadata(
    executablePath: r'C:\RPCS3\rpcs3.exe',
    startedAtUtc: _processStartedAt,
  );

  static _LogPaths paths() {
    final separator = Platform.pathSeparator;
    return _LogPaths(
      logDirectory: 'C:\\RPCS3${separator}log${separator}RPCS3.log',
      executableDirectory: 'C:\\RPCS3${separator}RPCS3.log',
    );
  }

  static Rpcs3GameIdentityLogDataSource source({
    Map<String, DateTime> modifiedAt = const {},
    Map<String, String> contents = const {},
    String Function(String path)? readAsString,
  }) => Rpcs3GameIdentityLogDataSource(
    fileExists: contents.containsKey,
    lastModifiedUtc: (path) => modifiedAt[path]!,
    readAsString: readAsString ?? (path) => contents[path]!,
  );
}

class _LogPaths {
  final String logDirectory;
  final String executableDirectory;

  const _LogPaths({
    required this.logDirectory,
    required this.executableDirectory,
  });
}
