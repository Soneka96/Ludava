import 'dart:ffi';
import 'dart:io';

import 'package:ludava/features/game_memory/data/datasources/windows_process_metadata_api.dart';
import 'package:test/test.dart';

void main() {
  group('Class WindowsProcessMetadataApi construction', () {
    test('Class WindowsProcessMetadataApi exposes injected process calls', () {
      var opened = false;
      var queried = false;
      var timesRead = false;
      var closed = false;
      final api = WindowsProcessMetadataApi(
        openProcess: (access, inherit, processId) {
          opened = access == 0x1000 && inherit == 0 && processId == 42;
          return Pointer<Void>.fromAddress(1);
        },
        queryFullProcessImageNameW: (_, flags, __, ___) {
          queried = flags == 0;
          return 1;
        },
        getProcessTimes: (_, __, ___, ____, _____) {
          timesRead = true;
          return 1;
        },
        closeHandle: (_) {
          closed = true;
          return 1;
        },
        getLastError: () => 5,
      );

      expect(api.openProcess(0x1000, 0, 42).address, 1);
      expect(
        api.queryFullProcessImageNameW(
          Pointer<Void>.fromAddress(1),
          0,
          nullptr.cast<Uint16>(),
          nullptr.cast<Uint32>(),
        ),
        1,
      );
      expect(
        api.getProcessTimes(
          Pointer<Void>.fromAddress(1),
          nullptr.cast<Uint64>(),
          nullptr.cast<Uint64>(),
          nullptr.cast<Uint64>(),
          nullptr.cast<Uint64>(),
        ),
        1,
      );
      expect(api.closeHandle(Pointer<Void>.fromAddress(1)), 1);

      expect(opened, isTrue);
      expect(queried, isTrue);
      expect(timesRead, isTrue);
      expect(closed, isTrue);
      expect(api.getLastError(), 5);
    });
  });

  group('Method system() behaves correctly', () {
    test('Method system() binds the Windows process metadata exports', () {
      if (!Platform.isWindows) {
        markTestSkipped('The process metadata exports require Windows.');
      }

      expect(
        WindowsProcessMetadataApi.system(),
        isA<WindowsProcessMetadataApi>(),
      );
    });
  });
}
