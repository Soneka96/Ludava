import 'package:nocterm/nocterm.dart';

/// Adapts Nocterm output to the key events translated by the Windows console.
class TrainerTerminalBackend implements TerminalBackend {
  /// Creates a Windows terminal backend around [backend].
  TrainerTerminalBackend(this._backend);

  static const Set<String> _keyboardProtocolControls = {
    '\x1b[>1u',
    '\x1b[>4;1m',
    '\x1b[<u',
    '\x1b[>4;0m',
  };

  final TerminalBackend _backend;

  /// Adds the Windows adapter only on Windows, preserving other backends.
  static TerminalBackend? forPlatform(
    TerminalBackend Function() createBackend, {
    required bool windows,
  }) => windows ? TrainerTerminalBackend(createBackend()) : null;

  /// Returns complete key events emitted by Windows console translation.
  @override
  Stream<List<int>>? get inputStream => _backend.inputStream;

  /// Writes terminal output except keyboard protocol controls handled by Windows.
  @override
  void writeRaw(String data) {
    var output = data;
    for (final control in _keyboardProtocolControls) {
      output = output.replaceAll(control, '');
    }
    if (output.isNotEmpty) _backend.writeRaw(output);
  }

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
