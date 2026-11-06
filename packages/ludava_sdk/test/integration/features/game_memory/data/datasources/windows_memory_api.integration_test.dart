import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava_sdk/features/game_memory/data/datasources/windows_memory_api.dart';
import 'package:test/test.dart';

void main() {
  group('Flow WindowsMemoryApi system binding behaves correctly', () {
    test(
      'Flow WindowsMemoryApi writes and reads an allocated local buffer',
      () {
        final api = WindowsMemoryApi.system();
        final handle = api.openProcess(0x0038, 0, api.getCurrentProcessId());
        if (handle.address == 0)
          fail('OpenProcess error ${api.getLastError()}');

        final target = calloc<Uint8>(4);
        final writeBuffer = calloc<Uint8>(4);
        final readBuffer = calloc<Uint8>(4);
        final transferred = calloc<Uint64>();
        try {
          writeBuffer.asTypedList(4).setAll(0, [10, 20, 30, 40]);
          final writeSucceeded = api.writeProcessMemory(
            handle,
            Pointer<Void>.fromAddress(target.address),
            writeBuffer,
            4,
            transferred,
          );
          expect(
            writeSucceeded,
            1,
            reason: 'WriteProcessMemory error ${api.getLastError()}',
          );
          expect(transferred.value, 4);

          final readSucceeded = api.readProcessMemory(
            handle,
            Pointer<Void>.fromAddress(target.address),
            readBuffer,
            4,
            transferred,
          );
          expect(
            readSucceeded,
            1,
            reason: 'ReadProcessMemory error ${api.getLastError()}',
          );
          expect(transferred.value, 4);
          expect(readBuffer.asTypedList(4), [10, 20, 30, 40]);
        } finally {
          api.closeHandle(handle);
          calloc.free(transferred);
          calloc.free(readBuffer);
          calloc.free(writeBuffer);
          calloc.free(target);
        }
      },
      skip: !Platform.isWindows,
    );
  });
}
