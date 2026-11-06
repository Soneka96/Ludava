import 'dart:async';

import 'package:ludava/features/trainer/presentation/nocterm/trainer_terminal_backend.dart';
import 'package:nocterm/nocterm.dart' show Size, TerminalBackend;
import 'package:test/test.dart';

void main() {
  group('Method forPlatform() behaves correctly', () {
    test('Method forPlatform() adapts Windows terminal input', () {
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
      'Property inputStream combines every split of a Kitty Escape sequence',
      () async {
        const sequence = [0x1b, 0x5b, 0x32, 0x37, 0x75];

        for (var split = 1; split < sequence.length; split++) {
          final source = _FakeTerminalBackend();
          final backend = TrainerTerminalBackend(
            source,
            escapeTimeout: Duration.zero,
          );
          final chunks = <List<int>>[];
          final subscription = backend.inputStream!.listen(chunks.add);

          source.send(sequence.sublist(0, split));
          source.send(sequence.sublist(split));

          expect(chunks, [sequence], reason: 'split after byte $split');

          await subscription.cancel();
          await source.close();
        }
      },
    );

    test(
      'Property inputStream combines bytewise Escape input without leaking protocol text',
      () async {
        final source = _FakeTerminalBackend();
        final backend = TrainerTerminalBackend(
          source,
          escapeTimeout: Duration.zero,
        );
        final chunks = <List<int>>[];
        final subscription = backend.inputStream!.listen(chunks.add);

        for (final byte in const [0x1b, 0x5b, 0x32, 0x37, 0x75]) {
          source.send([byte]);
        }

        expect(chunks, [
          const [0x1b, 0x5b, 0x32, 0x37, 0x75],
        ]);

        await subscription.cancel();
        await source.close();
      },
    );

    test('Property inputStream flushes a plain Escape exactly once', () async {
      final source = _FakeTerminalBackend();
      final backend = TrainerTerminalBackend(
        source,
        escapeTimeout: Duration.zero,
      );
      final chunks = <List<int>>[];
      final subscription = backend.inputStream!.listen(chunks.add);

      source.send([0x1b]);
      await Future<void>.delayed(Duration.zero);

      expect(chunks, [
        const [0x1b],
      ]);

      await subscription.cancel();
      await source.close();
    });

    test(
      'Property inputStream preserves printable text around a coalesced Escape event',
      () async {
        final source = _FakeTerminalBackend();
        final backend = TrainerTerminalBackend(source);
        final chunks = <List<int>>[];
        final subscription = backend.inputStream!.listen(chunks.add);

        source.send(const [0x61, 0x1b, 0x5b, 0x32, 0x37, 0x75, 0x62]);

        expect(chunks, [
          const [0x61],
          const [0x1b, 0x5b, 0x32, 0x37, 0x75],
          const [0x62],
        ]);

        await subscription.cancel();
        await source.close();
      },
    );

    test('Property inputStream preserves SS3 and Alt key sequences', () async {
      final source = _FakeTerminalBackend();
      final backend = TrainerTerminalBackend(source);
      final chunks = <List<int>>[];
      final subscription = backend.inputStream!.listen(chunks.add);

      source.send(const [0x1b, 0x4f, 0x50, 0x1b, 0x61]);

      expect(chunks, [
        const [0x1b, 0x4f, 0x50],
        const [0x1b, 0x61],
      ]);

      await subscription.cancel();
      await source.close();
    });

    test(
      'Property inputStream drops overlong CSI data without leaking it',
      () async {
        final source = _FakeTerminalBackend();
        final backend = TrainerTerminalBackend(
          source,
          escapeTimeout: Duration.zero,
        );
        final chunks = <List<int>>[];
        final subscription = backend.inputStream!.listen(chunks.add);

        source.send([0x1b, 0x5b, ...List<int>.filled(64, 0x30), 0x75, 0x78]);

        expect(chunks, [
          const [0x78],
        ]);

        await subscription.cancel();
        await source.close();
      },
    );

    test('Property inputStream forwards source errors', () async {
      final source = _FakeTerminalBackend();
      final backend = TrainerTerminalBackend(source);
      final errors = <Object>[];
      final subscription = backend.inputStream!.listen(
        (_) {},
        onError: errors.add,
      );
      final failure = StateError('input failed');

      source.fail(failure);

      expect(errors, [same(failure)]);

      await subscription.cancel();
      await source.close();
    });

    test(
      'Property inputStream flushes plain Escape and discards incomplete input when the source closes',
      () async {
        final plainSource = _FakeTerminalBackend();
        final plainBackend = TrainerTerminalBackend(plainSource);
        final plainChunks = <List<int>>[];
        final plainSubscription = plainBackend.inputStream!.listen(
          plainChunks.add,
        );
        plainSource.send([0x1b]);
        await plainSource.close();

        final partialSource = _FakeTerminalBackend();
        final partialBackend = TrainerTerminalBackend(partialSource);
        final partialChunks = <List<int>>[];
        final partialSubscription = partialBackend.inputStream!.listen(
          partialChunks.add,
        );
        partialSource.send(const [0x1b, 0x5b, 0x32, 0x37]);
        await partialSource.close();

        expect(plainChunks, [
          const [0x1b],
        ]);
        expect(partialChunks, isEmpty);

        await plainSubscription.cancel();
        await partialSubscription.cancel();
      },
    );

    test(
      'Property inputStream cancels a pending Escape timeout with its listener',
      () async {
        final source = _FakeTerminalBackend();
        final backend = TrainerTerminalBackend(
          source,
          escapeTimeout: const Duration(milliseconds: 100),
        );
        final chunks = <List<int>>[];
        final subscription = backend.inputStream!.listen(chunks.add);

        source.send([0x1b]);
        await subscription.cancel();
        await Future<void>.delayed(Duration.zero);

        expect(chunks, isEmpty);
        await source.close();
      },
    );

    test(
      'Property inputStream buffers input while its listener is paused',
      () async {
        final source = _FakeTerminalBackend();
        final backend = TrainerTerminalBackend(source);
        final chunks = <List<int>>[];
        final subscription = backend.inputStream!.listen(chunks.add);

        subscription.pause();
        source.send(const [0x61]);
        expect(chunks, isEmpty);

        subscription.resume();
        await Future<void>.delayed(Duration.zero);
        expect(chunks, [
          const [0x61],
        ]);

        await subscription.cancel();
        await source.close();
      },
    );
  });
}

class _FakeTerminalBackend implements TerminalBackend {
  _FakeTerminalBackend({this.provideInput = true});

  /// Whether the fake exposes its controlled input stream.
  final bool provideInput;

  final StreamController<List<int>> _input =
      StreamController<List<int>>.broadcast(sync: true);

  /// Sends one controlled input chunk to the backend listener.
  void send(List<int> bytes) => _input.add(bytes);

  /// Closes the controlled input source.
  Future<void> close() => _input.close();

  /// Sends an error through the controlled input source.
  void fail(Object error) => _input.addError(error);

  /// Returns the controlled source of raw input chunks.
  @override
  Stream<List<int>>? get inputStream => provideInput ? _input.stream : null;

  /// Ignores terminal output in the test backend.
  @override
  void writeRaw(String data) {}

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
