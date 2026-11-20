// The Repaso card's count ("N words today") is the count of the words Repaso can serve (page 15), by the one rule in
// coqui_contracts that the session asks too: not only the words that have a picture pair. A course that has not read
// the games' data keeps today's rule.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

RepasoSentence _sentence() => RepasoSentence(
  clip: 'a',
  story: 's1',
  text: 'Abuela pone la mesa.',
  tokens: const ['abuela', 'pone', 'la', 'mesa'],
  forbidden: const ['mesa'],
  forHearing: true,
  forBuilding: false,
);

/// puerta has a picture pair and its own sentence; mesa has none, and a sentence of story s1 that scores it; sol and
/// luna are two more words he has met (the wrong tiles beside that sentence).
RepasoData _games() => RepasoData(
  sentences: [_sentence()],
  words: [
    RepasoWord(
      word: 'puerta',
      place: 'casa',
      scoring: RepasoScoring.cual,
      pairLines: [RepasoPairLine(clip: 'p', text: 'Esta es la puerta.')],
    ),
    RepasoWord(
      word: 'mesa',
      place: 'casa',
      scoring: RepasoScoring.queOyes,
      sentences: const [0],
    ),
    RepasoWord(word: 'sol', place: 'casa', scoring: RepasoScoring.queOyes),
    RepasoWord(word: 'luna', place: 'casa', scoring: RepasoScoring.queOyes),
  ],
);

Rig _rig({RepasoData? games, bool played = true, bool mesaDue = true}) {
  final course = madeCourse(
    places: [
      place('casa', 1, 'La casa', ['s1']),
    ],
    stories: {
      's1': {'title': 'S1', 'focus_words': <String>[], 'clips': {}},
    },
    pairs: ['puerta'],
  )..repaso = games;
  final rig = Rig(course: course);
  if (played) rig.played('s1');
  rig.word('puerta', ear: 1, due: -1);
  rig.word('mesa', ear: 1, due: mesaDue ? -1 : 30);
  rig.word('sol', ear: 1, due: 30);
  rig.word('luna', ear: 1, due: 30);
  return rig;
}

void main() {
  testWidgets(
    'with the games\' data: a due word with no picture pair that a heard sentence can score is counted',
    (tester) async {
      await pumpTab(tester, _rig(games: _games()));
      // puerta (a pair) and mesa (a sentence of a story he has finished)
      expect(repaso(tester).line, '2 words today · about 1 min');
    },
  );

  testWidgets(
    'with no games\' data: today\'s rule, the words that have a picture pair',
    (tester) async {
      await pumpTab(tester, _rig());
      expect(repaso(tester).line, '1 word today · about 1 min');
    },
  );

  testWidgets(
    'a word Repaso cannot serve (its sentence is of a story he has not finished) is not counted',
    (tester) async {
      await pumpTab(tester, _rig(games: _games(), played: false));
      expect(repaso(tester).line, '1 word today · about 1 min');
    },
  );

  testWidgets(
    'Practice is on when only a word with no pair could be asked; off without the data',
    (tester) async {
      final withData = _rig(games: _games(), mesaDue: false);
      withData.word(
        'puerta',
        ear: 0,
      ); // nothing due, the pair word not heard yet
      await pumpTab(tester, withData);
      var r = repaso(tester);
      expect(
        (r.line, r.button, r.enabled),
        ('Nothing due today', 'Practice', true),
      );
      final without = _rig(mesaDue: false);
      without.word('puerta', ear: 0);
      await pumpTab(tester, without);
      r = repaso(tester);
      expect(
        (r.line, r.button, r.enabled),
        ('Nothing due today', 'Practice', false),
      );
    },
  );
}
