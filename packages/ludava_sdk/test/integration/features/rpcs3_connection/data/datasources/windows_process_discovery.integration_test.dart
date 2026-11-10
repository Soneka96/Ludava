@Timeout(Duration(minutes: 3))
import 'dart:ffi';
import 'dart:isolate';
import 'dart:io';

import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_process_discovery.datasource.dart';
import 'package:test/test.dart';

const _freshProcessLaunchCount = 50;

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
    onTimeout: () async {
      process.kill();
      await process.exitCode;
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
    workingDirectory: Directory.systemTemp.path,
  );
  final result = await Future.wait<Object>([
    process.exitCode,
    process.stdout.transform(systemEncoding.decoder).join(),
    process.stderr.transform(systemEncoding.decoder).join(),
  ]).timeout(
    const Duration(seconds: 20),
    onTimeout: () async {
      process.kill();
      await process.exitCode;
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

String get _childHelperPath =>
    '${_sdkDirectory.path}${Platform.pathSeparator}test${Platform.pathSeparator}'
    'integration${Platform.pathSeparator}features${Platform.pathSeparator}'
    'rpcs3_connection${Platform.pathSeparator}data${Platform.pathSeparator}'
    'datasources${Platform.pathSeparator}'
    'windows_process_discovery_child.dart';

String get _nativeLibraryPath =>
    '${_repositoryRoot.path}${Platform.pathSeparator}build${Platform.pathSeparator}'
    'ludava_process_discovery.dll';

Directory get _sdkDirectory =>
    Directory.fromUri(
      Isolate.resolvePackageUriSync(Uri.parse('package:ludava_sdk/'))!,
    ).parent;

Directory get _repositoryRoot => _sdkDirectory.parent.parent;

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

        final temporaryDirectory = await Directory.systemTemp.createTemp(
          'ludava-process-discovery-',
        );
        try {
          final executablePath =
              '${temporaryDirectory.path}${Platform.pathSeparator}'
              'ludava_process_discovery_smoke.exe';
          await File(_nativeLibraryPath).copy(
            '${temporaryDirectory.path}${Platform.pathSeparator}'
            'ludava_process_discovery.dll',
          );

          expect(
            await _compileAotHelper(_childHelperPath, executablePath),
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
        } finally {
          await temporaryDirectory.delete(recursive: true);
        }
      },
    );
  });
}
