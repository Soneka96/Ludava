import 'dart:ffi';
import 'dart:io';

import 'package:ludava/features/rpcs3_connection/data/datasources/windows_process_discovery_api.dart';
import 'package:ludava/features/rpcs3_connection/data/models/windows_process_discovery_call_result.model.dart';
import 'package:test/test.dart';

void main() {
  group('Class ProcessEntry32W construction', () {
    test('Class ProcessEntry32W initializes the Windows x64 layout', () {
      if (sizeOf<IntPtr>() != 8) {
        markTestSkipped('The process layout assertion requires a 64-bit host.');
        return;
      }

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
            return WindowsProcessDiscoveryCallResult<Pointer<Void>>(
              value: Pointer<Void>.fromAddress(1),
              errorCode: 0,
            );
          },
          process32FirstW: (_, __) {
            firstCalled = true;
            return const WindowsProcessDiscoveryCallResult<bool>(
              value: true,
              errorCode: 0,
            );
          },
          process32NextW: (_, __) {
            nextCalled = true;
            return const WindowsProcessDiscoveryCallResult<bool>(
              value: false,
              errorCode: 18,
            );
          },
          closeHandle: (_) {
            closeCalled = true;
            return const WindowsProcessDiscoveryCallResult<bool>(
              value: true,
              errorCode: 0,
            );
          },
        );

        final snapshot = api.createToolhelp32Snapshot(2, 0);
        expect(snapshot.value.address, 1);
        expect(snapshot.errorCode, 0);
        expect(
          api
              .process32FirstW(
                Pointer<Void>.fromAddress(1),
                nullptr.cast<ProcessEntry32W>(),
              )
              .value,
          isTrue,
        );
        final nextResult = api.process32NextW(
          Pointer<Void>.fromAddress(1),
          nullptr.cast<ProcessEntry32W>(),
        );
        expect(nextResult.value, isFalse);
        expect(nextResult.errorCode, 18);
        expect(api.closeHandle(Pointer<Void>.fromAddress(1)).value, isTrue);

        expect(snapshotCalled, isTrue);
        expect(firstCalled, isTrue);
        expect(nextCalled, isTrue);
        expect(closeCalled, isTrue);
      },
    );
  });

  group('Method system() behaves correctly', () {
    test('Method system() binds the Windows Tool Help exports', () {
      if (!Platform.isWindows) {
        markTestSkipped('The native Tool Help exports require Windows.');
        return;
      }

      expect(
        WindowsProcessDiscoveryApi.system(),
        isA<WindowsProcessDiscoveryApi>(),
      );
    });
  });
}
