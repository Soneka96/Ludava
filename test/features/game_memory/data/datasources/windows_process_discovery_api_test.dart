import 'dart:ffi';
import 'dart:io';

import 'package:ludava/features/game_memory/data/datasources/windows_process_discovery_api.dart';
import 'package:test/test.dart';

void main() {
  group('Class ProcessEntry32W construction', () {
    test('Class ProcessEntry32W initializes the Windows x64 layout', () {
      expect(sizeOf<ProcessEntry32W>(), 568);
      expect(sizeOf<IntPtr>(), 8);
    });
  });

  group('Class WindowsProcessDiscoveryApi construction', () {
    test(
      'Class WindowsProcessDiscoveryApi exposes injected Tool Help calls',
      () {
        var snapshotCalled = false;
        var firstCalled = false;
        var nextCalled = false;
        var closeCalled = false;
        final api = WindowsProcessDiscoveryApi(
          createToolhelp32Snapshot: (flags, processId) {
            snapshotCalled = flags == 2 && processId == 0;
            return Pointer<Void>.fromAddress(1);
          },
          process32FirstW: (_, __) {
            firstCalled = true;
            return 1;
          },
          process32NextW: (_, __) {
            nextCalled = true;
            return 0;
          },
          closeHandle: (_) {
            closeCalled = true;
            return 1;
          },
          getLastError: () => 18,
        );

        expect(api.createToolhelp32Snapshot(2, 0).address, 1);
        expect(
          api.process32FirstW(
            Pointer<Void>.fromAddress(1),
            nullptr.cast<ProcessEntry32W>(),
          ),
          1,
        );
        expect(
          api.process32NextW(
            Pointer<Void>.fromAddress(1),
            nullptr.cast<ProcessEntry32W>(),
          ),
          0,
        );
        expect(api.closeHandle(Pointer<Void>.fromAddress(1)), 1);

        expect(snapshotCalled, isTrue);
        expect(firstCalled, isTrue);
        expect(nextCalled, isTrue);
        expect(closeCalled, isTrue);
        expect(api.getLastError(), 18);
      },
    );
  });

  group('Method system() behaves correctly', () {
    test('Method system() binds the Windows Tool Help exports', () {
      if (!Platform.isWindows) {
        markTestSkipped('The native Tool Help exports require Windows.');
      }

      expect(
        WindowsProcessDiscoveryApi.system(),
        isA<WindowsProcessDiscoveryApi>(),
      );
    });
  });
}
