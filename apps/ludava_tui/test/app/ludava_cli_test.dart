import 'package:ludava_tui/app/ludava_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Method run() behaves correctly', () {
    test('Method run() delegates help to the trainer command runner', () {
      final output = StringBuffer();
      final error = StringBuffer();

      final exitCode = LudavaCli().run(
        ['--help'],
        output: output,
        errorOutput: error,
      );

      expect(exitCode, 0);
      expect(output.toString(), contains('Usage:'));
      expect(error.toString(), isEmpty);
    });
  });

  group('Method runAsync() behaves correctly', () {
    test(
      'Method runAsync() starts Nocterm for an interactive terminal',
      () async {
        var launchCalls = 0;
        final exitCode = await LudavaCli(
          hasTerminal: true,
          runNocterm: (_) async => launchCalls++,
        ).runAsync([]);

        expect(exitCode, 0);
        expect(launchCalls, 1);
      },
    );

    test('Method runAsync() rejects a noninteractive terminal', () async {
      var launchCalls = 0;
      final error = StringBuffer();
      final exitCode = await LudavaCli(
        hasTerminal: false,
        runNocterm: (_) async => launchCalls++,
      ).runAsync([], errorOutput: error);

      expect(exitCode, 2);
      expect(launchCalls, 0);
      expect(
        error.toString(),
        contains('Interactive mode requires a terminal'),
      );
    });
  });
}
