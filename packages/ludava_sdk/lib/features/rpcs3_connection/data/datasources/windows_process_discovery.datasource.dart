import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava_sdk/shared/platform/windows_memory_exception.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_process_discovery_api.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/models/windows_process_discovery_call_result.model.dart';

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
    final snapshotResult = api.createToolhelp32Snapshot(_th32csSnapProcess, 0);
    final snapshot = snapshotResult.value;
    final invalidHandle = Pointer<Void>.fromAddress(-1);
    if (snapshot.address == 0 || snapshot.address == invalidHandle.address) {
      throw WindowsMemoryException(
        operation: 'CreateToolhelp32Snapshot',
        errorCode: snapshotResult.errorCode,
      );
    }

    Pointer<ProcessEntry32W> entry = nullptr;
    List<int>? processIds;
    Object? primaryError;
    StackTrace? primaryStackTrace;
    WindowsMemoryException? closeError;
    try {
      entry = calloc<ProcessEntry32W>();
      entry.ref.dwSize = sizeOf<ProcessEntry32W>();
      final firstResult = api.process32FirstW(snapshot, entry);
      if (!firstResult.value) {
        _throwUnlessEnumerationComplete(firstResult, 'Process32FirstW');
        processIds = const [];
      } else {
        processIds = <int>[];
        var nextResult = firstResult;
        do {
          if (_executableName(entry.ref.szExeFile).toLowerCase() ==
              'rpcs3.exe') {
            processIds.add(entry.ref.th32ProcessID);
          }
          nextResult = api.process32NextW(snapshot, entry);
        } while (nextResult.value);

        _throwUnlessEnumerationComplete(nextResult, 'Process32NextW');
        processIds = List.unmodifiable(processIds);
      }
    } catch (error, stackTrace) {
      primaryError = error;
      primaryStackTrace = stackTrace;
    } finally {
      try {
        if (entry.address != 0) calloc.free(entry);
      } finally {
        final closeResult = api.closeHandle(snapshot);
        if (!closeResult.value) {
          closeError = WindowsMemoryException(
            operation: 'CloseHandle',
            errorCode: closeResult.errorCode,
          );
        }
      }
    }

    if (primaryError != null) {
      if (primaryError is WindowsMemoryException && closeError != null) {
        primaryError = WindowsMemoryException(
          operation: primaryError.operation,
          errorCode: primaryError.errorCode,
          processId: primaryError.processId,
          secondaryException: closeError,
        );
      }
      Error.throwWithStackTrace(primaryError, primaryStackTrace!);
    }
    if (closeError != null) throw closeError;
    return processIds!;
  }

  void _throwUnlessEnumerationComplete(
    WindowsProcessDiscoveryCallResult<bool> result,
    String operation,
  ) {
    final errorCode = result.errorCode;
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
