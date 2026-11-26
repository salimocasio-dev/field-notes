import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Thing;
import 'package:coqui_scenes/coqui_scenes.dart' show sceneRegistry;
import 'package:coqui_testing/coqui_testing.dart'
    show FakeCourseCatalog, arabicTestLanguage;
import 'package:coqui_ui/coqui_ui.dart' show NochePlayDisc;
import 'package:feature_story/src/play/play.dart';
import 'package:feature_story/src/play/trace_json.dart' show firstDifference;
import 'package:feature_story/src/runner/split_story.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/story_bubble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/differential.dart';
import '../tool/disk_course.dart';
import '../tool/frente_order.dart';
import '../tool/replay_scene.dart';
import '../tool/sha256.dart';
import '../tool/stand_in_scene.dart';
import '../tool/tool_progress.dart';
import 'real_scene.dart';
import 'support/rig.dart';
import 'support/screen_harness.dart';
import 'support/stories.dart';

final Language _frenchTestLanguage = Language(
  code: 'fr',
  englishName: 'French',
  nativeName: 'Français',
  recognitionLocale: 'fr-FR',
  direction: LanguageDirection.ltr,
  script: 'Latn',
  partnerName: 'Camille',
  callAgentId: 'agent_french_test',
  micWords: {
    'ready': 'Appuie et parle',
    'listening': 'Je t’écoute',
    'thinking': 'Un instant',
    'theySpeak': 'Écoute',
    'right': 'Très bien',
    'notYet': 'Encore une fois',
  },
  tabNames: {
    'library': 'Bibliothèque',
    'words': 'Mots',
    'map': 'Carte',
    'speak': 'Parler',
    'me': 'Moi',
  },
);

class _SplitMemoryCourse extends FakeCourseCatalog {
  _SplitMemoryCourse({
    required Language language,
    required this.games,
    required this.linesByStory,
    required Object wordsJson,
  }) : wordTable = parseStoryWordTable(wordsJson, expectedLang: language.code),
       super(language: language);

  final Map<String, Map<String, dynamic>> games;
  final Map<String, Map<String, dynamic>> linesByStory;
  final Map<String, String> wordTable;
  final Map<String, Future<Map<String, dynamic>>> _joined = {};

  @override
  Future<Map<String, dynamic>> story(String id) {
    final g = games[id];
    final l = linesByStory[id];
    if (g != null && l != null) {
      return _joined[id] ??= Future.value(
        joinSplitStory(
          game: g,
          lines: l,
          wordTable: wordTable,
          expectedLang: language.code,
        ),
      );
    }
    return super.story(id);
  }
}

class _CapturingProgress extends ToolProgress {
  final List<StoryResult> results = [];

  @override
  void storyFinished(StoryResult result) {
    results.add(result);
    super.storyFinished(result);
  }
}

