import 'dart:ffi';

/// Mirrors the Windows `PROCESSENTRY32W` structure used by Tool Help.
///
/// [Uint16] represents Windows `WCHAR` elements. Its native layout, including
/// the pointer-sized `th32DefaultHeapID` field, is required by the OS API.
final class ProcessEntry32W extends Struct {
  /// Size of this structure in bytes; set before enumeration.
  @Uint32()
  external int dwSize;

  /// Number of references to this process (unused by Ludava).
  @Uint32()
  external int cntUsage;

  /// Identifier of this process.
  @Uint32()
  external int th32ProcessID;

  /// Reserved native heap identifier.
  @Uint64()
  external int th32DefaultHeapID;

  /// Module identifier (unused by Ludava).
  @Uint32()
  external int th32ModuleID;

  /// Number of threads in this process.
  @Uint32()
  external int cntThreads;

  /// Parent process identifier.
  @Uint32()
  external int th32ParentProcessID;

  /// Base priority (unused by Ludava).
  @Int32()
  external int pcPriClassBase;

  /// Flags (unused by Ludava).
  @Uint32()
  external int dwFlags;

  /// Null-terminated executable name as UTF-16 code units.
  @Array(260)
  external Array<Uint16> szExeFile;
}

/// Holds the Windows Tool Help process-enumeration calls.
class WindowsProcessDiscoveryApi {
  /// Creates a Tool Help process snapshot.
  final Pointer<Void> Function(int, int) createToolhelp32Snapshot;

  /// Loads the first process entry from a snapshot.
  final int Function(Pointer<Void>, Pointer<ProcessEntry32W>) process32FirstW;

  /// Loads the next process entry from a snapshot.
  final int Function(Pointer<Void>, Pointer<ProcessEntry32W>) process32NextW;

  /// Closes a native snapshot handle.
  final int Function(Pointer<Void>) closeHandle;

  /// Returns the calling thread's last Windows error code.
  final int Function() getLastError;

  /// Creates an API adapter from injectable Windows functions.
  const WindowsProcessDiscoveryApi({
    required this.createToolhelp32Snapshot,
    required this.process32FirstW,
    required this.process32NextW,
    required this.closeHandle,
    required this.getLastError,
  });

  /// Binds the API adapter to `kernel32.dll` and `kernel32` Tool Help exports.
  factory WindowsProcessDiscoveryApi.system() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    return WindowsProcessDiscoveryApi(
      createToolhelp32Snapshot: kernel32.lookupFunction<
        Pointer<Void> Function(Uint32, Uint32),
        Pointer<Void> Function(int, int)
      >('CreateToolhelp32Snapshot', isLeaf: true),
      process32FirstW: kernel32.lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<ProcessEntry32W>),
        int Function(Pointer<Void>, Pointer<ProcessEntry32W>)
      >('Process32FirstW', isLeaf: true),
      process32NextW: kernel32.lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<ProcessEntry32W>),
        int Function(Pointer<Void>, Pointer<ProcessEntry32W>)
      >('Process32NextW', isLeaf: true),
      closeHandle: kernel32.lookupFunction<
        Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('CloseHandle', isLeaf: true),
      // Keep these calls on the direct leaf-call path so Dart's native-call
      // transition cannot disturb Win32's thread-local last-error value.
      getLastError: kernel32.lookupFunction<Uint32 Function(), int Function()>(
        'GetLastError',
        isLeaf: true,
      ),
    );
  }
}
