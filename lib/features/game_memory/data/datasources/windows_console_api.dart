import 'dart:ffi';

/// Holds the Windows console calls used to clear the active screen.
class WindowsConsoleApi {
  /// Returns the standard output console handle.
  final Pointer<Void> Function(int) getStdHandle;

  /// Retrieves the output mode for a console handle.
  final int Function(Pointer<Void>, Pointer<Uint32>) getConsoleMode;

  /// Sets the output mode for a console handle.
  final int Function(Pointer<Void>, int) setConsoleMode;

  /// Writes UTF-16 characters to a console handle.
  final int Function(
    Pointer<Void>,
    Pointer<Uint16>,
    int,
    Pointer<Uint32>,
    Pointer<Void>,
  )
  writeConsoleW;

  /// Creates an API adapter from injectable Windows functions.
  const WindowsConsoleApi({
    required this.getStdHandle,
    required this.getConsoleMode,
    required this.setConsoleMode,
    required this.writeConsoleW,
  });

  /// Binds console calls to `kernel32.dll`.
  factory WindowsConsoleApi.system() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    return WindowsConsoleApi(
      getStdHandle: kernel32.lookupFunction<
        Pointer<Void> Function(Int32),
        Pointer<Void> Function(int)
      >('GetStdHandle'),
      getConsoleMode: kernel32.lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Uint32>),
        int Function(Pointer<Void>, Pointer<Uint32>)
      >('GetConsoleMode'),
      setConsoleMode: kernel32.lookupFunction<
        Int32 Function(Pointer<Void>, Uint32),
        int Function(Pointer<Void>, int)
      >('SetConsoleMode'),
      writeConsoleW: kernel32.lookupFunction<
        Int32 Function(
          Pointer<Void>,
          Pointer<Uint16>,
          Uint32,
          Pointer<Uint32>,
          Pointer<Void>,
        ),
        int Function(
          Pointer<Void>,
          Pointer<Uint16>,
          int,
          Pointer<Uint32>,
          Pointer<Void>,
        )
      >('WriteConsoleW'),
    );
  }
}
