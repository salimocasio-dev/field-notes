/// Data model and local adapters for the "Your languages" sheet (N2.10).
///
/// Until `ProgressStoreCollection` (requested in
/// `coqui/requests/87-coqui-progress-needs-coqui-contracts-progress-extensions.md`)
/// and a multi-course directory land on `coqui_ui.Services`
/// (`coqui/requests/93-feature-profile-needs-coqui-ui-services-languages.md`),
/// [ServicesLanguagesSource] adapts a single active [Services] pair while
/// [CatalogLanguagesSource] supports any set of catalog courses and per-language
/// stores (used in multi-language tests and ready for N2.11 shell wiring).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/js.dart';

/// Shared setting key holding the active language code, matching
/// `coqui.shared.v1`'s `'idioma'` field in `coqui_progress`.
const String currentLanguageSettingKey = 'idioma';

/// Default CEFR level label until `coqui_contracts` exposes course/progress
/// level metadata
/// (`coqui/requests/101-feature-map-needs-coqui-contracts-story-scene-and-level.md`).
const String defaultLanguageLevel = 'A1';

final RegExp _whitespace = RegExp(r'\s');

bool _isValidLanguageCode(String code) =>
    code.isNotEmpty && !code.contains('.') && !_whitespace.hasMatch(code);

/// Whether [progress] has at least one recorded word or story, matching
/// `ProgressStores.hasProgress` in `coqui_progress`.
bool progressHasActivity(ProgressStore progress, CourseCatalog course) {
  if (progress.words.isNotEmpty) return true;
  final rawStories = progress.raw['cuentos'];
  if (rawStories is Map && rawStories.values.any(jsTruthy)) return true;
  for (final place in course.places) {
    if (place.stories.any(progress.played)) return true;
  }
  return false;
}

/// Index of the learner's current place in [places] (`app.html: aqui`): the
/// first place with stories that are not all played, or index 0 when all are
/// played or none have stories.
int currentPlaceIndex(ProgressStore progress, List<Place> places) => math.max(
  0,
  places.indexWhere(
    (place) =>
        place.stories.isNotEmpty && !place.stories.every(progress.played),
  ),
);

/// Snapshot of one language's status for the "Your languages" sheet.
class LanguageEntry {
  const LanguageEntry({
    required this.language,
    required this.hasProgress,
    required this.wordCount,
    required this.placeNumber,
    required this.placeTotal,
    this.level = defaultLanguageLevel,
  });

  final Language language;
  final bool hasProgress;
  final int wordCount;
  final int placeNumber;
  final int placeTotal;
  final String level;

  /// Line 2 of a language radio card: `"<level> · place <N> of <M> · <K> words"`.
  String get summaryLine {
    final wordsPart = '$wordCount ${plural(wordCount, 'word')}';
    if (placeTotal <= 0) return '$level · $wordsPart';
    return '$level · place $placeNumber of $placeTotal · $wordsPart';
  }
}

/// Builds a [LanguageEntry] from a [CourseCatalog] and its [ProgressStore].
LanguageEntry languageEntryFrom({
  required CourseCatalog course,
  required ProgressStore progress,
  String level = defaultLanguageLevel,
}) {
  final places = course.places;
  final placeTotal = places.length;
  final placeNumber = placeTotal == 0
      ? 0
      : places[currentPlaceIndex(progress, places)].n;
  return LanguageEntry(
    language: course.language,
    hasProgress: progressHasActivity(progress, course),
    wordCount: progress.words.length,
    placeNumber: placeNumber,
    placeTotal: placeTotal,
    level: level,
  );
}

/// Abstraction over available catalog languages, their per-language progress,
/// and the active language setting in the shared store.
abstract interface class LanguagesSource {
  String get currentLanguageCode;
  List<LanguageEntry> get entries;
  Stream<void> get changes;
  void selectLanguage(String code);
}

/// Partitioned view rendered by the "Your languages" sheet.
class LanguagesPartition {
  const LanguagesPartition({
    required this.currentCode,
    required this.yourLanguages,
    required this.addableLanguages,
  });

  final String currentCode;

  /// Started languages (plus the active language), current one first.
  final List<LanguageEntry> yourLanguages;

  /// Catalog languages that are not active and have no progress yet.
  final List<LanguageEntry> addableLanguages;
}

