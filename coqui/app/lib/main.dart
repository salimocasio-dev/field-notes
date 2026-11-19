import 'package:app/src/app.dart';
import 'package:app/src/real_platform.dart';
import 'package:app/src/switches.dart';
import 'package:material_ui/material_ui.dart';

/// Starts Coquí: the switches of the page's address, read once, and the real platform.
void main() {
  final switches = AppSwitches.fromQuery(Uri.base.queryParameters);
  runApp(CoquiApp(platform: realPlatform(switches), switches: switches));
}
