import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';

/// Reads one file of the course, by its path under `historia/` (for example `cuentos/la-lluvia.json` or
/// `audio/ready.json`), and gives its text. The shell passes a fetch of `historia/<path>` on the site; a test passes
/// a file reader. It throws when the file is not there.
typedef FetchText = Future<String> Function(String path);

/// The course read from the files the old site serves: `datos/*.json`, `cuentos/*.json`, `libros/*.json`,
/// `audio/ready.json`, `audio/marcas.json`. Replaces curso.js, the pair index (`CU.items` of cual.js), `NV`, `LLAMADAS`
/// and the fetches of cuentos/, libros/ and audio/ready.json.
///
/// [load] reads `datos/curso.json`, `datos/nivel.json`, `datos/llamadas.json`, `datos/fijos.json`,
/// `audio/ready.json`, `audio/marcas.json` and the review sets the course names (`cual`, files in `cuentos/`). A story
/// and a book are fetched when asked for and kept: the second ask does not fetch again. Before [load] has finished the
/// lists are empty and the lookups give null.
///
/// Who speaks and what a clip says are in the story files, so a clip's [ClipInfo] has its [ClipInfo.who] and
/// [ClipInfo.text] (and [ClipInfo.habla]) only once a story that has the clip has been read: the review sets by
/// [load], the others by [story], [linesWith] or any call that reads one. Before that [clip] gives what the old code
/// knows of a clip it has not read a line for: its marks and its url, and the line `fijos.json` holds for it under
/// `lineas` (the lines the old code writes in code, juego.js, loadVoice) or, with none, an empty `who` and `text`.
///
/// [load] also reads `datos/repaso.json` (Repaso's games, page 15) into [repaso]. That file is not needed to start:
/// when it is missing or cannot be read, [repaso] is null and nothing else changes (Repaso then plays today's game).
///
/// And it reads `cuentos/palabras-solas.json`, the one file of `cuentos/` the course names nowhere: each tracked word
/// said alone (clips `w_<word>`, for the word tiles of Repaso). It is not a story and not a review set (no [meta], no
/// pair, no place lists it); its clips are known like any other, by [clip], with their who and text from load on. When
/// it is missing or cannot be read nothing else changes (its clips then have no line, as any clip no story has been read
/// for).
/// [load] also reads the optional `idioma` object from `datos/curso.json` into [language] (implementing
/// [LanguageCatalog], defaulting to [Language.spanish] when missing) and uses its `callAgentId` as the default for
/// calls in `datos/llamadas.json`.
///
/// Implements [CallsCatalog]: `datos/llamadas.json` maps each place id to either a legacy single call object or a JSON
/// array of call objects (`main` and smaller calls). [callsFor] returns every call for a place in order; [callFor]
/// returns its main call (or the first call when none sets `isMain`).
class ContentCatalog
    implements CourseCatalog, RepasoCatalog, LanguageCatalog, CallsCatalog {
  ContentCatalog(this._fetch);

  final FetchText _fetch;

  Future<void>? _loading;
  bool _loaded = false;
  Language _language = Language.spanish;
  List<Place> _places = const [];
  Map<String, StoryMeta> _metas = const {};
  List<ReviewPair> _pairs = const [];
  Map<String, ReviewPair> _pairByWord = const {};
  List<String> _pairNormalized = const [];
  List<LevelItem> _levelItems = const [];
  Map<String, CallBrief> _calls = const {};
  Map<String, List<CallBrief>> _callsByPlace = const {};
  Map<String, String> _fixed = const {};
  // fijos.json, lineas: the lines the old code writes in code, by clip id
  Map<String, _Line> _written = const {};
  List<String> _goodbye = const [];
  RepasoData? _repaso;
  // cuentos/palabras-solas.json: the lines of the words said alone, by clip id (empty when the file is not there)
  Map<String, _Line> _alone = const {};

  // audio/ready.json: the clips that have a recording (null: the file could not be read), and its `v`
  Set<String>? _have;
  String _version = '0';
  // audio/marcas.json: id -> [startMs, endMs, lengthMs]
  Map<String, List<int>> _marks = const {};
  // who, text and habla of the lines read so far (the first story that has an id gives it)
  final Map<String, _Line> _lines = {};

  final Map<String, Future<Map<String, dynamic>>> _stories = {};
  final Map<String, Future<Book?>> _books = {};
  final Map<String, List<_StoryLine>> _heardIndex = {};

  /// Whether [load] has finished.
  bool get loaded => _loaded;

  @override
  Language get language => _language;

  @override
  Future<void> load() async {
    final running = _loading;
    if (running != null) return running;
    final first = _loading = _load();
    try {
      await first;
    } catch (_) {
      if (identical(_loading, first)) _loading = null;
      rethrow;
    }
  }

  Future<void> _load() async {
    final curso = _object(await _json('datos/curso.json'), 'datos/curso.json');
    final language = _parseLanguage(curso['idioma']);
    final places = [
      for (final l in curso['lugares'] as List)
        Place.fromJson(Map<String, dynamic>.from(l as Map)),
    ];
    final metas = {
      for (final e in (curso['cuentos'] as Map).entries)
        e.key as String: StoryMeta.fromJson(
          e.key as String,
          Map<String, dynamic>.from(e.value as Map),
        ),
    };
    final sets = _strings(curso['cual']);

    // everything else at once; the first failure (in this order) is the one thrown
    final nivel = _json('datos/nivel.json');
    final llamadas = _json('datos/llamadas.json');
    final fijos = _json('datos/fijos.json');
    final ready = _readReady();
    final marcas = _json('audio/marcas.json');
    final repaso = _readRepaso();
    final alone = _readAlone();
    final reviews = [for (final f in sets) story(f)];
    for (final f in <Future<Object?>>[
      nivel,
      llamadas,
      fijos,
      ready,
      marcas,
      ...reviews,
    ]) {
      f.ignore();
    }

    final levelItems = [
      for (final q in await nivel as List)
        LevelItem.fromJson(Map<String, dynamic>.from(q as Map)),
    ];
    final calls = _object(await llamadas, 'datos/llamadas.json');
    final fixed = _object(await fijos, 'datos/fijos.json');
    final readyJson = await ready;
    final marks = _object(await marcas, 'audio/marcas.json');
    final files = [for (final r in reviews) await r];

    // cual.js, cualCarga: the pairs of every review set, in the order curso.json names them
    final pairs = <ReviewPair>[];
    for (final j in files) {
      final scene = j['scene'] as String;
      for (final it in j['items'] as List) {
        pairs.add(
          ReviewPair.fromJson(
            Map<String, dynamic>.from(it as Map),
            scene: scene,
          ),
        );
      }
    }

    final pairNormalized = [for (final p in pairs) language.normalize(p.word)];
    final parsedCallsByPlace = <String, List<CallBrief>>{};
    final parsedMainCalls = <String, CallBrief>{};
    final seenCallIds = <String>{};
    for (final e in calls.entries) {
      final list = _parsePlaceCalls(e.key, e.value, language, seenCallIds);
      parsedCallsByPlace[e.key] = List<CallBrief>.unmodifiable(list);
      final main = _mainCallOf(list);
      if (main != null) parsedMainCalls[e.key] = main;
    }

    _language = language;
    _places = places;
    _metas = metas;
    _pairs = pairs;
    _pairNormalized = pairNormalized;
    // app.html, pares(): m.set(it.w, it) — the last item with a word is the one the word gives
    _pairByWord = {for (final p in pairs) p.word: p};
    _levelItems = levelItems;
    _calls = parsedMainCalls;
    _callsByPlace = parsedCallsByPlace;
    _fixed = Map<String, String>.from(fixed['clips'] as Map);
    _written = _writtenLines(fixed['lineas']);
    _goodbye = _strings(fixed['despedidas']);
    _have = readyJson.have;
    _version = readyJson.version;
    _marks = {
      for (final e in marks.entries)
        e.key: [for (final m in e.value as List) (m as num).toInt()],
    };
    _repaso = await repaso;
    _alone = await alone;
    _loaded = true;
  }

  Future<Object?> _json(String path) async {
    final text = await _fetch(path);
    try {
      return jsonDecode(text);
    } on FormatException catch (e) {
      throw FormatException('$path: ${e.message}', text, e.offset);
    }
  }

  static Map<String, dynamic> _object(Object? j, String path) {
    if (j is Map) return Map<String, dynamic>.from(j);
    throw FormatException('$path: a JSON object was expected');
  }

  // fijos.json, lineas: { <clip id>: { who, text } }. A file without it has none.
  static Map<String, _Line> _writtenLines(Object? j) {
    if (j == null) return const {};
    if (j is! Map) {
      throw const FormatException(
        'datos/fijos.json: lineas must be an object of clip id -> {who, text}',
      );
    }
    return {
      for (final e in j.entries)
        e.key as String: e.value is Map
            ? _Line.from(e.value as Map)
            : throw FormatException(
                'datos/fijos.json: lineas.${e.key} must be {who, text}',
              ),
    };
  }

  // datos/repaso.json: Repaso's games. Missing or broken, it is null: the load goes on without it.
  Future<RepasoData?> _readRepaso() async {
    try {
      return RepasoData.fromJson(
        _object(await _json('datos/repaso.json'), 'datos/repaso.json'),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  RepasoData? get repaso => _repaso;

  // the address of the file of the words said alone, under historia/ (the course names it nowhere)
  static const _solasPath = 'cuentos/palabras-solas.json';

  // cuentos/palabras-solas.json: { clips: { <clip id>: { who, text } } }. Missing or broken, it has no line: the load goes on.
  Future<Map<String, _Line>> _readAlone() async {
    try {
      final clips = _object(await _json(_solasPath), _solasPath)['clips'];
      return {
        if (clips is Map)
          for (final e in clips.entries)
            if (e.value is Map) e.key as String: _Line.from(e.value as Map),
      };
    } catch (_) {
      return const {};
    }
  }

  // app.html, audioListo: audio/ready.json, read once; a file that cannot be read is null, and then no clip has a
  // recording and oidoEn does not filter. `v` goes into every clip's url (juego.js, loadVoice: `j.v||0`).
  Future<({Set<String>? have, String version})> _readReady() async {
    Object? j;
    try {
      j = await _json('audio/ready.json');
    } catch (_) {
      j = null;
    }
    if (j is! Map) return (have: null, version: '0');
    final clips = j['clips'];
    return (
      have: {if (clips is List) ...clips.cast<String>()},
      version: _versionText(j['v']),
    );
  }

  // JavaScript's `j.v||0` written into a string: a missing, zero or empty `v` is 0
  static String _versionText(Object? v) {
    if (v == null || v == false || v == '' || v == 0) return '0';
    if (v is double && v.isFinite && v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return '$v';
  }

  @override
  List<Place> get places => _places;

  @override
  StoryMeta? meta(String id) => _metas[id];

  /// The story file `cuentos/<id>.json` as it is (do not change it: it is kept and given again). A review set
  /// (`cual-*`) is read the same way. Fetched once; a failed read throws and is not kept, so the next ask tries again.
  @override
  Future<Map<String, dynamic>> story(String id) {
    final kept = _stories[id];
    if (kept != null) return kept;
    final reading = _readStory(id);
    _stories[id] = reading;
    reading.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_stories[id], reading)) _stories.remove(id);
      },
    );
    return reading;
  }

  Future<Map<String, dynamic>> _readStory(String id) async {
    final path = 'cuentos/$id.json';
    final j = _object(await _json(path), path);
    // juego.js: LINES = S.clips — who, text and habla of each line
    final clips = j['clips'];
    if (clips is Map) {
      clips.forEach((k, v) {
        if (v is Map) _lines.putIfAbsent(k as String, () => _Line.from(v));
      });
    }
    return j;
  }

  /// app.html, libro: `libros/<id>.json`, fetched once. A book that is not there, or cannot be read, is null (and
  /// stays null: the old page keeps the answer for the page's life).
  @override
  Future<Book?> book(String id) => _books[id] ??= _readBook(id);

  Future<Book?> _readBook(String id) async {
    try {
      final path = 'libros/$id.json';
      return Book.fromJson(_object(await _json(path), path));
    } catch (_) {
      return null;
    }
  }

  @override
  List<ReviewPair> get pairs => _pairs;

  /// app.html, pares().m.get(word), matched on [Language.normalize]. Two pairs can have one normalised word (a word
  /// and the same word without its accent): the one whose word is exactly [word] is the one the old page gives; if
  /// none is, the first of the pairs that match.
  @override
  ReviewPair? pairFor(String word) {
    final exact = _pairByWord[word];
    if (exact != null) return exact;
    final n = _language.normalize(word);
    for (var i = 0; i < _pairs.length; i++) {
      if (_pairNormalized[i] == n) return _pairs[i];
    }
    return null;
  }

  @override
  List<LevelItem> get levelItems => _levelItems;

  @override
  CallBrief? callFor(String placeId) => _calls[placeId];

  @override
  List<CallBrief> callsFor(String placeId) =>
      _callsByPlace[placeId] ?? const <CallBrief>[];

  /// A clip that has a recording (it is in `audio/ready.json`) and marks (`audio/marcas.json`); otherwise null.
  /// Its `who`, `text` and `habla` are those of the first story read that has the line. Until one has been, they are
  /// the line `palabras-solas.json` gives it (a word said alone), else the line `fijos.json` gives it under `lineas`,
  /// and empty where it has none (juego.js: a story's own line wins, `!LINES.<id>`).
  /// The url is juego.js's: `audio/<id>.mp3?v=<ready.json's v>`.
  @override
  ClipInfo? clip(String id) {
    final marks = _marks[id];
    final have = _have;
    if (marks == null || have == null || !have.contains(id)) return null;
    final line = _lines[id] ?? _alone[id] ?? _written[id];
    return ClipInfo(
      id: id,
      who: line?.who ?? '',
      text: line?.text ?? '',
      habla: line?.habla,
      startMs: marks[0],
      endMs: marks[1],
      url: 'audio/$id.mp3?v=$_version',
    );
  }

  /// `fijos.json`, `clips`: the clip id under [role]. A role ending in `_prefix` holds the start of an id, not an id.
  /// Throws an [ArgumentError] naming the role when there is none.
  @override
  String fixedClip(String role) {
    final id = _fixed[role];
    if (id == null) {
      throw ArgumentError.value(
        role,
        'role',
        _loaded
            ? 'no fixed line for this role in datos/fijos.json'
            : 'no fixed line for this role: the catalog has not been loaded',
      );
    }
    return id;
  }

  @override
  List<String> get goodbyeWords => _goodbye;

  /// app.html, oidoEn: up to [max] lines of the played stories whose text holds [word] (matched on
  /// [Language.normalize], whole words), one line from each story first, then the next of each; a text already given
  /// is skipped.
  ///
  /// As oidoEn, the stories are the `cuentos` of the places, in the course's order, whatever the order of [storyIds]:
  /// an id that is not one of them (a picture story, a routine) is left out, and so is a story that cannot be read.
  /// A line is kept only when it has a recording (audio/ready.json), unless that file could not be read.
  @override
  Future<List<HeardLine>> linesWith(
    String word,
    Iterable<String> storyIds, {
    int max = 5,
  }) async {
    final played = storyIds.toSet();
    final nw = _language.normalize(word);
    final have = _have;
    final per = <List<HeardLine>>[];
    for (final c in [for (final l in _places) ...l.stories]) {
      if (!played.contains(c)) continue;
      final Map<String, dynamic> file;
      try {
        file = await story(c);
      } catch (_) {
        continue; // oidoEn skips a story whose file did not arrive (STOV[c] is not there)
      }
      final lines = _heard(c, file);
      final title = _metas[c]?.title ?? '';
      per.add([
        for (final l in lines)
          if ((have == null || have.contains(l.id)) &&
              l.normalized.contains(nw))
            HeardLine(
              storyId: c,
              storyTitle: title,
              clipId: l.id,
              text: l.text,
            ),
      ]);
    }
    final seen = <String>{};
    final out = <HeardLine>[];
    for (var r = 0; out.length < max; r++) {
      var any = false;
      for (final ls in per) {
        if (r >= ls.length) continue;
        any = true;
        final x = ls[r];
        if (!seen.add(_language.normalize(x.text))) continue;
        out.add(x);
        if (out.length >= max) break;
      }
      if (!any) break;
    }
    return out;
  }

  // oidoEn: [...new Set([...(T.leer||[]), ...Object.keys(T.clips)])], the ones with a text
  List<_StoryLine> _heard(String c, Map<String, dynamic> t) {
    final kept = _heardIndex[c];
    if (kept != null) return kept;
    final clips = t['clips'] is Map ? t['clips'] as Map : const {};
    final ids = <String>{
      if (t['leer'] is List) ...(t['leer'] as List).cast<String>(),
      ...clips.keys.cast<String>(),
    };
    final out = <_StoryLine>[];
    for (final id in ids) {
      final cl = clips[id];
      final text = cl is Map ? cl['text'] : null;
      if (text is String && text.isNotEmpty) {
        out.add(_StoryLine(id, text, _language.normalize(text)));
      }
    }
    return _heardIndex[c] = out;
  }
}

