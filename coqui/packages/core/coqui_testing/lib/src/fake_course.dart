import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/src/sample_files.dart';

/// Reads a file of the sample course by its path under `sample/` (for example `cuentos/la-lluvia.json`).
typedef SampleFetch = Future<String> Function(String path);

/// A file of the sample course, exactly as it is in coqui_testing/sample/ (kept as Dart strings in
/// sample_files.dart, so it reads the same in a test, a dev entry and a web build).
Future<String> sampleFile(String path) async {
  final text = sampleFiles[path];
  if (text == null) throw StateError('no file "$path" in the sample course');
  return text;
}

/// The course catalog over the sample course (coqui_testing/sample/, made by coqui/tool/contracts/make_sample.mjs):
/// La casa (El frente's place), stories 1 to 3 (la-lluvia, el-bizcocho, donde-esta-el-pajaro), the review set
/// cual-frente, the book la-lluvia, La casa's call, the level-check items of stories 1 to 3, the fixed lines
/// (datos/fijos.json) and the marks of twenty clips.
///
/// What it does: [load] reads datos/curso.json, the review sets it names, datos/nivel.json, datos/llamadas.json,
/// datos/fijos.json and audio/marcas.json (once; later calls wait for the same load). Before [load] has finished
/// the lists are empty and the lookups give null. [clip] gives a clip with marks: its who, text and habla from the
/// first sample story that has it, its url `audio/<id>.mp3`. [pairFor] matches on [normalize]. [fixedClip] and
/// [goodbyeWords] are fijos.json's `clips` and `despedidas`, unless the constructor is given others. [linesWith]
/// is app.html's oidoEn over the given stories, in the order given (without its ready.json filter).
///
/// What it does not do: a story or book that is not in the sample: [story] throws, [book] gives null. A clip
/// without marks in the sample: [clip] gives null. [fixedClip] throws on a role it does not know. No audio files.
class FakeCourseCatalog implements CourseCatalog {
  FakeCourseCatalog({
    SampleFetch? fetch,
    Map<String, String>? fixedClips,
    List<String>? goodbyeWords,
  }) : fetch = fetch ?? sampleFile,
       _fixedGiven = fixedClips,
       _goodbyeGiven = goodbyeWords;

  final SampleFetch fetch;
  final Map<String, String>? _fixedGiven;
  final List<String>? _goodbyeGiven;
  Map<String, String> _fixed = const {};
  List<String> _goodbye = const [];

  /// The fixed lines by role (fijos.json's `clips`, or what the constructor was given).
  Map<String, String> get fixedClips => _fixedGiven ?? _fixed;

  @override
  List<String> get goodbyeWords => _goodbyeGiven ?? _goodbye;

  Future<void>? _loading;
  bool _loaded = false;
  List<Place> _places = const [];
  Map<String, StoryMeta> _metas = const {};
  List<ReviewPair> _pairs = const [];
  List<LevelItem> _levelItems = const [];
  Map<String, CallBrief> _calls = const {};
  Map<String, ClipInfo> _clips = const {};
  final Map<String, Future<Map<String, dynamic>>> _stories = {};

  /// Whether [load] has finished.
  bool get loaded => _loaded;

  Future<Object?> _json(String path) async => jsonDecode(await fetch(path));