Map<String, dynamic> _laLluviaLines({
  required String lang,
  required String title,
  required String place,
  required Map<String, dynamic> clipOverrides,
  Map<String, String>? palabras,
}) {
  // Every clip ID referenced in content/games/la-lluvia.json.
  final clips = <String, dynamic>{
    'esta_casa': {'who': 'narr', 'text': '$lang: Esta es la casa de abuela.'},
    'mira_casa': {'who': 'narr', 'text': '$lang: Mira la casa de abuela.'},
    'puedes_casa': {'who': 'narr', 'text': '$lang: Puedes tocar la casa?'},
    'muy_bien': {'who': 'narr', 'text': '$lang: Muy bien!'},
    'esta_puerta': {
      'who': 'narr',
      'text': '$lang: Esta es la puerta de la casa.',
    },
    'cerrada': {'who': 'narr', 'text': '$lang: Esta cerrada.'},
    'donde_puerta': {'who': 'narr', 'text': '$lang: Donde esta la puerta?'},
    'mira_ventana': {'who': 'narr', 'text': '$lang: Mira la ventana.'},
    'tambien_cerrada': {'who': 'narr', 'text': '$lang: Tambien esta cerrada.'},
    'toca_ventana': {'who': 'narr', 'text': '$lang: Toca la ventana.'},
    'viene_lluvia': {
      'who': 'narr',
      'text': '$lang: Mira! Ahi viene la lluvia.',
    },
    'abuela_en_ventana': {
      'who': 'narr',
      'text': '$lang: Abuela esta en la ventana.',
    },
    'abuela_en_puerta': {
      'who': 'narr',
      'text': '$lang: Abuela esta en la puerta.',
    },
    'toca_ventana_ya': {'who': 'narr', 'text': '$lang: Toca la ventana!'},
    'toca_puerta_ya': {'who': 'narr', 'text': '$lang: Toca la puerta!'},
    'esa_ventana': {'who': 'narr', 'text': '$lang: Esa es la ventana.'},
    'esa_puerta': {'who': 'narr', 'text': '$lang: Esa es la puerta.'},
    'hola_quien': {
      'who': 'narr',
      'habla': 'abuela',
      'text': '$lang: Hola! Quien es?',
    },
    'ahora_en_ventana': {
      'who': 'narr',
      'text': '$lang: Ahora abuela esta en la ventana.',
    },
    'ahora_en_puerta': {
      'who': 'narr',
      'text': '$lang: Ahora abuela esta en la puerta.',
    },
    'abre_ventana': {'who': 'narr', 'text': '$lang: Abuela abre la ventana.'},
    'abre_puerta': {'who': 'narr', 'text': '$lang: Abuela abre la puerta.'},
    'es_abuela': {'who': 'narr', 'text': '$lang: Mira! Es abuela.'},
    'hola_abuela': {'who': 'tu', 'text': '$lang: Hola, abuela!'},
    'abuela_dice': {
      'who': 'narr',
      'habla': 'abuela',
      'text': '$lang: Hola! Como estas?',
    },
    'entra': {'who': 'narr', 'habla': 'abuela', 'text': '$lang: Entra, entra!'},
    'mojado': {
      'who': 'narr',
      'habla': 'abuela',
      'text': '$lang: Estas mojado.',
    },
    'casa': {'who': 'narr', 'text': '$lang: Es la casa.'},
    'puerta': {'who': 'narr', 'text': '$lang: Es la puerta.'},
    'ventana': {'who': 'narr', 'text': '$lang: Es la ventana.'},
    'abuela': {'who': 'narr', 'text': '$lang: Esta es abuela.'},
    'sol': {'who': 'narr', 'text': '$lang: Es el sol.'},
    'palma': {'who': 'narr', 'text': '$lang: Es la palma.'},
    'lluvia': {'who': 'narr', 'text': '$lang: Es la lluvia.'},
    'ay_lluvia': {'who': 'tu', 'text': '$lang: Ay, la lluvia!'},
    'soy_yo': {'who': 'tu', 'text': '$lang: Soy yo, abuela! Abre!'},
    'abre_puerta_tu': {'who': 'tu', 'text': '$lang: Abre la puerta, abuela!'},
    'abre_ventana_tu': {'who': 'tu', 'text': '$lang: Abre la ventana, abuela!'},
    'bien_gracias': {'who': 'tu', 'text': '$lang: Bien, gracias!'},
    'estoy_mojado': {'who': 'tu', 'text': '$lang: Ay, abuela! Estoy mojado.'},
    'yo_coqui': {'who': 'tu', 'text': '$lang: Coqui!'},
    ...clipOverrides,
  };
  return {
    'format': splitLinesFormat,
    'id': 'la-lluvia',
    'lang': lang,
    'title': title,
    'place': place,
    'focus_words': const [
      'casa',
      'puerta',
      'ventana',
      'abuela',
      'hola',
      'toca',
      'abre',
    ],
    'names': const {'casa': 'casa', 'puerta': 'puerta', 'ventana': 'ventana'},
    'palabras': ?palabras,
    'clips': clips,
  };
}

