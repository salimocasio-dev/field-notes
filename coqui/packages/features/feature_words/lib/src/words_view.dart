/// What the Palabras tab shows, worked out from the progress store and the course (app.html: `palabras`).
library;

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';

/// One card: the word's record and the review pair that gives it a picture (null: a plain tile).
class WordEntry {
  const WordEntry(this.record, this.pair);
  final WordRecord record;
  final ReviewPair? pair;
}

/// One place's heading and its words, in story order. `More words`: the words no played story brings.
class PlaceGroup {
  const PlaceGroup(this.name, this.words);
  final String name;
  final List<WordEntry> words;
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
  WordEntry entry(WordRecord r) => WordEntry(r, pairs[r.w]);
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
  // Repaso asks the words it can serve (page 15: a word with a picture pair, or one a sentence he has heard can score;
  // the one rule lives in coqui_contracts, where the session asks it too); a course that has not read the games' data
  // plays today's ¿Cuál?, which asks only words that have a picture pair. A session is up to 10 words.
  final serving = repasoServing(course, progress);
  bool serves(String w) =>
      serving != null ? serving.canServe(w) : pairs.containsKey(w);
  final due = [
    for (final w in progress.due(Skill.ear))
      if (serves(w)) w,
  ];
  final askable = [
    for (final r in recs)
      if (r.ear.etapa > 0 && serves(r.w)) r,
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
  );
}
