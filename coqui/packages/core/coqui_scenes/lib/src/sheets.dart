import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/sheet_cache.dart';
import 'package:flutter/services.dart';

/// Where a converted scene's sheet is, as an asset of this package (a copy of `docs/proyecto/pixel/<id>-sheet.json` made
/// by tool/make_sheets.dart).
String sheetAsset(String id) =>
    'packages/coqui_scenes/assets/sheets/$id-sheet.json';

/// The sheet of scene [id], read from this package's assets the first time (page 12, section 5: the data that goes
/// with a set reference). [bundle] is the asset bundle to read from (the root bundle when null).
Future<Sheet> loadSheet(String id, {AssetBundle? bundle}) async {
  final had = sheetIfRead(id);
  if (had != null) return had;
  final b = bundle ?? rootBundle;
  String text;
  try {
    text = await b.loadString(sheetAsset(id));
  } catch (_) {
    // this package run as the app itself (its dev entry): its own assets have no `packages/coqui_scenes/` in front
    text = await b.loadString('assets/sheets/$id-sheet.json');
  }
  return useSheet(id, text);
}
