import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ludava/features/game_memory/data/datasources/windows_console_api.dart';

/// Clears the Windows terminal when it supports virtual terminal output.
class WindowsConsoleDataSource {
  /// Creates a console data source with an optional native API seam.
  WindowsConsoleDataSource({WindowsConsoleApi? api, bool? isWindows})
    : _api = api,
      _isWindows = isWindows;

  static const int _standardOutputHandle = -11;
  static const int _enableProcessedOutput = 0x0001;
  static const int _enableVirtualTerminalProcessing = 0x0004;
  static const String _clearAndHome = '\x1b[2J\x1b[H';

  final WindowsConsoleApi? _api;
  final bool? _isWindows;

  /// Clears and homes the screen, returning false when the console cannot.
  bool clearScreen() {
    if (!(_isWindows ?? Platform.isWindows)) return false;
    final api = _api ?? WindowsConsoleApi.system();
    final handle = api.getStdHandle(_standardOutputHandle);
    if (handle == nullptr || handle.address == -1) return false;

    final allocator = calloc<Uint32>();
    try {
      if (api.getConsoleMode(handle, allocator) == 0) return false;
      final originalMode = allocator.value;
      final virtualTerminalMode =
          originalMode |
          _enableProcessedOutput |
          _enableVirtualTerminalProcessing;
      if (api.setConsoleMode(handle, virtualTerminalMode) == 0) return false;

      var cleared = false;
      var restored = false;
      final sequence = _clearAndHome.toNativeUtf16(allocator: calloc);
      final written = calloc<Uint32>();
      try {
        cleared =
            api.writeConsoleW(
                  handle,
                  sequence.cast<Uint16>(),
                  _clearAndHome.length,
                  written,
                  nullptr,
                ) !=
                0 &&
            written.value == _clearAndHome.length;
      } finally {
        calloc.free(written);
        calloc.free(sequence);
        restored = api.setConsoleMode(handle, originalMode) != 0;
      }
      return cleared && restored;
    } finally {
      calloc.free(allocator);
    }
  }
}
