import 'dart:io';

/// Clears and homes a terminal when it supports ANSI screen control.
class WindowsConsoleDataSource {
  static const String _clearAndHome = '\x1b[2J\x1b[H';

  /// Clears and homes the active screen, returning false when unsupported.
  bool clearScreen({StringSink? output, bool? isTerminal}) {
    final terminalOutput = output ?? stdout;
    final supportsAnsi =
        isTerminal ??
        (stdout.hasTerminal && Platform.environment['TERM'] != 'dumb');
    if (!supportsAnsi) return false;

    terminalOutput.write(_clearAndHome);
    return true;
  }
}
