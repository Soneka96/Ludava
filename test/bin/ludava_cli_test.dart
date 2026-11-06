import '../../bin/ludava_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Flow Ludava CLI entry behaves correctly', () {
    test('Flow Ludava CLI entry exposes the app composition root', () {
      final output = StringBuffer();

      final exitCode = LudavaCli().run(['--help'], output: output);

      expect(exitCode, 0);
      expect(output.toString(), contains('Usage:'));
    });
  });
}
