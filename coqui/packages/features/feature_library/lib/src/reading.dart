import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';

final readingWordPattern = RegExp(
  r"[\p{L}\p{M}]+(?:['’][\p{L}\p{M}]+)*",
  unicode: true,
);

List<String> readingWords(String text) => [
  for (final match in readingWordPattern.allMatches(text))
    match.group(0)!.toLowerCase(),
];

String readingKey(String text) => readingWords(text).join(' ');

final _lineBreak = RegExp(r'\r\n?|\n|(?<=[.!?…])[^\S\r\n]+');

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

class ReadingText {
  const ReadingText({
    required this.id,
    required this.title,
    required this.body,
    required this.generated,
    this.chapters,
  });

  final String id;
  final String title;
  final String body;
  final bool generated;
  final List<ReadingChapter>? chapters;

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'generated': generated,
    if (chapters != null)
      'chapters': [for (final chapter in chapters!) chapter.toJson()],
  };

  static ReadingText? fromJson(Object? value) {
    if (value
        case {
          'id': final String id,
          'title': final String title,
          'body': final String body,
          'generated': final bool generated,
        }
        when id.startsWith(personalBookPrefix)) {
      final rawChapters = value['chapters'];
      final parsedChapters = rawChapters is List
          ? rawChapters.map(ReadingChapter.fromJson).nonNulls.toList()
          : null;
      return ReadingText(
        id: id,
        title: title,
        body: body,
        generated: generated,
        chapters: parsedChapters,
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

  Object? _read(String key) {
    final text = storage.read(key);
    if (text == null) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  List<ReadingText> texts() {
    final saved = _read('texts');
    if (saved is! List) return [];
    return saved.map(ReadingText.fromJson).nonNulls.toList();
  }

  ReadingText? text(String id) =>
      texts().where((text) => text.id == id).firstOrNull;

  Future<ReadingText> add({
    required int now,
    required String title,
    required String body,
    required bool generated,
    List<ReadingChapter>? chapters,
  }) async {
    final previous = texts();
    final text = ReadingText(
      id: '$personalBookPrefix$now-${previous.length}',
      title: title,
      body: body,
      generated: generated,
      chapters: chapters,
    );
    await storage.write('texts', jsonEncode([text, ...previous]));
    return text;
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

  Future<void> markOpened(String id, int now) {
    final existing = place(id);
    return savePlace(
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
  }
}

/// Stage four is the same threshold Yo uses for words the learner knows well.
class ReadingVocabulary {
  ReadingVocabulary(Iterable<WordRecord> records) {
    for (final record in records) {
      final words = readingWords(record.w);
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
    final words = readingWords(line);
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
  ReadingPlace place,
) {
  final savedTotal = place.totalPages;
  if (savedTotal != null && savedTotal > 0) {
    final clampedIndex = place.page.clamp(0, savedTotal - 1);
    final totalWords = readingWords(text.body).length;
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
    remainingWords += readingWords(line).length;
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