void main() {
  final root = findRoot();
  final trazas = Directory('${root.path}/coqui/ref/trazas');
  final actsDir = Directory('test/fixtures/acts');
  final runs =
      (jsonDecode(File('${trazas.path}/runs.json').readAsStringSync())['runs']
              as List)
          .cast<Map<String, dynamic>>();
  final stories = {for (final r in runs) r['story'] as String}.toList();

  late DiskCourse legacyCourse;
  late DiskCourse splitCourse;

  setUpAll(() async {
    legacyCourse = DiskCourse(root);
    splitCourse = DiskCourse(root, useSplit: true);
    await legacyCourse.load();
    await splitCourse.load();
  });

  group('split_story helpers and validation', () {
    test(
      'parseStoryWordTable parses valid payload and rejects malformed ones',
      () {
        final table = parseStoryWordTable({
          'format': splitWordsFormat,
          'lang': 'fr',
          'words': {'casa': 'maison', 'nomas': '-'},
        }, expectedLang: 'fr');
        expect(table, {'casa': 'maison', 'nomas': '-'});
        expect(() => table['x'] = 'y', throwsUnsupportedError);

        expect(() => parseStoryWordTable('not-a-map'), throwsFormatException);
        expect(
          () => parseStoryWordTable({
            'format': 'wrong',
            'lang': 'fr',
            'words': <String, String>{},
          }),
          throwsFormatException,
        );
        expect(
          () => parseStoryWordTable({
            'format': splitWordsFormat,
            'lang': '../fr',
            'words': <String, String>{},
          }),
          throwsFormatException,
        );
        expect(
          () => parseStoryWordTable({
            'format': splitWordsFormat,
            'lang': 'es',
            'words': <String, String>{},
          }, expectedLang: 'fr'),
          throwsFormatException,
        );
        expect(
          () => parseStoryWordTable({
            'format': splitWordsFormat,
            'lang': 'fr',
            'words': {'casa': 123},
          }),
          throwsFormatException,
        );
      },
    );

    test('resolveStoryWord enforces lines.palabras > words.json > testedId and preserves -', () {
      const table = {
        'bebe': 'boit',
        'nino': 'garçon',
        'nomas': '-',
        'vacio': 'plein',
      };
      const storyPalabras = {'bebe': 'bébé', 'nino': '-', 'vacio': ''};

      expect(
        resolveStoryWord(
          'bebe',
          storyPalabras: storyPalabras,
          wordTable: table,
        ),
        'bébé',
      );
      expect(
        resolveStoryWord(
          'nino',
          storyPalabras: storyPalabras,
          wordTable: table,
        ),
        '-',
      );
      expect(
        resolveStoryWord(
          'nomas',
          storyPalabras: storyPalabras,
          wordTable: table,
        ),
        '-',
      );
      expect(
        resolveStoryWord(
          'vacio',
          storyPalabras: storyPalabras,
          wordTable: table,
        ),
        'plein',
      );
      expect(
        resolveStoryWord(
          'puerta',
          storyPalabras: storyPalabras,
          wordTable: table,
        ),
        'puerta',
      );
    });

    test(
      'joinSplitStory validates formats, ids, langs, keys, and cual items',
      () {
        Map<String, dynamic> validGame({Map<String, dynamic>? extra}) => {
          'format': splitGameFormat,
          'id': 'demo',
          'scene': 'frente',
          'beats': [
            {'wait': 10},
          ],
          'final': const <Object?>[],
          ...?extra,
        };
        Map<String, dynamic> validLines({Map<String, dynamic>? extra}) => {
          'format': splitLinesFormat,
          'id': 'demo',
          'lang': 'es',
          'title': 'Demo',
          'clips': const <String, dynamic>{},
          ...?extra,
        };

        expect(
          () => joinSplitStory(
            game: validGame()..['format'] = 'bad',
            lines: validLines(),
          ),
          throwsFormatException,
        );
        expect(
          () => joinSplitStory(
            game: validGame(),
            lines: validLines()..['format'] = 'bad',
          ),
          throwsFormatException,
        );
        expect(
          () => joinSplitStory(
            game: validGame()..['id'] = 'words',
            lines: validLines()..['id'] = 'words',
          ),
          throwsFormatException,
        );
        expect(
          () => joinSplitStory(
            game: validGame(),
            lines: validLines()..['id'] = 'other',
          ),
          throwsFormatException,
        );
        expect(
          () => joinSplitStory(
            game: validGame(),
            lines: validLines(),
            expectedLang: 'fr',
          ),
          throwsFormatException,
        );
        expect(
          () => joinSplitStory(
            game: validGame(),
            lines: validLines()..remove('title'),
          ),
          throwsFormatException,
        );
        expect(
          () => joinSplitStory(
            game: validGame(),
            lines: validLines()..remove('clips'),
          ),
          throwsFormatException,
        );
        expect(
          () => joinSplitStory(
            game: validGame(extra: {'unexpected': 1}),
            lines: validLines(),
          ),
          throwsFormatException,
        );
        expect(
          () => joinSplitStory(
            game: validGame(),
            lines: validLines(extra: {'unexpected': 1}),
          ),
          throwsFormatException,
        );
        expect(
          () => joinSplitStory(
            game: validGame(
              extra: {
                'tipo': 'cual',
                'items': [
                  {'say': 'a'},
                  {'say': 'b'},
                ],
              },
            ),
            lines: validLines(
              extra: {
                'item_words': ['uno'],
              },
            ),
          ),
          throwsFormatException,
        );
        expect(
          () => joinSplitStory(
            game: validGame(
              extra: {
                'tipo': 'cual',
                'items': [
                  {'w': 'already', 'say': 'a'},
                ],
              },
            ),
            lines: validLines(
              extra: {
                'item_words': ['uno'],
              },
            ),
          ),
          throwsFormatException,
        );
        expect(() => assembleStory(validGame()), throwsFormatException);
      },
    );

    test('joinSplitStory does not mutate caller inputs', () {
      final game = {
        'format': splitGameFormat,
        'id': 'demo',
        'scene': 'frente',
        'beats': [
          {'wait': 10},
        ],
        'final': const <Object?>[],
      };
      final lines = {
        'format': splitLinesFormat,
        'id': 'demo',
        'lang': 'fr',
        'title': 'Démo',
        'palabras': <String, dynamic>{'bebe': 'bébé'},
        'clips': <String, dynamic>{
          'c1': <String, dynamic>{'who': 'narr', 'text': 'Bonjour.'},
        },
      };
      final table = <String, String>{'casa': 'maison', 'bebe': 'boit'};

      final joined = joinSplitStory(
        game: game,
        lines: lines,
        wordTable: table,
        expectedLang: 'fr',
      );
      (joined['palabras'] as Map)['casa'] = 'mutated';
      ((joined['beats'] as List).first as Map)['wait'] = 999;

      expect((lines['palabras'] as Map).containsKey('casa'), isFalse);
      expect(((game['beats'] as List).first as Map)['wait'], 10);
      expect(table['casa'], 'maison');
    });

    test('DiskCourse(useSplit: true) joins cual and palabras-solas identically to legacy', () async {
      expect(splitCourse.wordTable['pajaro'], 'pájaro');
      expect(splitCourse.wordTable['nomas'], '-');

      for (final id in ['cual-balcon', 'palabras-solas']) {
        final legacy = await legacyCourse.story(id);
        final rawJoined = joinSplitStory(
          game: await splitCourse.game(id),
          lines: await splitCourse.lines(id),
          expectedLang: 'es',
        );
        expect(firstDifference(legacy, rawJoined), isNull, reason: id);

        final courseJoined = await splitCourse.story(id);
        expect(courseJoined['items'], legacy['items'], reason: id);
        expect(courseJoined['palabras'], splitCourse.wordTable, reason: id);
      }
    });
  });

  group('All 57 built stories x 3 plans (171 runs) split vs legacy parity', () {
    for (final s in stories) {
      test(
        '$s: right, wrong, alternate produce zero trace differences',
        () async {
          for (final plan in playPlans) {
            final committed = jsonDecode(
              File('${trazas.path}/$s/$plan.json').readAsStringSync(),
            ) as Map<String, dynamic>;
            final run = jsonDecode(
              File('${actsDir.path}/$s/$plan.acts.json').readAsStringSync(),
            ) as Map<String, dynamic>;
            final legacyStory = await legacyCourse.story(s);
            final game = await splitCourse.game(s);
            final lines = await splitCourse.lines(s);
            final wrongs = [
              for (final t
                  in (committed['touches'] as List)
                      .cast<Map<String, dynamic>>())
                if (t['why'] == 'wrong-poke')
                  (t: (t['t'] as num).toInt(), what: t['what'] as String),
            ];
            List<String> wrongOrder(Map<String, dynamic> W, int now) {
              for (final w in wrongs) {
                if (w.t >= now) return [w.what];
              }
              return const [];
            }

            final sha = sha256Hex(legacyCourse.storyBytes(s));
            final seed = committed['seed'] as int;

            late ReplayScene legacyScene;
            final legacyTrace = await play(
              story: legacyStory,
              plan: plan,
              seed: seed,
              sceneFor: (rng) => legacyScene = ReplayScene(
                sceneId: legacyStory['scene'] as String,
                story: legacyStory,
                run: run,
                rng: rng,
              ),
              course: legacyCourse,
              progress: ToolProgress(),
              storySha256: sha,
              thingOrder: wrongOrder,
            );
            expect(legacyScene.divergences, isEmpty, reason: '$s $plan legacy');

            late ReplayScene splitScene;
            final splitTrace = await play(
              story: game,
              lines: lines,
              wordTable: splitCourse.wordTable,
              plan: plan,
              seed: seed,
              sceneFor: (rng) => splitScene = ReplayScene(
                sceneId: game['scene'] as String,
                story: game,
                run: run,
                rng: rng,
              ),
              course: splitCourse,
              progress: ToolProgress(),
              storySha256: sha,
              thingOrder: wrongOrder,
            );
            expect(splitScene.divergences, isEmpty, reason: '$s $plan split');

            expect(
              firstDifference(
                forComparison(legacyTrace),
                forComparison(splitTrace),
              ),
              isNull,
              reason: '$s $plan legacy vs split',
            );
            expect(
              firstDifference(
                forComparison(committed),
                forComparison(splitTrace),
              ),
              isNull,
              reason: '$s $plan committed vs split',
            );

            expect(
              (splitTrace['steps'] as List).length,
              (legacyTrace['steps'] as List).length,
            );
            expect(
              (splitTrace['decisions'] as List).length,
              (legacyTrace['decisions'] as List).length,
            );
            expect(
              (splitTrace['touches'] as List).length,
              (legacyTrace['touches'] as List).length,
            );
            expect(splitTrace['draws'], legacyTrace['draws']);
            expect(splitTrace['lost'], legacyTrace['lost']);
            expect(splitTrace['ending'], legacyTrace['ending']);
            expect(splitTrace['virtualMs'], legacyTrace['virtualMs']);
          }
        },
      );
    }
  });

  group('Real converted scenes split vs legacy parity', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Pick the first story in runs.json for each converted scene so every real
    // scene in registryScenes with content/games/ stories is verified across
    // all 3 plans without duplicating the full 171-run suite above.
    final representativeByScene = <String, String>{};
    for (final r in runs) {
      final sceneId = r['scene'] as String;
      if (sceneRegistry.containsKey(sceneId)) {
        representativeByScene.putIfAbsent(sceneId, () => r['story'] as String);
      }
    }

    test('covers all 12 converted scenes from trazas', () {
      expect(representativeByScene.length, 12);
    });

    for (final entry in representativeByScene.entries) {
      final sceneId = entry.key;
      final s = entry.value;
      test(
        '$s ($sceneId): split matches legacy identically across 3 plans',
        () async {
          final legacyStory = await legacyCourse.story(s);
          final game = await splitCourse.game(s);
          final lines = await splitCourse.lines(s);
          final sha = sha256Hex(legacyCourse.storyBytes(s));
          final sceneFactory = await realSceneFor(sceneId);
          final thingOrder = sceneId == 'frente' ? frenteThingOrder : null;

          for (final plan in playPlans) {
            final committed = jsonDecode(
              File('${trazas.path}/$s/$plan.json').readAsStringSync(),
            ) as Map<String, dynamic>;
            final seed = committed['seed'] as int;

            final legacyTrace = await play(
              story: legacyStory,
              plan: plan,
              seed: seed,
              sceneFor: sceneFactory,
              course: legacyCourse,
              progress: ToolProgress(),
              storySha256: sha,
              thingOrder: thingOrder,
              startFrog: startFrogOf,
              frogShadow: frogShadowOf,
            );
            final splitTrace = await play(
              story: game,
              lines: lines,
              wordTable: splitCourse.wordTable,
              plan: plan,
              seed: seed,
              sceneFor: sceneFactory,
              course: splitCourse,
              progress: ToolProgress(),
              storySha256: sha,
              thingOrder: thingOrder,
              startFrog: startFrogOf,
              frogShadow: frogShadowOf,
            );

            expect(
              splitTrace['errors'],
              isEmpty,
              reason: '$s ($sceneId) $plan errors',
            );
            expect(
              firstDifference(
                forComparison(legacyTrace),
                forComparison(splitTrace),
              ),
              isNull,
              reason: '$s ($sceneId) $plan real scene split vs legacy',
            );
          }
        },
      );
    }
  });

  group(
    'Non-Spanish language split playback, resolution precedence, and Screen',
    () {
      test('StoryRunner & play resolve words.json, per-story palabras overrides, and "-" suppression', () async {
        final game = <String, dynamic>{
          'format': splitGameFormat,
          'id': 'homonym-check',
          'scene': 'prueba',
          'stake': {'thing': 'x', 'steps': 3},
          'dots': 3,
          'beats': [
            {
              'decide': 'tap',
              'options': ['casa', 'puerta'],
              'pick': 'casa',
              'line': 'q1',
            },
            {
              'decide': 'tap',
              'options': ['bebe', 'puerta'],
              'pick': 'bebe',
              'line': 'q2',
            },
            {
              'decide': 'tap',
              'options': ['nino', 'puerta'],
              'pick': 'nino',
              'line': 'q3',
            },
            {
              'decide': 'tap',
              'options': ['nomas', 'puerta'],
              'pick': 'nomas',
              'line': 'q4',
            },
            {
              'decide': 'tap',
              'options': ['ventana', 'puerta'],
              'pick': 'ventana',
              'line': 'q5',
            },
          ],
          'final': const <Object?>[],
        };
        final frLines = <String, dynamic>{
          'format': splitLinesFormat,
          'id': 'homonym-check',
          'lang': 'fr',
          'title': 'Vérification',
          'focus_words': const ['maison', 'bébé', 'fenêtre'],
          'palabras': const {
            'bebe': 'bébé', // overrides words.json 'bebe': 'boit'
            'nino': '-', // suppresses words.json 'nino': 'garçon'
            'casa': '', // empty does NOT clobber words.json 'casa': 'maison'
          },
          'clips': const {
            'q1': {'who': 'narr', 'text': 'Touche la maison.'},
            'q2': {'who': 'narr', 'text': 'Touche le bébé.'},
            'q3': {'who': 'narr', 'text': 'Touche le garçon.'},
            'q4': {'who': 'narr', 'text': 'Encore.'},
            'q5': {'who': 'narr', 'text': 'Touche la fenêtre.'},
            'muy_bien': {'who': 'narr', 'text': 'Très bien !'},
          },
        };
        final frWordTable = parseStoryWordTable({
          'format': splitWordsFormat,
          'lang': 'fr',
          'words': const {
            'casa': 'maison',
            'bebe': 'boit',
            'nino': 'garçon',
            'nomas': '-',
            'ventana': 'fenêtre',
          },
        }, expectedLang: 'fr');

        final frCourse = TestCourse(language: _frenchTestLanguage);
        final progress = _CapturingProgress();
        final trace = await play(
          story: game,
          lines: frLines,
          wordTable: frWordTable,
          plan: 'right',
          seed: 1,
          sceneFor: (_) => StandInScene(
            things: [
              Thing(id: 'casa', box: [10, 10, 20, 20]),
              Thing(id: 'bebe', box: [40, 10, 20, 20]),
              Thing(id: 'nino', box: [70, 10, 20, 20]),
              Thing(id: 'nomas', box: [100, 10, 20, 20]),
              Thing(id: 'ventana', box: [130, 10, 20, 20]),
              Thing(id: 'puerta', box: [160, 10, 20, 20]),
            ],
          ),
          course: frCourse,
          progress: progress,
        );

        expect(trace['errors'], isEmpty);
        expect(progress.results, hasLength(1));
        final loggedWords = [
          for (final d in progress.results.single.log) d.word,
        ];
        expect(loggedWords, ['maison', 'bébé', 'fenêtre']);

        // Direct StoryRunner with split game + lines + wordTable.
        final runnerProgress = TestProgress();
        final rig = await Rig.make(
          game,
          lines: frLines,
          wordTable: frWordTable,
          course: frCourse,
          progress: runnerProgress,
          scene: StandInScene(
            things: [
              Thing(id: 'casa', box: [10, 10, 20, 20]),
              Thing(id: 'bebe', box: [40, 10, 20, 20]),
              Thing(id: 'nino', box: [70, 10, 20, 20]),
              Thing(id: 'nomas', box: [100, 10, 20, 20]),
              Thing(id: 'ventana', box: [130, 10, 20, 20]),
              Thing(id: 'puerta', box: [160, 10, 20, 20]),
            ],
          ),
        );
        await rig.finish((pn) => pn.pick ?? pn.live.first);
        expect(rig.runner.view.title, 'Vérification');
        expect(
          [for (final d in runnerProgress.finished.single.log) d.word],
          ['maison', 'bébé', 'fenêtre'],
        );
      });

      test('real content/games/la-lluvia.json plays in French via play() and logs French words', () async {
        final game = await splitCourse.game('la-lluvia');
        final frLines = _laLluviaLines(
          lang: 'fr',
          title: 'La pluie',
          place: 'La maison',
          clipOverrides: const {
            'esta_casa': {'who': 'narr', 'text': 'Voici la maison de mamie.'},
            'abuela_dice': {
              'who': 'narr',
              'habla': 'abuela',
              'text': 'Mamie : Bonjour Coquí !',
            },
          },
        );
        final frWordTable = parseStoryWordTable({
          'format': splitWordsFormat,
          'lang': 'fr',
          'words': const {
            'casa': 'maison',
            'puerta': 'porte',
            'ventana': 'fenêtre',
          },
        }, expectedLang: 'fr');

        final frCourse = _SplitMemoryCourse(
          language: _frenchTestLanguage,
          games: {'la-lluvia': game},
          linesByStory: {'la-lluvia': frLines},
          wordsJson: {
            'format': splitWordsFormat,
            'lang': 'fr',
            'words': frWordTable,
          },
        );
        await frCourse.load();
        final sceneFactory = await realSceneFor('frente');
        final progress = _CapturingProgress();

        final trace = await play(
          story: game,
          lines: frLines,
          wordTable: frWordTable,
          plan: 'right',
          seed: 1,
          sceneFor: sceneFactory,
          course: frCourse,
          progress: progress,
          thingOrder: frenteThingOrder,
          startFrog: startFrogOf,
          frogShadow: frogShadowOf,
        );

        expect(trace['errors'], isEmpty);
        expect(trace['finished'], isTrue);
        final loggedWords = [
          for (final d in progress.results.single.log) d.word,
        ];
        expect(loggedWords, isNotEmpty);
        expect(loggedWords, containsAll(['porte', 'fenêtre']));
        expect(loggedWords, isNot(contains('puerta')));
        expect(loggedWords, isNot(contains('ventana')));
      });

      testWidgets(
        'StoryScreen plays real content/games/la-lluvia.json with French split lines',
        (tester) async {
          final game = await splitCourse.game('la-lluvia');
          final elBizcocho = await splitCourse.game('el-bizcocho');
          final dondePajaro = await splitCourse.game('donde-esta-el-pajaro');

          final frLines = _laLluviaLines(
            lang: 'fr',
            title: 'La pluie',
            place: 'La maison',
            clipOverrides: const {
              'esta_casa': {'who': 'narr', 'text': 'Voici la maison de mamie.'},
              'abuela_dice': {
                'who': 'narr',
                'habla': 'abuela',
                'text': 'Mamie : Bonjour Coquí !',
              },
            },
          );
          final frCourse = _SplitMemoryCourse(
            language: _frenchTestLanguage,
            games: {
              'la-lluvia': game,
              'el-bizcocho': elBizcocho,
              'donde-esta-el-pajaro': dondePajaro,
            },
            linesByStory: {
              'la-lluvia': frLines,
              'el-bizcocho': _laLluviaLines(
                lang: 'fr',
                title: 'Le gâteau',
                place: 'La maison',
                clipOverrides: const {},
              )..['id'] = 'el-bizcocho',
              'donde-esta-el-pajaro': _laLluviaLines(
                lang: 'fr',
                title: 'Où est l’oiseau ?',
                place: 'La maison',
                clipOverrides: const {},
              )..['id'] = 'donde-esta-el-pajaro',
            },
            wordsJson: const {
              'format': splitWordsFormat,
              'lang': 'fr',
              'words': {
                'casa': 'maison',
                'puerta': 'porte',
                'ventana': 'fenêtre',
              },
            },
          );

          final fr = await openScreen(
            tester,
            id: 'la-lluvia',
            course: frCourse,
          );
          expect(tester.takeException(), isNull);
          expect(fr.opened, isTrue);

          await tester.tap(find.byType(NochePlayDisc));
          await fr.until(
            () => fr.runner.view.captionOn && fr.runner.view.caption.isNotEmpty,
            what: 'first French caption',
          );
          expect(fr.runner.view.caption, 'Voici la maison de mamie.');
          expect(find.text('Voici la maison de mamie.'), findsOneWidget);

          await fr.answerUntil(
            () => fr.runner.view.screen == StoryScreenState.end,
            what: 'French end screen',
          );
          await fr.advance(300);
          expect(find.text('La pluie'), findsOneWidget);
          expect(find.text('Play again'), findsOneWidget);
        },
      );

      testWidgets(
        'StoryScreen plays real content/games/la-lluvia.json with Arabic RTL split lines',
        (tester) async {
          final game = await splitCourse.game('la-lluvia');
          final elBizcocho = await splitCourse.game('el-bizcocho');
          final dondePajaro = await splitCourse.game('donde-esta-el-pajaro');

          final arLines = _laLluviaLines(
            lang: 'ar',
            title: 'المطر',
            place: 'البيت',
            clipOverrides: const {
              'esta_casa': {'who': 'narr', 'text': 'هذا بيت الجدة.'},
              'ay_lluvia': {'who': 'tu', 'text': 'آه، المطر!'},
              'abuela_dice': {
                'who': 'narr',
                'habla': 'abuela',
                'text': 'الجدة: مرحباً كوكي!',
              },
            },
          );
          final arCourse = _SplitMemoryCourse(
            language: arabicTestLanguage,
            games: {
              'la-lluvia': game,
              'el-bizcocho': elBizcocho,
              'donde-esta-el-pajaro': dondePajaro,
            },
            linesByStory: {
              'la-lluvia': arLines,
              'el-bizcocho': _laLluviaLines(
                lang: 'ar',
                title: 'الكعكة',
                place: 'البيت',
                clipOverrides: const {},
              )..['id'] = 'el-bizcocho',
              'donde-esta-el-pajaro': _laLluviaLines(
                lang: 'ar',
                title: 'أين الطائر؟',
                place: 'البيت',
                clipOverrides: const {},
              )..['id'] = 'donde-esta-el-pajaro',
            },
            wordsJson: const {
              'format': splitWordsFormat,
              'lang': 'ar',
              'words': {'casa': 'بيت', 'puerta': 'باب', 'ventana': 'نافذة'},
            },
          );

          final ar = await openScreen(
            tester,
            id: 'la-lluvia',
            course: arCourse,
          );
          expect(tester.takeException(), isNull);
          expect(ar.opened, isTrue);

          await tester.tap(find.byType(NochePlayDisc));
          await ar.until(
            () => ar.runner.view.captionOn && ar.runner.view.caption.isNotEmpty,
            what: 'first Arabic split caption',
          );
          final arCap = tester.widget<Text>(find.text('هذا بيت الجدة.'));
          expect(arCap.textDirection, TextDirection.rtl);
          expect(arCap.locale, const Locale('ar'));

          await ar.answerUntil(
            () =>
                ar.runner.view.bubbleOn &&
                ar.runner.view.bubbleKind == BubbleKind.words &&
                ar.runner.view.bubbleText.isNotEmpty,
            what: 'Arabic split speech bubble',
          );
          final arBubble = tester.widget<Text>(
            find.descendant(
              of: find.byType(StoryBubbleBody),
              matching: find.byType(Text),
            ),
          );
          expect(arBubble.textDirection, TextDirection.rtl);

          await ar.answerUntil(
            () => ar.runner.view.screen == StoryScreenState.end,
            what: 'Arabic split end screen',
          );
          await ar.advance(300);
          final arTitle = tester.widget<Text>(find.text('المطر'));
          expect(arTitle.textDirection, TextDirection.rtl);
          expect(find.text('Play again'), findsOneWidget);
        },
      );
    },
  );

  group('Legacy compatibility and runner/play validation errors', () {
    test('legacy single-file story with empty wordTable plays identically without mutating input', () async {
      final legacy = story(
        beats: [
          {
            'decide': 'tap',
            'options': ['casa', 'puerta'],
            'pick': 'casa',
            'line': 'ask_casa',
          },
        ],
        clips: {'ask_casa': 'Toca la casa.', 'muy_bien': '¡Muy bien!'},
      );
      final beforeJson = jsonEncode(legacy);

      final trace = await play(
        story: legacy,
        plan: 'right',
        seed: 1,
        sceneFor: (_) => StandInScene(
          things: [
            Thing(id: 'casa', box: [10, 10, 20, 20]),
            Thing(id: 'puerta', box: [40, 10, 20, 20]),
          ],
        ),
        course: TestCourse(),
        progress: ToolProgress(),
      );

      expect(trace['finished'], isTrue);
      expect(jsonEncode(legacy), beforeJson);
    });

    test(
      'StoryRunner and play reject split game without lines or mismatched lang',
      () async {
        final game = await splitCourse.game('la-lluvia');
        final esLines = await splitCourse.lines('la-lluvia');

        expect(
          () => play(
            story: game,
            plan: 'right',
            seed: 1,
            sceneFor: (_) => StandInScene(),
            course: splitCourse,
            progress: ToolProgress(),
          ),
          throwsFormatException,
        );

        expect(
          () => play(
            story: game,
            lines: esLines,
            plan: 'right',
            seed: 1,
            sceneFor: (_) => StandInScene(),
            course: TestCourse(language: _frenchTestLanguage),
            progress: ToolProgress(),
          ),
          throwsFormatException,
        );

        expect(
          () => Rig.make(game, course: TestCourse(), scene: StandInScene()),
          throwsFormatException,
        );
      },
    );
  });
}
