/// What the Palabras tab shows, worked out from the progress store and the course (app.html: `palabras`).
library;

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/text_rules.dart';

/// One card: the word's record, the review pair that gives it a picture (null: no picture), whether today's Repaso
/// asks it, and, for a word with no picture, the line he heard it in that the card shows instead (null: none).
class WordEntry {
  const WordEntry(this.record, this.pair, {this.today = false, this.line});
  final WordRecord record;
  final ReviewPair? pair;

  /// One of the words the Repaso card counts ("N words today"): due, with a picture pair, within the session's 10.
  final bool today;

  /// The shortest of the lines the word sheet lists under "Heard in" (stories he has played), for a word with no
  /// picture: the card shows it where a picture would be.
  final HeardLine? line;

  /// Good by ear: the scheduler's last stage (palabras.js: right on three returns over two weeks or more).
  bool get good => record.ear.etapa >= 4;
}

/// One place's heading and its words, in story order. `More words`: the words no played story brings.
class PlaceGroup {
  const PlaceGroup(this.name, this.words);
  final String name;
  final List<WordEntry> words;
}

/// What the tab lists: every word by place, today's Repaso words, or the words that are good.
enum WordFilter { all, today, good }

/// The stage names of palabras.js ("Stages he sees: heard, found, holding, good"), 0 being a skill not met yet.
String stageName(int etapa) => switch (etapa) {
  <= 0 => 'Not yet',
  1 => 'Heard',
  2 => 'Found',
  3 => 'Holding',
  _ => 'Good',
};

/// Whether [word] answers the find field's [query]: accents, case and punctuation ignored (`normalize`), a part of
/// the word is enough. An empty query lets every word through.
bool matchesQuery(String word, String query) {
  final q = normalize(query).trim();
  if (q.isEmpty) return true;
  return normalize(word).contains(q);
}

/// The groups the tab shows for [filter] and [query]: by place for every word and for the good ones (a place with
/// none left has no heading); today's words as one group with no heading, in the order Repaso asks them.
List<PlaceGroup> shownGroups(WordsView v, WordFilter filter, String query) {
  bool keep(WordEntry e) =>
      matchesQuery(e.record.w, query) &&
      switch (filter) {
        WordFilter.all => true,
        WordFilter.today => e.today,
        WordFilter.good => e.good,
      };
  if (filter == WordFilter.today) {
    final byWord = {
      for (final g in v.groups)
        for (final e in g.words) e.record.w: e,
    };
    final ws = [
      for (final w in v.todayWords)
        if (byWord[w] case final e? when keep(e)) e,
    ];
    return ws.isEmpty ? const [] : [PlaceGroup('', ws)];
  }
  return [
    for (final g in v.groups)
      if (g.words.where(keep).toList() case final ws when ws.isNotEmpty)
        PlaceGroup(g.name, ws),
  ];
}

/// The whole tab.
class WordsView {
  const WordsView({
    required this.groups,
    required this.reviewText,
    required this.reviewButton,
    required this.reviewOff,
    required this.practice,
    required this.added,
    this.todayWords = const [],
  });

  /// Empty when he has met no word: the tab says to play the first story.
  final List<PlaceGroup> groups;

  /// The Repaso card's grey line and the button's label.
  final String reviewText;
  final String reviewButton;

  /// `off`: nothing is due and nothing can be asked, so the button is disabled.
  final bool reviewOff;

  /// Nothing is due (`n == 0`): the button starts a practice session.
  final bool practice;

  /// `db().extra`: what he typed in "Add a word or a goal".
  final List<String> added;

  /// The words the Repaso card counts, in the order Repaso asks them (most overdue first).
  final List<String> todayWords;

  /// Every word on the tab.
  int get count => groups.fold(0, (n, g) => n + g.words.length);

  /// The words that are good by ear.
  int get goodCount =>
      groups.fold(0, (n, g) => n + g.words.where((e) => e.good).length);
}

// app.html: pares().m (CU.items by `w`, the last one of a word wins, as Map.set does)
/// The review pair of each word that has one, on the exact word.
Map<String, ReviewPair> pairsByWord(CourseCatalog course) => {
  for (final p in course.pairs) p.word: p,
};

