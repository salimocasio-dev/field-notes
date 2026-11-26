import 'dart:convert';

import 'package:coqui_content/coqui_content.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

import 'fixture/small_tree.dart';
import 'support.dart';

Map<String, dynamic> _tree(String path) =>
    jsonDecode(smallTree[path]!) as Map<String, dynamic>;

Map<String, dynamic> _frenchIdioma() => {
  'code': 'fr',
  'englishName': 'French',
  'nativeName': 'Français',
  'recognitionLocale': 'fr-FR',
  'direction': 'ltr',
  'script': 'Latn',
  'partnerName': 'Camille',
  'callAgentId': 'agent_french_test',
  'micWords': {
    'ready': 'Touche et parle',
    'listening': 'Je t’écoute',
    'thinking': 'Un moment',
    'theySpeak': 'Écoute',
    'right': 'Très bien !',
    'notYet': 'Encore',
  },
  'tabNames': {
    'library': 'Bibliothèque',
    'words': 'Mots',
    'map': 'Carte',
    'speak': 'Parler',
    'me': 'Moi',
  },
};

void main() {
  group('parseWordTable', () {
    test(
      'parses valid coqui.words.v1 payload and returns unmodifiable map',
      () {
        final table = parseWordTable(
          {
            'format': splitWordsFormat,
            'lang': 'fr',
            'words': {'ventana': 'fenêtre', 'puerta': 'porte', 'nomas': '-'},
          },
          'lines/fr/words.json',
          expectedLang: 'fr',
        );
        expect(table, {'ventana': 'fenêtre', 'puerta': 'porte', 'nomas': '-'});
        expect(() => table['casa'] = 'maison', throwsUnsupportedError);
      },
    );

    test('throws FormatException on malformed payloads', () {
      final badCases = <String, Object?>{
        'non-object': [1, 2],
        'wrong format': {
          'format': 'coqui.words.v0',
          'lang': 'es',
          'words': <String, String>{},
        },
        'missing lang': {
          'format': splitWordsFormat,
          'words': <String, String>{},
        },
        'empty lang': {
          'format': splitWordsFormat,
          'lang': '',
          'words': <String, String>{},
        },
        'unsafe lang': {
          'format': splitWordsFormat,
          'lang': '../es',
          'words': <String, String>{},
        },
        'lang mismatch': {
          'format': splitWordsFormat,
          'lang': 'es',
          'words': <String, String>{},
        },
        'non-map words': {
          'format': splitWordsFormat,
          'lang': 'fr',
          'words': ['casa'],
        },
        'non-string word value': {
          'format': splitWordsFormat,
          'lang': 'fr',
          'words': {'casa': 42},
        },
      };

      for (final entry in badCases.entries) {
        expect(
          () => parseWordTable(
            entry.value,
            'lines/fr/words.json',
            expectedLang: 'fr',
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              startsWith('lines/fr/words.json: '),
            ),
          ),
          reason: entry.key,
        );
      }
    });
  });

  group('resolveTestedWord', () {
    const table = <String, String>{
      'ventana': 'fenêtre',
      'bebe': 'boit',
      'nino': 'garçon',
      'nomas': '-',
    };

    test('follows storyPalabras -> wordTable -> testedId precedence', () {
      expect(
        resolveTestedWord(
          'ventana',
          storyPalabras: const {'bebe': 'bébé'},
          wordTable: table,
        ),
        'fenêtre',
      );
      expect(
        resolveTestedWord(
          'bebe',
          storyPalabras: const {'bebe': 'bébé'},
          wordTable: table,
        ),
        'bébé',
      );
      expect(
        resolveTestedWord(
          'ventana',
          storyPalabras: const {'ventana': ''},
          wordTable: table,
        ),
        'fenêtre',
      );
      expect(
        resolveTestedWord(
          'nino',
          storyPalabras: const {'nino': '-'},
          wordTable: table,
        ),
        '-',
      );
      expect(
        resolveTestedWord('nomas', storyPalabras: null, wordTable: table),
        '-',
      );
      expect(
        resolveTestedWord('unmapped', storyPalabras: null, wordTable: table),
        'unmapped',
      );
    });
  });

  group('joinSplitStory', () {
    test('reconstructs items from item_words, deep copies inputs, and preserves palabras when wordTable is empty', () {
      final game = <String, dynamic>{
        'format': splitGameFormat,
        'id': 'cual-casa',
        'scene': 'frente',
        'tipo': 'cual',
        'items': [
          {
            'say': 'c_1',
            'si': {
              'cam': [0, 0, 10, 10],
              'set': {'puerta': 'open'},
            },
            'no': {
              'cam': [1, 1, 10, 10],
            },
          },
        ],
      };
      final lines = <String, dynamic>{
        'format': splitLinesFormat,
        'id': 'cual-casa',
        'lang': 'fr',
        'title': 'La maison',
        'place': 'Maison',
        'palabras': {'bebe': 'bébé', 'nino': '-'},
        'clips': {
          'c_1': {'who': 'narr', 'text': 'La fenêtre.'},
        },
        'item_words': ['fenêtre'],
      };

      final joined = joinSplitStory(
        game,
        lines,
        expectedLang: 'fr',
        gamePath: 'games/cual-casa.json',
        linesPath: 'lines/fr/cual-casa.json',
      );

      expect(joined.keys.toList(), [
        'id',
        'title',
        'place',
        'scene',
        'tipo',
        'palabras',
        'clips',
        'items',
      ]);
      expect(joined['items'], [
        {
          'w': 'fenêtre',
          'say': 'c_1',
          'si': {
            'cam': [0, 0, 10, 10],
            'set': {'puerta': 'open'},
          },
          'no': {
            'cam': [1, 1, 10, 10],
          },
        },
      ]);
      expect(joined['palabras'], {'bebe': 'bébé', 'nino': '-'});

      // Deep copy: mutating joined does not mutate inputs and vice versa.
      ((joined['items'] as List).first as Map)['si']['cam'][0] = 99;
      expect(((game['items'] as List).first as Map)['si']['cam'][0], 0);
      (lines['clips'] as Map)['c_1']['text'] = 'changed';
      expect((joined['clips'] as Map)['c_1']['text'], 'La fenêtre.');
    });

    test('merges wordTable beneath per-story palabras without clobbering on empty strings', () {
      final game = <String, dynamic>{
        'format': splitGameFormat,
        'id': 'la-lluvia',
        'scene': 'frente',
        'beats': <Object?>[],
        'final': <Object?>[],
      };
      final lines = <String, dynamic>{
        'format': splitLinesFormat,
        'id': 'la-lluvia',
        'lang': 'fr',
        'title': 'La pluie',
        'palabras': {'bebe': 'bébé', 'nino': '-', 'ventana': ''},
        'clips': <String, Object?>{},
      };

      final joined = joinSplitStory(
        game,
        lines,
        expectedLang: 'fr',
        wordTable: const {
          'ventana': 'fenêtre',
          'puerta': 'porte',
          'bebe': 'boit',
          'nino': 'garçon',
        },
      );

      expect(joined['palabras'], {
        'ventana': 'fenêtre',
        'puerta': 'porte',
        'bebe': 'bébé',
        'nino': '-',
      });
    });

    test('validates schema, ids, lang, keys, and items/item_words', () {
      Map<String, dynamic> validGame() => {
        'format': splitGameFormat,
        'id': 'la-lluvia',
        'scene': 'frente',
      };
      Map<String, dynamic> validLines() => {
        'format': splitLinesFormat,
        'id': 'la-lluvia',
        'lang': 'fr',
        'title': 'La pluie',
        'clips': <String, Object?>{},
      };

      expect(
        () => joinSplitStory(
          {...validGame(), 'format': 'bad'},
          validLines(),
          gamePath: 'games/la-lluvia.json',
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            startsWith('games/la-lluvia.json: '),
          ),
        ),
      );
      expect(
        () => joinSplitStory(validGame(), {...validLines(), 'format': 'bad'}),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(
          {...validGame(), 'id': 'words'},
          {...validLines(), 'id': 'words'},
        ),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(
          {...validGame(), 'id': '../bad'},
          {...validLines(), 'id': '../bad'},
        ),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(validGame(), {...validLines(), 'id': 'other'}),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(validGame(), {
          ...validLines(),
          'lang': 'es',
        }, expectedLang: 'fr'),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(validGame(), validLines()..remove('title')),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(validGame(), validLines()..remove('clips')),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory({...validGame(), 'extra': 1}, validLines()),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(validGame(), {...validLines(), 'extra': 1}),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(
          {...validGame(), 'items': <Object?>[]},
          {...validLines()},
        ),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(validGame(), {
          ...validLines(),
          'item_words': <String>[],
        }),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(
          {
            ...validGame(),
            'items': [
              {'say': 'a'},
            ],
          },
          {...validLines(), 'item_words': <String>[]},
        ),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(
          {
            ...validGame(),
            'items': [
              {'w': 'should_not_exist', 'say': 'a'},
            ],
          },
          {
            ...validLines(),
            'item_words': ['mot'],
          },
        ),
        throwsFormatException,
      );
      expect(
        () => joinSplitStory(
          {
            ...validGame(),
            'items': [
              {'say': 'a'},
            ],
          },
          {
            ...validLines(),
            'item_words': [42],
          },
        ),
        throwsFormatException,
      );
    });
  });

  group('ContentCatalog with fetchSplit', () {
    test('serves shared games with French lines, words.json, review pairs, and palabras-solas', () async {
      const dummyPic = {
        'cam': [0, 0, 100, 100],
      };
      final frCurso = {
        'idioma': _frenchIdioma(),
        'lugares': [
          {
            'id': 'casa',
            'n': 1,
            'nombre': 'La maison',
            'en': 'The house',
            'cuentos': ['la-lluvia', 'legacy-only'],
          },
        ],
        'cuentos': {
          'la-lluvia': {'t': 'La pluie', 'min': 3},
          'legacy-only': {'t': 'Héritage', 'min': 2},
        },
        'cual': ['cual-casa'],
      };

      final splitFiles = Files({
        'games/cual-casa.json': jsonEncode({
          'format': splitGameFormat,
          'id': 'cual-casa',
          'scene': 'frente',
          'tipo': 'cual',
          'items': [
            {'say': 'fr_1', 'si': dummyPic, 'no': dummyPic},
            {'say': 'fr_2', 'si': dummyPic, 'no': dummyPic},
          ],
        }),
        'lines/fr/cual-casa.json': jsonEncode({
          'format': splitLinesFormat,
          'id': 'cual-casa',
          'lang': 'fr',
          'title': 'Lequel ?',
          'clips': {
            'fr_1': {'who': 'narr', 'text': 'La fenêtre est grande.'},
            'fr_2': {'who': 'narr', 'text': 'La porte est ouverte.'},
          },
          'item_words': ['fenêtre', 'porte'],
        }),
        'games/la-lluvia.json': jsonEncode({
          'format': splitGameFormat,
          'id': 'la-lluvia',
          'scene': 'frente',
          'beats': [
            {
              'decide': 'toca',
              'options': ['ventana', 'puerta'],
            },
          ],
          'final': <Object?>[],
          'leer': ['fr_lluvia_1'],
        }),
        'lines/fr/la-lluvia.json': jsonEncode({
          'format': splitLinesFormat,
          'id': 'la-lluvia',
          'lang': 'fr',
          'title': 'La pluie',
          'place': 'La maison',
          'palabras': {'bebe': 'bébé', 'nino': '-'},
          'clips': {
            'fr_lluvia_1': {'who': 'abuela', 'text': 'Ouvre la fenêtre.'},
          },
        }),
        'games/palabras-solas.json': jsonEncode({
          'format': splitGameFormat,
          'id': 'palabras-solas',
          'tipo': 'palabras',
          'note': 'Shared word-alone skeleton',
        }),
        'lines/fr/palabras-solas.json': jsonEncode({
          'format': splitLinesFormat,
          'id': 'palabras-solas',
          'lang': 'fr',
          'title': 'Mots seuls',
          'clips': {
            'w_fenetre': {'who': 'narr', 'text': 'Fenêtre.'},
          },
        }),
        'lines/fr/words.json': jsonEncode({
          'format': splitWordsFormat,
          'lang': 'fr',
          'words': {
            'ventana': 'fenêtre',
            'puerta': 'porte',
            'casa': 'maison',
            'bebe': 'boit',
            'nino': 'garçon',
          },
        }),
      });

      final legacyFiles = Files({
        ...smallTree,
        'datos/curso.json': jsonEncode(frCurso),
        'cuentos/legacy-only.json': jsonEncode({
          'id': 'legacy-only',
          'title': 'Héritage',
          'scene': 'frente',
          'clips': {
            'leg_1': {'who': 'narr', 'text': 'Histoire legacy.'},
          },
        }),
        'audio/ready.json': jsonEncode({
          'v': 7,
          'clips': ['fr_1', 'fr_2', 'fr_lluvia_1', 'w_fenetre'],
        }),
        'audio/marcas.json': jsonEncode({
          'fr_1': [0, 900, 1000],
          'fr_2': [0, 900, 1000],
          'fr_lluvia_1': [0, 1100, 1200],
          'w_fenetre': [0, 800, 900],
        }),
      });

      final catalog = ContentCatalog(
        legacyFiles.call,
        fetchSplit: splitFiles.call,
      );
      await catalog.load();

      expect(catalog.language.code, 'fr');
      expect(catalog.wordTable, {
        'ventana': 'fenêtre',
        'puerta': 'porte',
        'casa': 'maison',
        'bebe': 'boit',
        'nino': 'garçon',
      });

      // Review sets came from split tree and populated French ReviewPairs.
      expect([for (final p in catalog.pairs) p.word], ['fenêtre', 'porte']);
      expect(catalog.pairFor('fenetre')!.word, 'fenêtre');
      expect(catalog.pairFor('PORTE')!.word, 'porte');
      expect(legacyFiles.calls, isNot(contains('cuentos/cual-casa.json')));
      expect(splitFiles.calls, contains('games/cual-casa.json'));
      expect(splitFiles.calls, contains('lines/fr/cual-casa.json'));
      expect(splitFiles.calls, contains('lines/fr/words.json'));

      // palabras-solas loaded from split tree for active language.
      expect(catalog.clip('w_fenetre')!.text, 'Fenêtre.');
      expect(legacyFiles.calls, isNot(contains('cuentos/palabras-solas.json')));

      // Split story merges words.json beneath per-story palabras overrides/suppressions.
      final story = await catalog.story('la-lluvia');
      expect(story['title'], 'La pluie');
      expect(story['palabras'], {
        'ventana': 'fenêtre',
        'puerta': 'porte',
        'casa': 'maison',
        'bebe': 'bébé',
        'nino': '-',
      });
      expect(catalog.resolveWord('ventana'), 'fenêtre');
      expect(
        catalog.resolveWord(
          'bebe',
          storyPalabras: story['palabras'] as Map<String, dynamic>,
        ),
        'bébé',
      );
      expect(
        catalog.resolveWord(
          'nino',
          storyPalabras: story['palabras'] as Map<String, dynamic>,
        ),
        '-',
      );

      // linesWith searches the French joined story text.
      final heard = await catalog.linesWith('fenêtre', ['la-lluvia']);
      expect(heard, hasLength(1));
      expect(heard.single.clipId, 'fr_lluvia_1');
      expect(heard.single.text, 'Ouvre la fenêtre.');

      // Legacy fallback when story is absent from fetchSplit.
      final legacy = await catalog.story('legacy-only');
      expect(legacy['title'], 'Héritage');
      expect(legacyFiles.count('cuentos/legacy-only.json'), 1);
    });

    test('missing words.json is allowed, while corrupt words.json throws FormatException', () async {
      final legacyFiles = Files(smallTree);
      final noWordsSplit = Files({
        'games/cual-casa.json': jsonEncode({
          'format': splitGameFormat,
          'id': 'cual-casa',
          'scene': 'frente',
          'tipo': 'cual',
          'items': const <Object?>[],
        }),
      });
      final okCatalog = ContentCatalog(
        legacyFiles.call,
        fetchSplit: noWordsSplit.call,
      );
      await okCatalog.load();
      expect(okCatalog.wordTable, isEmpty);
      expect(okCatalog.resolveWord('puerta'), 'puerta');

      final corruptCatalog = ContentCatalog(
        legacyFiles.call,
        fetchSplit: Files({'lines/es/words.json': '{not json'}).call,
      );
      await expectLater(
        corruptCatalog.load(),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            startsWith('lines/es/words.json: '),
          ),
        ),
      );
      expect(corruptCatalog.loaded, isFalse);

      final wrongLangCatalog = ContentCatalog(
        legacyFiles.call,
        fetchSplit: Files({
          'lines/es/words.json': jsonEncode({
            'format': splitWordsFormat,
            'lang': 'fr',
            'words': <String, String>{},
          }),
        }).call,
      );
      await expectLater(wrongLangCatalog.load(), throwsFormatException);
      expect(wrongLangCatalog.loaded, isFalse);
    });

    test('missing lines for an existing game throws clearly and corrupt game JSON rethrows FormatException', () async {
      final splitFiles = Files({
        'games/la-lluvia.json': jsonEncode({
          'format': splitGameFormat,
          'id': 'la-lluvia',
          'scene': 'frente',
        }),
        'games/bad-json.json': '{broken',
      });
      final legacyFiles = Files({
        ...smallTree,
        'cuentos/bad-json.json': jsonEncode({
          'id': 'bad-json',
          'title': 'Should not fall back',
          'clips': <String, Object?>{},
        }),
      });
      final catalog = ContentCatalog(
        legacyFiles.call,
        fetchSplit: splitFiles.call,
      );
      await catalog.load();

      // Missing lines/<lang>/<id>.json throws and is not cached.
      await expectLater(catalog.story('la-lluvia'), throwsA(isA<StateError>()));
      expect(legacyFiles.calls, isNot(contains('cuentos/la-lluvia.json')));

      splitFiles.files['lines/es/la-lluvia.json'] = jsonEncode({
        'format': splitLinesFormat,
        'id': 'la-lluvia',
        'lang': 'es',
        'title': 'La lluvia',
        'clips': <String, Object?>{},
      });
      expect((await catalog.story('la-lluvia'))['title'], 'La lluvia');

      // Corrupt game JSON throws FormatException immediately (no legacy fallback).
      await expectLater(
        catalog.story('bad-json'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            startsWith('games/bad-json.json: '),
          ),
        ),
      );
      expect(legacyFiles.calls, isNot(contains('cuentos/bad-json.json')));
    });

    test(
      'fetchSplit works for Spanish course too using smallTree fixture',
      () async {
        final firstId =
            (_tree('datos/curso.json')['lugares'] as List)
                    .cast<Map<String, dynamic>>()
                    .first['cuentos'][0]
                as String;
        final rawStory = _tree('cuentos/$firstId.json');
        final esSplit = Files({
          'lines/es/words.json': jsonEncode({
            'format': splitWordsFormat,
            'lang': 'es',
            'words': {'puerta': 'puerta'},
          }),
          'games/$firstId.json': jsonEncode({
            'format': splitGameFormat,
            'id': firstId,
            if (rawStory.containsKey('scene')) 'scene': rawStory['scene'],
            if (rawStory.containsKey('next')) 'next': rawStory['next'],
            if (rawStory.containsKey('goal')) 'goal': rawStory['goal'],
            if (rawStory.containsKey('stake')) 'stake': rawStory['stake'],
            if (rawStory.containsKey('beats')) 'beats': rawStory['beats'],
            if (rawStory.containsKey('final')) 'final': rawStory['final'],
            if (rawStory.containsKey('leer')) 'leer': rawStory['leer'],
          }),
          'lines/es/$firstId.json': jsonEncode({
            'format': splitLinesFormat,
            'id': firstId,
            'lang': 'es',
            'title': rawStory['title'],
            if (rawStory.containsKey('place')) 'place': rawStory['place'],
            if (rawStory.containsKey('focus_words'))
              'focus_words': rawStory['focus_words'],
            if (rawStory.containsKey('also_heard'))
              'also_heard': rawStory['also_heard'],
            if (rawStory.containsKey('names')) 'names': rawStory['names'],
            if (rawStory.containsKey('palabras'))
              'palabras': rawStory['palabras'],
            'clips': rawStory['clips'],
          }),
        });

        final catalog = ContentCatalog(
          Files(smallTree).call,
          fetchSplit: esSplit.call,
        );
        await catalog.load();
        expect(catalog.language, Language.spanish);
        expect(catalog.wordTable, {'puerta': 'puerta'});
        final joined = await catalog.story(firstId);
        expect(joined['title'], rawStory['title']);
        expect((joined['palabras'] as Map)['puerta'], 'puerta');
      },
    );
  });
}
