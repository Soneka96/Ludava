import 'dart:ffi';
import 'dart:io';

import 'package:ludava/features/rpcs3_connection/data/datasources/windows_process_discovery.datasource.dart';
import 'package:test/test.dart';

void main() {
  group('Integration Windows process discovery behaves correctly', () {
    test('Integration process discovery enumerates repeatedly on Windows', () {
      if (!Platform.isWindows || sizeOf<IntPtr>() != 8) {
        markTestSkipped('Process discovery requires 64-bit Windows.');
        return;
      }

      final dataSource = WindowsProcessDiscoveryDataSource();
      for (var attempt = 0; attempt < 5; attempt++) {
        final processIds = dataSource.findRpcs3ProcessIds();

        expect(processIds, everyElement(greaterThan(0)));
      }
    });
  });
}
