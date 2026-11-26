/// Helpers for playing split story files (`coqui.game.v1`, `coqui.lines.v1`,
/// `coqui.words.v1`) alongside legacy single-file story maps.
///
/// Mirrors `docs/proyecto/23-split-story-format.md`.
library;

/// Format tag for shared language-neutral game files (`content/games/<id>.json`).
const String splitGameFormat = 'coqui.game.v1';

/// Format tag for per-language story line files (`content/lines/<lang>/<id>.json`).
const String splitLinesFormat = 'coqui.lines.v1';

/// Format tag for per-language ID-to-word tables (`content/lines/<lang>/words.json`).
const String splitWordsFormat = 'coqui.words.v1';

final RegExp _safeSegmentRe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
const Set<String> _reservedStoryIds = {'words'};

const List<String> _canonicalStoryKeys = [
  'id',
  'title',
  'place',
  'scene',
  'tipo',
  'next',
  'nota',
  'goal',
  'stake',
  'note',
  'dots',
  'bien',
  'callado',
  'cam',
  'focus_words',
  'back_again',
  'also_heard',
  'names',
  'palabras',
  'clips',
  'beats',
  'final',
  'leer',
  'items',
];

const Set<String> _gameAllowedKeys = {
  'format',
  'id',
  'tipo',
  'scene',
  'next',
  'goal',
  'note',
  'stake',
  'dots',
  'bien',
  'callado',
  'cam',
  'beats',
  'final',
  'leer',
  'items',
};

const Set<String> _linesAllowedKeys = {
  'format',
  'id',
  'lang',
  'title',
  'place',
  'nota',
  'focus_words',
  'back_again',
  'also_heard',
  'names',
  'palabras',
  'clips',
  'item_words',
};

bool _isSafeSegment(Object? value) =>
    value is String &&
    value.isNotEmpty &&
    value != '.' &&
    value != '..' &&
    !value.contains('/') &&
    !value.contains('\\') &&
    _safeSegmentRe.hasMatch(value);

bool _isSafeSplitStoryId(Object? value) =>
    _isSafeSegment(value) && !_reservedStoryIds.contains(value);

/// Parses and validates a per-language `words.json` (`coqui.words.v1`) payload.
///
/// Throws [FormatException] if the payload is malformed or its `lang` does not
/// match [expectedLang] (when provided).
Map<String, String> parseStoryWordTable(Object? json, {String? expectedLang}) {
  if (json is! Map) {
    throw const FormatException('words.json: a JSON object was expected');
  }
  final format = json['format'];
  if (format != splitWordsFormat) {
    throw FormatException(
      'words.json: invalid words format $format (expected $splitWordsFormat)',
    );
  }
  final lang = json['lang'];
  if (lang is! String || !_isSafeSegment(lang)) {
    throw FormatException('words.json: unsafe or missing lang $lang');
  }
  if (expectedLang != null && lang != expectedLang) {
    throw FormatException(
      'words.json: lang "$lang" does not match expected "$expectedLang"',
    );
  }
  final rawWords = json['words'];
  if (rawWords is! Map) {
    throw const FormatException('words.json: words must be a JSON object');
  }
  final words = <String, String>{};
  for (final entry in rawWords.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || value is! String) {
      throw FormatException('words.json: words.$key must map string -> string');
    }
    words[key] = value;
  }
  return Map<String, String>.unmodifiable(words);
}

/// Resolves [testedId] to the target-language word using the split precedence:
///
/// 1. [storyPalabras]`[testedId]` when it is a non-empty [String]
/// 2. [wordTable]`[testedId]` when it is a non-empty [String]
/// 3. [testedId] itself
///
/// Preserves `'-'` suppression verbatim so the story runner skips logging.
String resolveStoryWord(
  String testedId, {
  Map<String, dynamic>? storyPalabras,
  Map<String, String> wordTable = const {},
}) {
  final storyValue = storyPalabras?[testedId];
  if (storyValue is String && storyValue.isNotEmpty) {
    return storyValue;
  }
  final tableValue = wordTable[testedId];
  if (tableValue != null && tableValue.isNotEmpty) {
    return tableValue;
  }
  return testedId;
}

