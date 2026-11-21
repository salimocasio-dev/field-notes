import 'dart:convert';

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/old_pictures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fixtures/old_sample.dart';
import 'fixtures/sheets.dart';
import 'fixtures/test_scene.dart';

final Map<String, dynamic> _oldSample =
    jsonDecode(oldSampleJson) as Map<String, dynamic>;

/// The scene whose old pictures the browser tests have (the last scene that is not converted), its index (name to
/// file) and its files (file to bytes), from test/support/fixtures/old_sample.dart.
String get oldSampleScene => _oldSample['scene'] as String;
Map<String, String> get oldSampleIndex =>
    (_oldSample['index'] as Map<String, dynamic>).cast<String, String>();
Map<String, String> get oldSampleFiles =>
    (_oldSample['files'] as Map<String, dynamic>).cast<String, String>();

/// An asset bundle that holds only the scenes' sheets (test/support/fixtures/sheets.dart, made by tool/make_sheets.dart)
/// and one scene's old pictures (test/support/fixtures/old_sample.dart, made by tool/make_old_pictures.dart).
class SheetBundle extends CachingAssetBundle {
  ByteData _bytes(List<int> b) => ByteData.sublistView(Uint8List.fromList(b));

  @override
  Future<ByteData> load(String key) async {
    for (final e in sheetTexts.entries) {
      if (key == sheetAsset(e.key)) return _bytes(utf8.encode(e.value));
    }
    final scene = oldSampleScene;
    if (key == oldPictureAsset(scene, 'index.json')) {
      return _bytes(utf8.encode(jsonEncode(oldSampleIndex)));
    }
    for (final e in oldSampleFiles.entries) {
      if (key == oldPictureAsset(scene, e.key)) {
        return _bytes(base64Decode(e.value));
      }
    }
    throw FlutterError('no asset $key in the sheet bundle');
  }
}

/// The bundle a test reads the assets from: in a browser the [SheetBundle] (the root bundle never answers there), on the
/// vm the root bundle itself (null), so the vm tests read the package's real assets.
AssetBundle? testBundle() => kIsWeb ? SheetBundle() : null;

final Map<String, dynamic> _testScene =
    jsonDecode(testSceneJson) as Map<String, dynamic>;

/// The test scene's old pictures (test/support/fixtures/test_scene.dart): its index (name to file) and files (file to
/// bytes).
Map<String, String> get testSceneIndex =>
    (_testScene['index'] as Map<String, dynamic>).cast<String, String>();
Map<String, String> get testSceneFiles =>
    (_testScene['files'] as Map<String, dynamic>).cast<String, String>();

/// The test bundle ([testBundle]: the sheet bundle in a browser, the root bundle on the vm) with the old pictures of the
/// test scene ([testSceneId], a scene that is never converted) added: the tests of the old pictures' path read it, so
/// that they do not depend on which real scenes are converted yet (order 36b).
class TestSceneBundle extends CachingAssetBundle {
  final AssetBundle _base = testBundle() ?? rootBundle;

  ByteData _bytes(List<int> b) => ByteData.sublistView(Uint8List.fromList(b));

  @override
  Future<ByteData> load(String key) async {
    if (key == oldPictureAsset(testSceneId, 'index.json')) {
      return _bytes(utf8.encode(jsonEncode(testSceneIndex)));
    }
    for (final e in testSceneFiles.entries) {
      if (key == oldPictureAsset(testSceneId, e.key)) {
        return _bytes(base64Decode(e.value));
      }
    }
    return _base.load(key);
  }
}
