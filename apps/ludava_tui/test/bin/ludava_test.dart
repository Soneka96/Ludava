import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Flow Ludava TUI executable behaves correctly', () {
    test(
      'Flow Ludava TUI executable exits clearly for noninteractive input',
      () async {
        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'bin/ludava.dart',
        ], workingDirectory: Directory.current.path);

        expect(result.exitCode, 2);
        expect(result.stderr, contains('Interactive mode requires a terminal'));
      },
    );

    test('Flow Ludava TUI executable starts the diagnostic CLI', () async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/ludava.dart',
        '--help',
      ], workingDirectory: Directory.current.path);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('bin/ludava.dart read'));
      expect(result.stderr, isEmpty);
    });
  });
}
