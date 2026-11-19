import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_progress/src/js.dart';

/// The learner's progress: historia/palabras.js (the global PAL), ported rule for rule, on a
/// [KeyValueStore] and a [Clock].
///
/// The whole store is the JSON object palabras.js keeps (`db`), held as a map and changed in
/// place as palabras.js changes it, so that a key this code does not know stays where it is
/// and a record the old code left half empty stays half empty. The typed records of
/// coqui_contracts are copies made from it when asked for.
///
/// Page 12, section 2: "Day keys and the 4 am cut are computed exactly as palabras.js computes
/// them (it mixes local time and UTC; keep the mix)". The day keys (`dias`) and the streak are
/// the UTC date of a time; "the next morning" is 4:00 in the local time zone, plus 24 hours.
class PalabrasStore implements ProgressStore {
  /// Loads what is under [storageKey] in [kv] (palabras.js lines 17 to 19), as the old file
  /// does when it starts. [clock] is the old `now()`: `Date.now()` and the `__PAL_NOW` hook.
  PalabrasStore(this._kv, this._clock) {
    _db = _emptyDb();
    try {
      final t = _kv.read(storageKey);
      if (t != null && t.isNotEmpty) {
        jsAssign(_db, jsonDecode(t));
      }
    } catch (_) {
      // palabras.js line 18: a store that cannot be read, or is not JSON, is ignored.
    }
    _fixLoaded();
  }

  /// The key the JSON is kept under.
  static const storageKey = 'coqui.palabras.v1';

  static const double _day = 864e5; // DAY
  static const int _slow = 2000; // SLOW

  final KeyValueStore _kv;
  final Clock _clock;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  late Map<String, dynamic> _db;

  // ---- palabras.js lines 17 to 23: the store, save, now, nextMorning -------------------------

  Map<String, dynamic> _emptyDb() => <String, dynamic>{
    'palabras': <String, dynamic>{},
    'dias': <String, dynamic>{},
    'cuentos': <String, dynamic>{},
    'ajustes': _defaultAjustes(),
    'minutos': 0,
    'v': 1,
  };

  Map<String, dynamic> _defaultAjustes() => <String, dynamic>{
    'min': 30,
    'todo': 0,
    'bienvenida': 0,
    'habla': 1,
  };

  // palabras.js line 19
  void _fixLoaded() {
    _db['cuentos'] = jsTruthy(_db['cuentos'])
        ? _db['cuentos']
        : <String, dynamic>{};
    final ajustes = _defaultAjustes();
    jsAssign(ajustes, jsTruthy(_db['ajustes']) ? _db['ajustes'] : null);
    _db['ajustes'] = ajustes;
  }

  // palabras.js: save. A store that cannot be written is ignored: the data stays in memory.
  void _save() {
    try {
      final done = _kv.write(storageKey, jsonStringify(_db));
      unawaited(
        done.catchError((Object _) {
          // The same: localStorage.setItem threw and palabras.js went on.
        }),
      );
    } catch (_) {
      // palabras.js line 20: the same, for a write that throws at once.
    }
    _changes.add(null);
  }

  // palabras.js: now
  int _now() => _clock.nowMs();

  // palabras.js: nextMorning. Local time: "today 4:00, plus 24 hours".
  int _nextMorning(int t) {
    final d = DateTime.fromMillisecondsSinceEpoch(t);
    return DateTime(d.year, d.month, d.day, 4).millisecondsSinceEpoch +
        _day.toInt();
  }