/// Joins a split [game] (`coqui.game.v1`) and [lines] (`coqui.lines.v1`) pair
/// into a single playable story map without mutating caller inputs.
///
/// Merges [wordTable] beneath `lines['palabras']` when [wordTable] is non-empty
/// (or preserves `lines['palabras']` verbatim when [wordTable] is empty).
Map<String, dynamic> joinSplitStory({
  required Map<String, dynamic> game,
  required Map<String, dynamic> lines,
  Map<String, String> wordTable = const {},
  String? expectedLang,
}) {
  if (game['format'] != splitGameFormat) {
    throw FormatException(
      'game: invalid format ${game['format']} (expected $splitGameFormat)',
    );
  }
  if (lines['format'] != splitLinesFormat) {
    throw FormatException(
      'lines: invalid format ${lines['format']} (expected $splitLinesFormat)',
    );
  }

  final gid = game['id'];
  if (!_isSafeSplitStoryId(gid)) {
    throw FormatException('game: unsafe or reserved story id $gid');
  }
  final lid = lines['id'];
  if (lid != gid) {
    throw FormatException('lines: mismatched story id $lid (expected $gid)');
  }

  final lang = lines['lang'];
  if (lang is! String || !_isSafeSegment(lang)) {
    throw FormatException('lines: unsafe or missing lang $lang');
  }
  if (expectedLang != null && lang != expectedLang) {
    throw FormatException(
      'lines: lang "$lang" does not match expected "$expectedLang"',
    );
  }

  if (!lines.containsKey('title') || lines['title'] is! String) {
    throw const FormatException('lines: missing required string key "title"');
  }
  if (!lines.containsKey('clips') || lines['clips'] is! Map) {
    throw const FormatException('lines: missing required object key "clips"');
  }

  final unknownGame = [
    for (final key in game.keys)
      if (!_gameAllowedKeys.contains(key)) key,
  ]..sort();
  if (unknownGame.isNotEmpty) {
    throw FormatException(
      'game: unknown key(s) in game $gid: ${unknownGame.join(', ')}',
    );
  }

  final unknownLines = [
    for (final key in lines.keys)
      if (!_linesAllowedKeys.contains(key)) key,
  ]..sort();
  if (unknownLines.isNotEmpty) {
    throw FormatException(
      'lines: unknown key(s) in lines $gid: ${unknownLines.join(', ')}',
    );
  }

  final hasItems = game.containsKey('items');
  final hasItemWords = lines.containsKey('item_words');
  if (hasItems != hasItemWords) {
    throw FormatException(
      'lines: items in game ($hasItems) must match item_words in lines ($hasItemWords)',
    );
  }
  if (game['tipo'] == 'cual' && !hasItems) {
    throw FormatException('game $gid with tipo "cual" must include items');
  }

  List<Map<String, dynamic>>? joinedItems;
  if (hasItems) {
    final rawItems = game['items'];
    final rawWords = lines['item_words'];
    if (rawItems is! List || rawWords is! List) {
      throw const FormatException(
        'lines: items and item_words must both be JSON arrays',
      );
    }
    if (rawItems.length != rawWords.length) {
      throw FormatException(
        'lines: item_words length (${rawWords.length}) does not match items length (${rawItems.length})',
      );
    }
    joinedItems = <Map<String, dynamic>>[];
    for (var i = 0; i < rawItems.length; i++) {
      final word = rawWords[i];
      if (word is! String) {
        throw FormatException('lines: item_words[$i] must be a string');
      }
      final item = rawItems[i];
      if (item is! Map) {
        throw FormatException('game: items[$i] must be a JSON object');
      }
      if (item.containsKey('w')) {
        throw FormatException(
          'game: items[$i] must not contain "w" in split game format',
        );
      }
      final zipped = <String, dynamic>{'w': word};
      for (final entry in item.entries) {
        final key = entry.key;
        if (key is! String) {
          throw FormatException('game: items[$i] keys must be strings');
        }
        zipped[key] = _deepCopy(entry.value, 'game.items[$i].$key');
      }
      joinedItems.add(zipped);
    }
  }

  final out = <String, dynamic>{};
  for (final key in _canonicalStoryKeys) {
    if (key == 'id') {
      out['id'] = gid as String;
    } else if (key == 'items') {
      if (joinedItems != null) {
        out['items'] = joinedItems;
      }
    } else if (key == 'palabras') {
      if (wordTable.isNotEmpty) {
        out['palabras'] = _mergePalabras(
          wordTable: wordTable,
          rawPalabras: lines['palabras'],
          hasPalabras: lines.containsKey('palabras'),
          context: 'lines',
        );
      } else if (lines.containsKey('palabras')) {
        final rawPalabras = lines['palabras'];
        if (rawPalabras != null && rawPalabras is! Map) {
          throw const FormatException('lines: palabras must be a JSON object');
        }
        out['palabras'] = _deepCopy(rawPalabras, 'lines.palabras');
      }
    } else if (game.containsKey(key)) {
      out[key] = _deepCopy(game[key], 'game.$key');
    } else if (lines.containsKey(key)) {
      out[key] = _deepCopy(lines[key], 'lines.$key');
    }
  }
  return out;
}

