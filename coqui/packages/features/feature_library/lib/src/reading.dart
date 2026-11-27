import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';

List<String> readingWords(String text, {Language? language}) {
  final lang = language ?? Language.spanish;
  if (lang.script == 'Latn') {
    return [for (final token in lang.tokens(text)) token.text.toLowerCase()];
  }
  final out = <String>[];
  for (final token in lang.tokens(text)) {
    final normalized = lang.normalize(token.text).trim();
    if (normalized.isNotEmpty) out.add(normalized);
  }
  return out;
}

String readingKey(String text, {Language? language}) =>
    readingWords(text, language: language).join(' ');

/// Language-tokenized key that preserves diacritics and accents (for exact
/// audio matching before falling back to [Language.normalize]).
String readingExactKey(String text, {Language? language}) {
  final lang = language ?? Language.spanish;
  return [for (final token in lang.tokens(text)) token.text.toLowerCase()]
      .join(' ');
}

final _lineBreak = RegExp(r'\r\n?|\n|(?<=[.!?؟…])[^\S\r\n]+');

List<String> readingLines(String body) => [
  for (final line in body.split(_lineBreak))
    if (line.trim().isNotEmpty) line.trim(),
];

const int readingPageSize = 3;

/// Fallback ear stage threshold until request 87 (`LanguageProgressStore.stageMax`)
/// lands in `coqui_contracts`.
const int defaultStageMax = 4;

const personalBookPrefix = 'biblioteca-';

class ReadingChapter {
  const ReadingChapter({
    this.label,
    required this.title,
    required this.paragraphs,
  });

  /// Only when the book itself has a chapter label; never invented.
  final String? label;
  final String title;
  final List<String> paragraphs;

  Map<String, Object> toJson() => {
    if (label != null && label!.isNotEmpty) 'label': label!,
    'title': title,
    'paragraphs': paragraphs,
  };

  static ReadingChapter? fromJson(Object? value) {
    if (value case {
      'title': final String title,
      'paragraphs': final List rawParagraphs,
    }) {
      final rawLabel = value['label'];
      return ReadingChapter(
        label: rawLabel is String && rawLabel.isNotEmpty ? rawLabel : null,
        title: title,
        paragraphs: rawParagraphs.whereType<String>().toList(),
      );
    }
    return null;
  }
}

/// Thrown when writing a personal text or book to local storage fails or is
/// dropped (for example, when browser storage quota is exceeded).
class ReadingStorageFullException implements Exception {
  const ReadingStorageFullException();
}

class ReadingText {
  const ReadingText({
    required this.id,
    required this.title,
    required this.body,
    required this.generated,
    this.isNew = false,
    this.chapters,
    this.format,
    this.byteSize,
    this.importedAt,
    this.estimatedPages,
  });

  final String id;
  final String title;
  final String body;
  final bool generated;
  final bool isNew;
  final List<ReadingChapter>? chapters;
  final String? format;
  final int? byteSize;
  final int? importedAt;
  final int? estimatedPages;

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'generated': generated,
    if (isNew) 'isNew': true,
    if (chapters != null)
      'chapters': [for (final chapter in chapters!) chapter.toJson()],
    if (format != null && format!.isNotEmpty) 'format': format!,
    'byteSize': ?byteSize,
    'importedAt': ?importedAt,
    'estimatedPages': ?estimatedPages,
  };

  static ReadingText? fromJson(
    Object? value, {
    String? Function(String key)? readBody,
  }) {
    if (value
        case {
          'id': final String id,
          'title': final String title,
          'generated': final bool generated,
        }
        when id.startsWith(personalBookPrefix)) {
      String? body;
      final rawBodyKey = value['bodyKey'];
      if (rawBodyKey is String && rawBodyKey.isNotEmpty && readBody != null) {
        body = readBody(rawBodyKey);
      }
      if (body == null) {
        final rawBody = value['body'];
        if (rawBody is String) body = rawBody;
      }
      if (body == null) return null;

      final rawChapters = value['chapters'];
      final parsedChapters = rawChapters is List
          ? rawChapters.map(ReadingChapter.fromJson).nonNulls.toList()
          : null;
      final rawFormat = value['format'];
      final format = rawFormat is String && rawFormat.isNotEmpty
          ? rawFormat
          : null;
      final rawByteSize = value['byteSize'];
      final byteSize = rawByteSize is int && rawByteSize >= 0
          ? rawByteSize
          : null;
      final rawImportedAt = value['importedAt'];
      final importedAt = rawImportedAt is int && rawImportedAt >= 0
          ? rawImportedAt
          : null;
      final rawEstimatedPages = value['estimatedPages'];
      final estimatedPages = rawEstimatedPages is int && rawEstimatedPages > 0
          ? rawEstimatedPages
          : null;

      return ReadingText(
        id: id,
        title: title,
        body: body,
        generated: generated,
        isNew: value['isNew'] == true,
        chapters: parsedChapters,
        format: format,
        byteSize: byteSize,
        importedAt: importedAt,
        estimatedPages: estimatedPages,
      );
    }
    return null;
  }
}

