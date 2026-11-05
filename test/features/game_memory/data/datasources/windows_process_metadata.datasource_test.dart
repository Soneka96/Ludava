import 'dart:ffi';

import 'package:ludava/features/game_memory/data/datasources/windows_memory_exception.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_process_metadata.datasource.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_process_metadata_api.dart';
import 'package:test/test.dart';

void main() {
  group('Method read() behaves correctly', () {
    test('Method read() returns the executable and process start time', () {
      final api = _FakeWindowsProcessMetadataApi();

      final metadata = _dataSource(api).read(42);

      expect(metadata.executablePath, api.executablePath);
      expect(metadata.startedAtUtc, api.startedAtUtc);
      expect(api.requestedAccess, 0x1000);
      expect(api.openedProcessId, 42);
      expect(api.closeCalls, 1);
    });

    test(
      'Method read() reports processes that exit before metadata is read',
      () {
        final api =
            _FakeWindowsProcessMetadataApi()
              ..handleAddress = 0
              ..errorCode = 87;

        expect(
          () => _dataSource(api).read(42),
          throwsA(
            isA<WindowsMemoryException>()
                .having((error) => error.operation, 'operation', 'OpenProcess')
                .having((error) => error.processId, 'processId', 42)
                .having((error) => error.errorCode, 'errorCode', 87),
          ),
        );
        expect(api.closeCalls, 0);
      },
    );

    test('Method read() closes the handle when image lookup fails', () {
      final api = _FakeWindowsProcessMetadataApi()..imageResult = 0;

      expect(
        () => _dataSource(api).read(42),
        throwsA(
          isA<WindowsMemoryException>().having(
            (error) => error.operation,
            'operation',
            'QueryFullProcessImageNameW',
          ),
        ),
      );
      expect(api.closeCalls, 1);
    });

    test('Method read() closes the handle when image lookup throws', () {
      final api = _FakeWindowsProcessMetadataApi()..throwOnImageLookup = true;

      expect(() => _dataSource(api).read(42), throwsStateError);
      expect(api.closeCalls, 1);
    });

    test('Method read() rejects invalid native image path lengths', () {
      for (final length in [0, 32769]) {
        final api =
            _FakeWindowsProcessMetadataApi()..pathLengthOverride = length;

        expect(
          () => _dataSource(api).read(42),
          throwsA(
            isA<WindowsMemoryException>().having(
              (error) => error.operation,
              'operation',
              'QueryFullProcessImageNameW returned an invalid path length',
            ),
          ),
        );
        expect(api.closeCalls, 1);
      }
    });

    test('Method read() closes the handle when process-time lookup fails', () {
      final api = _FakeWindowsProcessMetadataApi()..timesResult = 0;

      expect(
        () => _dataSource(api).read(42),
        throwsA(
          isA<WindowsMemoryException>().having(
            (error) => error.operation,
            'operation',
            'GetProcessTimes',
          ),
        ),
      );
      expect(api.closeCalls, 1);
    });

    test('Method read() rejects invalid PIDs and unsupported platforms', () {
      final api = _FakeWindowsProcessMetadataApi();

      for (final processId in [0, -1, 0x100000000]) {
        expect(() => _dataSource(api).read(processId), throwsArgumentError);
      }
      expect(
        () => _dataSource(api, isWindows: false).read(42),
        throwsUnsupportedError,
      );
      expect(
        () => _dataSource(api, pointerSize: 4).read(42),
        throwsUnsupportedError,
      );
      expect(api.openCalls, 0);
    });

    test('Method read() reports process handle close failures', () {
      final api = _FakeWindowsProcessMetadataApi()..closeResult = 0;

      expect(
        () => _dataSource(api).read(42),
        throwsA(
          isA<WindowsMemoryException>()
              .having((error) => error.operation, 'operation', 'CloseHandle')
              .having((error) => error.errorCode, 'errorCode', 6),
        ),
      );
      expect(api.closeCalls, 1);
    });
  });
}

WindowsProcessMetadataDataSource _dataSource(
  _FakeWindowsProcessMetadataApi fake, {
  bool isWindows = true,
  int pointerSize = 8,
}) => WindowsProcessMetadataDataSource(
  api: fake.adapter,
  isWindows: isWindows,
  pointerSize: pointerSize,
);

class _FakeWindowsProcessMetadataApi {
  final String executablePath = r'C:\RPCS3\rpcs3.exe';
  final DateTime startedAtUtc = DateTime.utc(2026, 11, 5, 10);
  int handleAddress = 0x1234;
  int imageResult = 1;
  int timesResult = 1;
  int closeResult = 1;
  int errorCode = 5;
  int closeErrorCode = 6;
  int openCalls = 0;
  int closeCalls = 0;
  int? requestedAccess;
  int? openedProcessId;
  int? pathLengthOverride;
  bool throwOnImageLookup = false;

  WindowsProcessMetadataApi get adapter => WindowsProcessMetadataApi(
    openProcess: (access, _, processId) {
      openCalls++;
      requestedAccess = access;
      openedProcessId = processId;
      return Pointer<Void>.fromAddress(handleAddress);
    },
    queryFullProcessImageNameW: (_, flags, buffer, pathLength) {
      if (throwOnImageLookup) throw StateError('fake lookup failure');
      if (flags != 0 || imageResult == 0) return imageResult;
      final codeUnits = executablePath.codeUnits;
      pathLength.value = pathLengthOverride ?? codeUnits.length;
      for (var index = 0; index < codeUnits.length; index++) {
        buffer[index] = codeUnits[index];
      }
      return 1;
    },
    getProcessTimes: (_, creationTime, __, ___, ____) {
      if (timesResult == 0) return timesResult;
      creationTime.value =
          (startedAtUtc.millisecondsSinceEpoch + 11644473600000) * 10000;
      return 1;
    },
    closeHandle: (_) {
      closeCalls++;
      if (closeResult == 0) errorCode = closeErrorCode;
      return closeResult;
    },
    getLastError: () => errorCode,
  );
}
