import 'package:ludava/features/game_memory/data/datasources/windows_process_memory.datasource.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_memory_exception.dart';
import 'package:ludava/shared/constants/enums.dart';
import 'package:test/test.dart';

import '../../../../support/fake_windows_memory_api.dart';

void main() {
  group('Method open behaves correctly', () {
    test('Method open requests read access only', () {
      final api = FakeWindowsMemoryApi();
      final source = _WindowsProcessMemoryDataSourceTestData.open(api);

      expect(api.openCalls, 1);
      expect(api.requestedAccess, 0x0010);
      expect(api.openedProcessId, 42);
      source.close();
    });

    test('Method open rejects invalid process ids before the native call', () {
      final api = FakeWindowsMemoryApi();

      for (final processId in [0, -1, 0x100000000]) {
        expect(
          () => WindowsProcessMemoryDataSource.open(
            processId,
            api: api.adapter,
            isWindows: true,
            pointerSize: 8,
          ),
          throwsArgumentError,
        );
      }
      expect(api.openCalls, 0);
    });

    test('Method open rejects unsupported operating systems and pointer sizes',
        () {
      final api = FakeWindowsMemoryApi();

      expect(
        () => WindowsProcessMemoryDataSource.open(
          42,
          api: api.adapter,
          isWindows: false,
          pointerSize: 8,
        ),
        throwsUnsupportedError,
      );
      expect(
        () => WindowsProcessMemoryDataSource.open(
          42,
          api: api.adapter,
          isWindows: true,
          pointerSize: 4,
        ),
        throwsUnsupportedError,
      );
      expect(api.openCalls, 0);
    });

    test('Method open preserves the Windows error when opening fails', () {
      final api = FakeWindowsMemoryApi(handleAddress: 0)..errorCode = 5;

      expect(
        () => _WindowsProcessMemoryDataSourceTestData.open(api),
        throwsA(
          isA<WindowsMemoryException>()
              .having((error) => error.processId, 'processId', 42)
              .having((error) => error.errorCode, 'errorCode', 5),
        ),
      );
      expect(api.lastErrorCalls, 1);
    });
  });

  group('Method read behaves correctly', () {
    test('Method read returns the exact bytes for a complete high address read',
        () {
      final api = FakeWindowsMemoryApi()..readBytes = [0x00, 0x01, 0x23, 0x45];
      final source = _WindowsProcessMemoryDataSourceTestData.open(api);

      final result = source.read(0x301329e80, 4);

      expect(result.status, MemoryReadStatus.complete);
      expect(result.bytes, [0x00, 0x01, 0x23, 0x45]);
      expect(result.bytesRead, 4);
      expect(result.requestedBytes, 4);
      expect(api.readAddress, 0x301329e80);
      expect(api.readCalls, 1);
      source.close();
    });

    test('Method read preserves native errors and bytes returned on failure',
        () {
      final api = FakeWindowsMemoryApi()
        ..readReturnValue = 0
        ..reportedReadBytes = 2
        ..errorCode = 299;
      final source = _WindowsProcessMemoryDataSourceTestData.open(api);

      final result = source.read(0x1000, 4);

      expect(result.status, MemoryReadStatus.nativeFailure);
      expect(result.bytes, [1, 2]);
      expect(result.bytesRead, 2);
      expect(result.errorCode, 299);
      source.close();
    });

    test('Method read reports partial and zero-byte successful transfers', () {
      final partialApi = FakeWindowsMemoryApi()..reportedReadBytes = 2;
      final partialSource = _WindowsProcessMemoryDataSourceTestData.open(
        partialApi,
      );
      final partial = partialSource.read(0x1000, 4);
      expect(partial.status, MemoryReadStatus.partial);
      expect(partial.bytes, [1, 2]);
      expect(partial.bytesRead, isNot(partial.requestedBytes));
      partialSource.close();

      final zeroApi = FakeWindowsMemoryApi()..reportedReadBytes = 0;
      final zeroSource = _WindowsProcessMemoryDataSourceTestData.open(zeroApi);
      final zero = zeroSource.read(0x1000, 4);
      expect(zero.status, MemoryReadStatus.partial);
      expect(zero.bytes, isEmpty);
      expect(zero.bytesRead, 0);
      expect(zero.bytesRead, isNot(zero.requestedBytes));
      zeroSource.close();
    });

    test('Method read rejects impossible native byte counts', () {
      final api = FakeWindowsMemoryApi()..reportedReadBytes = 5;
      final source = _WindowsProcessMemoryDataSourceTestData.open(api);

      final result = source.read(0x1000, 4);

      expect(result.status, MemoryReadStatus.invalidByteCount);
      expect(result.bytes, isEmpty);
      expect(result.bytesRead, 5);
      source.close();
    });

    test('Method read prioritizes impossible counts and preserves native error',
        () {
      final api = FakeWindowsMemoryApi()
        ..readReturnValue = 0
        ..reportedReadBytes = 5
        ..errorCode = 299;
      final source = _WindowsProcessMemoryDataSourceTestData.open(api);

      final result = source.read(0x1000, 4);

      expect(result.status, MemoryReadStatus.invalidByteCount);
      expect(result.errorCode, 299);
      source.close();
    });

    test(
        'Method read rejects invalid requests and addresses before native calls',
        () {
      final api = FakeWindowsMemoryApi();
      final source = _WindowsProcessMemoryDataSourceTestData.open(api);

      expect(source.read(0x1000, 0).status, MemoryReadStatus.invalidRequest);
      expect(source.read(0x1000, -1).status, MemoryReadStatus.invalidRequest);
      expect(source.read(0, 4).status, MemoryReadStatus.invalidAddress);
      expect(source.read(-1, 4).status, MemoryReadStatus.invalidAddress);
      expect(
        source.read(0x7ffffffffffffffe, 4).status,
        MemoryReadStatus.invalidAddress,
      );
      expect(api.readCalls, 0);
      source.close();
    });

    test('Method read throws when the source has been closed', () {
      final source =
          _WindowsProcessMemoryDataSourceTestData.open(FakeWindowsMemoryApi())
            ..close();

      expect(() => source.read(0x1000, 4), throwsStateError);
    });
  });

  group('Method close behaves correctly', () {
    test('Method close closes the handle only once', () {
      final api = FakeWindowsMemoryApi();
      final source = _WindowsProcessMemoryDataSourceTestData.open(api);

      source.close();
      source.close();

      expect(api.closeCalls, 1);
    });

    test('Method close preserves the Windows error when closing fails', () {
      final api = FakeWindowsMemoryApi()
        ..closeReturnValue = 0
        ..errorCode = 6;
      final source = _WindowsProcessMemoryDataSourceTestData.open(api);

      expect(
        source.close,
        throwsA(
          isA<WindowsMemoryException>()
              .having((error) => error.operation, 'operation', 'CloseHandle')
              .having((error) => error.errorCode, 'errorCode', 6),
        ),
      );
      expect(api.lastErrorCalls, 1);
    });
  });
}

abstract final class _WindowsProcessMemoryDataSourceTestData {
  static WindowsProcessMemoryDataSource open(FakeWindowsMemoryApi api) =>
      WindowsProcessMemoryDataSource.open(
        42,
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      );
}
