import 'dart:async';
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_progress/src/js.dart';

/// Legacy single-language storage key (`historia/palabras.js`).
const String legacyStorageKey = 'coqui.palabras.v1';

/// Cross-language shared progress storage key (streak, minutes, active language).
const String sharedStorageKey = 'coqui.shared.v1';

/// Number of calendar days kept in `minutosDia` (inclusive: `[today - 34, today]`).
const int minutesHistoryDays = 35;

final RegExp _whitespace = RegExp(r'\s');
final RegExp _isoDayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Whether [languageCode] is a valid key segment (non-empty, no dots or whitespace).
bool isValidLanguageCode(String languageCode) =>
    languageCode.isNotEmpty &&
    !languageCode.contains('.') &&
    !_whitespace.hasMatch(languageCode);

/// Storage key for one language's word/story store: `coqui.<lang>.palabras.v1`.
String languageStorageKey(String languageCode) {
  if (!isValidLanguageCode(languageCode)) {
    throw ArgumentError.value(
      languageCode,
      'languageCode',
      'must be a non-empty language code without dots or whitespace',
    );
  }
  return 'coqui.$languageCode.palabras.v1';
}

/// UTC calendar day key (`YYYY-MM-DD`), matching `new Date(t).toISOString().slice(0, 10)`.
String isoDayFromMs(int t) {
  final d = DateTime.fromMillisecondsSinceEpoch(t, isUtc: true);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

/// UTC calendar day key for [day]'s instant.
String isoDayFromDate(DateTime day) => isoDayFromMs(day.millisecondsSinceEpoch);

/// True when [db] has at least one truthy word in `palabras` or story in `cuentos`.
bool dbHasProgress(Map<String, dynamic> db) {
  final palabras = db['palabras'];
  if (palabras is Map && palabras.values.any(jsTruthy)) return true;
  final cuentos = db['cuentos'];
  if (cuentos is Map && cuentos.values.any(jsTruthy)) return true;
  return false;
}

/// Safely parses [raw] JSON and returns whether it represents saved progress.
bool storedJsonHasProgress(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  try {
    final parsed = jsonDecode(raw);
    if (parsed is Map) {
      final map = parsed is Map<String, dynamic>
          ? parsed
          : Map<String, dynamic>.from(parsed);
      return dbHasProgress(map);
    }
  } catch (_) {
    // Unreadable or malformed JSON counts as no progress.
  }
  return false;
}

/// Reads [key] from [kv], returning null if storage throws.
String? safeRead(KeyValueStore kv, String key) {
  try {
    return kv.read(key);
  } catch (_) {
    return null;
  }
}

/// Writes [value] under [key] in [kv], ignoring both sync and async storage errors.
void safeWrite(KeyValueStore kv, String key, String value) {
  try {
    final done = kv.write(key, value);
    unawaited(
      done.catchError((Object _) {
        // Same as palabras.js: localStorage.setItem failed asynchronously and we go on.
      }),
    );
  } catch (_) {
    // Same as palabras.js line 20: a write that throws at once is ignored.
  }
}

/// Drops `YYYY-MM-DD` entries from [minutesByDay] older than the inclusive
/// [minutesHistoryDays]-day window ending on the UTC day of [nowMs].
void pruneMinutesByDay(Map<String, dynamic> minutesByDay, int nowMs) {
  final todayUtc = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);
  final cutoffUtc = DateTime.utc(
    todayUtc.year,
    todayUtc.month,
    todayUtc.day - (minutesHistoryDays - 1),
  );
  final cutoffKey = isoDayFromMs(cutoffUtc.millisecondsSinceEpoch);
  minutesByDay.removeWhere(
    (key, _) => _isoDayPattern.hasMatch(key) && key.compareTo(cutoffKey) < 0,
  );
}

