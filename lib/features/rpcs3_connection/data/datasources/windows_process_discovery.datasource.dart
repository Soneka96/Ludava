import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava/shared/platform/windows_memory_exception.dart';
import 'package:ludava/features/rpcs3_connection/data/datasources/windows_process_discovery_api.dart';

/// Finds running RPCS3 process identifiers through the Windows Tool Help API.
class WindowsProcessDiscoveryDataSource {
  /// Creates a process discovery boundary with an optional native API fake.
  WindowsProcessDiscoveryDataSource({
    WindowsProcessDiscoveryApi? api,
    bool? isWindows,
    int? pointerSize,
  }) : _api = api,
       _isWindows = isWindows,
       _pointerSize = pointerSize;

  static const int _th32csSnapProcess = 0x00000002;
  static const int _errorNoMoreFiles = 18;

  final WindowsProcessDiscoveryApi? _api;
  final bool? _isWindows;
  final int? _pointerSize;

  /// Returns IDs of processes whose executable name is `rpcs3.exe`.
  ///
  /// The returned list may be empty or contain multiple process IDs. A failed
  /// enumeration throws [WindowsMemoryException] with the Windows error code.
  List<int> findRpcs3ProcessIds() {
    if (!(_isWindows ?? Platform.isWindows)) {
      throw UnsupportedError('Process discovery is supported on Windows only.');
    }
    if ((_pointerSize ?? sizeOf<IntPtr>()) != 8) {
      throw UnsupportedError('Process discovery requires 64-bit Windows.');
    }

    final api = _api ?? WindowsProcessDiscoveryApi.system();
    final snapshot = api.createToolhelp32Snapshot(_th32csSnapProcess, 0);
    final invalidHandle = Pointer<Void>.fromAddress(-1);
    if (snapshot.address == 0 || snapshot.address == invalidHandle.address) {
      throw WindowsMemoryException(
        operation: 'CreateToolhelp32Snapshot',
        errorCode: api.getLastError(),
      );
    }

    Pointer<ProcessEntry32W> entry = nullptr;
    try {
      entry = calloc<ProcessEntry32W>();
      entry.ref.dwSize = sizeOf<ProcessEntry32W>();
      var hasEntry = api.process32FirstW(snapshot, entry) != 0;
      if (!hasEntry) {
        _throwUnlessEnumerationComplete(api, 'Process32FirstW');
        return const [];
      }

      final processIds = <int>[];
      do {
        if (_executableName(entry.ref.szExeFile).toLowerCase() == 'rpcs3.exe') {
          processIds.add(entry.ref.th32ProcessID);
        }
        hasEntry = api.process32NextW(snapshot, entry) != 0;
      } while (hasEntry);

      _throwUnlessEnumerationComplete(api, 'Process32NextW');
      return List.unmodifiable(processIds);
    } finally {
      if (entry.address != 0) calloc.free(entry);
      if (api.closeHandle(snapshot) == 0) {
        throw WindowsMemoryException(
          operation: 'CloseHandle',
          errorCode: api.getLastError(),
        );
      }
    }
  }

  void _throwUnlessEnumerationComplete(
    WindowsProcessDiscoveryApi api,
    String operation,
  ) {
    final errorCode = api.getLastError();
    if (errorCode != _errorNoMoreFiles) {
      throw WindowsMemoryException(operation: operation, errorCode: errorCode);
    }
  }

  String _executableName(Array<Uint16> name) {
    final codeUnits = <int>[];
    for (var index = 0; index < 260; index++) {
      final codeUnit = name[index];
      if (codeUnit == 0) break;
      codeUnits.add(codeUnit);
    }
    return String.fromCharCodes(codeUnits);
  }
}
