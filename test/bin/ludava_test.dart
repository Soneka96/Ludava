import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Flow Ludava executable behaves correctly', () {
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