Language _parseLanguage(Object? raw) {
  if (raw == null) return Language.spanish;
  if (raw is! Map) {
    throw const FormatException(
      'datos/curso.json: idioma must be a JSON object',
    );
  }
  final code = _requiredLanguageString(raw, 'code');
  final englishName = _requiredLanguageString(raw, 'englishName');
  final nativeName = _requiredLanguageString(raw, 'nativeName');
  final recognitionLocale = _requiredLanguageString(raw, 'recognitionLocale');
  final direction = _parseDirection(raw['direction']);
  final script = _requiredLanguageString(raw, 'script');
  final partnerName = _requiredLanguageString(raw, 'partnerName');
  final callAgentId = _requiredLanguageString(raw, 'callAgentId');
  final micWords = _languageStringMap(raw, 'micWords', required: true);
  final tabNames = _languageStringMap(raw, 'tabNames', required: true);
  final a11yWords = _languageStringMap(raw, 'a11yWords', required: false);
  try {
    return Language(
      code: code,
      englishName: englishName,
      nativeName: nativeName,
      recognitionLocale: recognitionLocale,
      direction: direction,
      script: script,
      partnerName: partnerName,
      callAgentId: callAgentId,
      micWords: micWords,
      tabNames: tabNames,
      a11yWords: a11yWords,
    );
  } on ArgumentError catch (e) {
    throw FormatException(
      'datos/curso.json: idioma${e.name != null ? '.${e.name}' : ''}: ${e.message}',
    );
  }
}

