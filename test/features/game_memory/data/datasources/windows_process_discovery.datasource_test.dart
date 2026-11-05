import 'dart:ffi';

import 'package:ludava/features/game_memory/data/datasources/windows_memory_exception.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_process_discovery.datasource.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_process_discovery_api.dart';
import 'package:test/test.dart';

void main() {
  group('Method findRpcs3ProcessIds() behaves correctly', () {
    test(
      'Method findRpcs3ProcessIds() returns no IDs when RPCS3 is absent',
      () {
        final api = _FakeWindowsProcessDiscoveryApi([
          _ProcessInfo(10, 'notepad.exe'),
        ]);

        final processIds = _dataSource(api).findRpcs3ProcessIds();

        expect(processIds, isEmpty);
        expect(api.snapshotFlags, 2);
        expect(api.snapshotProcessId, 0);
        expect(api.entrySize, sizeOf<ProcessEntry32W>());
        expect(api.closeCalls, 1);
      },
    );

    test(
      'Method findRpcs3ProcessIds() returns the single matching process',
      () {
        final api = _FakeWindowsProcessDiscoveryApi([
          _ProcessInfo(51, 'rpcs3.exe'),
        ]);

        final processIds = _dataSource(api).findRpcs3ProcessIds();

        expect(processIds, [51]);
        expect(api.closeCalls, 1);
      },
    );

    test(
      'Method findRpcs3ProcessIds() returns all case-insensitive matches',
      () {
        final api = _FakeWindowsProcessDiscoveryApi([
          _ProcessInfo(51, 'RPCS3.EXE'),
          _ProcessInfo(52, 'rpcs3.exe'),
          _ProcessInfo(53, 'rpcs3.exe.bak'),
        ]);

        final processIds = _dataSource(api).findRpcs3ProcessIds();

        expect(processIds, [51, 52]);
        expect(api.closeCalls, 1);
      },
    );

    test(
      'Method findRpcs3ProcessIds() closes the snapshot on enumeration error',
      () {
        final api = _FakeWindowsProcessDiscoveryApi([
          _ProcessInfo(51, 'rpcs3.exe'),
        ])..nextError = 5;

        expect(
          () => _dataSource(api).findRpcs3ProcessIds(),
          throwsA(
            isA<WindowsMemoryException>()
                .having(
                  (error) => error.operation,
                  'operation',
                  'Process32NextW',
                )
                .having((error) => error.errorCode, 'errorCode', 5),
          ),
        );
        expect(api.closeCalls, 1);
      },
    );

    test(
      'Method findRpcs3ProcessIds() returns empty when no entries exist',
      () {
        final api = _FakeWindowsProcessDiscoveryApi([]);

        expect(_dataSource(api).findRpcs3ProcessIds(), isEmpty);
        expect(api.closeCalls, 1);
      },
    );

    test('Method findRpcs3ProcessIds() reports snapshot creation errors', () {
      final api =
          _FakeWindowsProcessDiscoveryApi([])
            ..snapshotAddress = 0
            ..snapshotError = 87;

      expect(
        () => _dataSource(api).findRpcs3ProcessIds(),
        throwsA(
          isA<WindowsMemoryException>()
              .having(
                (error) => error.operation,
                'operation',
                'CreateToolhelp32Snapshot',
              )
              .having((error) => error.errorCode, 'errorCode', 87),
        ),
      );
      expect(api.closeCalls, 0);
    });

    test(
      'Method findRpcs3ProcessIds() rejects an invalid snapshot sentinel',
      () {
        final api =
            _FakeWindowsProcessDiscoveryApi([])
              ..snapshotAddress = Pointer<Void>.fromAddress(-1).address
              ..snapshotError = 6;

        expect(
          () => _dataSource(api).findRpcs3ProcessIds(),
          throwsA(
            isA<WindowsMemoryException>()
                .having(
                  (error) => error.operation,
                  'operation',
                  'CreateToolhelp32Snapshot',
                )
                .having((error) => error.errorCode, 'errorCode', 6),
          ),
        );
        expect(api.closeCalls, 0);
      },
    );

    test(
      'Method findRpcs3ProcessIds() reports first-entry errors and closes',
      () {
        final api = _FakeWindowsProcessDiscoveryApi([
          _ProcessInfo(51, 'rpcs3.exe'),
        ])..firstError = 87;
        api.failFirst = true;

        expect(
          () => _dataSource(api).findRpcs3ProcessIds(),
          throwsA(
            isA<WindowsMemoryException>()
                .having(
                  (error) => error.operation,
                  'operation',
                  'Process32FirstW',
                )
                .having((error) => error.errorCode, 'errorCode', 87),
          ),
        );
        expect(api.closeCalls, 1);
      },
    );

    test(
      'Method findRpcs3ProcessIds() rejects non-Windows and 32-bit hosts',
      () {
        final api = _FakeWindowsProcessDiscoveryApi([]);

        expect(
          () => _dataSource(api, isWindows: false).findRpcs3ProcessIds(),
          throwsUnsupportedError,
        );
        expect(
          () => _dataSource(api, pointerSize: 4).findRpcs3ProcessIds(),
          throwsUnsupportedError,
        );
        expect(api.snapshotCalls, 0);
      },
    );

    test('Method findRpcs3ProcessIds() reports snapshot close failures', () {
      final api = _FakeWindowsProcessDiscoveryApi([
        _ProcessInfo(51, 'rpcs3.exe'),
      ])..closeResult = 0;

      expect(
        () => _dataSource(api).findRpcs3ProcessIds(),
        throwsA(
          isA<WindowsMemoryException>()
              .having((error) => error.operation, 'operation', 'CloseHandle')
              .having((error) => error.errorCode, 'errorCode', 6),
        ),
      );
      expect(api.closeCalls, 1);
    });

    test('Method findRpcs3ProcessIds() supports repeated discovery calls', () {
      final api = _FakeWindowsProcessDiscoveryApi([
        _ProcessInfo(51, 'rpcs3.exe'),
        _ProcessInfo(52, 'notepad.exe'),
      ]);
      final dataSource = _dataSource(api);

      expect(dataSource.findRpcs3ProcessIds(), [51]);
      expect(dataSource.findRpcs3ProcessIds(), [51]);
      expect(api.snapshotCalls, 2);
      expect(api.closeCalls, 2);
    });

    test('Method findRpcs3ProcessIds() returns an immutable result list', () {
      final api = _FakeWindowsProcessDiscoveryApi([
        _ProcessInfo(51, 'rpcs3.exe'),
      ]);

      final processIds = _dataSource(api).findRpcs3ProcessIds();

      expect(() => processIds.add(52), throwsUnsupportedError);
    });
  });
}

