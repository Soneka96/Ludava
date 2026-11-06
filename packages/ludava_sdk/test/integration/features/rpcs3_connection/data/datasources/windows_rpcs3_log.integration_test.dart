import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_rpcs3_log.datasource.dart';
import 'package:ludava_sdk/features/rpcs3_connection/data/datasources/windows_rpcs3_log_api.dart';
import 'package:test/test.dart';

void main() {
  group('Integration Windows RPCS3 log reading behaves correctly', () {
    test(
      'Integration log reader permits a writer to append during reading',
      () {
        if (!Platform.isWindows || sizeOf<IntPtr>() != 8) {
          markTestSkipped('64-bit Windows file sharing is required.');
        }

        final directory = Directory.systemTemp.createTempSync('ludava-log-');
        final logFile = File(
          '${directory.path}${Platform.pathSeparator}RPCS3.log',
        );
        final contents =
            '${'x' * (64 * 1024)}\n'
            'vm::g_base_addr = 0000000300000000 - 00000003ffffffff\n';
        const appended = 'log append completed\n';
        logFile.writeAsStringSync(contents);

        final api = WindowsRpcs3LogApi.system();
        final writerApi = _NativeFileWriterApi.system();
        try {
          final nativePath = logFile.path.toNativeUtf16();
          late final Pointer<Void> writerHandle;
          try {
            writerHandle = api.createFileW(
              nativePath,
              0x40000000 | 0x00010000,
              0x00000007,
              nullptr,
              3,
              0x00000080,
              nullptr,
            );
          } finally {
            calloc.free(nativePath);
          }

          final invalidHandle = Pointer<Void>.fromAddress(-1);
          expect(writerHandle.address, isNot(0));
          expect(writerHandle.address, isNot(invalidHandle.address));

          var appendedDuringRead = false;
          final readingApi = WindowsRpcs3LogApi(
            createFileW: api.createFileW,
            readFile: (handle, buffer, byteCount, bytesRead, overlapped) {
              final succeeded = api.readFile(
                handle,
                buffer,
                byteCount,
                bytesRead,
                overlapped,
              );
              if (!appendedDuringRead &&
                  succeeded != 0 &&
                  bytesRead.value > 0) {
                writerApi.append(writerHandle, appended);
                appendedDuringRead = true;
              }
              return succeeded;
            },
            closeHandle: api.closeHandle,
            getLastError: api.getLastError,
          );
          try {
            final read = WindowsRpcs3LogDataSource(
              api: readingApi,
            ).read(logFile.path);
            expect(read, '$contents$appended');
            expect(appendedDuringRead, isTrue);
          } finally {
            api.closeHandle(writerHandle);
          }
          expect(logFile.readAsStringSync(), '$contents$appended');
        } finally {
          directory.deleteSync(recursive: true);
        }
      },
      skip: !Platform.isWindows,
    );
  });
}

class _NativeFileWriterApi {
  final int Function(Pointer<Void>, int, Pointer<Int64>, int) setFilePointerEx;
  final int Function(
    Pointer<Void>,
    Pointer<Uint8>,
    int,
    Pointer<Uint32>,
    Pointer<Void>,
  )
  writeFile;

  const _NativeFileWriterApi({
    required this.setFilePointerEx,
    required this.writeFile,
  });

  factory _NativeFileWriterApi.system() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    return _NativeFileWriterApi(
      setFilePointerEx: kernel32.lookupFunction<
        Int32 Function(Pointer<Void>, Int64, Pointer<Int64>, Uint32),
        int Function(Pointer<Void>, int, Pointer<Int64>, int)
      >('SetFilePointerEx'),
      writeFile: kernel32.lookupFunction<
        Int32 Function(
          Pointer<Void>,
          Pointer<Uint8>,
          Uint32,
          Pointer<Uint32>,
          Pointer<Void>,
        ),
        int Function(
          Pointer<Void>,
          Pointer<Uint8>,
          int,
          Pointer<Uint32>,
          Pointer<Void>,
        )
      >('WriteFile'),
    );
  }

  void append(Pointer<Void> handle, String text) {
    final bytes = text.codeUnits;
    final buffer = calloc<Uint8>(bytes.length);
    final written = calloc<Uint32>();
    try {
      buffer.asTypedList(bytes.length).setAll(0, bytes);
      if (setFilePointerEx(handle, 0, nullptr.cast<Int64>(), 2) == 0) {
        throw StateError('SetFilePointerEx failed.');
      }
      if (writeFile(handle, buffer, bytes.length, written, nullptr) == 0 ||
          written.value != bytes.length) {
        throw StateError('WriteFile failed or completed a partial transfer.');
      }
    } finally {
      calloc.free(written);
      calloc.free(buffer);
    }
  }
}
