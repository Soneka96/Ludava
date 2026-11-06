import 'dart:ffi';
import 'dart:io';

import 'package:ludava_sdk/features/game_memory/data/datasources/windows_memory_api.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_process_metadata.datasource.dart';
import 'package:test/test.dart';

void main() {
  group('Integration Windows process metadata behaves correctly', () {
    test('Integration metadata reads the current Windows process', () {
      if (!Platform.isWindows || sizeOf<IntPtr>() != 8) {
        markTestSkipped('Process metadata requires 64-bit Windows.');
        return;
      }

      final processId = WindowsMemoryApi.system().getCurrentProcessId();
      final metadata = WindowsProcessMetadataDataSource().read(processId);

      expect(metadata.executablePath, isNotEmpty);
      expect(metadata.startedAtUtc.isBefore(DateTime.now().toUtc()), isTrue);
    });
  });
}
