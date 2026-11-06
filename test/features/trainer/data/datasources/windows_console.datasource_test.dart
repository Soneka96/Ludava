import 'package:ludava/features/trainer/data/datasources/windows_console.datasource.dart';
import 'package:test/test.dart';

void main() {
  group('Method clearScreen() behaves correctly', () {
    test('Method clearScreen() clears a supported terminal', () {
      final output = StringBuffer();

      final cleared = WindowsConsoleDataSource().clearScreen(
        output: output,
        isTerminal: true,
      );

      expect(cleared, isTrue);
      expect(output.toString(), '\x1b[2J\x1b[H');
    });

    test('Method clearScreen() leaves redirected output untouched', () {
      final output = StringBuffer();

      final cleared = WindowsConsoleDataSource().clearScreen(
        output: output,
        isTerminal: false,
      );

      expect(cleared, isFalse);
      expect(output.toString(), isEmpty);
    });
  });
}
