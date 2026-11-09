import 'dart:io';

import 'package:ludava_sdk/features/game_detection/data/datasources/rpcs3_game_identity_log.datasource.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:test/test.dart';

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

void main() {
  group('Method readCandidates() behaves correctly', () {
    test('Method readCandidates() parses distinct log identity values', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
        contents: {
          paths.logDirectory: '''
0:00:00 VFS: Path: D:/RPCS3/ignored-config-path
0:00:01 SYS: Path: D:/Games/TEST00001/PS3_GAME/USRDIR/EBOOT.BIN
0:00:02 SYS: Title: Synthetic Collection
0:00:02 SYS: Serial: TEST00001
0:00:03 SYS: Title: Synthetic Collection
0:00:03 SYS: Serial: TEST00001
''',
        },
      );

      final snapshots = source.readCandidates(_LogTestData.metadata());

      expect(snapshots, hasLength(1));
      expect(snapshots.single.titles, ['Synthetic Collection']);
      expect(snapshots.single.serials, ['TEST00001']);
      expect(snapshots.single.bootPaths, [
        'D:/Games/TEST00001/PS3_GAME/USRDIR/EBOOT.BIN',
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
          contents: {paths.logDirectory: 'SYS: Serial: TEST00001'},
        );

        expect(source.readCandidates(_LogTestData.metadata()), isEmpty);
      },
    );

    test('Method readCandidates() accepts a log modified at process start', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 11)},
        contents: {paths.logDirectory: 'SYS: Serial: TEST00001'},
      );

      expect(source.readCandidates(_LogTestData.metadata()).single.serials, [
        'TEST00001',
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
            paths.executableDirectory: 'SYS: Serial: TEST00001',
          },
        );

        final snapshots = source.readCandidates(_LogTestData.metadata());

        expect(snapshots, hasLength(1));
        expect(snapshots.single.logPath, paths.executableDirectory);
        expect(snapshots.single.serials, ['TEST00001']);
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
          paths.logDirectory: 'SYS: Serial: TEST00001',
          paths.executableDirectory: 'SYS: Serial: TEST00002',
        },
      );

      final snapshots = source.readCandidates(_LogTestData.metadata());

      expect(snapshots, hasLength(2));
      expect(snapshots.map((snapshot) => snapshot.logPath), [
        paths.logDirectory,
        paths.executableDirectory,
      ]);
      expect(snapshots.map((snapshot) => snapshot.serials.single), [
        'TEST00001',
        'TEST00002',
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
          readAsString: (_) => 'SYS: Serial: TEST00001',
        );

        expect(
          () => source.readCandidates(_LogTestData.metadata()),
          throwsA(isA<FileSystemException>()),
        );
      },
    );
  });

  group('Method readCandidates() parses lifecycle events', () {
    test('Method readCandidates() preserves PPU loads and stop order', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
        contents: {
          paths.logDirectory: '''
0:00:01 SYS: Path: D:/Games/SyntheticCollection.iso
0:00:02 SYS: Title: Synthetic Collection
0:00:02 SYS: Serial: TEST00001
0:00:03 SYS: Elf path: D:/Games/USRDIR/EBOOT.BIN
0:00:04 ppu_loader: PPU executable hash: PPU-cccccccccccccccccccccccccccccccccccccccc
0:02:17 sys_process: Process finished -> /dev_bdvd/PS3_GAME/USRDIR/ALPHA.self
0:02:18 SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/ALPHA.self
0:02:18 SYS: Title: Synthetic Collection
0:02:18 SYS: Serial: TEST00001
0:02:18 ppu_loader: PPU executable hash: PPU-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0:03:00 sys_process: Process finished
''',
        },
      );

      final snapshot = source.readCandidates(_LogTestData.metadata()).single;

      expect(snapshot.events, hasLength(4));
      expect(snapshot.events[0].executable, 'EBOOT.BIN');
      expect(
        snapshot.events[0].executableHash,
        'PPU-cccccccccccccccccccccccccccccccccccccccc',
      );
      expect(snapshot.events[1].processFinished, isTrue);
      expect(snapshot.events[1].nextExecutable, 'ALPHA.self');
      expect(snapshot.events[2].executable, 'ALPHA.self');
      expect(
        snapshot.events[2].executableHash,
        'PPU-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      );
      expect(snapshot.events[2].titleId, 'TEST00001');
      expect(snapshot.events[3].processFinished, isTrue);
      expect(snapshot.events[3].executableHash, isNull);
      expect(snapshot.latestEvent?.processFinished, isTrue);
    });

    test('Method readCandidates() preserves an unknown PPU hash', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
        contents: {
          paths.logDirectory: '''
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/Unknown.ppu.self
SYS: Serial: TEST00001
ppu_loader: PPU executable hash: PPU-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
''',
        },
      );

      final snapshot = source.readCandidates(_LogTestData.metadata()).single;

      expect(snapshot.events, hasLength(1));
      expect(snapshot.events.single.executable, 'Unknown.ppu.self');
      expect(
        snapshot.events.single.executableHash,
        'PPU-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
      );
    });

    test('Method readCandidates() parses an ELF path without a boot path', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
        contents: {
          paths.logDirectory: '''
SYS: Elf path: D:/Games/USRDIR/EBOOT.BIN
ppu_loader: PPU executable hash: PPU-cccccccccccccccccccccccccccccccccccccccc
''',
        },
      );

      final event =
          source.readCandidates(_LogTestData.metadata()).single.events.single;

      expect(event.executable, 'EBOOT.BIN');
      expect(event.bootPath, isNull);
      expect(
        event.executableHash,
        'PPU-cccccccccccccccccccccccccccccccccccccccc',
      );
    });

    test('Method readCandidates() clears identity after process finish', () {
      final paths = _LogTestData.paths();
      final source = _LogTestData.source(
        modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
        contents: {
          paths.logDirectory: '''
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/BETA.self
SYS: Title: Synthetic Collection
SYS: Serial: TEST00001
ppu_loader: PPU executable hash: PPU-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
sys_process: Process finished
ppu_loader: PPU executable hash: PPU-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
''',
        },
      );

      final events =
          source.readCandidates(_LogTestData.metadata()).single.events;

      expect(events, hasLength(3));
      expect(
        events[2].executableHash,
        'PPU-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
      );
      expect(events[2].title, isNull);
      expect(events[2].titleId, isNull);
      expect(events[2].bootPath, isNull);
      expect(events[2].executable, isNull);
    });

    test(
      'Method readCandidates() invalidates the prior hash during a new boot',
      () {
        final paths = _LogTestData.paths();
        final source = _LogTestData.source(
          modifiedAt: {paths.logDirectory: DateTime.utc(2026, 11, 5, 12)},
          contents: {
            paths.logDirectory: '''
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/BETA.self
SYS: Title: Synthetic Collection
SYS: Serial: TEST00001
ppu_loader: PPU executable hash: PPU-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
SYS: Path: /dev_bdvd/PS3_GAME/USRDIR/GAMMA.self
SYS: Title: Synthetic Collection
SYS: Serial: TEST00001
''',
          },
        );

        final snapshot = source.readCandidates(_LogTestData.metadata()).single;

        expect(snapshot.events, hasLength(2));
        expect(
          snapshot.events.first.executableHash,
          'PPU-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        );
        expect(snapshot.latestEvent?.executable, 'GAMMA.self');
        expect(snapshot.latestEvent?.executableHash, isNull);
        expect(snapshot.latestEvent?.titleId, 'TEST00001');
      },
    );
  });

  group('Method readCandidates() reports file-system errors', () {
    test('Method readCandidates() propagates candidate-existence errors', () {
      final source = Rpcs3GameIdentityLogDataSource(
        fileExists: (_) => throw FileSystemException('access denied'),
        lastModifiedUtc: (_) => DateTime.utc(2026, 11, 5, 12),
        readAsString: (_) => 'SYS: Serial: TEST00001',
      );

      expect(
        () => source.readCandidates(_LogTestData.metadata()),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
