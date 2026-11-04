import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava/src/memory_reader.dart';
import 'package:ludava/src/process_memory.dart';
import 'package:test/test.dart';

const _handleAddress = 0x1234;
const _sampleAddress = 0x301329e80;

class FakeMemoryApi {
  int openError = 5;
  int readError = 299;
  int closeError = 6;
  int openCalls = 0;
  int closeCalls = 0;
  int readCalls = 0;
  int? requestedAccess;
  int? requestedProcessId;
  int? readAddress;
  int bytesToTransfer = 4;
  bool openSucceeds = true;
  bool readSucceeds = true;
  bool closeSucceeds = true;
  List<int> readBytes = const [0x01, 0x02, 0x03, 0x04];
  int lastError = 0;

  late final WindowsMemoryApi api = WindowsMemoryApi(
    openProcess: (access, inherit, processId) {
      openCalls++;
      requestedAccess = access;
      requestedProcessId = processId;
      expect(inherit, 0);
      if (!openSucceeds) lastError = openError;
      return openSucceeds ? Pointer<Void>.fromAddress(_handleAddress) : nullptr;
    },
    readProcessMemory: (handle, address, buffer, count, transferred) {
      readCalls++;
      expect(handle.address, _handleAddress);
      readAddress = address.address;
      final reportedBytes = bytesToTransfer;
      for (var i = 0; i < reportedBytes && i < count; i++) {
        buffer[i] = readBytes[i];
      }
      transferred.value = reportedBytes;
      if (!readSucceeds) lastError = readError;
      return readSucceeds ? 1 : 0;
    },
    closeHandle: (handle) {
      closeCalls++;
      expect(handle.address, _handleAddress);
      if (!closeSucceeds) lastError = closeError;
      return closeSucceeds ? 1 : 0;
    },
    getLastError: () => lastError,
  );

  WindowsProcessMemory open() => WindowsProcessMemory.open(
        42,
        api: api,
        isWindows: true,
        pointerSize: 8,
      );
}

