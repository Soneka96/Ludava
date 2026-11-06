import 'dart:io';

import 'package:ludava/app/ludava_cli.dart';

export 'package:ludava/app/ludava_cli.dart' show LudavaCli;

/// Starts the Ludava CLI composition root.
Future<void> main(List<String> arguments) async {
  exitCode = await LudavaCli().runAsync(arguments);
}
