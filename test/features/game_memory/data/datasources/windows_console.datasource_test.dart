import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_console.datasource.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_console_api.dart';
import 'package:test/test.dart';

void main() {
  group('Method clearScreen() behaves correctly', () {
    test('Method clearScreen() clears with VT enabled and restores mode', () {
      final fake = _FakeConsole();

      final cleared =
          WindowsConsoleDataSource(
            api: fake.api,
            isWindows: true,
          ).clearScreen();

      expect(cleared, isTrue);
      expect(fake.standardHandle, -11);
      expect(fake.consoleModes, [0x0005, 0x0001]);
      expect(fake.output, '\x1b[2J\x1b[H');
      expect(fake.writeCount, 7);
    });

    test('Method clearScreen() rejects redirected standard output', () {
      final fake = _FakeConsole()..returnInvalidHandle = true;

      final cleared =
          WindowsConsoleDataSource(
            api: fake.api,
            isWindows: true,
          ).clearScreen();

      expect(cleared, isFalse);
      expect(fake.getModeCalls, 0);
      expect(fake.consoleModes, isEmpty);
    });

    test('Method clearScreen() rejects a non-console output handle', () {
      final fake = _FakeConsole()..getModeResult = 0;

      final cleared =
          WindowsConsoleDataSource(
            api: fake.api,
            isWindows: true,
          ).clearScreen();

      expect(cleared, isFalse);
      expect(fake.consoleModes, isEmpty);
      expect(fake.writeCalls, 0);
    });

    test('Method clearScreen() preserves mode when VT setup fails', () {
      final fake = _FakeConsole()..setModeResult = 0;

      final cleared =
          WindowsConsoleDataSource(
            api: fake.api,
            isWindows: true,
          ).clearScreen();

      expect(cleared, isFalse);
      expect(fake.consoleModes, [0x0005]);
      expect(fake.writeCalls, 0);
    });

    test('Method clearScreen() restores mode after a failed console write', () {
      final fake = _FakeConsole()..writeResult = 0;

      final cleared =
          WindowsConsoleDataSource(
            api: fake.api,
            isWindows: true,
          ).clearScreen();

      expect(cleared, isFalse);
      expect(fake.consoleModes, [0x0005, 0x0001]);
    });

    test('Method clearScreen() rejects a partial console write', () {
      final fake = _FakeConsole()..writtenCount = 2;

      final cleared =
          WindowsConsoleDataSource(
            api: fake.api,
            isWindows: true,
          ).clearScreen();

      expect(cleared, isFalse);
      expect(fake.consoleModes, [0x0005, 0x0001]);
    });

    test('Method clearScreen() reports a failed console mode restoration', () {
      final fake = _FakeConsole()..restoreModeResult = 0;

      final cleared =
          WindowsConsoleDataSource(
            api: fake.api,
            isWindows: true,
          ).clearScreen();

      expect(cleared, isFalse);
      expect(fake.consoleModes, [0x0005, 0x0001]);
    });

    test('Method clearScreen() rejects non-Windows platforms', () {
      final fake = _FakeConsole();

      final cleared =
          WindowsConsoleDataSource(
            api: fake.api,
            isWindows: false,
          ).clearScreen();

      expect(cleared, isFalse);
      expect(fake.standardHandle, isNull);
    });
  });
}

class _FakeConsole {
  final List<int> consoleModes = [];
  int? standardHandle;
  String? output;
  int getModeCalls = 0;
  int writeCalls = 0;
  int writeCount = 0;
  int getModeResult = 1;
  int setModeResult = 1;
  int writeResult = 1;
  int? writtenCount;
  int restoreModeResult = 1;
  bool returnInvalidHandle = false;

  Pointer<Void> get _handle => Pointer<Void>.fromAddress(1);

  WindowsConsoleApi get api => WindowsConsoleApi(
    getStdHandle: (standardHandle) {
      this.standardHandle = standardHandle;
      return returnInvalidHandle ? nullptr : _handle;
    },
    getConsoleMode: (_, mode) {
      getModeCalls++;
      mode.value = 0x0001;
      return getModeResult;
    },
    setConsoleMode: (_, mode) {
      consoleModes.add(mode);
      return consoleModes.length == 1 ? setModeResult : restoreModeResult;
    },
    writeConsoleW: (_, sequence, count, written, __) {
      writeCalls++;
      output = sequence.cast<Utf16>().toDartString();
      writeCount = count;
      written.value = writtenCount ?? (writeResult == 0 ? 0 : count);
      return writeResult;
    },
  );
}