/// Cross-language shared progress stored under [sharedStorageKey].
///
/// Holds the learner's shared day streak (`dias`), total minutes (`minutos`),
/// rolling 35-day minutes map (`minutosDia`), recorded languages with progress
/// (`idiomas`), and active language code (`idioma`).
///
/// Instances are coordinated per [KeyValueStore] via [SharedProgress.forStorage]
/// so standalone `PalabrasStore(..., language: ...)` stores and `ProgressStores`
/// sharing one [KeyValueStore] never overwrite each other's shared snapshot.
class SharedProgress {
  SharedProgress._(this._kv) {
    _loadFromRaw(safeRead(_kv, sharedStorageKey));
  }

  /// Returns the coordinated [SharedProgress] instance for [kv], creating it on
  /// first use and refreshing if [sharedStorageKey] changed externally.
  factory SharedProgress.forStorage(KeyValueStore kv) {
    final existing = _byStorage[kv];
    if (existing != null) {
      existing._reloadIfExternallyChanged();
      return existing;
    }
    final created = SharedProgress._(kv);
    _byStorage[kv] = created;
    return created;
  }

  static final Expando<SharedProgress> _byStorage = Expando<SharedProgress>(
    'coqui_progress.SharedProgress',
  );

  final KeyValueStore _kv;
  final List<void Function(Object? source)> _listeners = [];
  late Map<String, dynamic> _db;
  String? _lastStoredRaw;
  bool _syncReadVerified = false;

  void _loadFromRaw(String? raw) {
    _db = _emptyDb();
    _lastStoredRaw = raw;
    if (raw != null && raw.isNotEmpty) {
      _syncReadVerified = true;
      try {
        jsAssign(_db, jsonDecode(raw));
      } catch (_) {
        // Malformed shared JSON is ignored; defaults stand.
      }
    }
    _normalizeLoaded();
  }

  void _reloadIfExternallyChanged() {
    final raw = safeRead(_kv, sharedStorageKey);
    if (raw == _lastStoredRaw) return;
    if (raw == null && !_syncReadVerified) return;
    _loadFromRaw(raw);
  }

  Map<String, dynamic> _emptyDb() => <String, dynamic>{
    'dias': <String, dynamic>{},
    'minutos': 0,
    'minutosDia': <String, dynamic>{},
    'idiomas': <Object?>[],
    'idioma': Language.spanish.code,
    'v': 1,
  };

  void _normalizeLoaded() {
    final dias = _db['dias'];
    _db['dias'] = dias is Map
        ? Map<String, dynamic>.from(dias)
        : <String, dynamic>{};

    final minutosDia = _db['minutosDia'];
    _db['minutosDia'] = minutosDia is Map
        ? Map<String, dynamic>.from(minutosDia)
        : <String, dynamic>{};

    final idiomas = _db['idiomas'];
    _db['idiomas'] = idiomas is List
        ? List<Object?>.from(idiomas)
        : <Object?>[];

    final idioma = _db['idioma'];
    if (idioma is! String || !isValidLanguageCode(idioma)) {
      _db['idioma'] = Language.spanish.code;
    }
  }

  Map<String, dynamic> get _dias => _db['dias'] as Map<String, dynamic>;
  Map<String, dynamic> get _minutosDia =>
      _db['minutosDia'] as Map<String, dynamic>;
  List<Object?> get _idiomas => _db['idiomas'] as List<Object?>;

  void addListener(void Function(Object? source) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(Object? source) listener) {
    _listeners.remove(listener);
  }

  double get minutes =>
      jsTruthy(_db['minutos']) ? jsToNumber(_db['minutos']) : 0;

