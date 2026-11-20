// The one rule for which words Repaso can serve (the readers' fixes, item N): the session's plan, the Palabras tab's "N words
// today" and the map's Today card all ask it.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

RepasoSentence _s(
  String clip,
  String story,
  String text, {
  bool hear = true,
  List<String> forbidden = const [],
}) => RepasoSentence(
  clip: clip,
  story: story,
  text: text,
  tokens: repasoTokens(text),
  forbidden: forbidden,
  forHearing: hear,
  forBuilding: false,
);

RepasoWord _w(
  String w, {
  List<int> sentences = const [],
  List<RepasoPairLine> cual = const [],
}) => RepasoWord(
  word: w,
  place: 'casa',
  scoring: RepasoScoring.cual,
  sentences: sentences,
  pairLines: cual,
);

ReviewPair _pair(String w) => ReviewPair.fromJson({
  'w': w,
  'say': 'x',
  'si': {
    'cam': [0, 0],
  },
  'no': {
    'cam': [0, 0],
  },
}, scene: 'casa');

/// A progress store that answers only what the rule asks: the words met, the stories finished.
class _Progress implements ProgressStore {
  _Progress({
    this.met = const [],
    this.stories = const {},
    this.raw0 = const {},
  });
  final List<String> met;
  final Map<String, StoryRecord> stories;
  final Map<String, dynamic> raw0;

  @override
  Map<String, dynamic> get raw => raw0;

  @override
  WordRecord? word(String w) =>
      met.contains(w) ? WordRecord(w: w, primera: 1) : null;

  @override
  StoryRecord? story(String id) => stories[id];

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('$i');
}

class _Course implements CourseCatalog, RepasoCatalog {
  _Course(this.repaso, this.pairs);
  @override
  final RepasoData? repaso;
  @override
  final List<ReviewPair> pairs;

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('$i');
}

StoryRecord _played() => StoryRecord(n: 1, primera: 1);

void main() {
  // puerta: a pair of pictures and its own sentence; mesa: no pair, one ¿Qué oyes? sentence of story s1; sol and luna:
  // two met words that are in no sentence of it (the two wrong tiles); sin: nothing a game can use
  final data = RepasoData(
    sentences: [
      _s('a', 's1', 'Abuela pone la mesa.', forbidden: ['mesa']),
      _s('b', 's2', 'Mira la puerta.', forbidden: ['puerta']),
    ],
    words: [
      _w(
        'puerta',
        sentences: [1],
        cual: [RepasoPairLine(clip: 'p', text: 'Esta es la puerta.')],
      ),
      _w('mesa', sentences: [0]),
      _w('sol'),
      _w('luna'),
      _w('sin'),
    ],
  );
  ProgressStore learner({
    List<String> met = const ['puerta', 'mesa', 'sol', 'luna', 'sin'],
    Map<String, StoryRecord>? stories,
  }) => _Progress(met: met, stories: stories ?? {'s1': _played()});
  RepasoServing serving(
    ProgressStore p, {
    List<String> pairs = const ['puerta'],
  }) => RepasoServing(
    data: data,
    progress: p,
    pairs: [for (final w in pairs) _pair(w)],
  );

  test('a word with a picture pair is served by the pair\'s own sentence, whatever stories he has finished', () {
    final s = serving(learner(stories: {}));
    expect(s.canServe('puerta'), isTrue);
    expect(s.cualLines(data.word('puerta')!).single.clip, 'p');
  });

  test('a word with no pair is served by ¿Qué oyes? only from a finished story, with two fair wrong tiles', () {
    // s1 is finished, sol and luna are met and are in no word of the sentence
    expect(serving(learner()).canServe('mesa'), isTrue);
    // the story is not finished
    expect(serving(learner(stories: {})).canServe('mesa'), isFalse);
    // fewer than two wrong tiles: only sol is left to be met
    expect(serving(learner(met: ['mesa', 'sol'])).canServe('mesa'), isFalse);
    // a word with nothing for any game, and a word the data does not know
    expect(serving(learner()).canServe('sin'), isFalse);
    expect(serving(learner()).canServe('nada'), isFalse);
  });

  test('the wrong tiles are met words that are in no word of the sentence', () {
    final s = serving(learner());
    final tiles = s.wrongTileChoices(data.word('mesa')!, data.sentences[0]);
    expect([for (final t in tiles) t.word], ['puerta', 'sol', 'luna', 'sin']);
    // a word that is in the sentence is no tile
    final withSol = RepasoData(
      sentences: [
        _s('a', 's1', 'El sol sale.', forbidden: ['sol']),
      ],
      words: [
        _w('mesa', sentences: [0]),
        _w('sol'),
        _w('luna'),
      ],
    );
    final t = RepasoServing(
      data: withSol,
      progress: learner(),
      pairs: const [],
    ).wrongTileChoices(withSol.word('mesa')!, withSol.sentences[0]);
    expect([for (final x in t) x.word], ['luna']);
  });

  test('a story finished: played to its end, not only presumed by the level check; a picture story heard to its end', () {
    expect(repasoStoryFinished(learner(), 's1'), isTrue);
    expect(repasoStoryFinished(learner(), 'nope'), isFalse);
    final presumed = _Progress(
      stories: {'s1': StoryRecord(n: 1, primera: 1, presunto: 1)},
    );
    expect(repasoStoryFinished(presumed, 's1'), isFalse);
    final replayed = _Progress(
      stories: {'s1': StoryRecord(n: 2, primera: 1, presunto: 1)},
    );
    expect(repasoStoryFinished(replayed, 's1'), isTrue);
    final heard = _Progress(
      raw0: {
        'oidos': {'s9': 1},
      },
    );
    expect(repasoStoryFinished(heard, 's9'), isTrue);
  });

  test('a course that has not read the file gives no rule: the caller keeps today\'s (a word with a pair)', () {
    final p = learner();
    expect(repasoServing(_Course(data, [_pair('puerta')]), p), isNotNull);
    expect(repasoServing(_Course(null, [_pair('puerta')]), p), isNull);
    expect(repasoServing(_CourseOnly([_pair('puerta')]), p), isNull);
  });
}

/// A course that knows nothing of Repaso's data.
class _CourseOnly implements CourseCatalog {
  _CourseOnly(this.pairs);
  @override
  final List<ReviewPair> pairs;

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('$i');
}
