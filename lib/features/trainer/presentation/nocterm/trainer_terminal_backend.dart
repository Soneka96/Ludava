import 'dart:async';

import 'package:nocterm/nocterm.dart';

/// Holds Windows escape input until a complete key sequence can be delivered.
class TrainerTerminalBackend implements TerminalBackend {
  /// Maximum time a bare Escape waits for a possible protocol suffix.
  final Duration escapeTimeout;

  /// Creates a Windows terminal backend around [backend].
  TrainerTerminalBackend(
    this._backend, {
    this.escapeTimeout = const Duration(milliseconds: 100),
  });

  final TerminalBackend _backend;

  /// Adds the input adapter on Windows while preserving other platforms.
  static TerminalBackend? forPlatform(
    TerminalBackend Function() createBackend, {
    required bool windows,
  }) => windows ? TrainerTerminalBackend(createBackend()) : null;

  /// Returns the wrapped input stream with split escape sequences combined.
  @override
  Stream<List<int>>? get inputStream {
    final source = _backend.inputStream;
    if (source == null) return null;

    return Stream<List<int>>.multi((controller) {
      final chunker = _EscapeSequenceChunker();
      Timer? escapeTimer;
      late final StreamSubscription<List<int>> subscription;

      void publish(List<List<int>> chunks) {
        for (final chunk in chunks) {
          if (chunk.isNotEmpty) controller.addSync(chunk);
        }
      }

      void scheduleEscapeFlush() {
        escapeTimer?.cancel();
        if (!chunker.hasPendingEscape) return;
        escapeTimer = Timer(escapeTimeout, () {
          publish(chunker.flushPending());
        });
      }

      subscription = source.listen(
        (bytes) {
          publish(chunker.add(bytes));
          scheduleEscapeFlush();
        },
        onError: controller.addErrorSync,
        onDone: () {
          escapeTimer?.cancel();
          publish(chunker.flushPending());
          controller.closeSync();
        },
      );

      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume
        ..onCancel = () {
          escapeTimer?.cancel();
          return subscription.cancel();
        };
    });
  }

  /// Writes terminal output through the wrapped backend.
  @override
  void writeRaw(String data) => _backend.writeRaw(data);

  /// Returns the current terminal dimensions.
  @override
  Size getSize() => _backend.getSize();

  /// Reports whether the wrapped backend supports size queries.
  @override
  bool get supportsSize => _backend.supportsSize;

  /// Returns the wrapped resize stream, if available.
  @override
  Stream<Size>? get resizeStream => _backend.resizeStream;

  /// Returns the wrapped shutdown stream, if available.
  @override
  Stream<void>? get shutdownStream => _backend.shutdownStream;

  /// Enables raw input mode on the wrapped backend.
  @override
  void enableRawMode() => _backend.enableRawMode();

  /// Restores normal input mode on the wrapped backend.
  @override
  void disableRawMode() => _backend.disableRawMode();

  /// Reports whether the wrapped backend remains available.
  @override
  bool get isAvailable => _backend.isAvailable;

  /// Requests process exit through the wrapped backend.
  @override
  void requestExit([int exitCode = 0]) => _backend.requestExit(exitCode);

  /// Forwards externally reported terminal dimensions.
  @override
  void notifySizeChanged(Size newSize) => _backend.notifySizeChanged(newSize);

  /// Releases the wrapped backend and its native resources.
  @override
  void dispose() => _backend.dispose();
}

/// Coalesces escape-prefixed input without changing ordinary character bytes.
class _EscapeSequenceChunker {
  final List<int> _pending = [];
  bool _discardingCsi = false;

  /// Whether an escape-prefixed sequence is waiting for more bytes.
  bool get hasPendingEscape => _pending.isNotEmpty || _discardingCsi;

  /// Adds [bytes] and returns complete chunks safe for Nocterm to parse.
  List<List<int>> add(List<int> bytes) {
    final chunks = <List<int>>[];
    final printable = <int>[];

    void flushPrintable() {
      if (printable.isEmpty) return;
      chunks.add(List<int>.of(printable));
      printable.clear();
    }

    for (final byte in bytes) {
      if (_discardingCsi) {
        if (_isCsiFinal(byte)) _discardingCsi = false;
        continue;
      }
      if (_pending.isEmpty) {
        if (byte == 0x1b) {
          flushPrintable();
          _pending.add(byte);
        } else {
          printable.add(byte);
        }
        continue;
      }

      _pending.add(byte);
      if (_isCompleteSequence()) {
        chunks.add(List<int>.of(_pending));
        _pending.clear();
      } else if (_pending.length >= 64) {
        _pending.clear();
        _discardingCsi = true;
      } else if (!_canContinueSequence()) {
        chunks.add([_pending.first]);
        final remainder = List<int>.of(_pending.skip(1));
        _pending.clear();
        chunks.addAll(add(remainder));
      }
    }

    flushPrintable();
    return chunks;
  }

  /// Releases a lone Escape and discards a malformed incomplete sequence.
  List<List<int>> flushPending() {
    _discardingCsi = false;
    if (_pending.length == 1 && _pending.single == 0x1b) {
      _pending.clear();
      return [
        <int>[0x1b],
      ];
    }
    _pending.clear();
    return const [];
  }

  /// Reports whether the buffered sequence has reached its final byte.
  bool _isCompleteSequence() {
    if (_pending.length == 2) {
      return _pending[1] != 0x5b && _pending[1] != 0x4f;
    }
    if (_pending[1] == 0x5b) {
      return _pending.length >= 3 && _isCsiFinal(_pending.last);
    }
    if (_pending[1] == 0x4f) {
      return _pending.length == 3 && _isCsiFinal(_pending.last);
    }
    return _pending.length >= 2;
  }

  /// Reports whether more bytes can complete a recognized escape sequence.
  bool _canContinueSequence() {
    if (_pending.length == 1) return true;
    if (_pending[1] == 0x5b) {
      return _pending.length < 64;
    }
    if (_pending[1] == 0x4f) return _pending.length < 3;
    return false;
  }

  /// Returns whether [byte] is an ANSI CSI final byte.
  bool _isCsiFinal(int byte) => byte >= 0x40 && byte <= 0x7e;
}
