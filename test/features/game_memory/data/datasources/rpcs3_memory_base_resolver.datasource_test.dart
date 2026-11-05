@TestOn('windows')
library;

import 'dart:io';

import 'package:ludava/features/game_memory/data/datasources/windows_memory_exception.dart';
import 'package:ludava/features/game_memory/data/datasources/rpcs3_memory_base_resolver.datasource.dart';
import 'package:ludava/features/game_memory/domain/entities/rpcs3_process_metadata.entity.dart';
import 'package:test/test.dart';

void main() {
  group('Method resolveCandidate() behaves correctly', () {
    test('Method resolveCandidate() parses a fresh RPCS3 base candidate', () {
      final logPath = r'C:\RPCS3\log\RPCS3.log';
      final resolver = _resolver({
        logPath: 'vm::g_base_addr = 0000000300000000 - 00000003ffffffff',
      });

      final candidate = resolver.resolveCandidate(_processMetadata());

      expect(candidate?.memoryBase, 0x300000000);
      expect(candidate?.logPath, logPath);
    });

    test('Method resolveCandidate() checks the log beside the executable', () {
      final logPath = r'C:\RPCS3\RPCS3.log';
      final resolver = _resolver({logPath: 'vm::g_base_addr = 0x300000000'});

      final candidate = resolver.resolveCandidate(_processMetadata());

      expect(candidate?.memoryBase, 0x300000000);
      expect(candidate?.logPath, logPath);
    });

    test('Method resolveCandidate() ignores logs older than the process', () {
      final logPath = r'C:\RPCS3\log\RPCS3.log';
      final resolver = _resolver({
        logPath: 'vm::g_base_addr = 0x300000000',
      }, modifiedAt: DateTime.utc(2026, 11, 5, 9, 59));

      expect(resolver.resolveCandidate(_processMetadata()), isNull);
    });

    test(
      'Method resolveCandidate() accepts a log timestamp equal to start',
      () {
        final logPath = r'C:\RPCS3\log\RPCS3.log';
        final resolver = _resolver({
          logPath: 'vm::g_base_addr = 0x300000000',
        }, modifiedAt: DateTime.utc(2026, 11, 5, 10));

        expect(
          resolver.resolveCandidate(_processMetadata())?.memoryBase,
          0x300000000,
        );
      },
    );

    test(
      'Method resolveCandidate() tries a fresh fallback after a stale log',
      () {
        final resolver = Rpcs3MemoryBaseResolverDataSource(
          fileExists:
              (path) =>
                  path == r'C:\RPCS3\log\RPCS3.log' ||
                  path == r'C:\RPCS3\RPCS3.log',
          lastModifiedUtc:
              (path) =>
                  path == r'C:\RPCS3\log\RPCS3.log'
                      ? DateTime.utc(2026, 11, 5, 9, 59)
                      : DateTime.utc(2026, 11, 5, 10, 1),
          readAsString: (_) => 'vm::g_base_addr = 0x300000000',
        );

        expect(
          resolver.resolveCandidate(_processMetadata())?.logPath,
          r'C:\RPCS3\RPCS3.log',
        );
      },
    );

    test('Method resolveCandidate() ignores missing or malformed bases', () {
      final resolver = _resolver({
        r'C:\RPCS3\log\RPCS3.log': 'vm::g_base_addr = unknown',
      });

      expect(resolver.resolveCandidate(_processMetadata()), isNull);
      expect(_resolver({}).resolveCandidate(_processMetadata()), isNull);
    });

    test('Method resolveCandidate() rejects conflicting bases in one log', () {
      final resolver = _resolver({
        r'C:\RPCS3\log\RPCS3.log':
            'vm::g_base_addr = 0x300000000\n'
            'vm::g_base_addr = 0x400000000',
      });

      expect(resolver.resolveCandidate(_processMetadata()), isNull);
    });

    test(
      'Method resolveCandidate() reports a log removed during detection',
      () {
        final logPath = r'C:\RPCS3\log\RPCS3.log';
        final resolver = Rpcs3MemoryBaseResolverDataSource(
          fileExists: (path) => path == logPath,
          lastModifiedUtc:
              (_) => throw const FileSystemException('disappeared'),
          readAsString: (_) => 'vm::g_base_addr = 0x300000000',
        );

        expect(
          () => resolver.resolveCandidate(_processMetadata()),
          throwsA(isA<FileSystemException>()),
        );
      },
    );

    test('Method resolveCandidate() reports unreadable fresh logs', () {
      final logPath = r'C:\RPCS3\log\RPCS3.log';
      final resolver = Rpcs3MemoryBaseResolverDataSource(
        fileExists: (path) => path == logPath,
        lastModifiedUtc: (_) => DateTime.utc(2026, 11, 5, 10, 1),
        readAsString:
            (_) =>
                throw const WindowsMemoryException(
                  operation: 'CreateFileW RPCS3 log',
                  errorCode: 32,
                ),
      );

      expect(
        () => resolver.resolveCandidate(_processMetadata()),
        throwsA(
          isA<WindowsMemoryException>()
              .having(
                (error) => error.operation,
                'operation',
                'CreateFileW RPCS3 log',
              )
              .having((error) => error.errorCode, 'errorCode', 32),
        ),
      );
    });

    test(
      'Method resolveCandidate() uses a readable fallback after a log error',
      () {
        final primaryLog = r'C:\RPCS3\log\RPCS3.log';
        final fallbackLog = r'C:\RPCS3\RPCS3.log';
        final resolver = Rpcs3MemoryBaseResolverDataSource(
          fileExists: (path) => path == primaryLog || path == fallbackLog,
          lastModifiedUtc: (_) => DateTime.utc(2026, 11, 5, 10, 1),
          readAsString: (path) {
            if (path == primaryLog) {
              throw const WindowsMemoryException(
                operation: 'CreateFileW RPCS3 log',
                errorCode: 32,
              );
            }
            return 'vm::g_base_addr = 0x400000000';
          },
        );

        final candidate = resolver.resolveCandidate(_processMetadata());

        expect(candidate?.memoryBase, 0x400000000);
        expect(candidate?.logPath, fallbackLog);
      },
    );

    test(
      'Method resolveCandidate() rejects zero and overflowing addresses',
      () {
        final resolver = _resolver({
          r'C:\RPCS3\log\RPCS3.log':
              'vm::g_base_addr = 0x0\n'
              'vm::g_base_addr = 0xffffffffffffffff',
        });

        expect(resolver.resolveCandidate(_processMetadata()), isNull);
      },
    );

    test('Method resolveCandidate() prefers the RPCS3 log directory', () {
      final resolver = _resolver({
        r'C:\RPCS3\log\RPCS3.log': 'vm::g_base_addr = 0x300000000',
        r'C:\RPCS3\RPCS3.log': 'vm::g_base_addr = 0x400000000',
      });

      expect(
        resolver.resolveCandidate(_processMetadata())?.memoryBase,
        0x300000000,
      );
    });
  });
}

Rpcs3ProcessMetadata _processMetadata() => Rpcs3ProcessMetadata(
  executablePath: r'C:\RPCS3\rpcs3.exe',
  startedAtUtc: DateTime.utc(2026, 11, 5, 10),
);

Rpcs3MemoryBaseResolverDataSource _resolver(
  Map<String, String> logs, {
  DateTime? modifiedAt,
}) => Rpcs3MemoryBaseResolverDataSource(
  fileExists: logs.containsKey,
  lastModifiedUtc: (_) => modifiedAt ?? DateTime.utc(2026, 11, 5, 10, 1),
  readAsString: (path) => logs[path]!,
);
