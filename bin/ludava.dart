import 'dart:io';

import 'ludava_cli.dart';

/// Starts the Ludava command-line application.
Future<void> main(List<String> arguments) async {
  exitCode = await LudavaCli().runAsync(arguments);
}