  int streak(int nowMs) {
    var n = 0;
    var d = DateTime.fromMillisecondsSinceEpoch(nowMs);
    for (;;) {
      final k = isoDayFromMs(d.millisecondsSinceEpoch);
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

  double minutesOn(DateTime day) {
    final v = _minutosDia[isoDayFromDate(day)];
    return jsTruthy(v) ? jsToNumber(v) : 0;
  }

  void addMinutes(
    double m,
    int nowMs, {
    String? languageCode,
    bool? hasProgress,
    Object? source,
  }) {
    _db['minutos'] = jsNumberOut(minutes + m);
    final d = isoDayFromMs(nowMs);
    _dias[d] = jsTruthy(_dias[d]) ? _dias[d] : 1;
    final prev = jsTruthy(_minutosDia[d]) ? jsToNumber(_minutosDia[d]) : 0.0;
    _minutosDia[d] = jsNumberOut(prev + m);
    pruneMinutesByDay(_minutosDia, nowMs);
    if (languageCode != null && hasProgress != null) {
      _updateRecordedLanguage(languageCode, hasProgress);
    }
    save(source: source);
  }

  void recordDayActivity(
    int nowMs, {
    bool increment = false,
    String? languageCode,
    bool? hasProgress,
    Object? source,
  }) {
    final d = isoDayFromMs(nowMs);
    if (increment) {
      _dias[d] = jsNumberOut(
        (jsTruthy(_dias[d]) ? jsToNumber(_dias[d]) : 0) + 1,
      );
    } else {
      _dias[d] = jsTruthy(_dias[d]) ? _dias[d] : 1;
    }
    if (languageCode != null && hasProgress != null) {
      _updateRecordedLanguage(languageCode, hasProgress);
    }
    save(source: source);
  }

  List<String> get recordedLanguages {
    final seen = <String>{};
    final out = <String>[];
    for (final item in _idiomas) {
      if (item is String && isValidLanguageCode(item) && seen.add(item)) {
        out.add(item);
      }
    }
    return out;
  }

  bool _updateRecordedLanguage(String code, bool hasProgress) {
    final current = recordedLanguages;
    final present = current.contains(code);
    if (hasProgress == present) return false;
    if (hasProgress) {
      current.add(code);
    } else {
      current.remove(code);
    }
    _db['idiomas'] = <Object?>[...current];
    return true;
  }

  bool setLanguageHasProgress(String code, bool hasProgress, {Object? source}) {
    if (!_updateRecordedLanguage(code, hasProgress)) return false;
    save(source: source);
    return true;
  }

  String get currentLanguageCode {
    final v = _db['idioma'];
    return v is String && isValidLanguageCode(v) ? v : Language.spanish.code;
  }

  set currentLanguageCode(String code) {
    languageStorageKey(code);
    _db['idioma'] = code;
    save();
  }

  void seedFromLegacyIfEmpty(String legacyJson) {
    final existing = safeRead(_kv, sharedStorageKey);
    if (existing != null && existing.isNotEmpty) return;
    try {
      final parsed = jsonDecode(legacyJson);
      if (parsed is Map) {
        final dias = parsed['dias'];
        if (dias is Map) {
          for (final entry in dias.entries) {
            _dias['${entry.key}'] = entry.value;
          }
        }
        if (jsTruthy(parsed['minutos'])) {
          _db['minutos'] = jsNumberOut(jsToNumber(parsed['minutos']));
        }
        final map = parsed is Map<String, dynamic>
            ? parsed
            : Map<String, dynamic>.from(parsed);
        if (dbHasProgress(map)) {
          _updateRecordedLanguage(Language.spanish.code, true);
        }
      }
    } catch (_) {
      // Malformed legacy JSON leaves shared defaults intact.
    }
    save();
  }

  void save({Object? source}) {
    final encoded = jsonStringify(_db);
    safeWrite(_kv, sharedStorageKey, encoded);
    _lastStoredRaw = encoded;
    if (safeRead(_kv, sharedStorageKey) == encoded) {
      _syncReadVerified = true;
    }
    for (final listener in List<void Function(Object?)>.of(_listeners)) {
      listener(source);
    }
  }
}

/// Copies legacy `coqui.palabras.v1` to `coqui.es.palabras.v1` byte-for-byte
/// when `coqui.es.palabras.v1` does not exist yet, leaving `coqui.palabras.v1`
/// untouched and seeding [shared] if `coqui.shared.v1` is not yet stored.
void migrateLegacySpanish(KeyValueStore kv, SharedProgress shared) {
  final legacy = safeRead(kv, legacyStorageKey);
  if (legacy == null || legacy.isEmpty) return;
  final esKey = languageStorageKey(Language.spanish.code);
  final existingEs = safeRead(kv, esKey);
  if (existingEs != null && existingEs.isNotEmpty) return;
  safeWrite(kv, esKey, legacy);
  shared.seedFromLegacyIfEmpty(legacy);
}
