import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<String> loadReadingAsset(String name) async {
  final path = 'assets/$name';
  try {
    return await rootBundle.loadString(
      'packages/feature_library/$path',
      cache: false,
    );
  } on FlutterError {
    // The standalone dev app bundles its own assets at the root.
    return rootBundle.loadString(path, cache: false);
  }
}
