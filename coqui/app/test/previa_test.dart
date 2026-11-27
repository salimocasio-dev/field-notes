// The preview content (lib/src/previa.dart): the overlay merged into the site's course, the preview story files read from
// the bundle, the app as it is with no overlay, and a preview story opened from the map and played to its end, silent.
import 'dart:convert';
import 'dart:io';

import 'package:app/src/previa.dart';
import 'package:coqui_content/coqui_content.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart' show NocheTabs;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// The site's files under historia/, read from disk; every path asked for is kept in [asked].
FetchText siteFiles(List<String> asked) => (path) {
  asked.add(path);
  final f = File('$repoRoot/historia/$path');
  if (!f.existsSync()) return Future.error(StateError('404 $path'));
  return Future.value(f.readAsStringSync());
};

/// A preview bundle in memory: `curso.json` and `cuentos/<id>.json`.
PreviaRead memoryPrevia(Map<String, String> files, [List<String>? asked]) =>
    (path) async {
      asked?.add(path);
      return files[path];
    };

/// An overlay of [places] (place id -> its stories), each story titled after its id.
String overlayOf(Map<String, List<String>> places) => jsonEncode({
  'lugares': places,
  'cuentos': {
    for (final ids in places.values)
      for (final id in ids) id: {'t': 'T $id', 'min': 3},
  },
});

/// A preview story made from a story of the site: [from]'s file with a new id, title and place, no `next`, and one line
/// that has no recording (so that, as a story of the content lane before it is recorded, it is told silent: the story
/// runner gives a story its voice only when every line has one). [scene] replaces its scene.
String previewStory(String from, String id, {String? scene}) {
  final j = jsonDecode(
    repoFile('historia/cuentos/$from.json'),
  ) as Map<String, dynamic>;
  j['id'] = id;
  j['title'] = 'Previa $id';
  j['place'] = 'El colmado';
  j.remove('next');
  if (scene != null) j['scene'] = scene;
  (j['clips'] as Map)['pv_sin_grabar'] = {
    'who': 'narr',
    'text': 'Una línea sin grabar.',
  };
  return jsonEncode(j);
}

Map<String, dynamic> obj(String text) =>
    jsonDecode(text) as Map<String, dynamic>;

List<String> storiesOf(Map<String, dynamic> course, String place) => [
  for (final l in course['lugares'] as List)
    if ((l as Map)['id'] == place) ...?(l['cuentos'] as List?)?.cast<String>(),
];