/// Returns a playable story map from either a split `(game, lines)` pair or a
/// legacy single-file (or already-joined) [story] map.
///
/// Throws [FormatException] if [story] is a split `coqui.game.v1` payload
/// without [lines]. When [lines] is null for a legacy or already-joined map,
/// returns a top-level copy keeping nested step list/map references intact so
/// trace observers share the exact step identities; applies [wordTable] beneath
/// `story['palabras']` only when [wordTable] is non-empty.
Map<String, dynamic> assembleStory(
  Map<String, dynamic> story, {
  Map<String, dynamic>? lines,
  Map<String, String> wordTable = const {},
  String? expectedLang,
}) {
  if (lines != null) {
    return joinSplitStory(
      game: story,
      lines: lines,
      wordTable: wordTable,
      expectedLang: expectedLang,
    );
  }
  if (story['format'] == splitGameFormat) {
    throw FormatException(
      'split game "${story['id']}" requires lines ($splitLinesFormat)',
    );
  }
  final out = Map<String, dynamic>.of(story);
  if (wordTable.isNotEmpty) {
    out['palabras'] = _mergePalabras(
      wordTable: wordTable,
      rawPalabras: story['palabras'],
      hasPalabras: story.containsKey('palabras'),
      context: 'story',
    );
  }
  return out;
}

Map<String, dynamic> _mergePalabras({
  required Map<String, String> wordTable,
  required Object? rawPalabras,
  required bool hasPalabras,
  required String context,
}) {
  final merged = <String, dynamic>{...wordTable};
  if (!hasPalabras || rawPalabras == null) {
    return merged;
  }
  if (rawPalabras is! Map) {
    throw FormatException('$context: palabras must be a JSON object');
  }
  for (final entry in rawPalabras.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String) {
      throw FormatException('$context: palabras keys must be strings');
    }
    if (value is String && value.isNotEmpty) {
      merged[key] = value;
    } else if (!merged.containsKey(key) && value is String) {
      merged[key] = value;
    }
  }
  return merged;
}

Object? _deepCopy(Object? value, String path) {
  if (value is Map) {
    final copy = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException('$path: map keys must be strings');
      }
      copy[key] = _deepCopy(entry.value, '$path.$key');
    }
    return copy;
  }
  if (value is List) {
    return <Object?>[
      for (var i = 0; i < value.length; i++) _deepCopy(value[i], '$path[$i]'),
    ];
  }
  return value;
}