LanguageDirection _parseDirection(Object? raw) => switch (raw) {
  'ltr' => LanguageDirection.ltr,
  'rtl' => LanguageDirection.rtl,
  _ => throw const FormatException(
    'datos/curso.json: idioma.direction must be "ltr" or "rtl"',
  ),
};

String _requiredLanguageString(Map<dynamic, dynamic> m, String key) {
  final v = m[key];
  if (v is! String || v.trim().isEmpty) {
    throw FormatException(
      'datos/curso.json: idioma.$key must be a non-empty string',
    );
  }
  return v;
}

Map<String, String> _languageStringMap(
  Map<dynamic, dynamic> m,
  String key, {
  required bool required,
}) {
  final v = m[key];
  if (v == null) {
    if (required) {
      throw FormatException(
        'datos/curso.json: idioma.$key must be an object of string -> string',
      );
    }
    return const <String, String>{};
  }
  if (v is! Map) {
    throw FormatException(
      'datos/curso.json: idioma.$key must be an object of string -> string',
    );
  }
  final out = <String, String>{};
  for (final e in v.entries) {
    if (e.key is! String || e.value is! String) {
      throw FormatException(
        'datos/curso.json: idioma.$key.${e.key} must be a string',
      );
    }
    out[e.key as String] = e.value as String;
  }
  return out;
}

