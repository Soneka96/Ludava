import 'dart:io';

import 'package:ludava/features/rpcs3_connection/data/datasources/windows_process_discovery.datasource.dart';

/// Runs one fresh-process discovery for the parent integration test.
Future<void> main() async {
  try {
    final processIds =
        WindowsProcessDiscoveryDataSource().findRpcs3ProcessIds();
    if (Platform.environment['LUDAVA_EXPECT_NO_RPCS3'] == '1') {
      if (processIds.isNotEmpty) {
        stderr.writeln(
          'Expected no RPCS3 process, found ${processIds.length}.',
        );
        exitCode = 1;
        return;
      }
    }
    stdout.write('RESULT:${processIds.join(',')}');
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
