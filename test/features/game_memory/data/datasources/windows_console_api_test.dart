import 'dart:ffi';
import 'dart:io';

import 'package:ludava/features/game_memory/data/datasources/windows_console_api.dart';
import 'package:test/test.dart';

void main() {
  group('Class WindowsConsoleApi construction', () {
    test('Class WindowsConsoleApi exposes injected console calls', () {
      final handle = Pointer<Void>.fromAddress(1);
      final api = WindowsConsoleApi(
        getStdHandle: (_) => handle,
        getConsoleMode: (_, __) => 1,
        setConsoleMode: (_, __) => 1,
        writeConsoleW: (_, __, ___, ____, _____) => 1,
      );

      expect(api.getStdHandle(-11), same(handle));
      expect(api.getConsoleMode(handle, nullptr), 1);
      expect(api.setConsoleMode(handle, 5), 1);
      expect(api.writeConsoleW(handle, nullptr, 0, nullptr, nullptr), 1);
    });

    test('Class WindowsConsoleApi binds system calls on Windows', () {
      if (!Platform.isWindows) return;

      expect(WindowsConsoleApi.system(), isA<WindowsConsoleApi>());
    });
  });
}
