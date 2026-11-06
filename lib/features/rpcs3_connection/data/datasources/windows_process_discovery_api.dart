import 'dart:ffi';

import 'package:ludava/features/rpcs3_connection/data/models/windows_process_discovery_call_result.model.dart';

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
  final WindowsProcessDiscoveryCallResult<Pointer<Void>> Function(int, int)
  createToolhelp32Snapshot;

  /// Loads the first process entry from a snapshot.
  final WindowsProcessDiscoveryCallResult<bool> Function(
    Pointer<Void>,
    Pointer<ProcessEntry32W>,
  )
  process32FirstW;

  /// Loads the next process entry from a snapshot.
  final WindowsProcessDiscoveryCallResult<bool> Function(
    Pointer<Void>,
    Pointer<ProcessEntry32W>,
  )
  process32NextW;

  /// Closes a native snapshot handle.
  final WindowsProcessDiscoveryCallResult<bool> Function(Pointer<Void>)
  closeHandle;

  /// Creates an API adapter from injectable Windows functions.
  const WindowsProcessDiscoveryApi({
    required this.createToolhelp32Snapshot,
    required this.process32FirstW,
    required this.process32NextW,
    required this.closeHandle,
  });

  /// Binds the API adapter to `kernel32.dll` and `kernel32` Tool Help exports.
  factory WindowsProcessDiscoveryApi.system() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final getLastError = kernel32
        .lookupFunction<Uint32 Function(), int Function()>(
          'GetLastError',
          isLeaf: true,
        );
    var lastErrorIsResolved = false;

    void resolveLastError() {
      if (lastErrorIsResolved) return;
      getLastError();
      lastErrorIsResolved = true;
    }

    final createToolhelp32Snapshot = kernel32.lookupFunction<
      Pointer<Void> Function(Uint32, Uint32),
      Pointer<Void> Function(int, int)
    >('CreateToolhelp32Snapshot');
    final process32FirstW = kernel32.lookupFunction<
      Int32 Function(Pointer<Void>, Pointer<ProcessEntry32W>),
      int Function(Pointer<Void>, Pointer<ProcessEntry32W>)
    >('Process32FirstW');
    final process32NextW = kernel32.lookupFunction<
      Int32 Function(Pointer<Void>, Pointer<ProcessEntry32W>),
      int Function(Pointer<Void>, Pointer<ProcessEntry32W>)
    >('Process32NextW');
    final closeHandle = kernel32.lookupFunction<
      Int32 Function(Pointer<Void>),
      int Function(Pointer<Void>)
    >('CloseHandle');

    @pragma('vm:prefer-inline')
    WindowsProcessDiscoveryCallResult<Pointer<Void>> createSnapshot(
      int flags,
      int processId,
    ) {
      resolveLastError();
      final snapshot = createToolhelp32Snapshot(flags, processId);
      final failed =
          snapshot.address == 0 ||
          snapshot.address == Pointer<Void>.fromAddress(-1).address;
      return WindowsProcessDiscoveryCallResult<Pointer<Void>>(
        value: snapshot,
        errorCode: failed ? getLastError() : 0,
      );
    }

    @pragma('vm:prefer-inline')
    WindowsProcessDiscoveryCallResult<bool> readFirst(
      Pointer<Void> snapshot,
      Pointer<ProcessEntry32W> entry,
    ) {
      resolveLastError();
      final succeeded = process32FirstW(snapshot, entry) != 0;
      return WindowsProcessDiscoveryCallResult<bool>(
        value: succeeded,
        errorCode: succeeded ? 0 : getLastError(),
      );
    }

    @pragma('vm:prefer-inline')
    WindowsProcessDiscoveryCallResult<bool> readNext(
      Pointer<Void> snapshot,
      Pointer<ProcessEntry32W> entry,
    ) {
      resolveLastError();
      final succeeded = process32NextW(snapshot, entry) != 0;
      return WindowsProcessDiscoveryCallResult<bool>(
        value: succeeded,
        errorCode: succeeded ? 0 : getLastError(),
      );
    }

    @pragma('vm:prefer-inline')
    WindowsProcessDiscoveryCallResult<bool> closeSnapshot(
      Pointer<Void> snapshot,
    ) {
      resolveLastError();
      final succeeded = closeHandle(snapshot) != 0;
      return WindowsProcessDiscoveryCallResult<bool>(
        value: succeeded,
        errorCode: succeeded ? 0 : getLastError(),
      );
    }

    return WindowsProcessDiscoveryApi(
      createToolhelp32Snapshot: createSnapshot,
      process32FirstW: readFirst,
      process32NextW: readNext,
      closeHandle: closeSnapshot,
    );
  }
}
