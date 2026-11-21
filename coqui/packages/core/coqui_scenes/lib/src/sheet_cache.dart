import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';

/// The sheets read so far, by scene id. A sheet is data and never changes while the app runs, so it is read once.
final Map<String, Sheet> _sheets = {};

/// The new scenes' sheets read so far (places 4 to 10: [SceneSheet], order 50b), by scene id.
final Map<String, SceneSheet> _sceneSheets = {};

/// The sheet of scene [id] when it has been read, else null.
Sheet? sheetIfRead(String id) => _sheets[id];

/// The sheet of scene [id] when it has been read (`loadSheet`). A scene is made from its sheet, so making one before
/// its sheet is read is an error that says so.
Sheet sheetOf(String id) =>
    _sheets[id] ??
    (throw StateError(
      'the sheet of "$id" is not read yet: await loadScene("$id") (or loadSheet) first',
    ));

/// The sheet of new scene [id] (the content lane's shape, read by [SceneSheet]) when it has been read.
SceneSheet sceneSheetOf(String id) =>
    _sceneSheets[id] ??
    (throw StateError(
      'the sheet of new scene "$id" is not read yet: await loadScene("$id") (or loadSheet) first',
    ));

/// Reads a sheet from its [text] and keeps it for [sheetOf]. A new scene's sheet (no `pairPicture`: the content lane's
/// shape) is read by [SceneSheet] and kept for [sceneSheetOf]; [sheetOf] then gives its `legacy()` sheet.
Sheet useSheet(String id, String text) {
  final Object? v;
  try {
    v = jsonDecode(text);
  } on FormatException catch (e) {
    throw SheetError('the sheet is not JSON: ${e.message}');
  }
  if (v is Map<String, dynamic> && !v.containsKey('pairPicture')) {
    final s = _sceneSheets[id] = SceneSheet.fromJson(v);
    return _sheets[id] = s.legacy();
  }
  return _sheets[id] = Sheet.fromJson(v);
}
