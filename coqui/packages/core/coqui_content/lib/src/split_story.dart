/// Helpers for the split story format (`coqui.game.v1`, `coqui.lines.v1`, `coqui.words.v1`).
///
/// Mirrors `coqui/tool/split_stories.py` (see `docs/proyecto/23-split-story-format.md`).
library;

/// Format tag for shared language-neutral game files (`games/<id>.json`).
const String splitGameFormat = 'coqui.game.v1';

/// Format tag for per-language story line files (`lines/<lang>/<id>.json`).
const String splitLinesFormat = 'coqui.lines.v1';

/// Format tag for per-language ID-to-word tables (`lines/<lang>/words.json`).
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

/// Whether [value] is a single safe path segment (no path traversal or slashes).
bool isSafeSegment(Object? value) =>
    value is String &&
    value.isNotEmpty &&
    value != '.' &&
    value != '..' &&
    !value.contains('/') &&
    !value.contains('\\') &&
    _safeSegmentRe.hasMatch(value);

/// Whether [value] is a safe split-story ID (a safe segment and not `'words'`).
bool isSafeSplitStoryId(Object? value) =>
    isSafeSegment(value) && !_reservedStoryIds.contains(value);

/// Parses and validates a per-language `words.json` (`coqui.words.v1`) payload.
///
/// Throws [FormatException] naming [path] if the object is malformed or its
/// `lang` does not match [expectedLang] (when provided).
Map<String, String> parseWordTable(
  Object? json,
  String path, {
  String? expectedLang,
}) {
  if (json is! Map) {
    throw FormatException('$path: a JSON object was expected');
  }
  final format = json['format'];
  if (format != splitWordsFormat) {
    throw FormatException(
      '$path: invalid words format $format (expected $splitWordsFormat)',
    );
  }
  final lang = json['lang'];
  if (lang is! String || !isSafeSegment(lang)) {
    throw FormatException('$path: unsafe or missing lang $lang');
  }
  if (expectedLang != null && lang != expectedLang) {
    throw FormatException(
      '$path: lang "$lang" does not match expected "$expectedLang"',
    );
  }
  final rawWords = json['words'];
  if (rawWords is! Map) {
    throw FormatException('$path: words must be a JSON object');
  }
  final words = <String, String>{};
  for (final entry in rawWords.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || value is! String) {
      throw FormatException('$path: words.$key must map string -> string');
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
String resolveTestedWord(
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

/// Reconstructs a single-file story map from a split [game] (`coqui.game.v1`)
/// and [lines] (`coqui.lines.v1`) pair.
///
/// When [wordTable] is non-empty, merges it as defaults beneath per-story
/// `lines['palabras']` into the returned map's `'palabras'` (only non-empty
/// string entries from `lines['palabras']` override [wordTable]; empty strings
/// do not clobber non-empty [wordTable] entries). When [wordTable] is null or
/// empty, `lines['palabras']` is preserved verbatim for round-trip equality.
Map<String, dynamic> joinSplitStory(
  Map<String, dynamic> game,
  Map<String, dynamic> lines, {
  String? expectedLang,
  Map<String, String>? wordTable,
  String gamePath = 'game',
  String linesPath = 'lines',
}) {
  if (game['format'] != splitGameFormat) {
    throw FormatException(
      '$gamePath: invalid game format ${game['format']} (expected $splitGameFormat)',
    );
  }
  if (lines['format'] != splitLinesFormat) {
    throw FormatException(
      '$linesPath: invalid lines format ${lines['format']} (expected $splitLinesFormat)',
    );
  }

  final gid = game['id'];
  if (!isSafeSplitStoryId(gid)) {
    throw FormatException('$gamePath: unsafe or reserved game id $gid');
  }
  final lid = lines['id'];
  if (lid != gid) {
    throw FormatException(
      '$linesPath: mismatched story id $lid (expected $gid)',
    );
  }

  final lang = lines['lang'];
  if (!isSafeSegment(lang)) {
    throw FormatException('$linesPath: unsafe or missing lang $lang');
  }
  if (expectedLang != null && lang != expectedLang) {
    throw FormatException(
      '$linesPath: lang "$lang" does not match expected "$expectedLang"',
    );
  }

  if (!lines.containsKey('title')) {
    throw FormatException('$linesPath: missing required key "title"');
  }
  if (!lines.containsKey('clips')) {
    throw FormatException('$linesPath: missing required key "clips"');
  }

  final unknownGame = [
    for (final key in game.keys)
      if (!_gameAllowedKeys.contains(key)) key,
  ]..sort();
  if (unknownGame.isNotEmpty) {
    throw FormatException(
      '$gamePath: unknown key(s) in game $gid: ${unknownGame.join(', ')}',
    );
  }

  final unknownLines = [
    for (final key in lines.keys)
      if (!_linesAllowedKeys.contains(key)) key,
  ]..sort();
  if (unknownLines.isNotEmpty) {
    throw FormatException(
      '$linesPath: unknown key(s) in lines $gid: ${unknownLines.join(', ')}',
    );
  }

  final hasItems = game.containsKey('items');
  final hasItemWords = lines.containsKey('item_words');
  if (hasItems != hasItemWords) {
    throw FormatException(
      '$linesPath: items in $gamePath ($hasItems) must match item_words in $linesPath ($hasItemWords)',
    );
  }

  List<Map<String, dynamic>>? joinedItems;
  if (hasItems) {
    final rawItems = game['items'];
    final rawWords = lines['item_words'];
    if (rawItems is! List || rawWords is! List) {
      throw FormatException(
        '$linesPath: items and item_words must both be JSON arrays',
      );
    }
    if (rawItems.length != rawWords.length) {
      throw FormatException(
        '$linesPath: item_words length (${rawWords.length}) does not match items length (${rawItems.length})',
      );
    }
    joinedItems = <Map<String, dynamic>>[];
    for (var i = 0; i < rawItems.length; i++) {
      final word = rawWords[i];
      if (word is! String) {
        throw FormatException('$linesPath: item_words[$i] must be a string');
      }
      final item = rawItems[i];
      if (item is! Map) {
        throw FormatException('$gamePath: items[$i] must be a JSON object');
      }
      if (item.containsKey('w')) {
        throw FormatException(
          '$gamePath: items[$i] must not contain "w" in split game format',
        );
      }
      joinedItems.add(<String, dynamic>{
        'w': word,
        for (final entry in item.entries)
          entry.key as String: _deepCopy(entry.value),
      });
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
      if (wordTable != null && wordTable.isNotEmpty) {
        out['palabras'] = _mergePalabras(
          wordTable: wordTable,
          rawPalabras: lines['palabras'],
          hasPalabras: lines.containsKey('palabras'),
          linesPath: linesPath,
        );
      } else if (lines.containsKey('palabras')) {
        out['palabras'] = _deepCopy(lines['palabras']);
      }
    } else if (game.containsKey(key)) {
      out[key] = _deepCopy(game[key]);
    } else if (lines.containsKey(key)) {
      out[key] = _deepCopy(lines[key]);
    }
  }
  return out;
}

Map<String, dynamic> _mergePalabras({
  required Map<String, String> wordTable,
  required Object? rawPalabras,
  required bool hasPalabras,
  required String linesPath,
}) {
  final merged = <String, dynamic>{...wordTable};
  if (!hasPalabras || rawPalabras == null) {
    return merged;
  }
  if (rawPalabras is! Map) {
    throw FormatException('$linesPath: palabras must be a JSON object');
  }
  for (final entry in rawPalabras.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String) {
      throw FormatException('$linesPath: palabras keys must be strings');
    }
    if (value is String && value.isNotEmpty) {
      merged[key] = value;
    } else if (!merged.containsKey(key) && value is String) {
      merged[key] = value;
    }
  }
  return merged;
}

Object? _deepCopy(Object? value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key as String: _deepCopy(entry.value),
    };
  }
  if (value is List) {
    return <Object?>[for (final item in value) _deepCopy(item)];
  }
  return value;
}
