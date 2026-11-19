// The dev entry: feature_story alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_story/feature_story.dart';
import 'package:material_ui/material_ui.dart';

/// The dev entry's root widget: the module on [fakeServices].
Widget devApp() => FeatureDevApp(
  module: const StoryModule(),
  services: fakeServices(),
  route: const StoryRoute('la-lluvia'),
);

void main() => runApp(devApp());