class ReadingPlace {
  const ReadingPlace({
    this.page = 0,
    this.words = const {},
    this.openedAt = 0,
    this.finished = false,
    this.totalPages,
    this.chapterIndex,
    this.paragraphIndex,
    this.charOffset,
  });

  final int page;
  final Set<String> words;
  final int openedAt;
  final bool finished;
  final int? totalPages;
  final int? chapterIndex;
  final int? paragraphIndex;
  final int? charOffset;
}

class ReadingStore {
  ReadingStore(this.storage);

  final KeyValueStore storage;
  static const space = 'biblioteca';

  static String bodyKeyFor(String id) => 'body:$id';

  Object? _read(String key) {
    final text = storage.read(key);
    if (text == null) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  Map<String, Object> _indexEntry(ReadingText item) {
    final bodyKey = bodyKeyFor(item.id);
    final hasSeparateBody = storage.read(bodyKey) != null;
    return {
      'id': item.id,
      'title': item.title,
      if (hasSeparateBody) 'bodyKey': bodyKey else 'body': item.body,
      'generated': item.generated,
      if (item.isNew) 'isNew': true,
      if (item.chapters != null)
        'chapters': [for (final chapter in item.chapters!) chapter.toJson()],
      if (item.format != null && item.format!.isNotEmpty)
        'format': item.format!,
      'byteSize': ?item.byteSize,
      'importedAt': ?item.importedAt,
      'estimatedPages': ?item.estimatedPages,
    };
  }

  Future<void> _bestEffortDelete(String key) async {
    try {
      await storage.delete(key);
    } on Object {
      // Best-effort cleanup after a failed write.
    }
    // Production `SpaceStore` currently omits `implements DeletableKeyValueStore`,
    // making `KeyValueStoreDelete.delete` a no-op. Shrink any surviving key to
    // empty string so an orphaned multi-MB body cannot consume storage quota.
    if (storage.read(key) != null) {
      try {
        await storage.write(key, '');
      } on Object {
        // Best-effort cleanup after a failed write.
      }
    }
  }

  List<ReadingText> texts() {
    final saved = _read('texts');
    if (saved is! List) return [];
    return [
      for (final entry in saved)
        ?ReadingText.fromJson(entry, readBody: storage.read),
    ];
  }

  ReadingText? text(String id) {
    final saved = _read('texts');
    if (saved is! List) return null;
    for (final entry in saved) {
      if (entry is Map && entry['id'] == id) {
        return ReadingText.fromJson(entry, readBody: storage.read);
      }
    }
    return null;
  }

  static final Expando<Future<void>> _writeQueues = Expando<Future<void>>(
    'ReadingStore.writeQueue',
  );

  Future<ReadingText> add({
    required int now,
    required String title,
    required String body,
    required bool generated,
    bool isNew = false,
    List<ReadingChapter>? chapters,
    String? format,
    int? byteSize,
    int? importedAt,
    int? estimatedPages,
  }) {
    final prev = _writeQueues[storage] ?? Future<void>.value();
    final next = prev.catchError((Object _) {}).then((_) {
      return _addSerialized(
        now: now,
        title: title,
        body: body,
        generated: generated,
        isNew: isNew,
        chapters: chapters,
        format: format,
        byteSize: byteSize,
        importedAt: importedAt,
        estimatedPages: estimatedPages,
      );
    });
    _writeQueues[storage] = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<ReadingText> _addSerialized({
    required int now,
    required String title,
    required String body,
    required bool generated,
    bool isNew = false,
    List<ReadingChapter>? chapters,
    String? format,
    int? byteSize,
    int? importedAt,
    int? estimatedPages,
  }) async {
    final previous = texts();
    final existingIds = {for (final item in previous) item.id};
    var suffix = previous.length;
    var id = '$personalBookPrefix$now-$suffix';
    while (existingIds.contains(id)) {
      suffix++;
      id = '$personalBookPrefix$now-$suffix';
    }

    final bodyKey = bodyKeyFor(id);
    try {
      await storage.write(bodyKey, body);
    } on Object {
      await _bestEffortDelete(bodyKey);
      throw const ReadingStorageFullException();
    }
    if (storage.read(bodyKey) != body) {
      await _bestEffortDelete(bodyKey);
      throw const ReadingStorageFullException();
    }

    final text = ReadingText(
      id: id,
      title: title,
      body: body,
      generated: generated,
      isNew: isNew,
      chapters: chapters,
      format: format,
      byteSize: byteSize,
      importedAt: importedAt,
      estimatedPages: estimatedPages,
    );

    final encoded = jsonEncode([
      for (final item in [text, ...previous]) _indexEntry(item),
    ]);
    try {
      await storage.write('texts', encoded);
    } on Object {
      await _bestEffortDelete(bodyKey);
      throw const ReadingStorageFullException();
    }
    if (storage.read('texts') != encoded) {
      await _bestEffortDelete(bodyKey);
      throw const ReadingStorageFullException();
    }

    return text;
  }

  Future<void> clearNew(String id) {
    final prev = _writeQueues[storage] ?? Future<void>.value();
    final next = prev
        .catchError((Object _) {})
        .then((_) => _clearNewSerialized(id));
    _writeQueues[storage] = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _clearNewSerialized(String id) async {
    final saved = _read('texts');
    if (saved is! List) return;
    var changed = false;
    final updated = <Object?>[];
    for (final entry in saved) {
      if (entry is Map && entry['id'] == id && entry['isNew'] == true) {
        final copy = Map<String, Object?>.from(entry)..remove('isNew');
        updated.add(copy);
        changed = true;
      } else {
        updated.add(entry);
      }
    }
    if (!changed) return;
    await storage.write('texts', jsonEncode(updated));
  }

  ReadingPlace place(String id) {
    final saved = _read('place:$id');
    if (saved case {'page': final int page, 'words': final List words}) {
      final rawOpened = saved['openedAt'];
      final openedAt = rawOpened is int ? rawOpened : 0;
      final finished = saved['finished'] == true;
      final rawTotal = saved['totalPages'];
      final totalPages = rawTotal is int && rawTotal > 0 ? rawTotal : null;
      final rawChapter = saved['chapterIndex'];
      final chapterIndex = rawChapter is int && rawChapter >= 0
          ? rawChapter
          : null;
      final rawParagraph = saved['paragraphIndex'];
      final paragraphIndex = rawParagraph is int && rawParagraph >= 0
          ? rawParagraph
          : null;
      final rawCharOffset = saved['charOffset'];
      final charOffset = rawCharOffset is int && rawCharOffset >= 0
          ? rawCharOffset
          : null;
      return ReadingPlace(
        page: page,
        words: words.whereType<String>().toSet(),
        openedAt: openedAt,
        finished: finished,
        totalPages: totalPages,
        chapterIndex: chapterIndex,
        paragraphIndex: paragraphIndex,
        charOffset: charOffset,
      );
    }
    return const ReadingPlace();
  }

  Future<void> savePlace(String id, ReadingPlace place) => storage.write(
    'place:$id',
    jsonEncode({
      'page': place.page,
      'words': place.words.toList(),
      if (place.openedAt > 0) 'openedAt': place.openedAt,
      if (place.finished) 'finished': true,
      if (place.totalPages != null) 'totalPages': place.totalPages,
      if (place.chapterIndex != null) 'chapterIndex': place.chapterIndex,
      if (place.paragraphIndex != null) 'paragraphIndex': place.paragraphIndex,
      if (place.charOffset != null) 'charOffset': place.charOffset,
    }),
  );

  Future<void> markOpened(String id, int now) async {
    final existing = place(id);
    await savePlace(
      id,
      ReadingPlace(
        page: existing.page,
        words: existing.words,
        openedAt: now,
        finished: false,
        totalPages: existing.totalPages,
        chapterIndex: existing.chapterIndex,
        paragraphIndex: existing.paragraphIndex,
        charOffset: existing.charOffset,
      ),
    );
    await clearNew(id);
  }
}

/// Stage four is the same threshold Yo uses for words the learner knows well.
class ReadingVocabulary {
  ReadingVocabulary(Iterable<WordRecord> records, {Language? language})
    : language = language ?? Language.spanish {
    for (final record in records) {
      final words = readingWords(record.w, language: this.language);
      if (words.isEmpty) continue;
      final key = words.join(' ');
      final stage = record.ear.etapa;
      if (stage > (_stages[key] ?? 0)) _stages[key] = stage;
      if (stage >= 4 && words.length > 1) {
        (_phrases[words.first] ??= []).add(words);
      }
    }
    for (final phrases in _phrases.values) {
      phrases.sort((a, b) => b.length.compareTo(a.length));
    }
  }

  final Language language;
  final Map<String, int> _stages = {};
  final Map<String, List<List<String>>> _phrases = {};

  int stage(String key) => _stages[key] ?? 0;

  bool _matches(List<String> words, int start, List<String> phrase) {
    if (start + phrase.length > words.length) return false;
    for (var i = 0; i < phrase.length; i++) {
      if (words[start + i] != phrase[i]) return false;
    }
    return true;
  }

  Map<String, int> unknownCounts(List<String> words) {
    final unknown = <String, int>{};
    var i = 0;
    while (i < words.length) {
      final word = words[i];
      final phrase = _phrases[word]
          ?.where((phrase) => _matches(words, i, phrase))
          .firstOrNull;
      if (phrase != null) {
        i += phrase.length;
        continue;
      }
      if (stage(word) < 4) {
        unknown.update(word, (count) => count + 1, ifAbsent: () => 1);
      }
      i++;
    }
    return unknown;
  }
}

/// Coverage is checked within utterances so a known phrase can't match
/// across sentence boundaries.
({int total, Map<String, int> unknown}) readingCoverage(
  String body,
  ReadingVocabulary vocabulary,
) {
  var total = 0;
  final unknown = <String, int>{};
  for (final line in readingLines(body)) {
    final words = readingWords(line, language: vocabulary.language);
    total += words.length;
    vocabulary.unknownCounts(words).forEach((word, count) {
      unknown.update(word, (n) => n + count, ifAbsent: () => count);
    });
  }
  return (total: total, unknown: unknown);
}

bool meetsReadingCoverage(({int total, Map<String, int> unknown}) coverage) {
  final missed = coverage.unknown.values.fold(
    0,
    (total, count) => total + count,
  );
  return coverage.total > 0 && missed * 100 <= coverage.total * 2;
}

bool tracksReading(ProgressStore progress) {
  final band = progress.levelResult?['cefr'];
  return const ['A2', 'B1', 'B2', 'C1', 'C2'].contains(band);
}

({int page, int totalPages, int minutesLeft}) readingProgress(
  ReadingText text,
  ReadingPlace place, {
  Language? language,
}) {
  final savedTotal = place.totalPages;
  if (savedTotal != null && savedTotal > 0) {
    final clampedIndex = place.page.clamp(0, savedTotal - 1);
    final totalWords = readingWords(text.body, language: language).length;
    final remainingWords = totalWords <= 0
        ? 0
        : ((totalWords * (savedTotal - clampedIndex)) / savedTotal).ceil();
    final minutesLeft = remainingWords <= 0 ? 1 : (remainingWords + 119) ~/ 120;
    return (
      page: clampedIndex + 1,
      totalPages: savedTotal,
      minutesLeft: minutesLeft,
    );
  }
  final lines = readingLines(text.body);
  final totalPages = lines.isEmpty
      ? 1
      : (lines.length + readingPageSize - 1) ~/ readingPageSize;
  final clampedIndex = place.page.clamp(0, totalPages - 1);
  var remainingWords = 0;
  for (final line in lines.skip(clampedIndex * readingPageSize)) {
    remainingWords += readingWords(line, language: language).length;
  }
  final minutesLeft = remainingWords <= 0 ? 1 : (remainingWords + 119) ~/ 120;
  return (
    page: clampedIndex + 1,
    totalPages: totalPages,
    minutesLeft: minutesLeft,
  );
}

List<ReadingText> sortShelfByRecent(
  List<ReadingText> texts,
  ReadingPlace Function(String id) placeOf,
) {
  final indexed = [
    for (var i = 0; i < texts.length; i++)
      (index: i, text: texts[i], openedAt: placeOf(texts[i].id).openedAt),
  ];
  indexed.sort((a, b) {
    final byTime = b.openedAt.compareTo(a.openedAt);
    return byTime != 0 ? byTime : a.index.compareTo(b.index);
  });
  return [for (final item in indexed) item.text];
}

ReadingText? keepReadingBook(
  List<ReadingText> texts,
  ReadingPlace Function(String id) placeOf,
  bool Function(String id) hasRead,
) {
  for (final text in sortShelfByRecent(texts, placeOf)) {
    if (text.generated) continue;
    final place = placeOf(text.id);
    if (place.openedAt > 0) {
      if (!place.finished) return text;
    } else if (place.page > 0 && !place.finished && !hasRead(text.id)) {
      return text;
    }
  }
  return null;
}

String keepReadingEyebrow({int chapter = 1, int chapterCount = 1}) =>
    chapterCount > 1 ? 'Keep reading · Chapter $chapter' : 'Keep reading';
