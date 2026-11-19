import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fixtures/sheets.dart';

/// An asset bundle that holds only the scenes' sheets (test/support/fixtures/sheets.dart, made by tool/make_sheets.dart).
class SheetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    for (final e in sheetTexts.entries) {
      if (key == sheetAsset(e.key)) {
        return ByteData.sublistView(Uint8List.fromList(utf8.encode(e.value)));
      }
    }
    throw FlutterError('no asset $key in the sheet bundle');
  }
}

/// The bundle a test reads the sheets from: in a browser the [SheetBundle] (the root bundle never answers there), on
/// the vm the root bundle itself (null), so the vm tests read the package's real assets.
AssetBundle? testBundle() => kIsWeb ? SheetBundle() : null;
