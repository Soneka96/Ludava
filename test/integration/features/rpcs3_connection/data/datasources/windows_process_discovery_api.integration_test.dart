import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava/features/rpcs3_connection/data/datasources/windows_process_discovery_api.dart';
import 'package:test/test.dart';

void main() {
  group('Integration Windows process discovery API behaves correctly', () {
    test(
      'Integration system API pairs invalid snapshot status and error on Windows',
      () {
        if (!Platform.isWindows || sizeOf<IntPtr>() != 8) {
          markTestSkipped('The Tool Help API requires 64-bit Windows.');
          return;
        }

        final api = WindowsProcessDiscoveryApi.system();
        final result = api.createToolhelp32Snapshot(0x18, 0xFFFFFFFF);
        if (result.value.address != Pointer<Void>.fromAddress(-1).address) {
          api.closeHandle(result.value);
        }

        expect(result.value.address, Pointer<Void>.fromAddress(-1).address);
        expect(result.errorCode, 87);
      },
    );

    test(
      'Integration system API captures end-of-snapshot error with next status',
      () {
        if (!Platform.isWindows || sizeOf<IntPtr>() != 8) {
          markTestSkipped('The Tool Help API requires 64-bit Windows.');
          return;
        }

        final api = WindowsProcessDiscoveryApi.system();
        final snapshot = api.createToolhelp32Snapshot(2, 0);
        expect(snapshot.errorCode, 0);
        expect(snapshot.value.address, isNot(0));
        expect(
          snapshot.value.address,
          isNot(Pointer<Void>.fromAddress(-1).address),
        );

        final entry = calloc<ProcessEntry32W>();
        try {
          entry.ref.dwSize = sizeOf<ProcessEntry32W>();
          final firstResult = api.process32FirstW(snapshot.value, entry);
          expect(firstResult.value, isTrue);
          expect(firstResult.errorCode, 0);

          var nextResult = firstResult;
          while (nextResult.value) {
            nextResult = api.process32NextW(snapshot.value, entry);
          }
          expect(nextResult.errorCode, 18);
        } finally {
          calloc.free(entry);
          expect(api.closeHandle(snapshot.value).value, isTrue);
        }
      },
    );

    test(
      'Integration system API captures Process32FirstW invalid handle error',
      () {
        if (!Platform.isWindows || sizeOf<IntPtr>() != 8) {
          markTestSkipped('The Tool Help API requires 64-bit Windows.');
          return;
        }

        final api = WindowsProcessDiscoveryApi.system();
        final snapshot = api.createToolhelp32Snapshot(2, 0);
        final entry = calloc<ProcessEntry32W>();
        try {
          entry.ref.dwSize = sizeOf<ProcessEntry32W>();
          expect(api.closeHandle(snapshot.value).value, isTrue);

          final result = api.process32FirstW(snapshot.value, entry);

          expect(result.value, isFalse);
          expect(result.errorCode, 6);
        } finally {
          calloc.free(entry);
        }
      },
    );

    test(
      'Integration system API captures Process32NextW invalid handle error',
      () {
        if (!Platform.isWindows || sizeOf<IntPtr>() != 8) {
          markTestSkipped('The Tool Help API requires 64-bit Windows.');
          return;
        }

        final api = WindowsProcessDiscoveryApi.system();
        final snapshot = api.createToolhelp32Snapshot(2, 0);
        final entry = calloc<ProcessEntry32W>();
        try {
          entry.ref.dwSize = sizeOf<ProcessEntry32W>();
          expect(api.process32FirstW(snapshot.value, entry).value, isTrue);
          expect(api.closeHandle(snapshot.value).value, isTrue);

          final result = api.process32NextW(snapshot.value, entry);

          expect(result.value, isFalse);
          expect(result.errorCode, 6);
        } finally {
          calloc.free(entry);
        }
      },
    );

    test('Integration system API captures a repeated close error', () {
      if (!Platform.isWindows || sizeOf<IntPtr>() != 8) {
        markTestSkipped('CloseHandle requires 64-bit Windows.');
        return;
      }

      final api = WindowsProcessDiscoveryApi.system();
      final snapshot = api.createToolhelp32Snapshot(2, 0);
      expect(snapshot.value.address, isNot(0));
      expect(
        snapshot.value.address,
        isNot(Pointer<Void>.fromAddress(-1).address),
      );
      expect(api.closeHandle(snapshot.value).value, isTrue);
      final result = api.closeHandle(snapshot.value);

      expect(result.value, isFalse);
      expect(result.errorCode, 6);
    });
  });
}
