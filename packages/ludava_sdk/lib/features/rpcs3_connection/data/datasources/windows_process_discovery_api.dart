import 'dart:ffi';
import 'dart:isolate';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/models/windows_process_discovery_call_result.model.dart';

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

  /// Binds the API adapter to the native Tool Help error-capture shim.
  factory WindowsProcessDiscoveryApi.system() {
    final nativeApi = DynamicLibrary.open(_nativeLibraryPath());
    final createToolhelp32Snapshot = nativeApi.lookupFunction<
      Pointer<Void> Function(Uint32, Uint32, Pointer<Uint32>),
      Pointer<Void> Function(int, int, Pointer<Uint32>)
    >('ludavaCreateToolhelp32Snapshot');
    final process32FirstW = nativeApi.lookupFunction<
      Int32 Function(Pointer<Void>, Pointer<ProcessEntry32W>, Pointer<Uint32>),
      int Function(Pointer<Void>, Pointer<ProcessEntry32W>, Pointer<Uint32>)
    >('ludavaProcess32FirstW');
    final process32NextW = nativeApi.lookupFunction<
      Int32 Function(Pointer<Void>, Pointer<ProcessEntry32W>, Pointer<Uint32>),
      int Function(Pointer<Void>, Pointer<ProcessEntry32W>, Pointer<Uint32>)
    >('ludavaProcess32NextW');
    final closeHandle = nativeApi.lookupFunction<
      Int32 Function(Pointer<Void>, Pointer<Uint32>),
      int Function(Pointer<Void>, Pointer<Uint32>)
    >('ludavaCloseHandle');

    WindowsProcessDiscoveryCallResult<Pointer<Void>> createSnapshot(
      int flags,
      int processId,
    ) {
      final errorCode = calloc<Uint32>();
      try {
        return WindowsProcessDiscoveryCallResult<Pointer<Void>>(
          value: createToolhelp32Snapshot(flags, processId, errorCode),
          errorCode: errorCode.value,
        );
      } finally {
        calloc.free(errorCode);
      }
    }

    WindowsProcessDiscoveryCallResult<bool> readFirst(
      Pointer<Void> snapshot,
      Pointer<ProcessEntry32W> entry,
    ) {
      final errorCode = calloc<Uint32>();
      try {
        return WindowsProcessDiscoveryCallResult<bool>(
          value: process32FirstW(snapshot, entry, errorCode) != 0,
          errorCode: errorCode.value,
        );
      } finally {
        calloc.free(errorCode);
      }
    }

    WindowsProcessDiscoveryCallResult<bool> readNext(
      Pointer<Void> snapshot,
      Pointer<ProcessEntry32W> entry,
    ) {
      final errorCode = calloc<Uint32>();
      try {
        return WindowsProcessDiscoveryCallResult<bool>(
          value: process32NextW(snapshot, entry, errorCode) != 0,
          errorCode: errorCode.value,
        );
      } finally {
        calloc.free(errorCode);
      }
    }

    WindowsProcessDiscoveryCallResult<bool> closeSnapshot(
      Pointer<Void> snapshot,
    ) {
      final errorCode = calloc<Uint32>();
      try {
        return WindowsProcessDiscoveryCallResult<bool>(
          value: closeHandle(snapshot, errorCode) != 0,
          errorCode: errorCode.value,
        );
      } finally {
        calloc.free(errorCode);
      }
    }

    return WindowsProcessDiscoveryApi(
      createToolhelp32Snapshot: createSnapshot,
      process32FirstW: readFirst,
      process32NextW: readNext,
      closeHandle: closeSnapshot,
    );
  }

  static String _nativeLibraryPath() {
    const libraryName = 'ludava_process_discovery.dll';
    final executable = File(Platform.resolvedExecutable);
    final executableName = executable.uri.pathSegments.last.toLowerCase();
    final String path;
    if (executableName.endsWith('.exe') && executableName != 'dart.exe') {
      path = '${executable.parent.path}${Platform.pathSeparator}$libraryName';
    } else {
      final sdkLibraryUri = Isolate.resolvePackageUriSync(
        Uri.parse('package:ludava_sdk/'),
      );
      if (sdkLibraryUri == null || !sdkLibraryUri.isScheme('file')) {
        throw StateError(
          'The Ludava SDK package location could not be resolved.',
        );
      }
      final repositoryRoot =
          Directory.fromUri(sdkLibraryUri).parent.parent.parent.path;
      path =
          '$repositoryRoot${Platform.pathSeparator}build${Platform.pathSeparator}$libraryName';
    }
    if (!File(path).existsSync()) {
      throw StateError(
        'The Ludava Windows discovery library is missing. Run '
        r'.\tool\build_windows.ps1 before starting Ludava.',
      );
    }
    return path;
  }
}
