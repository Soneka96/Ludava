import 'dart:io';

import 'package:ludava_tui/ludava_tui.dart';

export 'package:ludava_tui/ludava_tui.dart' show LudavaCli;

/// Starts the Ludava TUI package command entry point.
Future<void> main(List<String> arguments) async {
  exitCode = await LudavaCli().runAsync(arguments);
}
