import 'package:ludava/app/ludava_cli.dart';
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
}
