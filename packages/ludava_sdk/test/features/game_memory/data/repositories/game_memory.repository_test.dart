import 'package:ludava_sdk/features/game_memory/data/datasources/windows_process_memory.datasource.dart';
import 'package:ludava_sdk/features/game_memory/data/repositories/game_memory.repository.dart';
import 'package:ludava_sdk/shared/constants/enums.dart';
import 'package:test/test.dart';

import '../../../../support/fake_windows_memory_api.dart';

void main() {
  group('Method read() behaves correctly', () {
    test('Method read() maps a data-source read into a domain result', () {
      final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 42];
      final source = WindowsProcessMemoryDataSource.open(
        42,
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      );
      final repository = GameMemoryRepository(source);

      final result = repository.read(0x301329e80, 4);

      expect(result.status, MemoryReadStatus.complete);
      expect(result.bytes, [0, 0, 0, 42]);
      expect(result.isComplete, isTrue);
      expect(result.errorCode, isNull);
      source.close();
    });

    test('Method read() preserves data-source failure details', () {
      final api =
          FakeWindowsMemoryApi()
            ..readReturnValue = 0
            ..reportedReadBytes = 1
            ..errorCode = 299;
      final source = WindowsProcessMemoryDataSource.open(
        42,
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      );
      final repository = GameMemoryRepository(source);

      final result = repository.read(0x1000, 4);

      expect(result.status, MemoryReadStatus.nativeFailure);
      expect(result.bytes, [1]);
      expect(result.errorCode, 299);
      source.close();
    });
  });

  group('Method write() behaves correctly', () {
    test('Method write() maps a data-source write into a domain result', () {
      final api = FakeWindowsMemoryApi();
      final source = WindowsProcessMemoryDataSource.open(
        42,
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        allowWrites: true,
      );
      final repository = GameMemoryRepository(source);

      final result = repository.write(0x301329e80, [0, 0, 0, 42]);

      expect(result.status, MemoryWriteStatus.complete);
      expect(result.bytesWritten, 4);
      expect(result.isComplete, isTrue);
      expect(api.writtenBytes, [0, 0, 0, 42]);
      source.close();
    });

    test('Method write() preserves data-source failures', () {
      final api =
          FakeWindowsMemoryApi()
            ..writeReturnValue = 0
            ..reportedWriteBytes = 2
            ..errorCode = 5;
      final source = WindowsProcessMemoryDataSource.open(
        42,
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
        allowWrites: true,
      );
      final repository = GameMemoryRepository(source);

      final result = repository.write(0x1000, [1, 2, 3, 4]);

      expect(result.status, MemoryWriteStatus.nativeFailure);
      expect(result.bytesWritten, 2);
      expect(result.errorCode, 5);
      source.close();
    });
  });
}
