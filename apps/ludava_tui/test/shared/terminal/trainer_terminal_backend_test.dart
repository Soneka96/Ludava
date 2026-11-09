import 'dart:async';

import 'package:ludava_tui/shared/terminal/trainer_terminal_backend.dart';
import 'package:nocterm/nocterm.dart' show Size, TerminalBackend;
import 'package:test/test.dart';

class _FakeTerminalBackend implements TerminalBackend {
  _FakeTerminalBackend({this.provideInput = true});

  /// Whether the fake exposes its controlled input stream.
  final bool provideInput;

  final StreamController<List<int>> _input =
      StreamController<List<int>>.broadcast(sync: true);

  /// Terminal output recorded for assertions.
  final List<String> writes = [];

  /// Sends one translated Windows console key event to the input listener.
  void send(List<int> bytes) => _input.add(bytes);

  /// Closes the controlled input source.
  Future<void> close() => _input.close();

  /// Returns the controlled source of translated input events.
  @override
  Stream<List<int>>? get inputStream => provideInput ? _input.stream : null;

  /// Records terminal output written by the backend.
  @override
  void writeRaw(String data) => writes.add(data);

  /// Returns the test terminal dimensions.
  @override
  Size getSize() => const Size(80, 24);

  /// Reports that size queries are not supported by the test backend.
  @override
  bool get supportsSize => false;

  /// Provides no resize events in the test backend.
  @override
  Stream<Size>? get resizeStream => null;

  /// Provides no shutdown events in the test backend.
  @override
  Stream<void>? get shutdownStream => null;

  /// Ignores raw-mode changes in the test backend.
  @override
  void enableRawMode() {}

  /// Ignores raw-mode restoration in the test backend.
  @override
  void disableRawMode() {}

  /// Reports that the test input source is available.
  @override
  bool get isAvailable => true;

  /// Ignores exit requests in the test backend.
  @override
  void requestExit([int exitCode = 0]) {}

  /// Ignores size changes in the controlled test backend.
  @override
  void notifySizeChanged(Size newSize) {}

  /// Closes the controlled input source.
  @override
  void dispose() {
    unawaited(_input.close());
  }
}

void main() {
  group('Method forPlatform() behaves correctly', () {
    test('Method forPlatform() adapts Windows terminal output', () {
      final source = _FakeTerminalBackend();
      var backendCreations = 0;

      expect(
        TrainerTerminalBackend.forPlatform(() {
          backendCreations++;
          return source;
        }, windows: true),
        isA<TrainerTerminalBackend>(),
      );
      expect(backendCreations, 1);
      expect(
        TrainerTerminalBackend.forPlatform(() {
          backendCreations++;
          return source;
        }, windows: false),
        isNull,
      );
      expect(backendCreations, 1);

      source.dispose();
    });
  });

  group('Property inputStream behaves correctly', () {
    test('Property inputStream is absent when the source has no input', () {
      final source = _FakeTerminalBackend(provideInput: false);
      final backend = TrainerTerminalBackend(source);

      expect(backend.inputStream, isNull);
      source.dispose();
    });

    test(
      'Property inputStream forwards native Escape, Ctrl+C and following keys once',
      () async {
        final source = _FakeTerminalBackend();
        final backend = TrainerTerminalBackend(source);
        final chunks = <List<int>>[];
        final subscription = backend.inputStream!.listen(chunks.add);

        source
          ..send(const [0x1b])
          ..send(const [0x03])
          ..send(const [0x61]);

        expect(chunks, [
          const [0x1b],
          const [0x03],
          const [0x61],
        ]);
        expect(
          String.fromCharCodes(chunks.expand((chunk) => chunk)),
          isNot(contains('[27u')),
        );
        expect(
          String.fromCharCodes(chunks.expand((chunk) => chunk)),
          isNot(contains('[99;5u')),
        );

        await subscription.cancel();
        await source.close();
      },
    );

    test('Property inputStream forwards complete special-key events', () async {
      final source = _FakeTerminalBackend();
      final backend = TrainerTerminalBackend(source);
      final chunks = <List<int>>[];
      final subscription = backend.inputStream!.listen(chunks.add);

      source
        ..send(const [0x1b, 0x5b, 0x41])
        ..send(const [0x1b, 0x5b, 0x48])
        ..send(const [0x1b, 0x5b, 0x33, 0x7e])
        ..send(const [0x7f])
        ..send(const [0x01]);

      expect(chunks, [
        const [0x1b, 0x5b, 0x41],
        const [0x1b, 0x5b, 0x48],
        const [0x1b, 0x5b, 0x33, 0x7e],
        const [0x7f],
        const [0x01],
      ]);

      await subscription.cancel();
      await source.close();
    });
  });

  group('Method writeRaw() behaves correctly', () {
    test(
      'Method writeRaw() suppresses enhanced keyboard protocol negotiation and reset',
      () {
        final source = _FakeTerminalBackend();
        final backend = TrainerTerminalBackend(source);

        const controls = ['\x1b[>1u', '\x1b[>4;1m', '\x1b[<u', '\x1b[>4;0m'];
        backend.writeRaw('${controls.join()}screen output');

        expect(source.writes, ['screen output']);
        source.dispose();
      },
    );

    test('Method writeRaw() preserves unrelated terminal controls', () {
      final source = _FakeTerminalBackend();
      final backend = TrainerTerminalBackend(source);

      backend.writeRaw('\x1b[?1049h');
      backend.writeRaw('screen output');

      expect(source.writes, ['\x1b[?1049h', 'screen output']);
      source.dispose();
    });
  });
}
