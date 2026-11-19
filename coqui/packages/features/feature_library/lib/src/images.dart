/// Where the books' pictures come from.
///
/// A page of a book names its picture by a path under `libros/` (`img/la-lluvia-1.png`). `Services` carries no
/// base for the content files and does not grow one: the base is a parameter of this module (decided), which the
/// shell passes. Its default is the old site's relative path with its version tag (`BV` of app.html:305: the
/// books and their pictures are fetched with `?v=39`, so a phone does not keep an old copy).
library;

import 'package:material_ui/material_ui.dart';

/// Turns a page's `img` into the address of the file.
typedef BookImageUrl = String Function(String path);

/// Turns an address into the picture to load (a network image; tests and dev entries give their own).
typedef BookImageProvider = ImageProvider Function(String url);

/// app.html:305 (`BV`) and 337, 358: `libros/` + the path + `?v=39`.
String defaultBookImageUrl(String path) => 'libros/$path?v=39';

/// The picture at [url], loaded over the network.
ImageProvider networkBookImage(String url) => NetworkImage(url);
