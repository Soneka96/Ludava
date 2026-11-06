import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/app/ludava_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Method runAsync() behaves correctly', () {
    test(
      'Method runAsync() delegates help to the trainer command runner',
      () async {
        final output = StringBuffer();
        final error = StringBuffer();
        final sdk = LudavaSdk.create();
        final streamClosed = Completer<void>();
        sdk.session.stateChanges.listen((_) {}, onDone: streamClosed.complete);

        final exitCode = await LudavaCli(
          sdk: sdk,
        ).runAsync(['--help'], output: output, errorOutput: error);
        await streamClosed.future.timeout(const Duration(seconds: 1));

        expect(exitCode, 0);
        expect(output.toString(), contains('Usage:'));
        expect(error.toString(), isEmpty);
      },
    );
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
