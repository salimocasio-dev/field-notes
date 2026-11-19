import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/src/fake_platform.dart';

/// A progress store in memory, holding today's JSON shape (palabras.js, `db`).
///
/// It is NOT the scheduler (that is order 16, coqui_progress). What it does:
/// - Loads and resets as palabras.js does: the defaults
///   `{palabras:{}, dias:{}, cuentos:{}, ajustes:{min:30,todo:0,bienvenida:0,habla:1}, minutos:0, v:1}`,
///   with a given JSON laid over them; unknown keys are kept, on every key of the store and of each record.
/// - [heard]: makes the record if new (primera = now), `oida` + 1, ear `etapa` at least 1.
/// - [answer]: `n` + 1, `bien` + 1 when right, `ultima` = now; `etapa` at least 2 when right, at least 1 when not.
/// - [storyFinished]: [heard] for its focus and back-again words, [answer] (ear) for each decision with a word,
///   the story's record (`n` + 1, `primera`, `ultima`, `perdido` = lost), and the day's count + 1.
/// - [presume]: each word's ear at `etapa` 3 (`paso` at least 2, `presunta` 1) when it was lower; each story
///   with no plays counted as played once (`presunto` 1); `nivel` = {t, log, historias}.
/// - [due] is PAL.vence over the records as they stand; [openForSpeaking] is PAL.abiertaHabla.
/// - [listened] (`oidos`), [markRead] (`leidos`: the time, once), [addMinutes] (`minutos`), [add] (`extra`),
///   settings (`ajustes`), [export], [import], [reset], as palabras.js and app.html keep them.
/// - Day keys are the UTC date of [Clock.nowMs] (palabras.js's toISOString); [streak] counts UTC days back from
///   today that have an entry in `dias`.
///
/// What it does NOT do: no gaps, no `due` dates, no steps (`paso` on answers), no runs (`seguidas`, `fallos`),
/// no `aciertos`, no parking or flag, no "next morning at 4 am" and none of the old local-time mix. A test that
/// needs a word due seeds it with [put]. Nothing is written to a [KeyValueStore].
class FakeProgressStore implements ProgressStore {
  FakeProgressStore({Clock? clock, String? json})
    : clock = clock ?? FakeClock() {
    _db = _load(json);
  }

  final Clock clock;
  late Map<String, dynamic> _db;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// How many times it saved (one a change).
  int saves = 0;

  static Map<String, dynamic> _defaults() => {
    'palabras': <String, dynamic>{},
    'dias': <String, dynamic>{},
    'cuentos': <String, dynamic>{},
    'ajustes': _defaultSettings(),
    'minutos': 0,
    'v': 1,
  };

  static Map<String, dynamic> _defaultSettings() => {
    'min': 30,
    'todo': 0,
    'bienvenida': 0,
    'habla': 1,
  };

  // palabras.js: db=Object.assign(db,JSON.parse(t)); db.cuentos=db.cuentos||{}; db.ajustes=Object.assign({...},db.ajustes||{})
  static Map<String, dynamic> _load(String? json) {
    final db = _defaults();
    if (json != null) db.addAll(jsonDecode(json) as Map<String, dynamic>);
    db['cuentos'] ??= <String, dynamic>{};
    db['ajustes'] = {
      ..._defaultSettings(),
      ...?(db['ajustes'] as Map?)?.cast<String, dynamic>(),
    };
    return db;
  }

  void _save() {
    saves++;
    _changes.add(null);
  }

  int get _now => clock.nowMs();

  String _day(int t) => DateTime.fromMillisecondsSinceEpoch(
    t,
    isUtc: true,
  ).toIso8601String().substring(0, 10);

  Map<String, dynamic> _sub(String key) =>
      (_db[key] ??= <String, dynamic>{}) as Map<String, dynamic>;

  Map<String, dynamic> get _words => _sub('palabras');

  WordRecord _rec(String w) {
    final j = _words[w];
    if (j != null) return WordRecord.fromJson(j as Map<String, dynamic>);
    final r = WordRecord(w: w, primera: _now);
    _words[w] = r.toJson();
    return r;
  }

  static Map<String, dynamic> _merge(
    Map<String, dynamic>? old,
    Map<String, dynamic> now,
  ) {
    final out = {...?old};
    now.forEach(
      (k, v) => out[k] = v is Map<String, dynamic> && old?[k] is Map
          ? _merge(old![k] as Map<String, dynamic>, v)
          : v,
    );
    return out;
  }

  /// Writes a record into the store as it is (keys the record does not know are kept). For seeding tests.
  void put(WordRecord r) {
    _words[r.w] = _merge(_words[r.w] as Map<String, dynamic>?, r.toJson());
    _save();
  }

  void _write(WordRecord r) =>
      _words[r.w] = _merge(_words[r.w] as Map<String, dynamic>?, r.toJson());

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Map<String, dynamic> get raw => UnmodifiableMapView(_db);

  @override
  Iterable<WordRecord> get words => [
    for (final j in _words.values)
      WordRecord.fromJson(j as Map<String, dynamic>),
  ];

  @override
  WordRecord? word(String w) {
    final j = _words[w];
    return j == null ? null : WordRecord.fromJson(j as Map<String, dynamic>);
  }

  @override
  StoryRecord? story(String id) {
    final j = _sub('cuentos')[id];
    return j == null ? null : StoryRecord.fromJson(j as Map<String, dynamic>);
  }

