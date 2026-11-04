import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_memory_api.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_memory_exception.dart';
import 'package:ludava/features/game_memory/data/models/process_memory_read.model.dart';
import 'package:ludava/features/game_memory/domain/utils/address_resolver.dart';
import 'package:ludava/shared/constants/enums.dart';

/// Performs checked, read-only transfers from a Windows process.
class WindowsProcessMemoryDataSource {
  WindowsProcessMemoryDataSource._(this._handle, this._api);

  /// Opens [processId] with read access only.
  factory WindowsProcessMemoryDataSource.open(
    int processId, {
    WindowsMemoryApi? api,
    bool? isWindows,
    int? pointerSize,
  }) {
    if (processId <= 0 || processId > 0xffffffff) {
      throw ArgumentError.value(processId, 'processId', 'must be a valid PID');
    }
    if (!(isWindows ?? Platform.isWindows)) {
      throw UnsupportedError(
        'Process memory access is supported on Windows only.',
      );
    }
    if ((pointerSize ?? sizeOf<IntPtr>()) != 8) {
      throw UnsupportedError('Process memory access requires 64-bit Windows.');
    }

    final nativeApi = api ?? WindowsMemoryApi.system();
    final handle = nativeApi.openProcess(_processVmRead, 0, processId);
    if (handle.address == 0) {
      final errorCode = nativeApi.getLastError();
      throw WindowsMemoryException(
        operation: 'OpenProcess',
        processId: processId,
        errorCode: errorCode,
      );
    }
    return WindowsProcessMemoryDataSource._(handle, nativeApi);
  }

  static const int _processVmRead = 0x0010;

  final Pointer<Void> _handle;
  final WindowsMemoryApi _api;
  bool _closed = false;

  /// Reads [byteCount] bytes from [address] and reports the exact native result.
  ProcessMemoryReadModel read(int address, int byteCount) {
    _ensureOpen();
    if (byteCount <= 0) {
      return ProcessMemoryReadModel(
        status: MemoryReadStatus.invalidRequest,
        bytes: const [],
        bytesRead: 0,
        requestedBytes: byteCount,
      );
    }
    if (!_hasValidRange(address, byteCount)) {
      return ProcessMemoryReadModel(
        status: MemoryReadStatus.invalidAddress,
        bytes: const [],
        bytesRead: 0,
        requestedBytes: byteCount,
      );
    }

    Pointer<Uint8> buffer = nullptr;
    Pointer<Uint64> transferred = nullptr;
    try {
      buffer = calloc<Uint8>(byteCount);
      transferred = calloc<Uint64>();
      final succeeded = _api.readProcessMemory(
        _handle,
        Pointer<Void>.fromAddress(address),
        buffer,
        byteCount,
        transferred,
      );
      final errorCode = succeeded == 0 ? _api.getLastError() : null;
      final bytesRead = transferred.value;
      if (bytesRead > byteCount) {
        return ProcessMemoryReadModel(
          status: MemoryReadStatus.invalidByteCount,
          bytes: const [],
          bytesRead: bytesRead,
          requestedBytes: byteCount,
          errorCode: errorCode,
        );
      }

      final bytes = buffer.asTypedList(bytesRead).toList(growable: false);
      if (succeeded == 0) {
        return ProcessMemoryReadModel(
          status: MemoryReadStatus.nativeFailure,
          bytes: bytes,
          bytesRead: bytesRead,
          requestedBytes: byteCount,
          errorCode: errorCode,
        );
      }
      if (bytesRead != byteCount) {
        return ProcessMemoryReadModel(
          status: MemoryReadStatus.partial,
          bytes: bytes,
          bytesRead: bytesRead,
          requestedBytes: byteCount,
        );
      }
      return ProcessMemoryReadModel(
        status: MemoryReadStatus.complete,
        bytes: bytes,
        bytesRead: bytesRead,
        requestedBytes: byteCount,
      );
    } finally {
      if (transferred.address != 0) calloc.free(transferred);
      if (buffer.address != 0) calloc.free(buffer);
    }
  }

  /// Closes the process handle once.
  void close() {
    if (_closed) return;
    _closed = true;
    if (_api.closeHandle(_handle) == 0) {
      final errorCode = _api.getLastError();
      throw WindowsMemoryException(
        operation: 'CloseHandle',
        errorCode: errorCode,
      );
    }
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Process handle is closed.');
  }

  bool _hasValidRange(int address, int byteCount) {
    if (address <= 0) return false;
    try {
      AddressResolver.resolve(
        memoryBase: address,
        guestOffset: 0,
        byteLength: byteCount,
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }
}