// app.html: jug (the stories he has played, in the course's order)
/// The ids of the stories he has played, in the course's order.
List<String> playedStories(Services s) => [
  for (final l in s.course.places)
    for (final c in l.stories)
      if (s.progress.played(c)) c,
];

// app.html: palabras
Future<WordsView> buildWordsView(Services s) async {
  final progress = s.progress;
  final course = s.course;
  await course.load();
  final pairs = pairsByWord(course);
  final recs = [
    for (final r in progress.words)
      if (r.ear.etapa > 0 || r.mouth.n > 0) r,
  ];
  final played = playedStories(s);
  // the story files (cuentoJ): one that does not arrive is left out (STOV[c] is not there)
  final stories = <String, Map<String, dynamic>>{};
  await Future.wait([
    for (final c in played)
      course.story(c).then<void>((t) => stories[c] = t, onError: (Object _) {}),
  ]);
  // a word belongs to the place of the first story (in story order) that brings it, as a focus word first, else as
  // one that comes back
  final placeOf = <String, ({Place place, int k})>{};
  var k = 0;
  for (final pass in const ['focus_words', 'back_again']) {
    for (final l in course.places) {
      for (final c in l.stories) {
        final t = stories[c];
        if (t == null || !progress.played(c)) continue;
        for (final w in (t[pass] as List?) ?? const []) {
          placeOf.putIfAbsent(w as String, () => (place: l, k: k++));
        }
      }
    }
  }
  // ¿Cuál? asks only words he has heard that have a picture pair; a session is up to 10 words
  final due = [
    for (final w in progress.due(Skill.ear))
      if (pairs.containsKey(w)) w,
  ];
  final today = due.take(10).toList();
  // a word with no picture shows the shortest line he heard it in (the word sheet's "Heard in" lines)
  final lineOf = <String, HeardLine>{};
  await Future.wait([
    for (final r in recs)
      if (!pairs.containsKey(r.w))
        course.linesWith(r.w, played).then<void>((ls) {
          final best = shortestLine(ls, r.w);
          if (best != null) lineOf[r.w] = best;
        }, onError: (Object _) {}),
  ]);
  final todaySet = today.toSet();
  WordEntry entry(WordRecord r) => WordEntry(
    r,
    pairs[r.w],
    today: todaySet.contains(r.w),
    line: lineOf[r.w],
  );
  final groups = <PlaceGroup>[];
  for (final l in course.places) {
    final ws = [
      for (final r in recs)
        if (placeOf[r.w]?.place.id == l.id) r,
    ]..sort((a, b) => placeOf[a.w]!.k - placeOf[b.w]!.k);
    if (ws.isNotEmpty) groups.add(PlaceGroup(l.name, ws.map(entry).toList()));
  }
  final sin = [
    for (final r in recs)
      if (!placeOf.containsKey(r.w)) r,
  ];
  if (sin.isNotEmpty) {
    groups.add(PlaceGroup('More words', sin.map(entry).toList()));
  }
  final askable = [
    for (final r in recs)
      if (r.ear.etapa > 0 && pairs.containsKey(r.w)) r,
  ];
  final n = math.min(due.length, 10);
  final min = math.max(1, (n * 10 / 60 + 0.5).floor());
  return WordsView(
    groups: groups,
    reviewText: n > 0
        ? '$n word${n > 1 ? 's' : ''} today · about $min min'
        : 'Nothing due today',
    reviewButton: n > 0 ? 'Start' : 'Practice',
    reviewOff: n == 0 && askable.isEmpty,
    practice: n == 0,
    added: progress.added,
    todayWords: today,
  );
}

/// Of [lines], the shortest one in which [word] stands as a word, with its own accents (case and the punctuation
/// round it aside): "Esta es abuela." is not a line of "está". Null when none.
HeardLine? shortestLine(List<HeardLine> lines, String word) {
  final tokens = wordTokens(word);
  final exact = _bare(word);
  HeardLine? best;
  for (final l in lines) {
    final hit = occurrences(l.text, [
      tokens,
    ]).any((o) => _bare(l.text.substring(o.a, o.z)) == exact);
    if (!hit) continue;
    if (best == null || l.text.length < best.text.length) best = l;
  }
  return best;
}

final RegExp _edges = RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true);

// lower case, without the punctuation at either end ("¿Dónde está?" -> "dónde está")
String _bare(String s) => s.toLowerCase().replaceAll(_edges, '');
