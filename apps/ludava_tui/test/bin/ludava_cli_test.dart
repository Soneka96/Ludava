import 'dart:io';

import 'package:test/test.dart';

void main() {
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
