// The dev entry: feature_map alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_map/feature_map.dart';
import 'package:material_ui/material_ui.dart';

/// The dev entry's root widget: the module on [fakeServices].
Widget devApp() =>
    FeatureDevApp(module: const MapModule(), services: fakeServices());

void main() => runApp(devApp());
