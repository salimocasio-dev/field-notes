/// Preview content ("previa"): stories of places 4 to 10 whose files are not on the old site yet, bundled in the app so that
/// a published build can play them, silent, before they are recorded (coqui/AGENTS.md, "Preview content (previa)").
///
/// Two kinds of bundled file, both made by `coqui/tool/make_previa.py` and never by hand:
///
/// - `assets/previa/curso.json`, the overlay: for each place id the list of its preview stories in order (`lugares`), and
///   for each preview story its title and minutes (`cuentos`: `{"t": ..., "min": ...}`). Nothing else.
/// - `assets/previa/cuentos/<id>.json`, each story file as its generator writes it, byte for byte.
///
/// The shell wraps the catalog's fetch ([previaFetch]); `coqui_content` knows nothing of it. `datos/curso.json` is the site's
/// file with the overlay merged in ([mergeCourse]) for every overlay story the site's file does not list; `cuentos/<id>.json`
/// of such a story is the bundled file. A story the site lists is the site's alone: the overlay's copy is ignored, so nothing
/// has to be removed when the content lane publishes. With an empty or missing overlay every fetch is the site's, as it was.
library;

import 'dart:convert';

import 'package:coqui_content/coqui_content.dart';
import 'package:flutter/services.dart' show AssetBundle;

/// Reads a bundled preview file by its path under `assets/previa/` (`curso.json`, `cuentos/<id>.json`); null when the
/// app has none.
typedef PreviaRead = Future<String?> Function(String path);

/// No preview at all: every fetch is the site's.
Future<String?> noPrevia(String path) async => null;

/// The preview files bundled in the app ([bundle]: the root bundle in the app).
PreviaRead bundledPrevia(AssetBundle bundle) => (path) async {
  try {
    return await bundle.loadString('assets/previa/$path', cache: false);
  } catch (_) {
    return null; // not bundled
  }
};

/// The overlay: each place's preview stories in order, and each preview story's title and minutes.
class PreviaOverlay {
  const PreviaOverlay({required this.places, required this.metas});

  /// No place, no story.
  static const PreviaOverlay empty = PreviaOverlay(places: {}, metas: {});

  /// `assets/previa/curso.json`. Throws a [FormatException] when it is not the overlay's shape: every listed story has its
  /// `{t, min}`, and every `{t, min}` belongs to a listed story; no story is listed twice.
  factory PreviaOverlay.parse(String text) {
    final j = jsonDecode(text);
    if (j is! Map || j['lugares'] is! Map || j['cuentos'] is! Map) {
      throw const FormatException(
        'previa/curso.json: {"lugares": {...}, "cuentos": {...}} expected',
      );
    }
    final places = <String, List<String>>{};
    final seen = <String>{};
    for (final e in (j['lugares'] as Map).entries) {
      final ids = e.value;
      if (e.key is! String || ids is! List || ids.any((i) => i is! String)) {
        throw FormatException(
          'previa/curso.json: lugares.${e.key} must be a list of story ids',
        );
      }
      for (final i in ids.cast<String>()) {
        if (!seen.add(i)) {
          throw FormatException('previa/curso.json: "$i" is listed twice');
        }
      }
      places[e.key as String] = List.unmodifiable(ids.cast<String>());
    }
    final metas = <String, ({String t, int min})>{};
    for (final e in (j['cuentos'] as Map).entries) {
      final m = e.value;
      if (m is! Map || m['t'] is! String || m['min'] is! int) {
        throw FormatException(
          'previa/curso.json: cuentos.${e.key} must be {"t": <title>, "min": <minutes>}',
        );
      }
      metas[e.key as String] = (t: m['t'] as String, min: m['min'] as int);
    }
    final unmet = seen.difference(metas.keys.toSet());
    final unlisted = metas.keys.toSet().difference(seen);
    if (unmet.isNotEmpty || unlisted.isNotEmpty) {
      throw FormatException(
        'previa/curso.json: stories with no {t, min}: $unmet; {t, min} of no listed story: $unlisted',
      );
    }
    return PreviaOverlay(places: places, metas: metas);
  }

