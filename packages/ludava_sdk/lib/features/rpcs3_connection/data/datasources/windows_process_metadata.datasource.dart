import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava_sdk/shared/platform/windows_memory_exception.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_process_metadata_api.dart';
import 'package:ludava_sdk/features/rpcs3_connection/domain/entities/rpcs3_process_metadata.entity.dart';

/// Reads the executable path and start time of a selected Windows process.
class WindowsProcessMetadataDataSource {
  /// Creates a process metadata boundary with an optional native API fake.
  WindowsProcessMetadataDataSource({
    WindowsProcessMetadataApi? api,
    bool? isWindows,
    int? pointerSize,
  }) : _api = api,
       _isWindows = isWindows,
       _pointerSize = pointerSize;

  static const int _processQueryLimitedInformation = 0x1000;
  static const int _pathCapacity = 32768;
  static const int _windowsToUnixEpochMilliseconds = 11644473600000;

  final WindowsProcessMetadataApi? _api;
  final bool? _isWindows;
  final int? _pointerSize;

  /// Reads [processId]'s image path and process creation time.
  Rpcs3ProcessMetadata read(int processId) {
    if (processId <= 0 || processId > 0xffffffff) {
      throw ArgumentError.value(processId, 'processId', 'must be a valid PID');
    }
    if (!(_isWindows ?? Platform.isWindows)) {
      throw UnsupportedError('Process metadata is supported on Windows only.');
    }
    if ((_pointerSize ?? sizeOf<IntPtr>()) != 8) {
      throw UnsupportedError('Process metadata requires 64-bit Windows.');
    }

    final api = _api ?? WindowsProcessMetadataApi.system();
    final handle = api.openProcess(
      _processQueryLimitedInformation,
      0,
      processId,
    );
    if (handle.address == 0) {
      throw WindowsMemoryException(
        operation: 'OpenProcess',
        processId: processId,
        errorCode: api.getLastError(),
      );
    }

    Pointer<Uint16> pathBuffer = nullptr;
    Pointer<Uint32> pathLength = nullptr;
    Pointer<Uint64> creationTime = nullptr;
    Pointer<Uint64> exitTime = nullptr;
    Pointer<Uint64> kernelTime = nullptr;
    Pointer<Uint64> userTime = nullptr;
    try {
      pathBuffer = calloc<Uint16>(_pathCapacity);
      pathLength = calloc<Uint32>()..value = _pathCapacity;
      creationTime = calloc<Uint64>();
      exitTime = calloc<Uint64>();
      kernelTime = calloc<Uint64>();
      userTime = calloc<Uint64>();

      if (api.queryFullProcessImageNameW(handle, 0, pathBuffer, pathLength) ==
          0) {
        throw WindowsMemoryException(
          operation: 'QueryFullProcessImageNameW',
          processId: processId,
          errorCode: api.getLastError(),
        );
      }
      if (pathLength.value == 0 || pathLength.value > _pathCapacity) {
        throw WindowsMemoryException(
          operation:
              'QueryFullProcessImageNameW returned an invalid path length',
          processId: processId,
          errorCode: 0,
        );
      }
      if (api.getProcessTimes(
            handle,
            creationTime,
            exitTime,
            kernelTime,
            userTime,
          ) ==
          0) {
        throw WindowsMemoryException(
          operation: 'GetProcessTimes',
          processId: processId,
          errorCode: api.getLastError(),
        );
      }

      final imagePath = String.fromCharCodes(
        pathBuffer.asTypedList(pathLength.value),
      );
      final creationMilliseconds =
          creationTime.value ~/ 10000 - _windowsToUnixEpochMilliseconds;
      return Rpcs3ProcessMetadata(
        executablePath: imagePath,
        startedAtUtc: DateTime.fromMillisecondsSinceEpoch(
          creationMilliseconds,
          isUtc: true,
        ),
      );
    } finally {
      if (userTime.address != 0) calloc.free(userTime);
      if (kernelTime.address != 0) calloc.free(kernelTime);
      if (exitTime.address != 0) calloc.free(exitTime);
      if (creationTime.address != 0) calloc.free(creationTime);
      if (pathLength.address != 0) calloc.free(pathLength);
      if (pathBuffer.address != 0) calloc.free(pathBuffer);
      if (api.closeHandle(handle) == 0) {
        throw WindowsMemoryException(
          operation: 'CloseHandle',
          processId: processId,
          errorCode: api.getLastError(),
        );
      }
    }
  }
}