void main() {
  final site = repoFile('historia/datos/curso.json');
  final siteCourse = obj(site);
  final cocina = storiesOf(siteCourse, 'cocina');

  group('the merge', () {
    final overlay = PreviaOverlay.parse(
      overlayOf({
        'colmado': ['p-uno', 'p-dos', 'p-tres'],
        'calle': ['p-cuatro'],
      }),
    );

    test('the site lists none of the overlay\'s stories: all of them are merged, each at the end of its place', () {
      final m = mergeCourse(site, overlay);
      expect(m.preview, {'p-uno', 'p-dos', 'p-tres', 'p-cuatro'});
      final j = obj(m.text);
      expect(storiesOf(j, 'colmado'), ['p-uno', 'p-dos', 'p-tres']);
      expect(storiesOf(j, 'calle'), ['p-cuatro']);
      expect((j['cuentos'] as Map)['p-dos'], {'t': 'T p-dos', 'min': 3});
      // nothing else of the site's course changes
      expect(storiesOf(j, 'cocina'), cocina);
      expect(
        (j['cuentos'] as Map).length,
        (siteCourse['cuentos'] as Map).length + 4,
      );
      for (final k in siteCourse.keys) {
        if (k == 'lugares' || k == 'cuentos') continue;
        expect(j[k], siteCourse[k], reason: k);
      }
      final places = j['lugares'] as List;
      expect(places.length, (siteCourse['lugares'] as List).length);
      for (var i = 0; i < places.length; i++) {
        final a = Map.of(places[i] as Map)..remove('cuentos');
        final b = Map.of((siteCourse['lugares'] as List)[i] as Map)
          ..remove('cuentos');
        expect(a, b);
      }
    });

    test('the site lists some of them: the site wins for those (its place, its title), the others are merged', () {
      // the content lane has published p-dos in El colmado (with its own title) and p-cuatro in another place
      final j0 = obj(site);
      for (final l in j0['lugares'] as List) {
        if ((l as Map)['id'] == 'colmado') l['cuentos'] = ['p-dos'];
        if (l['id'] == 'plaza') l['cuentos'] = ['p-cuatro'];
      }
      (j0['cuentos'] as Map)['p-dos'] = {'t': 'Del sitio', 'min': 9};
      (j0['cuentos'] as Map)['p-cuatro'] = {'t': 'También', 'min': 8};
      final m = mergeCourse(jsonEncode(j0), overlay);
      expect(m.preview, {'p-uno', 'p-tres'});
      final j = obj(m.text);
      expect(storiesOf(j, 'colmado'), ['p-dos', 'p-uno', 'p-tres']);
      expect(storiesOf(j, 'calle'), isEmpty);
      expect(storiesOf(j, 'plaza'), ['p-cuatro']);
      expect((j['cuentos'] as Map)['p-dos'], {'t': 'Del sitio', 'min': 9});
      expect((j['cuentos'] as Map)['p-uno'], {'t': 'T p-uno', 'min': 3});
    });

    test('the site lists all of them: the site\'s file is given as it is, byte for byte', () {
      final j0 = obj(site);
      for (final l in j0['lugares'] as List) {
        if ((l as Map)['id'] == 'colmado') {
          l['cuentos'] = ['p-uno', 'p-dos', 'p-tres'];
        }
        if (l['id'] == 'calle') l['dibujos'] = ['p-cuatro'];
      }
      for (final id in ['p-uno', 'p-dos', 'p-tres', 'p-cuatro']) {
        (j0['cuentos'] as Map)[id] = {'t': id, 'min': 4};
      }
      final text = const JsonEncoder.withIndent('  ').convert(j0);
      final m = mergeCourse(text, overlay);
      expect(m.preview, isEmpty);
      expect(identical(m.text, text), isTrue);
    });

    test('a place the site does not have gets nothing; an empty overlay gives the site\'s file as it is', () {
      final m = mergeCourse(
        site,
        PreviaOverlay.parse(
          overlayOf({
            'luna': ['p-x'],
          }),
        ),
      );
      expect(m.preview, isEmpty);
      expect(identical(m.text, site), isTrue);
      final e = mergeCourse(site, PreviaOverlay.empty);
      expect(identical(e.text, site), isTrue);
    });

    test('an overlay that is not the overlay\'s shape is refused', () {
      for (final bad in [
        '[]',
        '{"lugares": {}}',
        '{"lugares": {"colmado": ["a"]}, "cuentos": {}}', // a story with no {t, min}
        '{"lugares": {}, "cuentos": {"a": {"t": "A", "min": 2}}}', // {t, min} of no listed story
        '{"lugares": {"colmado": ["a"], "calle": ["a"]}, "cuentos": {"a": {"t": "A", "min": 2}}}', // twice
        '{"lugares": {"colmado": ["a"]}, "cuentos": {"a": {"t": "A"}}}',
      ]) {
        expect(
          () => PreviaOverlay.parse(bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });
  });

  group('the fetch', () {
    test('a preview story\'s file is the bundled one; the site\'s stories and every other file are the site\'s', () async {
      final asked = <String>[], bundle = <String>[];
      final fetch = previaFetch(
        siteFiles(asked),
        memoryPrevia({
          'curso.json': overlayOf({
            'colmado': ['p-uno', 'la-lluvia'],
          }),
          'cuentos/p-uno.json': '{"id":"p-uno"}',
          'cuentos/la-lluvia.json': '{"id":"not the site\'s"}',
        }, bundle),
      );
      final course = obj(await fetch('datos/curso.json'));
      // la-lluvia is the site's (El frente's first story): the overlay's copy is ignored
      expect(storiesOf(course, 'colmado'), ['p-uno']);
      expect(await fetch('cuentos/p-uno.json'), '{"id":"p-uno"}');
      expect(
        await fetch('cuentos/la-lluvia.json'),
        repoFile('historia/cuentos/la-lluvia.json'),
      );
      expect(
        await fetch('audio/ready.json'),
        repoFile('historia/audio/ready.json'),
      );
      expect(asked, [
        'datos/curso.json',
        'cuentos/la-lluvia.json',
        'audio/ready.json',
      ]);
      expect(bundle, ['curso.json', 'cuentos/p-uno.json']);
      // the book of a preview story is asked of the site (it has none: the catalog then has no book)
      await expectLater(fetch('libros/p-uno.json'), throwsStateError);
    });

    test('the catalog over the fetch: the place has its preview stories, with their titles, and reads them', () async {
      final course = ContentCatalog(
        previaFetch(
          siteFiles([]),
          memoryPrevia({
            'curso.json': overlayOf({
              'colmado': ['p-uno'],
            }),
            'cuentos/p-uno.json': previewStory('la-lluvia', 'p-uno'),
          }),
        ),
      );
      await course.load();
      final colmado = course.places.firstWhere((p) => p.id == 'colmado');
      expect(colmado.stories, ['p-uno']);
      expect(course.meta('p-uno')!.title, 'T p-uno');
      expect((await course.story('p-uno'))['scene'], 'frente');
      expect(await course.book('p-uno'), isNull);
    });
  });

  group('no overlay is today', () {
    // every path the catalog reads, with what it got, by a catalog over [fetch]
    Future<Map<String, String>> readAll(FetchText fetch) async {
      final got = <String, String>{};
      Future<String> keep(String path) async => got[path] = await fetch(path);
      final course = ContentCatalog(keep);
      await course.load();
      for (final l in course.places) {
        for (final c in [...l.stories, ...l.pictureStories, ...l.routines]) {
          await course.story(c);
          await course.book(c);
        }
      }
      await course.linesWith('casa', [
        for (final l in course.places) ...l.stories,
      ]);
      return got;
    }

    test('an empty, a missing and a broken overlay: every file the catalog reads is the site\'s, byte for byte, in the same order', () async {
      final today = <String>[];
      final plain = await readAll(siteFiles(today));
      for (final previa in <PreviaRead>[
        memoryPrevia({'curso.json': '{"lugares": {}, "cuentos": {}}'}),
        memoryPrevia({}),
        noPrevia,
        memoryPrevia({'curso.json': '{"lugares": '}),
      ]) {
        final asked = <String>[];
        final got = await readAll(previaFetch(siteFiles(asked), previa));
        expect(asked, today);
        expect(got.keys, plain.keys);
        for (final k in plain.keys) {
          expect(identical(got[k], plain[k]) || got[k] == plain[k], isTrue);
        }
      }
    });

    testWidgets(
      'the bundled overlay is the overlay\'s shape, and every story it lists is bundled and names itself',
      (tester) async {
        final read = bundledPrevia(rootBundle);
        final text = (await tester.runAsync(() => read('curso.json')))!;
        final o = PreviaOverlay.parse(text);
        for (final ids in o.places.values) {
          for (final id in ids) {
            final f = (await tester.runAsync(() => read('cuentos/$id.json')))!;
            expect(obj(f)['id'], id);
          }
        }
        // the folder holds the overlay's stories and nothing else (make_previa.py --check says whether they are current)
        final dir = Directory('$repoRoot/coqui/app/assets/previa/cuentos');
        expect(
          {
            for (final f in dir.listSync())
              if (f.path.endsWith('.json')) f.uri.pathSegments.last,
          },
          {for (final id in o.metas.keys) '$id.json'},
        );
      },
    );
  });

  group('in the app', () {
    // Progress of a learner who has played every story of the site twice and
    // has no word due: the map's Up Next card picks the first unplayed story,
    // which is the bundled preview story.
    String allPlayed() {
      final db = obj(seed('todo'));
      db['palabras'] = <String, dynamic>{};
      // The seed predates A comer in the course: mark its three stories played
      // twice like jugo-de-china so the bundled preview story is Up Next.
      final cuentos = db['cuentos'] as Map<String, dynamic>;
      for (final id in ['que-quieres', 'buen-provecho', 'cafe-con-azucar']) {
        cuentos[id] = Map<String, dynamic>.of(
          cuentos['jugo-de-china'] as Map<String, dynamic>,
        );
      }
      return jsonEncode(db);
    }

    testWidgets(
      'a preview story with a converted scene reaches Up Next, plays silently to completion, persists played, and keeps all tabs and lesson routes clean',
      (tester) async {
        final app = TestApp(tester);
        final story = previewStory('la-lluvia', 'previa-uno');
        app.previa = memoryPrevia({
          'curso.json': jsonEncode({
            'lugares': {
              'colmado': ['previa-uno'],
            },
            'cuentos': {
              'previa-uno': {'t': 'Previa uno', 'min': 2},
            },
          }),
          'cuentos/previa-uno.json': story,
        });
        await app.open(stored: allPlayed(), speechAvailable: false);

        expect(app.services.course.meta('previa-uno'), isNotNull);
        expect(findShellTab('map').hitTestable(), findsOneWidget);
        expect(findMapUpNextAction().hitTestable(), findsOneWidget);

        // Tapping Up Next launches the bundled preview story and plays it to completion.
        await playUpNextStoryToEnd(app, 'previa-uno');

        // Silent: no clip of the preview story was played (it has an unrecorded line).
        final lines = (obj(story)['clips'] as Map).keys.toSet();
        expect(app.clips!.played.where(lines.contains), isEmpty);
        expect(app.services.progress.played('previa-uno'), isTrue);
        expect(app.fetched, isNot(contains('cuentos/previa-uno.json')));
        expect(tester.takeException(), isNull);

        expect(await tester.binding.handlePopRoute(), isTrue);
        await app.settle(rounds: 5);
        await app.advance(5000);
        expect(app.tabBarShown, isTrue);
        expect(app.selectedTab, 'map');

        // All five tabs mount cleanly with the preview overlay active.
        for (final id in NocheTabs.order) {
          await app.openTab(id);
          expect(app.selectedTab, id);
          expect(findShellTab(id).hitTestable(), findsOneWidget, reason: id);
          expect(tester.takeException(), isNull, reason: id);
        }

        // Review and level-check routes mount cleanly with the preview overlay active.
        await app.go(const ReviewRoute());
        expect(findShellRoute(const ReviewRoute()), findsOneWidget);
        expect(app.lessonShown, isTrue);
        expect(tester.takeException(), isNull);

        await app.go(const TabRoute('map'));
        await app.go(const LevelCheckRoute());
        expect(findShellRoute(const LevelCheckRoute()), findsOneWidget);
        expect(app.lessonShown, isTrue);
        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    testWidgets(
      'a preview story whose scene is not in the registry mounts its route without a start disc and returns to map on back',
      (tester) async {
        final app = TestApp(tester);
        app.previa = memoryPrevia({
          'curso.json': overlayOf({
            'colmado': ['previa-dos'],
          }),
          'cuentos/previa-dos.json': previewStory(
            'la-lluvia',
            'previa-dos',
            // a scene id the registry will never hold (it was 'mostrador' until order 50b converted it)
            scene: 'no-es-una-escena',
          ),
        });
        await app.open(stored: seed('curso'), location: '/cuento/previa-dos');
        await app.settle(rounds: 15);

        expect(findShellRoute(const StoryRoute('previa-dos')), findsOneWidget);
        expect(app.lessonShown, isTrue);
        expect(findStoryStartButton(), findsNothing);
        expect(tester.takeException(), isNull);

        expect(await tester.binding.handlePopRoute(), isTrue);
        await app.settle(rounds: 5);
        expect(findShellRoute(const StoryRoute('previa-dos')), findsNothing);
        expect(app.tabBarShown, isTrue);
        expect(app.selectedTab, 'map');
        expect(findShellTab('map').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
