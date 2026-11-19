/// Where the course's files come from, and how they are fetched.
///
/// Until cutover the app reads the old site's files by address (page 11, "Decisions made here"): the app is served
/// at `/field-notes/app/` and the old site's files at `/field-notes/historia/`, so the content base is `../historia/`
/// from the app's base address, on the live site and on a local server that serves the repository at `/field-notes/`
/// alike. The fetch follows the old pages' cache rules ([contentRequest]).
library;

import 'package:coqui_content/coqui_content.dart';

/// The content base: `../historia/` from the app's base address ([appBase], the page's `<base href>`).
Uri contentBaseOf(Uri appBase) => appBase.resolve('../historia/');

/// How one file under `historia/` is asked for: its address and whether the browser's cache may answer.
typedef ContentRequest = ({Uri url, bool noStore});

/// The old pages' cache rules, for the file [path] under `historia/`:
///
/// - `audio/ready.json`: never from the cache (app.html, audioListo; juego.js, loadVoice: `cache:"no-store"`).
/// - `audio/marcas.json` and `datos/*.json` (files the old pages did not have; they are made from the same sources as
///   ready.json and the course, and must agree with them): never from the cache, as ready.json.
/// - `cuentos/*.json` (stories and review sets): never from the cache (juego.js, arranca; cual.js, cualCarga:
///   `cache:"no-store"`).
/// - `libros/*.json`: `?v=39` (app.html, libro: `"libros/"+c+".json"+BV`, `BV="?v=39"`).
/// - Anything else is asked for as it is. A clip's address already carries `?v=<ready.json's v>` (the catalog writes
///   it, as juego.js does) and the clip player resolves it against the content base; a book's picture is
///   [bookImageUrl].
ContentRequest contentRequest(Uri base, String path) {
  if (path.startsWith('libros/') && path.endsWith('.json')) {
    return (url: base.resolve('$path?v=$bookVersion'), noStore: false);
  }
  final noStore =
      path == 'audio/ready.json' ||
      path == 'audio/marcas.json' ||
      path.startsWith('datos/') ||
      path.startsWith('cuentos/');
  return (url: base.resolve(path), noStore: noStore);
}

/// app.html: `BV="?v=39"`, the tag of the books and their pictures.
const String bookVersion = '39';

/// A book page's picture (`img/<file>`, under `libros/`), as app.html asks for it: `libros/<path>?v=39`, from the
/// content base.
String bookImageUrl(Uri base, String path) =>
    base.resolve('libros/$path?v=$bookVersion').toString();

/// Fetches one address as text. Throws when the answer is not 2xx or the network fails.
typedef HttpText = Future<String> Function(Uri url, {required bool noStore});

/// The catalog's fetch: a path under `historia/`, asked for by [contentRequest]'s rules.
FetchText contentFetch(Uri base, HttpText get) => (path) {
  final r = contentRequest(base, path);
  return get(r.url, noStore: r.noStore);
};
