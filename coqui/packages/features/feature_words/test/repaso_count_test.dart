// The "Start review" / "Practice" button uses the one serving rule in
// coqui_contracts (page 15: picture pair OR a heard sentence that scores it).
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_words/src/wording.dart';
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

Rig _rig({
  RepasoData? games,
  bool played = true,
  bool puertaDue = true,
  bool mesaDue = true,
}) {
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
  rig.word('puerta', ear: 1, due: puertaDue ? -1 : 30);
  rig.word('mesa', ear: 1, due: mesaDue ? -1 : 30);
  rig.word('sol', ear: 1, due: 30);
  rig.word('luna', ear: 1, due: 30);
  return rig;
}

void main() {
  testWidgets(
    'with games data: a due word with no picture pair that a heard sentence can score enables Start review',
    (tester) async {
      await pumpTab(tester, _rig(games: _games(), puertaDue: false));
      final btn = reviewButton(tester);
      expect((btn.label, btn.enabled), (WordsWording.startReview, true));
      expect(dueCardCount(tester), '1');
    },
  );

  testWidgets(
    'with no games data: only picture-pair due words trigger Start review; otherwise Practice',
    (tester) async {
      await pumpTab(tester, _rig(puertaDue: false, mesaDue: true));
      final btn = reviewButton(tester);
      expect((btn.label, btn.enabled), (WordsWording.practice, true));
      // The due card still reflects the skill's due word (mesa).
      expect(dueCardCount(tester), '1');
    },
  );

  testWidgets(
    'a word Repaso cannot serve (its sentence is of an unplayed story) does not trigger Start review',
    (tester) async {
      await pumpTab(
        tester,
        _rig(games: _games(), played: false, puertaDue: false, mesaDue: true),
      );
      final btn = reviewButton(tester);
      expect((btn.label, btn.enabled), (WordsWording.practice, true));
    },
  );

  testWidgets(
    'Practice is enabled when only a word with no pair could be asked with games data; disabled without',
    (tester) async {
      final withData = _rig(games: _games(), puertaDue: false, mesaDue: false);
      withData.word('puerta', ear: 0);
      await pumpTab(tester, withData);
      expect(
        (reviewButton(tester).label, reviewButton(tester).enabled),
        (WordsWording.practice, true),
      );

      final without = _rig(puertaDue: false, mesaDue: false);
      without.word('puerta', ear: 0);
      await pumpTab(tester, without);
      expect(
        (reviewButton(tester).label, reviewButton(tester).enabled),
        (WordsWording.practice, false),
      );
    },
  );
}