List<CallBrief> _parsePlaceCalls(
  String placeId,
  Object? value,
  Language language,
  Set<String> seenCallIds,
) {
  if (value is Map) {
    final brief = _parseCallBrief(
      placeId,
      value,
      language,
      context: 'datos/llamadas.json: $placeId',
      legacyObject: true,
    );
    if (!brief.isMain) {
      throw FormatException(
        'datos/llamadas.json: $placeId: legacy object entry cannot set isMain: false',
      );
    }
    if (!seenCallIds.add(brief.id)) {
      throw FormatException(
        'datos/llamadas.json: duplicate call id "${brief.id}"',
      );
    }
    return [brief];
  }
  if (value is List) {
    final out = <CallBrief>[];
    var mainCount = 0;
    for (var i = 0; i < value.length; i++) {
      final brief = _parseCallBrief(
        placeId,
        value[i],
        language,
        context: 'datos/llamadas.json: $placeId[$i]',
        legacyObject: false,
      );
      if (!seenCallIds.add(brief.id)) {
        throw FormatException(
          'datos/llamadas.json: duplicate call id "${brief.id}"',
        );
      }
      if (brief.isMain) {
        mainCount++;
        if (mainCount > 1) {
          throw FormatException(
            'datos/llamadas.json: $placeId has more than one main call',
          );
        }
      }
      out.add(brief);
    }
    return out;
  }
  throw FormatException(
    'datos/llamadas.json: $placeId must be a JSON object or array',
  );
}