  // app.html: hecho=id=>!!(db().cuentos[id]&&db().cuentos[id].n)
  @override
  bool played(String id) => (story(id)?.n ?? 0) != 0;

  // palabras.js: vence
  @override
  List<String> due(Skill skill, {int? at}) {
    final t = (at == null || at == 0) ? _now : at;
    final rs = words.map((r) => r.of(skill)).toList();
    final ws = words.toList();
    final idx = [
      for (var i = 0; i < rs.length; i++)
        if (rs[i].etapa > 0 &&
            rs[i].due != 0 &&
            rs[i].due <= t &&
            !(rs[i].aparcada > t))
          i,
    ];
    // JavaScript's sort is stable: equal dues keep the store's order.
    idx.sort((a, b) {
      final c = rs[a].due.compareTo(rs[b].due);
      return c != 0 ? c : a.compareTo(b);
    });
    return [for (final i in idx) ws[i].w];
  }

  @override
  WordRecord heard(String w) {
    final r = _rec(w);
    r.oida++;
    if (r.ear.etapa < 1) r.ear.etapa = 1;
    _write(r);
    _save();
    return r;
  }

  @override
  SkillRecord answer(
    String w,
    Skill skill, {
    required bool ok,
    int? ms,
    bool intro = false,
  }) {
    final r = _rec(w);
    final e = r.of(skill);
    e.n++;
    if (ok) e.bien++;
    e.ultima = _now;
    if (ok && e.etapa < 2) e.etapa = 2;
    if (e.etapa < 1) e.etapa = 1;
    _write(r);
    _save();
    return e;
  }

  @override
  void storyFinished(StoryResult r) {
    final t = _now;
    for (final w in [...r.focusWords, ...r.backAgain]) {
      heard(w);
    }
    for (final d in r.log) {
      final w = d.word;
      if (w != null) answer(w, Skill.ear, ok: d.ok, ms: d.ms, intro: true);
    }
    final dias = _sub('dias');
    final k = _day(t);
    dias[k] = ((dias[k] as num?) ?? 0) + 1;
    final cuentos = _sub('cuentos');
    final c =
        (cuentos[r.id] ??= <String, dynamic>{'n': 0, 'primera': t})
            as Map<String, dynamic>;
    c['n'] = ((c['n'] as num?) ?? 0) + 1;
    c['ultima'] = t;
    c['perdido'] = r.lost;
    _save();
  }

  @override
  void presume(List<String> words, List<String> stories, List<Object?> log) {
    final t = _now;
    for (final w in words) {
      final r = _rec(w);
      final e = r.ear;
      if (e.etapa < 3) {
        e.etapa = 3;
        if (e.paso < 2) e.paso = 2;
        e.presunta = 1;
      }
      _write(r);
    }
    final cuentos = _sub('cuentos');
    for (final id in stories) {
      final c =
          (cuentos[id] ??= <String, dynamic>{'n': 0, 'primera': t})
              as Map<String, dynamic>;
      if (((c['n'] as num?) ?? 0) == 0) {
        c['n'] = 1;
        c['ultima'] = t;
        c['presunto'] = 1;
      }
    }
    _db['nivel'] = {'t': t, 'log': log, 'historias': stories.length};
    _sub('dias').putIfAbsent(_day(t), () => 1);
    _save();
  }

  @override
  void listened(String id) {
    final o = _sub('oidos');
    o[id] = ((o[id] as num?) ?? 0) + 1;
    _save();
  }

  @override
  bool hasRead(String id) {
    final v = (_db['leidos'] as Map?)?[id];
    return v != null && v != 0;
  }

  // app.html: marcaLeido
  @override
  void markRead(String id) {
    final l = _sub('leidos');
    if (l[id] == null || l[id] == 0) {
      l[id] = _now;
      _save();
    }
  }

  @override
  void addMinutes(double m) {
    _db['minutos'] = ((_db['minutos'] as num?) ?? 0) + m;
    _sub('dias').putIfAbsent(_day(_now), () => 1);
    _save();
  }

  @override
  double get minutes => ((_db['minutos'] as num?) ?? 0).toDouble();

  @override
  int get streak {
    final dias = _sub('dias');
    var n = 0;
    var d = DateTime.fromMillisecondsSinceEpoch(_now, isUtc: true);
    while (true) {
      final v = dias[d.toIso8601String().substring(0, 10)];
      if (v == null || v == 0) break;
      n++;
      d = DateTime.utc(d.year, d.month, d.day - 1);
    }
    return n;
  }

  // palabras.js: abiertaHabla
  @override
  bool openForSpeaking(String w) {
    final r = word(w);
    return r != null && (r.ear.etapa >= 3 || r.mouth.n > 0);
  }

  @override
  Object? setting(String key) => _sub('ajustes')[key];

  @override
  void setSetting(String key, Object value) {
    _sub('ajustes')[key] = value;
    _save();
  }

  @override
  List<String> get added => [
    for (final x in (_db['extra'] as List?) ?? const []) x as String,
  ];

  @override
  void add(String wordOrGoal) {
    ((_db['extra'] ??= <Object?>[]) as List).add(wordOrGoal);
    _save();
  }

  @override
  Map<String, dynamic>? get levelResult =>
      (_db['nivel'] as Map?)?.cast<String, dynamic>();

  @override
  String export() => jsonEncode(_db);

  @override
  void import(String json) {
    _db = _load(json);
    _save();
  }

  @override
  void reset() {
    _db = _defaults();
    _save();
  }
}
