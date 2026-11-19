// app.html `pares` and `occs`: which words of a line have a picture, and where.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_library/src/word_marks.dart';
import 'package:flutter_test/flutter_test.dart';

ReviewPair pair(String w) => ReviewPair.fromJson({
  'w': w,
  'say': 'x',
  'si': {
    'cam': [1, 2],
  },
  'no': {
    'cam': [3, 4],
  },
}, scene: 's');

List<List<String>> phrases(List<String> words) => [
  for (final w in words) normalize(w).trim().split(' '),
];

String at(String text, WordMark m) => text.substring(m.start, m.end);

void main() {
  group('occs: where the words of a list of phrases stand in a text', () {
    test('a word is found where it stands, with its own spelling', () {
      const text = 'La hermana dice: Hola.';
      final m = wordMarks(text, phrases(['hermana', 'hola']));
      expect(m.map((x) => at(text, x)), ['hermana', 'Hola']);
      expect(m.map((x) => x.k), [0, 1]);
      expect(m.first.start, 3);
      expect(m.first.end, 10);
    });

    test('accents, case and punctuation are ignored (matched on the normalised word)', () {
      const text = '¿CÓMO ESTÁS? Está aquí.';
      final m = wordMarks(text, phrases(['como estas', 'esta']));
      expect(m.map((x) => at(text, x)), ['CÓMO ESTÁS', 'Está']);
      expect(m.map((x) => x.k), [0, 1]);
    });

    test('a phrase is one mark from its first letter to its last', () {
      const text = 'Hola, ¿cómo estás hoy?';
      final m = wordMarks(text, phrases(['como estas']));
      expect(m, hasLength(1));
      expect(at(text, m.single), 'cómo estás');
    });

    test('the first phrase of the list that fits wins, so the longest when the list is sorted so', () {
      const text = 'como estas tu';
      final longFirst = wordMarks(text, phrases(['como estas', 'como']));
      expect(longFirst.map((x) => at(text, x)), ['como estas']);
      final shortFirst = wordMarks(text, phrases(['como', 'como estas']));
      expect(shortFirst.map((x) => at(text, x)), ['como']);
    });

    test('after a phrase the search goes on after its last word', () {
      const text = 'como estas como estas';
      final m = wordMarks(text, phrases(['como estas']));
      expect(m, hasLength(2));
      expect(m[1].start, 11);
    });

    test('every place a word stands is a mark', () {
      const text = 'hermana de la hermana';
      final m = wordMarks(text, phrases(['hermana']));
      expect(m.map((x) => x.start), [0, 14]);
    });

    test('a phrase that runs past the end of the text does not match', () {
      expect(wordMarks('como', phrases(['como estas'])), isEmpty);
    });

    test(
      'a word is a whole token: a longer word that holds it is not a match',
      () {
        expect(wordMarks('hermanastra', phrases(['hermana'])), isEmpty);
      },
    );

    test('numbers are tokens too; ñ is n', () {
      const text = 'el año 2026';
      final m = wordMarks(text, phrases(['ano', '2026']));
      expect(m.map((x) => at(text, x)), ['año', '2026']);
    });

    test('no phrases, or no text: nothing', () {
      expect(wordMarks('hola', const []), isEmpty);
      expect(wordMarks('', phrases(['hola'])), isEmpty);
    });
  });

  group('pares: the words that have a picture pair', () {
    test(
      'the longest phrase is first; equal lengths keep the order of the items',
      () {
        final w = PictureWords([
          pair('casa'),
          pair('como estas'),
          pair('agua'),
          pair('buenas noches amigo'),
          pair('luz'),
        ]);
        expect(w.list.map((x) => x.word), [
          'buenas noches amigo',
          'como estas',
          'casa',
          'agua',
          'luz',
        ]);
      },
    );

    test(
      'a word given twice is one: it keeps its first place and the last item',
      () {
        final first = pair('casa');
        final second = pair('casa');
        final w = PictureWords([first, pair('agua'), second]);
        expect(w.list.map((x) => x.word), ['casa', 'agua']);
        expect(identical(w.list.first.pair, second), isTrue);
      },
    );

    test('the tokens are the normalised word split at its spaces', () {
      final w = PictureWords([pair('¿Cómo estás?')]);
      expect(w.list.single.tokens, ['como', 'estas']);
    });

    test('marks find the words of a line, indexed in this list', () {
      final w = PictureWords([pair('casa'), pair('como estas')]);
      final m = w.marks('La casa. ¿Cómo estás?');
      // the phrase is first in the list
      expect(m.map((x) => x.k), [1, 0]);
    });
  });
}
