// The course the dev entry shows: the sample course of coqui_testing, or the real files of historia/ when the
// page is opened with ?content=real (the screenshot script serves them; nothing of historia/ is copied here).
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The sample course, with its book readable. The sample holds one book, La lluvia, and its own verdict
/// (`lee`) is false, so the shelf would show no Read button; the dev entry turns it on to show the reader.
class DevCatalog extends FakeCourseCatalog {
  DevCatalog({super.fetch});

  /// Over the real files, which the page's server gives under `assets/content/` (the same paths as historia/).
  DevCatalog.real()
    : super(fetch: (path) => rootBundle.loadString('content/$path'));

  /// Whether the books keep the verdict they carry (the real files) or all read (the sample).
  bool get keepsVerdict => false;

  @override
  Future<Book?> book(String id) async {
    final b = await super.book(id);
    if (b != null && !keepsVerdict) b.readable = true;
    return b;
  }
}

/// The real files: each book keeps its own `lee`.
class RealCatalog extends DevCatalog {
  RealCatalog() : super.real();

  @override
  bool get keepsVerdict => true;
}
