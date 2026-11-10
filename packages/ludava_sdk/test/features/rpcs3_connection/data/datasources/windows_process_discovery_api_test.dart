import 'dart:ffi';

import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_process_discovery_api.dart';
import 'package:test/test.dart';

void main() {
  group('Class ProcessEntry32W construction', () {
    test('Class ProcessEntry32W initializes the Windows x64 layout', () {
      if (sizeOf<IntPtr>() != 8) {
        markTestSkipped('The process layout assertion requires a 64-bit host.');
        return;
      }

      expect(sizeOf<ProcessEntry32W>(), 568);
      expect(sizeOf<IntPtr>(), 8);
    });
  });
}
