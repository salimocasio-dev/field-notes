import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_progress/src/palabras_store.dart';
import 'package:coqui_progress/src/shared_progress.dart';

/// Holds per-language [PalabrasStore] instances on one [KeyValueStore] and
/// [Clock], sharing cross-language streak, total minutes, minutes by day,
/// recorded progress languages, and active language code under
/// [PalabrasStore.sharedStorageKey].
class ProgressStores {
  /// Creates a multi-language store collection, migrating any legacy
  /// `coqui.palabras.v1` Spanish record into `coqui.es.palabras.v1` and
  /// seeding `coqui.shared.v1` on first startup without overwriting existing
  /// data or deleting the legacy key.
  ProgressStores(
    this._kv,
    this._clock, {
    Iterable<Language> languages = const [],
  }) : _shared = SharedProgress(_kv, _clock) {
    migrateLegacySpanish(_kv, _shared);
    _knownCodes.add(Language.spanish.code);
    for (final language in languages) {
      languageStorageKey(language.code);
      _knownCodes.add(language.code);
    }
    _shared.addListener((source) {
      if (source == null) {
        _changes.add(null);
      }
    });
  }

  final KeyValueStore _kv;
  final Clock _clock;
  final SharedProgress _shared;
  final Map<String, PalabrasStore> _stores = <String, PalabrasStore>{};
  final Set<String> _knownCodes = <String>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Returns the cached [PalabrasStore] for [language], creating it on first
  /// access.
  PalabrasStore forLanguage(Language language) {
    languageStorageKey(language.code);
    _knownCodes.add(language.code);
    return _stores.putIfAbsent(
      language.code,
      () => PalabrasStore.withShared(
        _kv,
        _clock,
        language,
        _shared,
        onSaved: () => _changes.add(null),
      ),
    );
  }

  /// Whether [languageCode] currently has at least one saved word or story.
  bool hasProgress(String languageCode) {
    final key = languageStorageKey(languageCode);
    final cached = _stores[languageCode];
    if (cached != null) return cached.hasProgress;
    return storedJsonHasProgress(safeRead(_kv, key));
  }

  /// Language codes that currently have saved progress (at least one word or
  /// story), deduplicated and ordered by recorded languages then known codes.
  List<String> get languagesWithProgress {
    final candidates = <String>{..._shared.recordedLanguages, ..._knownCodes};
    return [
      for (final code in candidates)
        if (hasProgress(code)) code,
    ];
  }

  /// The last selected language code, defaulting to `'es'`.
  String get currentLanguageCode => _shared.currentLanguageCode;

  /// Updates and persists the selected language code, firing [changes].
  set currentLanguageCode(String code) => _shared.currentLanguageCode = code;

  /// Shared day streak across all languages.
  int get streak => _shared.streak(_clock.nowMs());

  /// Shared total minutes across all languages.
  double get minutes => _shared.minutes;

  /// Shared minutes logged on the UTC calendar day of [day] across all languages.
  double minutesOn(DateTime day) => _shared.minutesOn(day);

  /// Fires after any store save or shared-state change (such as changing
  /// [currentLanguageCode]).
  Stream<void> get changes => _changes.stream;
}
