@Timeout(Duration(minutes: 3))
import 'dart:ffi';
import 'dart:io';

import 'package:ludava/features/rpcs3_connection/data/datasources/windows_process_discovery.datasource.dart';
import 'package:test/test.dart';

const _freshProcessLaunchCount = 50;

void main() {
  group('Integration Windows process discovery behaves correctly', () {
    test(
      'Integration process discovery enumerates in fresh AOT processes on Windows',
      () async {
        if (!Platform.isWindows || sizeOf<IntPtr>() != 8) {
          markTestSkipped('Process discovery requires 64-bit Windows.');
          return;
        }

        final dataSource = WindowsProcessDiscoveryDataSource();
        final expectedProcessIds = dataSource.findRpcs3ProcessIds();
        expect(expectedProcessIds, everyElement(greaterThan(0)));
        expect(expectedProcessIds.toSet().length, expectedProcessIds.length);

        if (Platform.environment['LUDAVA_EXPECT_NO_RPCS3'] == '1') {
          expect(expectedProcessIds, isEmpty);
        }

        final helperPath = _childHelperPath;
        final executablePath = _aotSmokeExecutablePath;
        expect(
          await _compileAotHelper(helperPath, executablePath),
          isTrue,
          reason: 'The AOT discovery smoke helper did not compile.',
        );

        for (var attempt = 0; attempt < _freshProcessLaunchCount; attempt++) {
          final result = await _discoverInFreshProcess(executablePath);

          expect(
            result.length == expectedProcessIds.length &&
                result.toSet().containsAll(expectedProcessIds),
            isTrue,
            reason:
                'Fresh AOT process launch ${attempt + 1} returned a different RPCS3 process set.',
          );
        }
      },
    );
  });
}

String get _childHelperPath =>
    File(
      'test/integration/features/rpcs3_connection/data/datasources/windows_process_discovery_child.dart',
    ).absolute.path;

String get _aotSmokeExecutablePath =>
    File('build/ludava_process_discovery_smoke.exe').absolute.path;

Future<bool> _compileAotHelper(String sourcePath, String executablePath) async {
  final process = await Process.start(Platform.resolvedExecutable, [
    'compile',
    'exe',
    sourcePath,
    '-o',
    executablePath,
  ], workingDirectory: Directory.current.path);
  final result = await Future.wait<Object>([
    process.exitCode,
    process.stdout.transform(systemEncoding.decoder).join(),
    process.stderr.transform(systemEncoding.decoder).join(),
  ]).timeout(
    const Duration(seconds: 60),
    onTimeout: () {
      process.kill();
      return const [-1, '', 'Dart AOT compilation timed out.'];
    },
  );
  final exitCode = result[0] as int;
  return exitCode == 0;
}

Future<List<int>> _discoverInFreshProcess(String executablePath) async {
  final process = await Process.start(
    executablePath,
    const [],
    workingDirectory: Directory.current.path,
  );
  final result = await Future.wait<Object>([
    process.exitCode,
    process.stdout.transform(systemEncoding.decoder).join(),
    process.stderr.transform(systemEncoding.decoder).join(),
  ]).timeout(
    const Duration(seconds: 20),
    onTimeout: () {
      process.kill();
      return const [-1, '', 'AOT child process timed out.'];
    },
  );
  final exitCode = result[0] as int;
  final output = (result[1] as String).trim();
  final errorOutput = (result[2] as String).trim();

  expect(
    exitCode,
    0,
    reason: 'Fresh AOT process failed or timed out: $errorOutput',
  );
  expect(output, startsWith('RESULT:'), reason: errorOutput);

  final encodedIds = output.substring('RESULT:'.length);
  if (encodedIds.isEmpty) return const [];
  return encodedIds.split(',').map(int.parse).toList(growable: false);
}