/// Splits [source.entries] into "Your languages" (current first, then any
/// other language with progress) and "Add a language" (catalog languages with
/// no progress yet). Entries are deduplicated by `language.code`.
LanguagesPartition partitionLanguages(LanguagesSource source) {
  final seen = <String>{};
  final unique = <LanguageEntry>[];
  for (final entry in source.entries) {
    if (seen.add(entry.language.code)) {
      unique.add(entry);
    }
  }
  if (unique.isEmpty) {
    return LanguagesPartition(
      currentCode: source.currentLanguageCode,
      yourLanguages: const [],
      addableLanguages: const [],
    );
  }

  final requestedCode = source.currentLanguageCode;
  LanguageEntry? current;
  for (final entry in unique) {
    if (entry.language.code == requestedCode) {
      current = entry;
      break;
    }
  }
  current ??= unique.first;
  final effectiveCurrentCode = current.language.code;

  final yourLanguages = <LanguageEntry>[
    current,
    for (final entry in unique)
      if (entry.language.code != effectiveCurrentCode && entry.hasProgress)
        entry,
  ];
  final addableLanguages = <LanguageEntry>[
    for (final entry in unique)
      if (entry.language.code != effectiveCurrentCode && !entry.hasProgress)
        entry,
  ];

  return LanguagesPartition(
    currentCode: effectiveCurrentCode,
    yourLanguages: yourLanguages,
    addableLanguages: addableLanguages,
  );
}

/// Default single-course adapter backed by [Services].
class ServicesLanguagesSource implements LanguagesSource {
  ServicesLanguagesSource(this.services);

  final Services services;

  @override
  String get currentLanguageCode {
    final stored = services.progress.setting(currentLanguageSettingKey);
    if (stored is String && _isValidLanguageCode(stored)) {
      return stored;
    }
    return services.course.language.code;
  }

  @override
  List<LanguageEntry> get entries => [
    languageEntryFrom(course: services.course, progress: services.progress),
  ];

  @override
  Stream<void> get changes => services.progress.changes;

  @override
  void selectLanguage(String code) {
    if (!_isValidLanguageCode(code)) {
      throw ArgumentError.value(code, 'code', 'invalid language code');
    }
    services.progress.setSetting(currentLanguageSettingKey, code);
  }
}

/// Multi-course adapter over a catalog of [CourseCatalog]s, a per-language
/// store lookup, and a shared store holding the current language setting.
class CatalogLanguagesSource implements LanguagesSource {
  CatalogLanguagesSource({
    required this.courses,
    required this.storeFor,
    required this.sharedStore,
    this.readCurrentLanguage,
    this.writeCurrentLanguage,
    this.levelOf,
    Stream<void>? changes,
  }) : _changesStream = changes;

  final List<CourseCatalog> courses;
  final ProgressStore Function(Language language) storeFor;
  final ProgressStore sharedStore;
  final String Function()? readCurrentLanguage;
  final void Function(String code)? writeCurrentLanguage;
  final String Function(CourseCatalog course, ProgressStore progress)? levelOf;
  final Stream<void>? _changesStream;

  @override
  String get currentLanguageCode {
    final fromCallback = readCurrentLanguage?.call();
    if (fromCallback != null && _isValidLanguageCode(fromCallback)) {
      return fromCallback;
    }
    final stored = sharedStore.setting(currentLanguageSettingKey);
    if (stored is String && _isValidLanguageCode(stored)) {
      return stored;
    }
    if (courses.isNotEmpty) {
      return courses.first.language.code;
    }
    return Language.spanish.code;
  }

  @override
  List<LanguageEntry> get entries => [
    for (final course in courses)
      () {
        final store = storeFor(course.language);
        return languageEntryFrom(
          course: course,
          progress: store,
          level: levelOf?.call(course, store) ?? defaultLanguageLevel,
        );
      }(),
  ];

  @override
  Stream<void> get changes => _changesStream ?? sharedStore.changes;

  @override
  void selectLanguage(String code) {
    if (!_isValidLanguageCode(code)) {
      throw ArgumentError.value(code, 'code', 'invalid language code');
    }
    final write = writeCurrentLanguage;
    if (write != null) {
      write(code);
    } else {
      sharedStore.setSetting(currentLanguageSettingKey, code);
    }
  }
}
