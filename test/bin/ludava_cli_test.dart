import 'dart:io';

import 'package:test/test.dart';

import '../../bin/ludava_cli.dart';

void main() {
  group('Flow Ludava CLI entry behaves correctly', () {
    test('Flow Ludava CLI entry exposes the app composition root', () async {
      final output = StringBuffer();

      final exitCode = await LudavaCli().runAsync(['--help'], output: output);

      expect(exitCode, 0);
      expect(output.toString(), contains('Usage:'));
    });
  });

  group('Flow Ludava CLI executable behaves correctly', () {
    test(
      'Flow Ludava CLI executable reports noninteractive default startup',
      () async {
        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'bin/ludava_cli.dart',
        ]);

        expect(result.exitCode, 2);
        expect(result.stderr, contains('Interactive mode requires a terminal'));
      },
    );

    test('Flow Ludava CLI executable preserves diagnostic help', () async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/ludava_cli.dart',
        '--help',
      ]);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('Usage:'));
      expect(result.stderr, isEmpty);
    });
  });
}
