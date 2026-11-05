import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Flow Ludava executable behaves correctly', () {
    test('Flow Ludava executable exits clearly for noninteractive input',
        () async {
      final result = await Process.run(
        Platform.resolvedExecutable,
        ['run', 'bin/ludava.dart'],
      );

      expect(result.exitCode, 2);
      expect(result.stderr, contains('Interactive mode requires a terminal'));
    });

    test('Flow Ludava executable starts the generic CLI', () async {
      final result = await Process.run(
        Platform.resolvedExecutable,
        ['run', 'bin/ludava.dart', '--help'],
      );

      expect(result.exitCode, 0);
      expect(result.stdout, contains('bin/ludava.dart read'));
      expect(result.stderr, isEmpty);
    });
  });
}
