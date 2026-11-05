import 'dart:ffi';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_memory_exception.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_rpcs3_log.datasource.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_rpcs3_log_api.dart';
import 'package:test/test.dart';

void main() {
  group('Method read() behaves correctly', () {
    test('Method read() shares the log and reads its full contents', () {
      final contents =
          '${'x' * (64 * 1024)}\n'
          'vm::g_base_addr = 0000000300000000 - 00000003ffffffff\n';
      final api = _FakeWindowsRpcs3LogApi(utf8.encode(contents));

      final result = WindowsRpcs3LogDataSource(
        api: api.adapter,
        isWindows: true,
      ).read(r'C:\RPCS3\log\RPCS3.log');

      expect(result, contents);
      expect(api.openedPath, r'C:\RPCS3\log\RPCS3.log');
      expect(api.requestedAccess, 0x80000000);
      expect(api.requestedSharing, 0x00000007);
      expect(api.creationDisposition, 3);
      expect(api.fileFlags, 0x80);
      expect(api.readCalls, greaterThan(1));
      expect(api.closeCalls, 1);
    });

    test('Method read() returns an empty string for an empty log', () {
      final api = _FakeWindowsRpcs3LogApi(const []);

      final result = WindowsRpcs3LogDataSource(
        api: api.adapter,
        isWindows: true,
      ).read(r'C:\RPCS3\log\RPCS3.log');

      expect(result, isEmpty);
      expect(api.readCalls, 1);
      expect(api.closeCalls, 1);
    });

    test('Method read() continues after a short successful read', () {
      const contents = 'vm::g_base_addr = 0x300000000';
      final api = _FakeWindowsRpcs3LogApi(utf8.encode(contents))
        ..maxBytesPerRead = 3;

      final result = WindowsRpcs3LogDataSource(
        api: api.adapter,
        isWindows: true,
        readBufferSize: 8,
      ).read(r'C:\RPCS3\log\RPCS3.log');

      expect(result, contents);
      expect(api.readCalls, greaterThan(1));
      expect(api.closeCalls, 1);
    });

    test('Method read() rejects a log that exceeds its configured limit', () {
      final api = _FakeWindowsRpcs3LogApi([1, 2, 3, 4]);

      expect(
        () => WindowsRpcs3LogDataSource(
          api: api.adapter,
          isWindows: true,
          readBufferSize: 2,
          maximumLogBytes: 3,
        ).read(r'C:\RPCS3\log\RPCS3.log'),
        throwsA(isA<FileSystemException>()),
      );
      expect(api.closeCalls, 1);
    });

    test('Method read() reports a sharing violation when opening fails', () {
      final api =
          _FakeWindowsRpcs3LogApi(const [])
            ..handleAddress = Pointer<Void>.fromAddress(-1).address
            ..openError = 32;

      expect(
        () => WindowsRpcs3LogDataSource(
          api: api.adapter,
          isWindows: true,
        ).read(r'C:\RPCS3\log\RPCS3.log'),
        throwsA(
          isA<WindowsMemoryException>()
              .having(
                (error) => error.operation,
                'operation',
                contains('FILE_SHARE_DELETE'),
              )
              .having((error) => error.errorCode, 'errorCode', 32),
        ),
      );
      expect(api.closeCalls, 0);
    });

    test('Method read() rejects a null CreateFileW handle', () {
      final api =
          _FakeWindowsRpcs3LogApi(const [])
            ..handleAddress = 0
            ..openError = 5;

      expect(
        () => WindowsRpcs3LogDataSource(
          api: api.adapter,
          isWindows: true,
        ).read(r'C:\RPCS3\log\RPCS3.log'),
        throwsA(
          isA<WindowsMemoryException>()
              .having(
                (error) => error.operation,
                'operation',
                contains('CreateFileW RPCS3 log'),
              )
              .having((error) => error.errorCode, 'errorCode', 5),
        ),
      );
      expect(api.closeCalls, 0);
    });

    test('Method read() closes the handle when native reading fails', () {
      final api =
          _FakeWindowsRpcs3LogApi(const [])
            ..readResult = 0
            ..readError = 299;

      expect(
        () => WindowsRpcs3LogDataSource(
          api: api.adapter,
          isWindows: true,
        ).read(r'C:\RPCS3\log\RPCS3.log'),
        throwsA(
          isA<WindowsMemoryException>()
              .having(
                (error) => error.operation,
                'operation',
                'ReadFile RPCS3 log',
              )
              .having((error) => error.errorCode, 'errorCode', 299),
        ),
      );
      expect(api.closeCalls, 1);
    });

    test('Method read() closes the handle when native output is invalid', () {
      final api = _FakeWindowsRpcs3LogApi(const [])
        ..reportedReadBytes = 64 * 1024 + 1;

      expect(
        () => WindowsRpcs3LogDataSource(
          api: api.adapter,
          isWindows: true,
        ).read(r'C:\RPCS3\log\RPCS3.log'),
        throwsStateError,
      );
      expect(api.closeCalls, 1);
    });

    test('Method read() reports a handle close failure', () {
      final api =
          _FakeWindowsRpcs3LogApi(const [])
            ..closeResult = 0
            ..closeError = 6;

      expect(
        () => WindowsRpcs3LogDataSource(
          api: api.adapter,
          isWindows: true,
        ).read(r'C:\RPCS3\log\RPCS3.log'),
        throwsA(
          isA<WindowsMemoryException>()
              .having(
                (error) => error.operation,
                'operation',
                'CloseHandle RPCS3 log',
              )
              .having((error) => error.errorCode, 'errorCode', 6),
        ),
      );
      expect(api.closeCalls, 1);
    });

    test('Method read() rejects empty paths and unsupported platforms', () {
      final api = _FakeWindowsRpcs3LogApi(const []);

      expect(
        () => WindowsRpcs3LogDataSource(
          api: api.adapter,
          isWindows: true,
        ).read(''),
        throwsArgumentError,
      );
      expect(
        () => WindowsRpcs3LogDataSource(
          api: api.adapter,
          isWindows: false,
        ).read(r'C:\RPCS3\log\RPCS3.log'),
        throwsUnsupportedError,
      );
      expect(api.openCalls, 0);
    });
  });

  group('Class WindowsRpcs3LogDataSource construction', () {
    test(
      'Class WindowsRpcs3LogDataSource rejects non-positive buffer limits',
      () {
        final api = _FakeWindowsRpcs3LogApi(const []);
        for (final reader in [
          WindowsRpcs3LogDataSource(
            api: api.adapter,
            isWindows: true,
            readBufferSize: 0,
          ),
          WindowsRpcs3LogDataSource(
            api: api.adapter,
            isWindows: true,
            maximumLogBytes: 0,
          ),
        ]) {
          expect(
            () => reader.read(r'C:\RPCS3\log\RPCS3.log'),
            throwsArgumentError,
          );
        }
        expect(api.openCalls, 0);
      },
    );
  });
}