  @override
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final curso = await _json('datos/curso.json') as Map<String, dynamic>;
    _places = [
      for (final l in curso['lugares'] as List)
        Place.fromJson(l as Map<String, dynamic>),
    ];
    _metas = {
      for (final e in (curso['cuentos'] as Map<String, dynamic>).entries)
        e.key: StoryMeta.fromJson(e.key, e.value as Map<String, dynamic>),
    };
    final pairs = <ReviewPair>[];
    for (final f in (curso['cual'] as List).cast<String>()) {
      final j = await story(f);
      for (final it in j['items'] as List) {
        pairs.add(
          ReviewPair.fromJson(
            it as Map<String, dynamic>,
            scene: j['scene'] as String,
          ),
        );
      }
    }
    _pairs = pairs;
    _levelItems = [
      for (final q in await _json('datos/nivel.json') as List)
        LevelItem.fromJson(q as Map<String, dynamic>),
    ];
    final calls = await _json('datos/llamadas.json') as Map<String, dynamic>;
    _calls = {
      for (final e in calls.entries)
        e.key: CallBrief.fromJson(e.key, e.value as Map<String, dynamic>),
    };
    final fijos = await _json('datos/fijos.json') as Map<String, dynamic>;
    _fixed = (fijos['clips'] as Map).cast<String, String>();
    _goodbye = (fijos['despedidas'] as List).cast<String>();
    // who, text and habla: the first sample story (in the course's order) that has the clip
    final lines = <String, Map<String, dynamic>>{};
    for (final id in _metas.keys) {
      final clips =
          ((await story(id))['clips'] as Map?)?.cast<String, dynamic>() ??
          const {};
      clips.forEach(
        (k, v) =>
            lines.putIfAbsent(k, () => (v as Map).cast<String, dynamic>()),
      );
    }
    final marcas = await _json('audio/marcas.json') as Map<String, dynamic>;
    _clips = {
      for (final e in marcas.entries)
        if (lines[e.key] != null)
          e.key: _clip(e.key, lines[e.key]!, (e.value as List).cast<num>()),
    };
    _loaded = true;
  }

  // marcas.json: [startMs, endMs, lengthMs]
  static ClipInfo _clip(
    String id,
    Map<String, dynamic> line,
    List<num> marks,
  ) => ClipInfo(
    id: id,
    who: line['who'] as String,
    text: line['text'] as String,
    habla: line['habla'] as String?,
    startMs: marks[0].toInt(),
    endMs: marks[1].toInt(),
    url: 'audio/$id.mp3',
  );

  @override
  List<Place> get places => _places;

  @override
  StoryMeta? meta(String id) => _metas[id];

  @override
  Future<Map<String, dynamic>> story(String id) => _stories[id] ??= () async {
    try {
      return await _json('cuentos/$id.json') as Map<String, dynamic>;
    } catch (_) {
      _stories.remove(id);
      throw StateError('the story "$id" is not in the sample course');
    }
  }();

  @override
  Future<Book?> book(String id) async {
    try {
      return Book.fromJson(
        await _json('libros/$id.json') as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<ReviewPair> get pairs => _pairs;

  @override
  ReviewPair? pairFor(String word) {
    final n = normalize(word);
    for (final p in _pairs) {
      if (normalize(p.word) == n) return p;
    }
    return null;
  }

  @override
  List<LevelItem> get levelItems => _levelItems;

  @override
  CallBrief? callFor(String placeId) => _calls[placeId];

  @override
  ClipInfo? clip(String id) => _clips[id];

  @override
  String fixedClip(String role) {
    final id = fixedClips[role];
    if (id == null) {
      throw ArgumentError.value(
        role,
        'role',
        'no fixed line for this role in the fake catalog',
      );
    }
    return id;
  }

  // app.html: oidoEn
  @override
  Future<List<HeardLine>> linesWith(
    String word,
    Iterable<String> storyIds, {
    int max = 5,
  }) async {
    final nw = normalize(word);
    final per = <List<HeardLine>>[];
    for (final c in storyIds) {
      Map<String, dynamic> t;
      try {
        t = await story(c);
      } catch (_) {
        continue;
      }
      final clips = (t['clips'] as Map?)?.cast<String, dynamic>() ?? const {};
      final ids = <String>{
        ...((t['leer'] as List?)?.cast<String>() ?? const []),
        ...clips.keys,
      };
      final ls = <HeardLine>[];
      for (final id in ids) {
        final cl = clips[id] as Map?;
        final text = cl?['text'] as String?;
        if (text != null && text.isNotEmpty && normalize(text).contains(nw)) {
          ls.add(
            HeardLine(
              storyId: c,
              storyTitle: (t['title'] as String?) ?? c,
              clipId: id,
              text: text,
            ),
          );
        }
      }
      per.add(ls);
    }
    final seen = <String>{};
    final out = <HeardLine>[];
    for (var r = 0; out.length < max; r++) {
      var any = false;
      for (final ls in per) {
        if (r >= ls.length) continue;
        any = true;
        final x = ls[r];
        if (!seen.add(normalize(x.text))) continue;
        out.add(x);
        if (out.length >= max) break;
      }
      if (!any) break;
    }
    return out;
  }
}
