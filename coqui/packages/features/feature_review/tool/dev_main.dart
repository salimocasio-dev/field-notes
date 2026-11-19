// The dev entry: feature_review alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_review/feature_review.dart';
import 'package:material_ui/material_ui.dart';

/// The dev entry's root widget: the module on [fakeServices].
Widget devApp() => FeatureDevApp(
  module: const ReviewModule(),
  services: fakeServices(),
  route: const ReviewRoute(),
);

void main() => runApp(devApp());
