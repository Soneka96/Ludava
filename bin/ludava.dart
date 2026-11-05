import 'dart:io';

import 'ludava_cli.dart';

/// Starts the Ludava command-line application.
void main(List<String> arguments) {
  exitCode = LudavaCli().run(arguments);
}
