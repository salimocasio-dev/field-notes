import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/story_generator.dart';
import 'package:flutter_test/flutter_test.dart';

WordRecord known(String word) =>
    WordRecord(w: word, primera: 0, ear: SkillRecord(etapa: 4));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('coverage respects accents and recognizes known phrases only within an utterance', () {
    final vocabulary = ReadingVocabulary([known('té'), known('tengo sed')]);
    expect(readingCoverage('Tengo sed. Te doy té.', vocabulary).unknown, {
      'te': 1,
      'doy': 1,
    });
    expect(readingCoverage('Tengo. Sed.', vocabulary).unknown, {
      'tengo': 1,
      'sed': 1,
    });
  });

  test('the 98 percent floor is enforced at token level', () {
    final text = List.filled(98, 'casa').join(' ');
    final vocabulary = ReadingVocabulary([known('casa')]);
    final generator = StoryGenerator([
      (
        title: 'Casa',
        beats: [
          ['$text gato gato.'],
        ],
      ),
    ]);
    final story = generator.generate(
      vocabulary: vocabulary,
      focus: ['gato'],
      due: [],
      previous: {},
      rng: Mulberry32(1),
    );
    expect(story, isNotNull);
    expect(readingCoverage(story!.body, vocabulary).unknown, {'gato': 2});
    expect(
      meetsReadingCoverage(
        readingCoverage('$text gato gato gato.', vocabulary),
      ),
      isFalse,
    );
  });

  test('bundled combinations pass with their matching vocabulary and are offered once', () async {
    final generator = await StoryGenerator.load();
    final vocabulary = ReadingVocabulary([
      for (final plot in generator.plots)
        for (final beat in plot.beats)
          for (final option in beat)
            for (final word in readingWords(option)) known(word),
    ]);
    final used = <String>{};
    while (true) {
      final draft = generator.generate(
        vocabulary: vocabulary,
        focus: [],
        due: [],
        previous: used,
        rng: Mulberry32(2),
      );
      if (draft == null) break;
      expect(used.add(draft.body), isTrue);
      expect(
        meetsReadingCoverage(readingCoverage(draft.body, vocabulary)),
        isTrue,
      );
    }
    expect(used, hasLength(40));
  });

  test(
    'generation prioritizes due vocabulary and requires requested words',
    () {
      final vocabulary = ReadingVocabulary([
        known('casa'),
        known('gato'),
        known('perro'),
      ]);
      final generator = StoryGenerator([
        (
          title: 'Cat',
          beats: [
            ['Casa gato.'],
          ],
        ),
        (
          title: 'Dog',
          beats: [
            ['Casa perro.'],
          ],
        ),
      ]);
      StoryDraft? draft(String focus) => generator.generate(
        vocabulary: vocabulary,
        focus: [focus],
        due: ['gato'],
        previous: {},
        rng: Mulberry32(3),
      );
      expect(draft('')?.title, 'Cat');
      expect(draft('perro')?.title, 'Dog');
      expect(draft('libro'), isNull);
    },
  );

  test('canWrite matches generate(focus: []) across empty, eligible, and exhausted states', () async {
    final generator = await StoryGenerator.load();
    final emptyVocab = ReadingVocabulary(const []);
    expect(
      generator.canWrite(
        vocabulary: emptyVocab,
        due: const [],
        previous: const {},
      ),
      isFalse,
    );
    expect(
      generator.generate(
        vocabulary: emptyVocab,
        focus: const [],
        due: const [],
        previous: const {},
        rng: Mulberry32(4),
      ),
      isNull,
    );

    final fullVocab = ReadingVocabulary([
      for (final plot in generator.plots)
        for (final beat in plot.beats)
          for (final option in beat)
            for (final word in readingWords(option)) known(word),
    ]);
    final used = <String>{};
    while (true) {
      final can = generator.canWrite(
        vocabulary: fullVocab,
        due: const ['casa'],
        previous: used,
      );
      final draft = generator.generate(
        vocabulary: fullVocab,
        focus: const [],
        due: const ['casa'],
        previous: used,
        rng: Mulberry32(5),
      );
      expect(can, draft != null);
      if (draft == null) break;
      used.add(draft.body);
    }
    expect(
      generator.canWrite(vocabulary: fullVocab, due: const [], previous: used),
      isFalse,
    );
  });
}
