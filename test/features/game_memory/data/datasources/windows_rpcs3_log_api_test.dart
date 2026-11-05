import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_rpcs3_log_api.dart';
import 'package:test/test.dart';

void main() {
  group('Class WindowsRpcs3LogApi construction', () {
    test('Class WindowsRpcs3LogApi exposes injected file calls', () {
      var openCalled = false;
      var readCalled = false;
      var closeCalled = false;
      final api = WindowsRpcs3LogApi(
        createFileW: (
          path,
          access,
          sharing,
          security,
          creation,
          flags,
          template,
        ) {
          openCalled =
              path.address == 1 && access == 0x80000000 && sharing == 7;
          return Pointer<Void>.fromAddress(2);
        },
        readFile: (handle, buffer, count, bytesRead, overlapped) {
          readCalled = handle.address == 2 && count == 4;
          bytesRead.value = 3;
          return 1;
        },
        closeHandle: (handle) {
          closeCalled = handle.address == 2;
          return 1;
        },
        getLastError: () => 32,
      );

      expect(
        api
            .createFileW(
              Pointer<Utf16>.fromAddress(1),
              0x80000000,
              7,
              nullptr,
              3,
              0x80,
              nullptr,
            )
            .address,
        2,
      );
      final bytesRead = calloc<Uint32>();
      try {
        expect(
          api.readFile(
            Pointer<Void>.fromAddress(2),
            nullptr.cast<Uint8>(),
            4,
            bytesRead,
            nullptr,
          ),
          1,
        );
        expect(bytesRead.value, 3);
      } finally {
        calloc.free(bytesRead);
      }
      expect(api.closeHandle(Pointer<Void>.fromAddress(2)), 1);
      expect(api.getLastError(), 32);
      expect(openCalled, isTrue);
      expect(readCalled, isTrue);
      expect(closeCalled, isTrue);
    });
  });

  group('Method system() behaves correctly', () {
    test('Method system() binds the Windows log-reading APIs', () {
      if (!Platform.isWindows) {
        markTestSkipped('The RPCS3 log APIs require Windows.');
      }

      expect(WindowsRpcs3LogApi.system(), isA<WindowsRpcs3LogApi>());
    });
  });
}
