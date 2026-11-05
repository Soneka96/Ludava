import 'dart:ffi';

/// Holds the Windows process-memory calls used by the data source.
class WindowsMemoryApi {
  /// Opens a target process with the requested access flags.
  final Pointer<Void> Function(int, int, int) openProcess;

  /// Reads bytes from a target process.
  final int Function(
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Uint8>,
    int,
    Pointer<Uint64>,
  ) readProcessMemory;

  /// Writes bytes to a target process.
  final int Function(
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Uint8>,
    int,
    Pointer<Uint64>,
  ) writeProcessMemory;

  /// Closes a native process handle.
  final int Function(Pointer<Void>) closeHandle;

  /// Returns the calling thread's last Windows error code.
  final int Function() getLastError;

  /// Returns the current process identifier.
  final int Function() getCurrentProcessId;

  /// Creates an API adapter from injectable Windows functions.
  const WindowsMemoryApi({
    required this.openProcess,
    required this.readProcessMemory,
    required this.writeProcessMemory,
    required this.closeHandle,
    required this.getLastError,
    required this.getCurrentProcessId,
  });

  /// Binds the API adapter to `kernel32.dll`.
  factory WindowsMemoryApi.system() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    return WindowsMemoryApi(
      openProcess: kernel32.lookupFunction<
          Pointer<Void> Function(Uint32, Int32, Uint32),
          Pointer<Void> Function(int, int, int)>('OpenProcess'),
      readProcessMemory: kernel32.lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Void>, Pointer<Uint8>, Uint64,
              Pointer<Uint64>),
          int Function(Pointer<Void>, Pointer<Void>, Pointer<Uint8>, int,
              Pointer<Uint64>)>('ReadProcessMemory'),
      writeProcessMemory: kernel32.lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Void>, Pointer<Uint8>, Uint64,
              Pointer<Uint64>),
          int Function(Pointer<Void>, Pointer<Void>, Pointer<Uint8>, int,
              Pointer<Uint64>)>('WriteProcessMemory'),
      closeHandle: kernel32.lookupFunction<Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)>('CloseHandle'),
      getLastError: kernel32.lookupFunction<Uint32 Function(), int Function()>(
        'GetLastError',
      ),
      getCurrentProcessId:
          kernel32.lookupFunction<Uint32 Function(), int Function()>(
        'GetCurrentProcessId',
      ),
    );
  }
}
