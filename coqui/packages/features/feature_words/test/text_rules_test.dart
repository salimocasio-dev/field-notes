// app.html: occs and vuelve, as pure functions.
import 'package:feature_words/src/text_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('app.html: vuelve (comesBack)', () {
    const now = 1795104000000;
    const dayMs = 86400000;

    test('no return date: nothing is said', () {
      expect(comesBack(0, now), '');
      expect(comesBack(double.nan, now), '');
    });

    test('due now or past: "Comes back today"', () {
      expect(comesBack(now, now), 'Comes back today');
      expect(comesBack(now - 5 * dayMs, now), 'Comes back today');
    });

    test('a day or less (rounded, at least one): "Comes back in 1 day"', () {
      expect(comesBack(now + 1, now), 'Comes back in 1 day');
      expect(comesBack(now + dayMs ~/ 2 - 1, now), 'Comes back in 1 day');
      expect(comesBack(now + dayMs, now), 'Comes back in 1 day');
      expect(comesBack(now + 1.49 * dayMs, now), 'Comes back in 1 day');
    });

    test('more: "Comes back in N days", Math.round (a half goes up)', () {
      expect(comesBack(now + 1.5 * dayMs, now), 'Comes back in 2 days');
      expect(comesBack(now + 2.4 * dayMs, now), 'Comes back in 2 days');
      expect(comesBack(now + 10 * dayMs, now), 'Comes back in 10 days');
    });

    test('a fraction of a millisecond in the stored date is read as it is', () {
      expect(comesBack(now + 3 * dayMs + 0.25, now), 'Comes back in 3 days');
    });
  });

  group('app.html: occs (occurrences)', () {
    List<String> found(String text, List<List<String>> phrases) => [
      for (final o in occurrences(text, phrases)) text.substring(o.a, o.z),
    ];

    test('a word, whatever its case, accents or punctuation', () {
      expect(found('Mira: abuela y ABUELO.', [wordTokens('abuelo')]), [
        'ABUELO',
      ]);
      expect(found('¿Qué está?', [wordTokens('esta')]), ['está']);
    });

    test('a phrase is a run of tokens', () {
      expect(found('Hola, ¿cómo estás? Bien.', [wordTokens('¿cómo estás?')]), [
        'cómo estás',
      ]);
      expect(found('cómo y estás', [wordTokens('cómo estás')]), isEmpty);
    });

    test('every place the word occurs, and nothing inside another word', () {
      expect(found('casa, casas, la casa', [wordTokens('casa')]), [
        'casa',
        'casa',
      ]);
    });

    test('the first phrase of the list that fits wins at a place', () {
      final o = occurrences('la casa grande', [
        wordTokens('casa grande'),
        wordTokens('casa'),
      ]);
      expect([for (final x in o) (x.a, x.z, x.k)], [(3, 14, 0)]);
    });

    test('offsets are UTF-16 offsets of the text', () {
      final o = occurrences('¡Sí! casa', [wordTokens('casa')]);
      expect((o.single.a, o.single.z), (5, 9));
    });
  });

  test('wordTokens: the normalised tokens of a word or phrase', () {
    expect(wordTokens('¿cómo estás?'), ['como', 'estas']);
    expect(wordTokens('Árbol'), ['arbol']);
  });
}