class _FakeWindowsRpcs3LogApi {
  final List<int> contents;
  int handleAddress = 0x1234;
  int openError = 5;
  int readError = 5;
  int closeError = 6;
  int readResult = 1;
  int closeResult = 1;
  int? reportedReadBytes;
  int? maxBytesPerRead;
  int openCalls = 0;
  int readCalls = 0;
  int closeCalls = 0;
  int? requestedAccess;
  int? requestedSharing;
  int? creationDisposition;
  int? fileFlags;
  String? openedPath;
  int _offset = 0;
  int _lastError = 0;

  _FakeWindowsRpcs3LogApi(this.contents);

  WindowsRpcs3LogApi get adapter => WindowsRpcs3LogApi(
    createFileW: (path, access, sharing, _, disposition, flags, __) {
      openCalls++;
      openedPath = path.toDartString();
      requestedAccess = access;
      requestedSharing = sharing;
      creationDisposition = disposition;
      fileFlags = flags;
      _lastError = openError;
      return Pointer<Void>.fromAddress(handleAddress);
    },
    readFile: (_, buffer, bufferLength, bytesRead, __) {
      readCalls++;
      if (readResult == 0) {
        _lastError = readError;
        return 0;
      }
      final bytesRemaining = contents.length - _offset;
      final count =
          reportedReadBytes ??
          min(
            min(bufferLength, bytesRemaining),
            maxBytesPerRead ?? bufferLength,
          );
      bytesRead.value = count;
      if (count <= bufferLength && count > 0) {
        for (
          var index = 0;
          index < count && _offset + index < contents.length;
          index++
        ) {
          buffer[index] = contents[_offset + index];
        }
        _offset += count;
      }
      return 1;
    },
    closeHandle: (_) {
      closeCalls++;
      if (closeResult == 0) _lastError = closeError;
      return closeResult;
    },
    getLastError: () => _lastError,
  );
}
