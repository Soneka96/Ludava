import 'package:ludava_tui/shared/terminal/trainer_terminal_backend.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nocterm/nocterm.dart' show TerminalBackend;
import 'package:test/test.dart';

class _MockTerminalBackend extends Mock implements TerminalBackend {}

void main() {
  group('Method forPlatform() behaves correctly', () {
    test('Method forPlatform() adapts Windows terminal output only', () {
      final source = _MockTerminalBackend();
      var backendCreations = 0;

      final windowsBackend = TrainerTerminalBackend.forPlatform(() {
        backendCreations++;
        return source;
      }, windows: true);
      final otherBackend = TrainerTerminalBackend.forPlatform(() {
        backendCreations++;
        return source;
      }, windows: false);

      expect(windowsBackend, isNotNull);
      expect(otherBackend, isNull);
      expect(backendCreations, 1);
    });
  });

  group('Method writeRaw() behaves correctly', () {
    test(
      'Method writeRaw() removes unsupported keyboard controls and extra output',
      () {
        final source = _MockTerminalBackend();
        final backend = TrainerTerminalBackend(source);
        const controls = ['\x1b[>1u', '\x1b[>4;1m', '\x1b[<u', '\x1b[>4;0m'];

        backend.writeRaw('${controls.join()}screen output');
        backend.writeRaw(controls.join());

        verify(() => source.writeRaw('screen output')).called(1);
        verifyNoMoreInteractions(source);
      },
    );

    test('Method writeRaw() preserves unrelated terminal controls', () {
      final source = _MockTerminalBackend();
      final backend = TrainerTerminalBackend(source);

      backend.writeRaw('\x1b[?1049h');
      backend.writeRaw('screen output');

      verify(() => source.writeRaw('\x1b[?1049h')).called(1);
      verify(() => source.writeRaw('screen output')).called(1);
      verifyNoMoreInteractions(source);
    });
  });
}