  // `new Date(t).toISOString().slice(0, 10)`: UTC.
  String _isoDay(int t) {
    final d = DateTime.fromMillisecondsSinceEpoch(t, isUtc: true);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  Map<String, dynamic> get _palabras => _db['palabras'] as Map<String, dynamic>;
  // Object.values(db.palabras)
  List<dynamic> get _palabrasInJsOrder => [
    for (final k in jsKeys(_palabras)) _palabras[k],
  ];
  Map<String, dynamic> get _dias => _db['dias'] as Map<String, dynamic>;
  Map<String, dynamic> get _cuentos => _db['cuentos'] as Map<String, dynamic>;

  // r[sk] / r.ear: reading a field of a record that is not there throws, as in JavaScript.
  Map<String, dynamic> _skillOf(Object? r, String sk) =>
      (r as Map<String, dynamic>)[sk] as Map<String, dynamic>;

  // x++ on a field
  void _inc(Map<String, dynamic> m, String k) {
    m[k] = jsNumberOut(jsNumberAt(m, k) + 1);
  }

  // db.cuentos[id] || (db.cuentos[id] = {n: 0, primera: t})
  Map<String, dynamic> _cuentoRec(String id, int t) {
    final c = _cuentos[id];
    if (jsTruthy(c)) return c as Map<String, dynamic>;
    return _cuentos[id] = <String, dynamic>{'n': 0, 'primera': t};
  }

  // ---- palabras.js lines 23 and 24: rec, skill ----------------------------------------------

  // palabras.js: skill
  Map<String, dynamic> _skill() => <String, dynamic>{
    'etapa': 0,
    'paso': 1,
    'seguidas': 0,
    'fallos': 0,
    'gap': 0,
    'due': 0,
    'aciertos': <Object?>[],
    'ultima': 0,
    'aparcada': 0,
    'marca': 0,
    'n': 0,
    'bien': 0,
  };

  // palabras.js: rec. It does not save.
  Map<String, dynamic> _rec(String w) {
    final p = _palabras;
    if (!jsTruthy(p[w])) {
      p[w] = <String, dynamic>{
        'w': w,
        'primera': _now(),
        'oida': 0,
        'ear': _skill(),
        'mouth': _skill(),
      };
    }
    return p[w] as Map<String, dynamic>;
  }

  // ---- palabras.js line 26: oida --------------------------------------------------------------

  // palabras.js: oida. It does not save: only a function that follows it does.
  Map<String, dynamic> _oida(String w) {
    final r = _rec(w);
    _inc(r, 'oida');
    final e = _skillOf(r, 'ear');
    if (jsNumberAt(e, 'etapa') < 1) e['etapa'] = 1;
    if (!jsTruthy(e['due'])) {
      e['due'] = _nextMorning(_now());
      e['gap'] = 1;
    }
    return r;
  }

  /// palabras.js `oida`. It does not save, exactly as `oida` does not: the word is in the store
  /// and in [raw] at once, but it reaches the storage with the next save (the answer, the story, the
  /// minutes, any setting that follows), and [changes] does not fire for it.
  @override
  WordRecord heard(String w) => WordRecord.fromJson(_oida(w));

  // ---- palabras.js lines 29 to 37: responde ---------------------------------------------------

  // palabras.js: responde
  Map<String, dynamic> _responde(
    String w,
    String sk,
    bool ok,
    int? ms,
    bool intro,
  ) {
    final r = _rec(w);
    final e = _skillOf(r, sk);
    final t = _now();
    _inc(e, 'n');
    if (ok) _inc(e, 'bien');
    e['ultima'] = t;
    if (intro) {
      if (ok && jsNumberAt(e, 'etapa') < 2) e['etapa'] = 2;
      if (jsNumberAt(e, 'etapa') < 1) e['etapa'] = 1;
      if (!jsTruthy(e['due'])) {
        e['due'] = _nextMorning(t);
        e['gap'] = 1;
      }
      _save();
      return e;
    }
    if (ok) {
      e['fallos'] = 0;
      _inc(e, 'seguidas');
      if (jsNumberAt(e, 'seguidas') >= 2 && jsNumberAt(e, 'paso') < 4) {
        _inc(e, 'paso');
        e['seguidas'] = 0;
      }
      final slow = ms != null && ms > _slow;
      // right but slow: counts as right, the gap is not stretched
      if (!slow) {
        final gap = jsTruthy(e['gap']) ? jsNumberAt(e, 'gap') : 1.0;
        e['gap'] = jsNumberOut(math.max(1.0, gap * 2.5));
      }
      (e['aciertos'] as List<dynamic>).add(t);
      e['due'] = jsNumberOut(t + jsNumberAt(e, 'gap') * _day);
      if (jsNumberAt(e, 'etapa') < 2) e['etapa'] = 2;
      final a = e['aciertos'] as List<dynamic>;
      // aciertos.length>=1
      if (jsNumberAt(e, 'etapa') < 3 && a.isNotEmpty) e['etapa'] = 3;
      if (a.length >= 3 &&
          jsToNumber(a[a.length - 1]) - jsToNumber(a[0]) >= 14 * _day) {
        e['etapa'] = 4;
      }
    } else {
      e['seguidas'] = 0;
      _inc(e, 'fallos');
      if (jsNumberAt(e, 'paso') > 1) {
        e['paso'] = jsNumberOut(jsNumberAt(e, 'paso') - 1);
      }
      if (jsNumberAt(e, 'etapa') > 3) e['etapa'] = 3;
      final gap = jsTruthy(e['gap']) ? jsNumberAt(e, 'gap') : 1.0;
      e['gap'] = jsNumberOut(math.max(1.0, gap / 3));
      // back later in this session, and sooner after it
      e['due'] = t + 10 * 60000;
      if (jsNumberAt(e, 'fallos') >= 3) {
        // parked for a week; flagged
        e['aparcada'] = t + (7 * _day).toInt();
        e['due'] = e['aparcada'];
        e['marca'] = 1;
        e['fallos'] = 0;
        e['etapa'] = jsNumberOut(math.min(jsNumberAt(e, 'etapa'), 2.0));
        e['aciertos'] = <Object?>[];
      }
    }
    _save();
    return e;
  }

  @override
  SkillRecord answer(
    String w,
    Skill skill, {
    required bool ok,
    int? ms,
    bool intro = false,
  }) => SkillRecord.fromJson(_responde(w, skill.name, ok, ms, intro));

  // ---- palabras.js lines 39 to 44: cuento -----------------------------------------------------

  // palabras.js: cuento. A finished story: every word it brings is heard; each decision is an
  // answer on the ear record.
  @override
  void storyFinished(StoryResult r) {
    final t = _now();
    // a word that was due: this play is its return
    bool pend(String w) {
      final rec = _palabras[w];
      if (!jsTruthy(rec)) return false;
      final ear = _skillOf(rec, 'ear');
      return jsTruthy(ear['due']) && jsNumberAt(ear, 'due') <= t;
    }

    bool named(Decision x) => x.word != null && x.word!.isNotEmpty;

    final ret = <String>{
      for (final x in r.log)
        if (named(x) && pend(x.word!)) x.word!,
    };
    for (final w in [...r.focusWords, ...r.backAgain]) {
      _oida(w);
    }
    for (final x in r.log) {
      if (named(x)) {
        _responde(x.word!, 'ear', x.ok, x.ms, !ret.contains(x.word));
      }
    }
    final d = _isoDay(_now());
    _dias[d] = jsNumberOut((jsTruthy(_dias[d]) ? jsToNumber(_dias[d]) : 0) + 1);
    _db['cuentos'] = jsTruthy(_db['cuentos'])
        ? _db['cuentos']
        : <String, dynamic>{};
    final c = _cuentoRec(r.id, t);
    _inc(c, 'n');
    c['ultima'] = t;
    c['perdido'] = r.lost; // S._lost||0
    _save();
  }

  // ---- palabras.js lines 47 to 49: presume ----------------------------------------------------

  // palabras.js: presume. The level check: words he is presumed to know start at "se queda",
  // are due for a cold check the next morning, and open for speaking at once. The stories that
  // teach them count as done.
  @override
  void presume(List<String> words, List<String> stories, List<Object?> log) {
    final t = _now();
    for (final w in words) {
      final r = _rec(w);
      final e = _skillOf(r, 'ear');
      if (jsNumberAt(e, 'etapa') < 3) {
        e['etapa'] = 3;
        e['paso'] = jsNumberOut(math.max(jsNumberAt(e, 'paso'), 2.0));
        e['gap'] = 1;
        e['due'] = _nextMorning(t);
        e['presunta'] = 1;
      }
    }
    for (final id in stories) {
      final c = _cuentoRec(id, t);
      if (!jsTruthy(c['n'])) {
        c['n'] = 1;
        c['ultima'] = t;
        c['presunto'] = 1;
      }
    }
    _db['nivel'] = <String, dynamic>{
      't': t,
      'log': [...log],
      'historias': stories.length,
    };
    final d = _isoDay(t);
    _dias[d] = jsTruthy(_dias[d]) ? _dias[d] : 1;
    _save();
  }

  // ---- palabras.js lines 53 to 57: abiertaHabla, oido, minutos, vence, racha ------------------

  // palabras.js: abiertaHabla. A word is open for speaking when his ear has held it (stage 3
  // or more) or his mouth already has an answer.
  @override
  bool openForSpeaking(String w) {
    final r = _palabras[w];
    if (!jsTruthy(r)) return false;
    final m = r as Map<String, dynamic>;
    final ear = m['ear'];
    if (jsTruthy(ear) &&
        jsNumberAt(ear as Map<String, dynamic>, 'etapa') >= 3) {
      return true;
    }
    final mouth = m['mouth'];
    return jsTruthy(mouth) &&
        jsNumberAt(mouth as Map<String, dynamic>, 'n') > 0;
  }

  // palabras.js: oido. Escuchar: how often a piece was heard to the end. Nothing is scored.
  @override
  void listened(String id) {
    _db['oidos'] = jsTruthy(_db['oidos']) ? _db['oidos'] : <String, dynamic>{};
    final oidos = _db['oidos'] as Map<String, dynamic>;
    oidos[id] = jsNumberOut(
      (jsTruthy(oidos[id]) ? jsToNumber(oidos[id]) : 0) + 1,
    );
    _save();
  }

  // palabras.js: minutos
  @override
  void addMinutes(double m) {
    _db['minutos'] = jsNumberOut(
      (jsTruthy(_db['minutos']) ? jsToNumber(_db['minutos']) : 0) + m,
    );
    final d = _isoDay(_now());
    _dias[d] = jsTruthy(_dias[d]) ? _dias[d] : 1;
    _save();
  }

  // palabras.js: vence. The words whose time has come, most overdue first. `t||now()`: an `at`
  // of 0 is now. A stored record with no `ear` (or `mouth`) makes it throw, as in the old code.
  @override
  List<String> due(Skill skill, {int? at}) {
    final t = (at != null && at != 0) ? at : _now();
    final sk = skill.name;
    final rs = _palabrasInJsOrder.where((r) {
      final e = _skillOf(r, sk);
      return jsNumberAt(e, 'etapa') > 0 &&
          jsTruthy(e['due']) &&
          jsNumberAt(e, 'due') <= t &&
          !(jsNumberAt(e, 'aparcada') > t);
    }).toList();
    mergeSort<dynamic>(
      rs,
      compare: (a, b) {
        final d =
            jsNumberAt(_skillOf(a, sk), 'due') -
            jsNumberAt(_skillOf(b, sk), 'due');
        return d > 0 ? 1 : (d < 0 ? -1 : 0);
      },
    );
    return [for (final r in rs) (r as Map<String, dynamic>)['w'] as String];
  }

  // palabras.js: racha. How many days in a row, counted back from today: the UTC date of the
  // time, then one local day earlier each step.
  @override
  int get streak {
    var n = 0;
    var d = DateTime.fromMillisecondsSinceEpoch(_now());
    for (;;) {
      final k = _isoDay(d.millisecondsSinceEpoch);
      if (jsTruthy(_dias[k])) {
        n++;
        d = DateTime(
          d.year,
          d.month,
          d.day - 1,
          d.hour,
          d.minute,
          d.second,
          d.millisecond,
        );
      } else {
        break;
      }
    }
    return n;
  }

  // ---- palabras.js line 58: reset -------------------------------------------------------------

  // palabras.js: reset. Everything goes, unknown keys too.
  @override
  void reset() {
    _db = _emptyDb();
    _save();
  }

  // ---- the rest of ProgressStore ---------------------------------------------------------------

  @override
  Stream<void> get changes => _changes.stream;

  // palabras.js: get db
  @override
  Map<String, dynamic> get raw => UnmodifiableMapView<String, dynamic>(_db);

  @override
  Iterable<WordRecord> get words => [
    for (final r in _palabrasInJsOrder)
      WordRecord.fromJson(r as Map<String, dynamic>),
  ];

  @override
  WordRecord? word(String w) {
    final r = _palabras[w];
    return jsTruthy(r) ? WordRecord.fromJson(r as Map<String, dynamic>) : null;
  }

  @override
  StoryRecord? story(String id) {
    final c = _cuentos[id];
    return jsTruthy(c) ? StoryRecord.fromJson(c as Map<String, dynamic>) : null;
  }

  // app.html yo: d.minutos||0
  @override
  double get minutes =>
      jsTruthy(_db['minutos']) ? jsToNumber(_db['minutos']) : 0;

  // app.html line 185: hecho=id=>!!(db().cuentos[id]&&db().cuentos[id].n). A play is counted by
  // cuento() and by presume(), and both leave `n` at 1 or more.
  @override
  bool played(String id) {
    final c = jsGet(_db['cuentos'], id);
    return jsTruthy(c) && jsTruthy(jsGet(c, 'n'));
  }

  // app.html biblioteca: rd=db().leidos||{} ... leido=!!rd[c]
  @override
  bool hasRead(String id) {
    final rd = jsTruthy(_db['leidos']) ? _db['leidos'] : <String, dynamic>{};
    return jsTruthy(jsGet(rd, id));
  }

  // app.html: marcaLeido. "Completion only: no word record is written." The first time a book is
  // read its id gets the time (the palabras clock) and the store is saved; a book that is already
  // there changes nothing and saves nothing. The `leidos` object is made if it is not there.
  @override
  void markRead(String id) {
    _db['leidos'] = jsTruthy(_db['leidos'])
        ? _db['leidos']
        : <String, dynamic>{};
    final leidos = _db['leidos'] as Map<String, dynamic>;
    if (!jsTruthy(leidos[id])) {
      leidos[id] = _now();
      _save();
    }
  }

  // app.html: AJ()[key], with AJ=()=>db().ajustes. `ajustes` holds min, todo, bienvenida and habla
  // from the start (palabras.js), and any key a page has written (notaHabla).
  @override
  Object? setting(String key) => jsGet(_db['ajustes'], key);

  // app.html: AJ().key=value; PAL.save(). Every write of a setting in app.html is followed by the save.
  @override
  void setSetting(String key, Object value) {
    (_db['ajustes'] as Map<String, dynamic>)[key] = value is num
        ? jsNumberOut(value.toDouble())
        : value;
    _save();
  }

  // app.html palabras: ex=db().extra||[]
  @override
  List<String> get added {
    final x = _db['extra'];
    return jsTruthy(x) ? [for (final w in x as List<dynamic>) w as String] : [];
  }

  // app.html: extra. The value is trimmed as JavaScript trims; an empty one is dropped (nothing is
  // changed or saved); the rest goes to the end of `extra`, with no check for a word that is
  // already there and no limit on the length or the number.
  @override
  void add(String wordOrGoal) {
    final v = jsTrim(wordOrGoal);
    if (v.isEmpty) return;
    _db['extra'] = jsTruthy(_db['extra']) ? _db['extra'] : <Object?>[];
    (_db['extra'] as List<dynamic>).add(v);
    _save();
  }

  /// The stored `nivel` (written by [presume]), or null. app.html yo: `db().nivel?"Done: "+db().nivel.historias`.
  @override
  Map<String, dynamic>? get levelResult {
    final n = _db['nivel'];
    return jsTruthy(n) && n is Map<String, dynamic> ? n : null;
  }

  /// The text palabras.js would keep under [storageKey]: `JSON.stringify(db)`.
  @override
  String export() => jsonStringify(_db);

  /// Replaces the store with [json], read as palabras.js reads its stored text when it starts
  /// (the defaults, then every key of [json] over them; `cuentos` and `ajustes` made whole),
  /// and saves. Text that is not JSON throws a [FormatException] and the store is left as it was.
  ///
  /// New behaviour: the old code has no import. Its load, which this reuses, ignores text that is
  /// not JSON and starts with an empty store, which would wipe the store here (order 43 uses it).
  @override
  void import(String json) {
    final parsed = jsonDecode(json);
    _db = _emptyDb();
    jsAssign(_db, parsed);
    _fixLoaded();
    _save();
  }
}
