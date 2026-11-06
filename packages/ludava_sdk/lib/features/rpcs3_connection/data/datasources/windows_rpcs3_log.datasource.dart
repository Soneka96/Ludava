import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:ludava_sdk/shared/platform/windows_memory_exception.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_rpcs3_log_api.dart';

/// Reads an RPCS3 log with sharing that permits the running emulator to keep writing.
class WindowsRpcs3LogDataSource {
  /// Creates a log reader with an optional native API fake and read limits.
  ///
  /// [readBufferSize] controls each native chunk. [maximumLogBytes] bounds the
  /// in-memory copy of a log; the default supports the current RPCS3 log while
  /// avoiding unbounded allocation from an unexpectedly large file.
  WindowsRpcs3LogDataSource({
    WindowsRpcs3LogApi? api,
    bool? isWindows,
    int readBufferSize = _defaultReadBufferSize,
    int maximumLogBytes = _defaultMaximumLogBytes,
  }) : _api = api,
       _isWindows = isWindows,
       _readBufferSize = readBufferSize,
       _maximumLogBytes = maximumLogBytes;

  static const int _genericRead = 0x80000000;
  static const int _fileShareRead = 0x00000001;
  static const int _fileShareWrite = 0x00000002;
  static const int _fileShareDelete = 0x00000004;
  static const int _openExisting = 3;
  static const int _fileAttributeNormal = 0x00000080;
  static const int _defaultReadBufferSize = 64 * 1024;
  static const int _defaultMaximumLogBytes = 256 * 1024 * 1024;

  static const String _fileShareDescription =
      'FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE';

  final WindowsRpcs3LogApi? _api;
  final bool? _isWindows;
  final int _readBufferSize;
  final int _maximumLogBytes;

  /// Reads the UTF-8 contents of [logPath] without changing the file.
  ///
  /// The handle permits concurrent reads, writes, and deletes so RPCS3 can
  /// continue logging while Ludava reads the base address.
  String read(String logPath) {
    if (logPath.isEmpty) {
      throw ArgumentError.value(logPath, 'logPath', 'must not be empty');
    }
    if (_readBufferSize <= 0) {
      throw ArgumentError.value(
        _readBufferSize,
        'readBufferSize',
        'must be positive',
      );
    }
    if (_maximumLogBytes <= 0) {
      throw ArgumentError.value(
        _maximumLogBytes,
        'maximumLogBytes',
        'must be positive',
      );
    }
    if (!(_isWindows ?? Platform.isWindows)) {
      throw UnsupportedError('RPCS3 log reading is supported on Windows only.');
    }

    final api = _api ?? WindowsRpcs3LogApi.system();
    final path = logPath.toNativeUtf16();
    late final Pointer<Void> handle;
    try {
      handle = api.createFileW(
        path,
        _genericRead,
        _fileShareRead | _fileShareWrite | _fileShareDelete,
        nullptr,
        _openExisting,
        _fileAttributeNormal,
        nullptr,
      );
    } finally {
      calloc.free(path);
    }

    final invalidHandle = Pointer<Void>.fromAddress(-1);
    if (handle.address == 0 || handle.address == invalidHandle.address) {
      throw WindowsMemoryException(
        operation: 'CreateFileW RPCS3 log ($_fileShareDescription)',
        errorCode: api.getLastError(),
      );
    }

    Pointer<Uint8> buffer = nullptr;
    Pointer<Uint32> bytesRead = nullptr;
    try {
      buffer = calloc<Uint8>(_readBufferSize);
      bytesRead = calloc<Uint32>();
      final builder = BytesBuilder(copy: true);
      var totalBytes = 0;

      while (true) {
        bytesRead.value = 0;
        if (api.readFile(handle, buffer, _readBufferSize, bytesRead, nullptr) ==
            0) {
          throw WindowsMemoryException(
            operation: 'ReadFile RPCS3 log',
            errorCode: api.getLastError(),
          );
        }

        final count = bytesRead.value;
        if (count > _readBufferSize) {
          throw StateError('ReadFile returned an invalid byte count.');
        }
        if (count == 0) break;
        if (totalBytes > _maximumLogBytes - count) {
          throw FileSystemException(
            'RPCS3 log exceeds the $_maximumLogBytes byte read limit.',
            logPath,
          );
        }

        builder.add(buffer.asTypedList(count));
        totalBytes += count;
      }

      return utf8.decode(builder.takeBytes(), allowMalformed: true);
    } finally {
      if (bytesRead.address != 0) calloc.free(bytesRead);
      if (buffer.address != 0) calloc.free(buffer);
      if (api.closeHandle(handle) == 0) {
        throw WindowsMemoryException(
          operation: 'CloseHandle RPCS3 log',
          errorCode: api.getLastError(),
        );
      }
    }
  }
}
