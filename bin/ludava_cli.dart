import 'dart:io';

import 'package:ludava/app/ludava_cli.dart';

export 'package:ludava/app/ludava_cli.dart' show LudavaCli;

/// Starts the Ludava CLI composition root.
void main(List<String> arguments) {
  exitCode = LudavaCli().run(arguments);
}