CallBrief? _mainCallOf(List<CallBrief> calls) {
  if (calls.isEmpty) return null;
  for (final c in calls) {
    if (c.isMain) return c;
  }
  return calls.first;
}

CallBrief _parseCallBrief(
  String placeId,
  Object? value,
  Language language, {
  required String context,
  required bool legacyObject,
}) {
  final raw = ContentCatalog._object(value, context);
  final primary = raw['agentId'];
  if (primary != null && primary is! String) {
    throw FormatException('$context.agentId must be a string');
  }
  final legacy = raw['agentid'];
  if (legacy != null && legacy is! String) {
    throw FormatException('$context.agentid must be a string');
  }
  if (!legacyObject) {
    final id = raw['id'];
    if (id != null && (id is! String || id.trim().isEmpty)) {
      throw FormatException('$context.id must be a non-empty string');
    }
    final title = raw['title'];
    if (title != null && title is! String) {
      throw FormatException('$context.title must be a string');
    }
    final jobEn = raw['jobEn'];
    if (jobEn != null && jobEn is! String) {
      throw FormatException('$context.jobEn must be a string');
    }
    final minutes = raw['minutos'];
    if (minutes is! num ||
        !minutes.isFinite ||
        minutes != minutes.truncateToDouble() ||
        minutes <= 0) {
      throw FormatException('$context.minutos must be a positive integer');
    }
    if (raw['job'] is! String) {
      throw FormatException('$context.job must be a string');
    }
    if (raw['opening'] is! String) {
      throw FormatException('$context.opening must be a string');
    }
    final photo = raw['foto'];
    if (photo != null && photo is! String) {
      throw FormatException('$context.foto must be a string');
    }
    final isMain = raw['isMain'];
    if (isMain != null && isMain is! bool) {
      throw FormatException('$context.isMain must be a boolean');
    }
  }
  final perCall = (primary is String && primary.trim().isNotEmpty)
      ? primary
      : (legacy is String && legacy.trim().isNotEmpty)
      ? legacy
      : null;
  final fallback = language.callAgentId.trim().isNotEmpty
      ? language.callAgentId
      : null;
  return CallBrief.fromJson(placeId, raw, agentId: perCall ?? fallback);
}

/// The strings of a JSON list; a missing list is empty.
List<String> _strings(Object? v) =>
    v == null ? <String>[] : [for (final x in v as List) x as String];

class _Line {
  _Line(this.who, this.text, this.habla);

  factory _Line.from(Map<dynamic, dynamic> v) => _Line(
    v['who'] is String ? v['who'] as String : '',
    v['text'] is String ? v['text'] as String : '',
    v['habla'] as String?,
  );

  final String who;
  final String text;
  final String? habla;
}

class _StoryLine {
  _StoryLine(this.id, this.text, this.normalized);

  final String id;
  final String text;
  final String normalized;
}
