import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Holds the Windows calls used to read an RPCS3 log while it is open.
class WindowsRpcs3LogApi {
  /// Opens an existing log with the requested access and sharing modes.
  final Pointer<Void> Function(
    Pointer<Utf16>,
    int,
    int,
    Pointer<Void>,
    int,
    int,
    Pointer<Void>,
  )
  createFileW;

  /// Reads bytes from an opened log file.
  final int Function(
    Pointer<Void>,
    Pointer<Uint8>,
    int,
    Pointer<Uint32>,
    Pointer<Void>,
  )
  readFile;

  /// Closes a native log-file handle.
  final int Function(Pointer<Void>) closeHandle;

  /// Returns the calling thread's last Windows error code.
  final int Function() getLastError;

  /// Creates an API adapter from injectable Windows functions.
  const WindowsRpcs3LogApi({
    required this.createFileW,
    required this.readFile,
    required this.closeHandle,
    required this.getLastError,
  });

  /// Binds log-reading calls to `kernel32.dll`.
  factory WindowsRpcs3LogApi.system() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    return WindowsRpcs3LogApi(
      createFileW: kernel32.lookupFunction<
        Pointer<Void> Function(
          Pointer<Utf16>,
          Uint32,
          Uint32,
          Pointer<Void>,
          Uint32,
          Uint32,
          Pointer<Void>,
        ),
        Pointer<Void> Function(
          Pointer<Utf16>,
          int,
          int,
          Pointer<Void>,
          int,
          int,
          Pointer<Void>,
        )
      >('CreateFileW'),
      readFile: kernel32.lookupFunction<
        Int32 Function(
          Pointer<Void>,
          Pointer<Uint8>,
          Uint32,
          Pointer<Uint32>,
          Pointer<Void>,
        ),
        int Function(
          Pointer<Void>,
          Pointer<Uint8>,
          int,
          Pointer<Uint32>,
          Pointer<Void>,
        )
      >('ReadFile'),
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
