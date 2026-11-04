import 'package:test/test.dart';

import '../../bin/ludava_cli.dart';
import '../support/fake_windows_memory_api.dart';

void main() {
  group('Method run() behaves correctly', () {
    test('Method run() prints help without opening a process', () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(['--help'], output: output, errorOutput: errorOutput);

      expect(exitCode, 0);
      expect(output.toString(), contains('bin/ludava.dart read'));
      expect(errorOutput.toString(), isEmpty);
      expect(api.openCalls, 0);
    });

    test('Method run() reads the selected field through the generic profile',
        () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi()..readBytes = [0, 0, 0, 42];

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
        ],
        output: output,
        errorOutput: errorOutput,
      );

      expect(exitCode, 0);
      expect(output.toString(), contains('Field: bolts'));
      expect(output.toString(), contains('Value: 42'));
      expect(errorOutput.toString(), isEmpty);
      expect(api.requestedAccess, 0x0010);
      expect(api.readAddress, 0x301329e80);
      expect(api.closeCalls, 1);
    });

    test('Method run() reports an unknown profile before opening a process',
        () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'read',
          '--game',
          'unknown',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
        ],
        errorOutput: errorOutput,
      );

      expect(exitCode, 2);
      expect(errorOutput.toString(), contains('Unknown game profile'));
      expect(api.openCalls, 0);
    });

    test('Method run() reports an unavailable field before opening a process',
        () {
      final output = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'health',
          '--pid',
          '42',
          '--memory-base',
          '0x1',
        ],
        output: output,
      );

      expect(exitCode, 1);
      expect(output.toString(), contains('field is not approved for reading'));
      expect(api.openCalls, 0);
    });

    test('Method run() keeps writes disabled until active-build verification',
        () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'write',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
          '--value',
          '50',
          '--confirm-write',
        ],
        errorOutput: errorOutput,
      );

      expect(exitCode, 1);
      expect(errorOutput.toString(),
          contains('active game build is not verified'));
      expect(api.openCalls, 0);
      expect(api.writeCalls, 0);
    });

    test('Method run() reports inaccessible processes with the Windows error',
        () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi(handleAddress: 0)..errorCode = 5;

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(
        [
          'read',
          '--game',
          'rc2-collection',
          '--field',
          'bolts',
          '--pid',
          '42',
          '--memory-base',
          '0x300000000',
        ],
        errorOutput: errorOutput,
      );

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('Windows error 5'));
      expect(api.lastErrorCalls, 1);
    });

    test('Method run() returns an argument error before opening a process', () {
      final errorOutput = StringBuffer();
      final api = FakeWindowsMemoryApi();

      final exitCode = LudavaCli(
        api: api.adapter,
        isWindows: true,
        pointerSize: 8,
      ).run(['read', '--pid', '42'], errorOutput: errorOutput);

      expect(exitCode, 2);
      expect(errorOutput.toString(), contains('--game, --field, --pid'));
      expect(api.openCalls, 0);
    });
  });
}
