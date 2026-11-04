import 'package:ludava/src/bolt_service.dart';
import 'package:ludava/src/process_memory.dart';
import 'package:test/test.dart';

import '../bin/rc2_bolts.dart' as cli;

void main() {
  group('parseDiagnosticArguments', () {
    test('requires an explicit decimal PID and hexadecimal memory base', () {
      final options = cli.parseDiagnosticArguments([
        '--pid',
        '42',
        '--memory-base',
        '0x300000000',
      ]);

      expect(options.processId, 42);
      expect(options.memoryBase, 0x300000000);
    });

    test('accepts options in either order and uppercase hexadecimal digits',
        () {
      final options = cli.parseDiagnosticArguments([
        '--memory-base',
        '0XABCDEF',
        '--pid',
        '7',
      ]);

      expect(options.processId, 7);
      expect(options.memoryBase, 0xabcdef);
    });

    test('rejects missing, duplicate, unknown, and malformed options', () {
      for (final arguments in <List<String>>[
        [],
        ['--pid', '42'],
        ['--pid', '42', '--pid', '43'],
        ['--pid', '42', '--memory-base', '300000000'],
        ['--pid', '42', '--memory-base', '0x'],
        ['--pid', '42', '--memory-base', '0xGG'],
        ['--pid', '42', '--memory-base', '0x1', '--other', '1'],
      ]) {
        expect(
          () => cli.parseDiagnosticArguments(arguments),
          throwsFormatException,
          reason: '$arguments should be rejected',
        );
      }
    });

    test('rejects invalid process IDs and out-of-range bases', () {
      for (final pid in ['0', '-1', '1.5', '4294967296']) {
        expect(
          () => cli.parseDiagnosticArguments([
            '--pid',
            pid,
            '--memory-base',
            '0x1',
          ]),
          throwsFormatException,
        );
      }
      expect(
        () => cli.parseDiagnosticArguments([
          '--pid',
          '42',
          '--memory-base',
          '0x8000000000000000',
        ]),
        throwsFormatException,
      );
    });
  });

  group('formatDiagnosticResult', () {
    test('labels successful values experimental and displays the count', () {
      final output = cli.formatDiagnosticResult(
        const BoltReadResult(status: BoltReadStatus.success, boltCount: 123),
      );

      expect(output, contains('EXPERIMENTAL'));
      expect(output, contains('active build is not verified'));
      expect(output, contains('Status: read complete'));
      expect(output, contains('Bolt count: 123'));
    });

    test('reports a successful numeric zero as a value', () {
      final output = cli.formatDiagnosticResult(
        const BoltReadResult(status: BoltReadStatus.success, boltCount: 0),
      );

      expect(output, contains('Bolt count: 0'));
    });

    test('does not show a bolt count for failures or incomplete reads', () {
      const results = [
        BoltReadResult(status: BoltReadStatus.unsupportedProfile),
        BoltReadResult(status: BoltReadStatus.invalidMapping),
        BoltReadResult(status: BoltReadStatus.readFailed, errorCode: 299),
        BoltReadResult(status: BoltReadStatus.incompleteRead),
        BoltReadResult(status: BoltReadStatus.invalidReadResult),
      ];

      for (final result in results) {
        final output = cli.formatDiagnosticResult(result);
        expect(output, contains('EXPERIMENTAL'));
        expect(output, isNot(contains('Bolt count:')));
      }
      expect(cli.formatDiagnosticResult(results[2]),
          contains('Windows error: 299'));
    });

    test('refuses to display a success status without a value', () {
      final output = cli.formatDiagnosticResult(
        const BoltReadResult(status: BoltReadStatus.success),
      );

      expect(output, contains('Status: invalid diagnostic result'));
      expect(output, isNot(contains('Bolt count:')));
    });
  });

  group('runDiagnostic', () {
    test('prints help and succeeds without opening a process', () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();

      final exitCode = cli.runDiagnostic(
        ['--help'],
        output: output,
        errorOutput: errorOutput,
        openProcess: (_) => throw StateError('must not open a process'),
      );

      expect(exitCode, 0);
      expect(output.toString(), contains('--memory-base <0xHEX>'));
      expect(errorOutput.toString(), isEmpty);
    });

    test('reports argument errors with a nonzero exit code before opening', () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();

      final exitCode = cli.runDiagnostic(
        ['--pid', '42'],
        output: output,
        errorOutput: errorOutput,
        openProcess: (_) => throw StateError('must not open a process'),
      );

      expect(exitCode, 2);
      expect(errorOutput.toString(),
          contains('Both --pid and --memory-base are required'));
      expect(output.toString(), isEmpty);
    });

    test('reports inaccessible processes and preserves the Windows error', () {
      final output = StringBuffer();
      final errorOutput = StringBuffer();

      final exitCode = cli.runDiagnostic(
        ['--pid', '42', '--memory-base', '0x300000000'],
        output: output,
        errorOutput: errorOutput,
        openProcess: (_) => throw const ProcessMemoryOpenException(42, 5),
      );

      expect(exitCode, 1);
      expect(errorOutput.toString(), contains('Windows error 5'));
      expect(errorOutput.toString(), isNot(contains('Bolt count:')));
      expect(output.toString(), isEmpty);
    });
  });
}