void main() {
  group('WindowsProcessMemory.open', () {
    test('requests only process read access', () {
      final fake = FakeMemoryApi();
      final memory = fake.open();

      expect(fake.requestedAccess, 0x0010);
      expect(fake.requestedProcessId, 42);
      expect(memory, isA<WindowsProcessMemory>());
      expect(memory, isA<MemoryReader>());
      memory.close();
    });

    test('reports OpenProcess failure and preserves Windows error', () {
      final fake = FakeMemoryApi()..openSucceeds = false;

      expect(
        fake.open,
        throwsA(
          isA<ProcessMemoryOpenException>()
              .having((error) => error.processId, 'processId', 42)
              .having((error) => error.errorCode, 'errorCode', 5),
        ),
      );
    });

    test('rejects invalid process IDs before calling Windows', () {
      final fake = FakeMemoryApi();

      expect(
        () => WindowsProcessMemory.open(0,
            api: fake.api, isWindows: true, pointerSize: 8),
        throwsArgumentError,
      );
      expect(fake.openCalls, 0);
    });

    test('rejects unsupported platform and pointer size', () {
      final fake = FakeMemoryApi();

      expect(
        () => WindowsProcessMemory.open(42,
            api: fake.api, isWindows: false, pointerSize: 8),
        throwsUnsupportedError,
      );
      expect(
        () => WindowsProcessMemory.open(42,
            api: fake.api, isWindows: true, pointerSize: 4),
        throwsUnsupportedError,
      );
      expect(fake.openCalls, 0);
    });
  });

  group('WindowsProcessMemory.read', () {
    test(
      'reads a local allocated buffer through the real Windows API',
      () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final currentProcessId =
            kernel32.lookupFunction<Uint32 Function(), int Function()>(
          'GetCurrentProcessId',
        )();
        final data = calloc<Uint8>(4);
        WindowsProcessMemory? memory;
        try {
          data[0] = 0x12;
          data[1] = 0x34;
          data[2] = 0x56;
          data[3] = 0x78;
          memory = WindowsProcessMemory.open(currentProcessId);

          final result = memory.read(data.address, 4);

          expect(result.status, MemoryReadStatus.complete);
          expect(result.bytes, [0x12, 0x34, 0x56, 0x78]);
        } finally {
          try {
            memory?.close();
          } finally {
            calloc.free(data);
          }
        }
      },
      skip: !Platform.isWindows || sizeOf<IntPtr>() != 8,
    );

    test('returns a complete read and preserves addresses above 32 bits', () {
      final fake = FakeMemoryApi();
      final memory = fake.open();

      final result = memory.read(_sampleAddress, 4);

      expect(fake.readAddress, _sampleAddress);
      expect(result.status, MemoryReadStatus.complete);
      expect(result.bytes, [0x01, 0x02, 0x03, 0x04]);
      expect(result.bytesRead, 4);
      expect(result.requestedBytes, 4);
      memory.close();
    });

    test('represents a successful complete read of zero bytes as valid bytes',
        () {
      final fake = FakeMemoryApi()..readBytes = const [0, 0, 0, 0];
      final memory = fake.open();

      final result = memory.read(_sampleAddress, 4);

      expect(result.isComplete, isTrue);
      expect(result.bytes, [0, 0, 0, 0]);
      memory.close();
    });

    test('distinguishes native failure and preserves its Windows error', () {
      final fake = FakeMemoryApi()..readSucceeds = false;
      final memory = fake.open();

      final result = memory.read(_sampleAddress, 4);

      expect(result.status, MemoryReadStatus.nativeFailure);
      expect(result.bytesRead, 4);
      expect(result.errorCode, 299);
      memory.close();
    });

    test('keeps a failed zero-byte read distinct from a successful zero value',
        () {
      final fake = FakeMemoryApi()
        ..readSucceeds = false
        ..bytesToTransfer = 0;
      final memory = fake.open();

      final result = memory.read(_sampleAddress, 4);

      expect(result.status, MemoryReadStatus.nativeFailure);
      expect(result.bytesRead, 0);
      expect(result.isComplete, isFalse);
      expect(result.errorCode, 299);
      memory.close();
    });

    test('represents a successful partial transfer without marking it complete',
        () {
      final fake = FakeMemoryApi()..bytesToTransfer = 2;
      final memory = fake.open();

      final result = memory.read(_sampleAddress, 4);

      expect(result.status, MemoryReadStatus.partial);
      expect(result.bytes, [0x01, 0x02]);
      expect(result.bytesRead, 2);
      expect(result.isComplete, isFalse);
      memory.close();
    });

    test('rejects invalid addresses and byte counts without calling Windows',
        () {
      final fake = FakeMemoryApi();
      final memory = fake.open();

      expect(memory.read(0, 4).status, MemoryReadStatus.invalidAddress);
      expect(
        memory.read(0x7ffffffffffffffe, 4).status,
        MemoryReadStatus.invalidAddress,
      );
      expect(memory.read(_sampleAddress, 0).status,
          MemoryReadStatus.invalidRequest);
      expect(fake.readCalls, 0);
      memory.close();
    });

    test('rejects native byte counts larger than the requested buffer', () {
      final fake = FakeMemoryApi()..bytesToTransfer = 5;
      final memory = fake.open();

      final result = memory.read(_sampleAddress, 4);

      expect(result.status, MemoryReadStatus.invalidByteCount);
      expect(result.bytesRead, 5);
      expect(result.bytes, isEmpty);
      memory.close();
    });

    test('does not read after closing the handle and closes it only once', () {
      final fake = FakeMemoryApi();
      final memory = fake.open();

      memory.close();
      memory.close();

      expect(fake.closeCalls, 1);
      expect(() => memory.read(_sampleAddress, 4), throwsStateError);
      expect(fake.readCalls, 0);
    });

    test('reports CloseHandle failure', () {
      final fake = FakeMemoryApi()..closeSucceeds = false;
      final memory = fake.open();

      expect(
        memory.close,
        throwsA(
          isA<ProcessMemoryException>()
              .having((error) => error.operation, 'operation', 'CloseHandle')
              .having((error) => error.errorCode, 'errorCode', 6),
        ),
      );
    });
  });
}
