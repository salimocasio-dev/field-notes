// The dev entry: feature_library alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_library/feature_library.dart';
import 'package:material_ui/material_ui.dart';

/// The dev entry's root widget: the module on [fakeServices].
Widget devApp() =>
    FeatureDevApp(module: const LibraryModule(), services: fakeServices());

void main() => runApp(devApp());
