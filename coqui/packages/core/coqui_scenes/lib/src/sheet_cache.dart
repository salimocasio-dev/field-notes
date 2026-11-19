import 'package:coqui_pixel/coqui_pixel.dart';

/// The sheets read so far, by scene id. A sheet is data and never changes while the app runs, so it is read once.
final Map<String, Sheet> _sheets = {};

/// The sheet of scene [id] when it has been read, else null.
Sheet? sheetIfRead(String id) => _sheets[id];

/// The sheet of scene [id] when it has been read (`loadSheet`). A scene is made from its sheet, so making one before
/// its sheet is read is an error that says so.
Sheet sheetOf(String id) =>
    _sheets[id] ??
    (throw StateError(
      'the sheet of "$id" is not read yet: await loadScene("$id") (or loadSheet) first',
    ));

/// Reads a sheet from its [text] and keeps it for [sheetOf].
Sheet useSheet(String id, String text) => _sheets[id] = Sheet.parse(text);
