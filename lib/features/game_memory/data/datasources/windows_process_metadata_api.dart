import 'dart:ffi';

/// Holds the Windows calls used to identify a selected process.
class WindowsProcessMetadataApi {
  /// Opens a process with the requested access rights.
  final Pointer<Void> Function(int, int, int) openProcess;

  /// Retrieves the full UTF-16 executable path for a process handle.
  final int Function(Pointer<Void>, int, Pointer<Uint16>, Pointer<Uint32>)
  queryFullProcessImageNameW;

  /// Retrieves process times using native eight-byte Windows `FILETIME` slots.
  final int Function(
    Pointer<Void>,
    Pointer<Uint64>,
    Pointer<Uint64>,
    Pointer<Uint64>,
    Pointer<Uint64>,
  )
  getProcessTimes;

  /// Closes a native process handle.
  final int Function(Pointer<Void>) closeHandle;

  /// Returns the calling thread's last Windows error code.
  final int Function() getLastError;

  /// Creates an API adapter from injectable Windows functions.
  const WindowsProcessMetadataApi({
    required this.openProcess,
    required this.queryFullProcessImageNameW,
    required this.getProcessTimes,
    required this.closeHandle,
    required this.getLastError,
  });

  /// Binds process metadata functions to Windows system libraries.
  factory WindowsProcessMetadataApi.system() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    return WindowsProcessMetadataApi(
      openProcess: kernel32.lookupFunction<
        Pointer<Void> Function(Uint32, Int32, Uint32),
        Pointer<Void> Function(int, int, int)
      >('OpenProcess'),
      queryFullProcessImageNameW: kernel32.lookupFunction<
        Int32 Function(Pointer<Void>, Uint32, Pointer<Uint16>, Pointer<Uint32>),
        int Function(Pointer<Void>, int, Pointer<Uint16>, Pointer<Uint32>)
      >('QueryFullProcessImageNameW'),
      getProcessTimes: kernel32.lookupFunction<
        Int32 Function(
          Pointer<Void>,
          Pointer<Uint64>,
          Pointer<Uint64>,
          Pointer<Uint64>,
          Pointer<Uint64>,
        ),
        int Function(
          Pointer<Void>,
          Pointer<Uint64>,
          Pointer<Uint64>,
          Pointer<Uint64>,
          Pointer<Uint64>,
        )
      >('GetProcessTimes'),
      closeHandle: kernel32.lookupFunction<
        Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('CloseHandle'),
      getLastError: kernel32.lookupFunction<Uint32 Function(), int Function()>(
        'GetLastError',
      ),
    );
  }
}
