import 'dart:async';

import 'package:ludava_sdk/ludava_sdk.dart';
import 'package:ludava_tui/app/ludava_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Method runAsync() behaves correctly', () {
    test('Method runAsync() disposes the SDK after a help request', () async {
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
    });
  });
}
