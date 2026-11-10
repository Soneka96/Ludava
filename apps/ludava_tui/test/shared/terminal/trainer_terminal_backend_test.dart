import 'dart:async';

import 'package:ludava_tui/shared/terminal/trainer_terminal_backend.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nocterm/nocterm.dart' show TerminalBackend;
import 'package:test/test.dart';

class _MockTerminalBackend extends Mock implements TerminalBackend {}

void main() {
  group('Method forPlatform() behaves correctly', () {
    test('Method forPlatform() adapts Windows terminal output', () {
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

  group('Property inputStream behaves correctly', () {
    test('Property inputStream is absent when the source has no input', () {
      final source = _MockTerminalBackend();
      when(() => source.inputStream).thenReturn(null);
      final backend = TrainerTerminalBackend(source);

      expect(backend.inputStream, isNull);
    });

    test(
      'Property inputStream forwards native Escape, Ctrl+C and following keys once',
      () async {
        final source = _MockTerminalBackend();
        final input = StreamController<List<int>>.broadcast(sync: true);
        when(() => source.inputStream).thenAnswer((_) => input.stream);
        final backend = TrainerTerminalBackend(source);
        final chunks = <List<int>>[];
        final subscription = backend.inputStream!.listen(chunks.add);
        try {
          input
            ..add(const [0x1b])
            ..add(const [0x03])
            ..add(const [0x61]);

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
        } finally {
          await subscription.cancel();
          await input.close();
        }
      },
    );

    test('Property inputStream forwards complete special-key events', () async {
      final source = _MockTerminalBackend();
      final input = StreamController<List<int>>.broadcast(sync: true);
      when(() => source.inputStream).thenAnswer((_) => input.stream);
      final backend = TrainerTerminalBackend(source);
      final chunks = <List<int>>[];
      final subscription = backend.inputStream!.listen(chunks.add);
      try {
        input
          ..add(const [0x1b, 0x5b, 0x41])
          ..add(const [0x1b, 0x5b, 0x48])
          ..add(const [0x1b, 0x5b, 0x33, 0x7e])
          ..add(const [0x7f])
          ..add(const [0x01]);

        expect(chunks, [
          const [0x1b, 0x5b, 0x41],
          const [0x1b, 0x5b, 0x48],
          const [0x1b, 0x5b, 0x33, 0x7e],
          const [0x7f],
          const [0x01],
        ]);
      } finally {
        await subscription.cancel();
        await input.close();
      }
    });

    test(
      'Property inputStream preserves fragmented and coalesced chunks',
      () async {
        final source = _MockTerminalBackend();
        final input = StreamController<List<int>>.broadcast(sync: true);
        when(() => source.inputStream).thenAnswer((_) => input.stream);
        final backend = TrainerTerminalBackend(source);
        final chunks = <List<int>>[];
        final subscription = backend.inputStream!.listen(chunks.add);
        const inputChunks = [
          [0x1b],
          [0x5b, 0x41],
          [0x1b, 0x5b, 0x42, 0x1b, 0x5b, 0x43],
        ];

        try {
          for (final chunk in inputChunks) {
            input.add(chunk);
          }

          expect(chunks, inputChunks);
        } finally {
          await subscription.cancel();
          await input.close();
        }
      },
    );
  });

  group('Method writeRaw() behaves correctly', () {
    test(
      'Method writeRaw() suppresses enhanced keyboard protocol negotiation and reset',
      () {
        final source = _MockTerminalBackend();
        final backend = TrainerTerminalBackend(source);

        const controls = ['\x1b[>1u', '\x1b[>4;1m', '\x1b[<u', '\x1b[>4;0m'];
        backend.writeRaw('${controls.join()}screen output');

        verify(() => source.writeRaw('screen output')).called(1);
        for (final control in controls) {
          verifyNever(() => source.writeRaw(control));
        }
      },
    );

    test('Method writeRaw() preserves unrelated terminal controls', () {
      final source = _MockTerminalBackend();
      final backend = TrainerTerminalBackend(source);

      backend.writeRaw('\x1b[?1049h');
      backend.writeRaw('screen output');

      verify(() => source.writeRaw('\x1b[?1049h')).called(1);
      verify(() => source.writeRaw('screen output')).called(1);
    });
  });
}
