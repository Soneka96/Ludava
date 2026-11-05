import 'dart:ffi';

import 'package:ludava/features/game_memory/data/datasources/windows_memory_api.dart';

/// Configurable native-call fake for process-memory adapter tests.
class FakeWindowsMemoryApi {
  /// Handle address returned by the fake `OpenProcess` call.
  final int handleAddress;

  /// Requested read bytes copied into a native read buffer.
  List<int> readBytes = [1, 2, 3, 4];

  /// Optional byte count reported by the fake read call.
  int? reportedReadBytes;

  /// Native return value for the fake read call.
  int readReturnValue = 1;

  /// Optional byte count reported by the fake write call.
  int? reportedWriteBytes;

  /// Native return value for the fake write call.
  int writeReturnValue = 1;

  /// Native return value for the fake close call.
  int closeReturnValue = 1;

  /// Error code returned by the fake `GetLastError` call.
  int errorCode = 5;

  /// Access flags observed by the fake `OpenProcess` call.
  int? requestedAccess;

  /// Process ID observed by the fake `OpenProcess` call.
  int? openedProcessId;

  /// Target address observed by the fake read call.
  int? readAddress;

  /// Target address observed by the fake write call.
  int? writeAddress;

  /// Bytes copied from the fake write buffer.
  List<int>? writtenBytes;

  /// Number of calls made to each fake native function.
  int openCalls = 0;
  int readCalls = 0;
  int writeCalls = 0;
  int closeCalls = 0;
  int lastErrorCalls = 0;

  /// Creates the fake native API with a valid process handle by default.
  FakeWindowsMemoryApi({this.handleAddress = 0x1234});

  /// Exposes the configured functions through [WindowsMemoryApi].
  WindowsMemoryApi get adapter => WindowsMemoryApi(
        openProcess: (access, _, processId) {
          openCalls++;
          requestedAccess = access;
          openedProcessId = processId;
          return Pointer<Void>.fromAddress(handleAddress);
        },
        readProcessMemory: (handle, address, buffer, byteCount, transferred) {
          readCalls++;
          readAddress = address.address;
          final copiedCount =
              readBytes.length < byteCount ? readBytes.length : byteCount;
          for (var index = 0; index < copiedCount; index++) {
            buffer[index] = readBytes[index];
          }
          transferred.value = reportedReadBytes ?? byteCount;
          return readReturnValue;
        },
        writeProcessMemory: (handle, address, buffer, byteCount, transferred) {
          writeCalls++;
          writeAddress = address.address;
          writtenBytes = buffer.asTypedList(byteCount).toList(growable: false);
          transferred.value = reportedWriteBytes ?? byteCount;
          return writeReturnValue;
        },
        closeHandle: (_) {
          closeCalls++;
          return closeReturnValue;
        },
        getLastError: () {
          lastErrorCalls++;
          return errorCode;
        },
        getCurrentProcessId: () => 42,
      );
}