  /// The preview stories of each place, in the overlay's order.
  final Map<String, List<String>> places;

  /// `{t, min}` of each preview story.
  final Map<String, ({String t, int min})> metas;

  bool get isEmpty => metas.isEmpty;
}

/// The site's `datos/curso.json` ([site]) with [overlay] merged in, and the stories that came from the overlay.
///
/// A story the site's file lists anywhere (a place's `cuentos`, `dibujos` or `haz`, the metas `cuentos{}`, the review sets
/// `cual`) is the site's: the overlay's copy is ignored. Each other overlay story goes at the end of its place's `cuentos`
/// (the key is made when the place has none), in the overlay's order, and its `{t, min}` into `cuentos{}`. A place the
/// site's file does not have gets nothing. When nothing is merged, the text is [site] as it was, byte for byte.
({String text, Set<String> preview}) mergeCourse(
  String site,
  PreviaOverlay overlay,
) {
  if (overlay.isEmpty) return (text: site, preview: const {});
  final j = jsonDecode(site);
  if (j is! Map<String, dynamic> || j['lugares'] is! List) {
    return (
      text: site,
      preview: const {},
    ); // not the course: the catalog says why
  }
  final metas = j['cuentos'] is Map<String, dynamic>
      ? j['cuentos'] as Map<String, dynamic>
      : <String, dynamic>{};
  final listed = <String>{
    ...metas.keys,
    if (j['cual'] is List) ...(j['cual'] as List).whereType<String>(),
    for (final l in j['lugares'] as List)
      if (l is Map)
        for (final k in const ['cuentos', 'dibujos', 'haz'])
          if (l[k] is List) ...(l[k] as List).whereType<String>(),
  };
  final preview = <String>{};
  for (final l in j['lugares'] as List) {
    if (l is! Map || l['id'] is! String) continue;
    final add = [
      for (final id in overlay.places[l['id']] ?? const <String>[])
        if (!listed.contains(id)) id,
    ];
    if (add.isEmpty) continue;
    l['cuentos'] = [...?(l['cuentos'] as List?), ...add];
    for (final id in add) {
      final m = overlay.metas[id]!;
      metas[id] = {'t': m.t, 'min': m.min};
    }
    preview.addAll(add);
  }
  if (preview.isEmpty) return (text: site, preview: const {});
  j['cuentos'] = metas;
  return (text: jsonEncode(j), preview: preview);
}

/// The catalog's fetch with the preview content: [site] is the fetch of `historia/<path>` on the site, [read] the bundled
/// preview files.
///
/// The overlay is read once, on the first fetch; one that is missing or broken is empty. `datos/curso.json` is
/// [mergeCourse]'s text; `cuentos/<id>.json` of a story the last course read took from the overlay is the bundled file;
/// everything else is [site]'s. With an empty overlay every path goes to [site] as it is.
FetchText previaFetch(FetchText site, PreviaRead read) {
  Future<PreviaOverlay>? overlay;
  var preview = const <String>{};
  return (path) async {
    final o = await (overlay ??= _overlay(read));
    if (o.isEmpty) return site(path);
    if (path == 'datos/curso.json') {
      final merged = mergeCourse(await site(path), o);
      preview = merged.preview;
      return merged.text;
    }
    final id = _storyOf(path);
    if (id != null && preview.contains(id)) {
      final text = await read('cuentos/$id.json');
      if (text != null) return text;
    }
    return site(path);
  };
}

Future<PreviaOverlay> _overlay(PreviaRead read) async {
  try {
    final text = await read('curso.json');
    return text == null ? PreviaOverlay.empty : PreviaOverlay.parse(text);
  } catch (_) {
    return PreviaOverlay.empty; // a broken overlay is no overlay: the app is as it is without one
  }
}

// `cuentos/<id>.json` -> id
String? _storyOf(String path) {
  const pre = 'cuentos/', post = '.json';
  if (!path.startsWith(pre) || !path.endsWith(post)) return null;
  final id = path.substring(pre.length, path.length - post.length);
  return id.isEmpty || id.contains('/') ? null : id;
}
