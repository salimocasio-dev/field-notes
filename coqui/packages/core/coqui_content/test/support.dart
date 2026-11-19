import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

/// A file reader over a map of path -> text that keeps the paths it was asked for. A path that is not in the map
/// throws, as a fetch of a file that is not on the site does.
class Files {
  Files(Map<String, String> files) : files = {...files};

  final Map<String, String> files;
  final List<String> calls = [];

  Future<String> call(String path) async {
    calls.add(path);
    final text = files[path];
    if (text == null) throw StateError('no file $path');
    return text;
  }

  /// How many times [path] was asked for.
  int count(String path) => calls.where((p) => p == path).length;
}

const _deep = DeepCollectionEquality();

/// The same JSON: numbers compared as numbers, maps without regard to key order.
Matcher sameJson(Object? expected) => predicate<Object?>(
  (actual) => _deep.equals(jsonDecode(jsonEncode(actual)), expected),
  'the same JSON as ${jsonEncode(expected)}',
);

/// What the old code answers (made by tool/make_expected.mjs and tool/make_fixture.mjs): app.html's pares() and
/// oidoEn() and cual.js's cualCarga(), run in node over a tree of files.
class OldAnswers {
  OldAnswers(Map<String, dynamic> j)
    : words = List<String>.from(j['words'] as List),
      pairs = [
        for (final p in j['pairs'] as List) Map<String, dynamic>.from(p as Map),
      ],
      allPlayed = List<String>.from((j['played'] as Map)['all'] as List),
      place1Played = List<String>.from((j['played'] as Map)['place1'] as List),
      wordList = List<String>.from(j['wordList'] as List),
      _lines = Map<String, dynamic>.from(j['lines'] as Map),
      titles = Map<String, String>.from(j['titles'] as Map),
      urls = Map<String, String>.from(j['urls'] as Map);

  /// The keys of pares().m: one per distinct item word, in order.
  final List<String> words;

  /// CU.items: each item with its `esc` (the file's scene).
  final List<Map<String, dynamic>> pairs;

  /// The stories played in the two cases: every story of the places, and the first place's.
  final List<String> allPlayed;
  final List<String> place1Played;

  /// The words oidoEn was asked about.
  final List<String> wordList;
  final Map<String, dynamic> _lines;

  /// CURSO.cuentos[id].t.
  final Map<String, String> titles;

  /// Clip id -> the url juego.js builds.
  final Map<String, String> urls;

  /// oidoEn(word): [story id, clip id, text] for each line.
  List<List<String>> lines(String word, {required bool allStories}) => [
    for (final l
        in (_lines[word] as Map)[allStories ? 'all' : 'place1'] as List)
      List<String>.from(l as List),
  ];
}

/// What [lines] (from the old code) and [got] (from the catalog) say, as the same list of [story, clip, text]
/// and the old page's title for each story.
void expectSameLines(
  List<HeardLine> got,
  List<List<String>> lines,
  Map<String, String> titles,
  String why,
) {
  expect(
    [
      for (final l in got) [l.storyId, l.clipId, l.text],
    ],
    lines,
    reason: why,
  );
  for (final l in got) {
    expect(
      l.storyTitle,
      titles[l.storyId],
      reason: '$why: title of ${l.storyId}',
    );
  }
}
