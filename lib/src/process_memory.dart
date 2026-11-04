import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

const _processVmRead = 0x0010;
const _maxNativeAddress = 0x7fffffffffffffff;

typedef _OpenProcessNative = Pointer<Void> Function(
  Uint32,
  Int32,
  Uint32,
);
typedef _OpenProcessDart = Pointer<Void> Function(int, int, int);
typedef _ReadProcessMemoryNative = Int32 Function(
  Pointer<Void>,
  Pointer<Void>,
  Pointer<Uint8>,
  Uint64,
  Pointer<Uint64>,
);
typedef _ReadProcessMemoryDart = int Function(
  Pointer<Void>,
  Pointer<Void>,
  Pointer<Uint8>,
  int,
  Pointer<Uint64>,
);
typedef _CloseHandleNative = Int32 Function(Pointer<Void>);
typedef _CloseHandleDart = int Function(Pointer<Void>);
typedef _GetLastErrorNative = Uint32 Function();
typedef _GetLastErrorDart = int Function();

class WindowsMemoryApi {
  const WindowsMemoryApi({
    required this.openProcess,
    required this.readProcessMemory,
    required this.closeHandle,
    required this.getLastError,
  });

  factory WindowsMemoryApi.system() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    return WindowsMemoryApi(
      openProcess:
          kernel32.lookupFunction<_OpenProcessNative, _OpenProcessDart>(
        'OpenProcess',
      ),
      readProcessMemory: kernel32
          .lookupFunction<_ReadProcessMemoryNative, _ReadProcessMemoryDart>(
        'ReadProcessMemory',
      ),
      closeHandle:
          kernel32.lookupFunction<_CloseHandleNative, _CloseHandleDart>(
        'CloseHandle',
      ),
      getLastError:
          kernel32.lookupFunction<_GetLastErrorNative, _GetLastErrorDart>(
        'GetLastError',
      ),
    );
  }

  final _OpenProcessDart openProcess;
  final _ReadProcessMemoryDart readProcessMemory;
  final _CloseHandleDart closeHandle;
  final _GetLastErrorDart getLastError;
}

enum MemoryReadStatus {
  complete,
  nativeFailure,
  partial,
  invalidAddress,
  invalidRequest,
  invalidByteCount,
}

class MemoryReadResult {
  const MemoryReadResult({
    required this.status,
    required this.bytes,
    required this.bytesRead,
    required this.requestedBytes,
    this.errorCode,
  });

  final MemoryReadStatus status;
  final Uint8List bytes;
  final int bytesRead;
  final int requestedBytes;
  final int? errorCode;

  bool get isComplete => status == MemoryReadStatus.complete;
}

class ProcessMemoryOpenException implements Exception {
  const ProcessMemoryOpenException(this.processId, this.errorCode);

  final int processId;
  final int errorCode;

  @override
  String toString() =>
      'Could not open process $processId for reading (Windows error $errorCode).';
}

class ProcessMemoryException implements Exception {
  const ProcessMemoryException(this.operation, this.errorCode);

  final String operation;
  final int errorCode;

  @override
  String toString() => '$operation failed (Windows error $errorCode).';
}

class WindowsProcessMemory {
  WindowsProcessMemory._(this._handle, this._api);

  static WindowsProcessMemory open(
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
          'Process memory access is supported on Windows only.');
    }
    if ((pointerSize ?? sizeOf<IntPtr>()) != 8) {
      throw UnsupportedError('Process memory access requires 64-bit Windows.');
    }

    final nativeApi = api ?? WindowsMemoryApi.system();
    final handle = nativeApi.openProcess(_processVmRead, 0, processId);
    if (handle.address == 0) {
      throw ProcessMemoryOpenException(processId, nativeApi.getLastError());
    }
    return WindowsProcessMemory._(handle, nativeApi);
  }

  final Pointer<Void> _handle;
  final WindowsMemoryApi _api;
  bool _closed = false;

  MemoryReadResult read(int address, int byteCount) {
    if (_closed) throw StateError('Process handle is closed.');

    if (byteCount <= 0) {
      return MemoryReadResult(
        status: MemoryReadStatus.invalidRequest,
        bytes: Uint8List(0),
        bytesRead: 0,
        requestedBytes: byteCount,
      );
    }
    if (address <= 0 ||
        address > _maxNativeAddress ||
        byteCount - 1 > _maxNativeAddress - address) {
      return MemoryReadResult(
        status: MemoryReadStatus.invalidAddress,
        bytes: Uint8List(0),
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
      final bytesRead = transferred.value;
      if (bytesRead > byteCount) {
        return MemoryReadResult(
          status: MemoryReadStatus.invalidByteCount,
          bytes: Uint8List(0),
          bytesRead: bytesRead,
          requestedBytes: byteCount,
          errorCode: succeeded == 0 ? _api.getLastError() : null,
        );
      }

      final bytes = Uint8List.fromList(buffer.asTypedList(bytesRead));
      if (succeeded == 0) {
        return MemoryReadResult(
          status: MemoryReadStatus.nativeFailure,
          bytes: bytes,
          bytesRead: bytesRead,
          requestedBytes: byteCount,
          errorCode: _api.getLastError(),
        );
      }
      if (bytesRead != byteCount) {
        return MemoryReadResult(
          status: MemoryReadStatus.partial,
          bytes: bytes,
          bytesRead: bytesRead,
          requestedBytes: byteCount,
        );
      }
      return MemoryReadResult(
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

  void close() {
    if (_closed) return;
    _closed = true;
    if (_api.closeHandle(_handle) == 0) {
      throw ProcessMemoryException('CloseHandle', _api.getLastError());
    }
  }
}
