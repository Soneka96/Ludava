import 'package:flutter/widgets.dart';
import 'package:ludava_app/app/ludava_app.dart';

/// Starts the Ludava Flutter desktop application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LudavaApp());
}