WindowsProcessDiscoveryDataSource _dataSource(
  _FakeWindowsProcessDiscoveryApi fake, {
  bool isWindows = true,
  int pointerSize = 8,
}) => WindowsProcessDiscoveryDataSource(
  api: fake.adapter,
  isWindows: isWindows,
  pointerSize: pointerSize,
);

class _ProcessInfo {
  final int processId;
  final String executable;

  const _ProcessInfo(this.processId, this.executable);
}

class _FakeWindowsProcessDiscoveryApi {
  final List<_ProcessInfo> processes;
  int snapshotAddress = 0x1234;
  int snapshotError = 5;
  int firstError = 18;
  int nextError = 18;
  int closeError = 6;
  int closeResult = 1;
  int snapshotCalls = 0;
  int closeCalls = 0;
  int? snapshotFlags;
  int? snapshotProcessId;
  int? entrySize;
  int _index = -1;
  int _lastError = 0;
  bool failFirst = false;

  _FakeWindowsProcessDiscoveryApi(this.processes);

  WindowsProcessDiscoveryApi get adapter => WindowsProcessDiscoveryApi(
    createToolhelp32Snapshot: (flags, processId) {
      snapshotCalls++;
      snapshotFlags = flags;
      snapshotProcessId = processId;
      _lastError = snapshotError;
      return Pointer<Void>.fromAddress(snapshotAddress);
    },
    process32FirstW: (_, entry) {
      entrySize = entry.ref.dwSize;
      if (processes.isEmpty || failFirst) {
        _lastError = firstError;
        return 0;
      }
      _index = 0;
      _writeEntry(entry);
      return 1;
    },
    process32NextW: (_, entry) {
      _index++;
      if (_index >= processes.length) {
        _lastError = nextError;
        return 0;
      }
      _writeEntry(entry);
      return 1;
    },
    closeHandle: (_) {
      closeCalls++;
      if (closeResult == 0) _lastError = closeError;
      return closeResult;
    },
    getLastError: () => _lastError,
  );

  void _writeEntry(Pointer<ProcessEntry32W> entry) {
    final process = processes[_index];
    entry.ref.th32ProcessID = process.processId;
    final codeUnits = process.executable.codeUnits;
    for (var index = 0; index < codeUnits.length && index < 259; index++) {
      entry.ref.szExeFile[index] = codeUnits[index];
    }
    entry.ref.szExeFile[codeUnits.length < 260 ? codeUnits.length : 259] = 0;
  }
}
