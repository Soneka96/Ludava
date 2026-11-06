import 'dart:io';

import 'package:ludava_tui/ludava_tui.dart';

/// Starts the Ludava Nocterm trainer or diagnostic CLI.
Future<void> main(List<String> arguments) async {
  exitCode = await LudavaCli().runAsync(arguments);
}
