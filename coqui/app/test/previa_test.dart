// The preview content (lib/src/previa.dart): the overlay merged into the site's course, the preview story files read from
// the bundle, the app as it is with no overlay, and a preview story opened from the map and played to its end, silent.
import 'dart:convert';
import 'dart:io';

import 'package:app/src/previa.dart';
import 'package:coqui_content/coqui_content.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show AxisDirection, Scrollable;
import 'package:flutter_test/flutter_test.dart';

import 'story_test.dart' show playFromToday;
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
    // the progress of a learner who has played every story of the site twice and has no word due: the map's Today card
    // names the first story nobody has played, which is the preview's
    String allPlayed() {
      final db = obj(seed('todo'));
      db['palabras'] = <String, dynamic>{};
      // the seed was made before A comer was in the course: its three stories, played twice as the last one was
      final cuentos = db['cuentos'] as Map<String, dynamic>;
      for (final id in ['que-quieres', 'buen-provecho', 'cafe-con-azucar']) {
        cuentos[id] = Map<String, dynamic>.of(
          cuentos['jugo-de-china'] as Map<String, dynamic>,
        );
      }
      return jsonEncode(db);
    }

    testWidgets(
      'a preview story with a converted scene opens from the map and plays to its end, silent',
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
        // the map: El colmado is where he is, its story the next to play
        expect(find.text('4 · El colmado'), findsOneWidget);
        expect(find.text('Previa uno'), findsOneWidget);
        expect(find.text('New story · play it twice · 4 min'), findsOneWidget);

        await playFromToday(app);
        // silent: no line of it was played (one of its lines has no recording)
        final lines = (obj(story)['clips'] as Map).keys.toSet();
        expect(app.clips!.played.where(lines.contains), isEmpty);
        expect(app.services.progress.played('previa-uno'), isTrue);
        // the end screen's title (the file's own)
        expect(find.text('Previa previa-uno'), findsOneWidget);
        expect(find.text('Next story'), findsNothing);
        expect(app.fetched, isNot(contains('cuentos/previa-uno.json')));
        expect(tester.takeException(), isNull);

        // the other tabs, with the preview story played
        await app.tap(find.text('Map').last);
        await app.settle(rounds: 5);
        expect(app.selectedTab, 'map');
        // Biblioteca opens; the course's stories are not listed there
        await app.openTab('library');
        await app.until(
          () => find.text('Write my story').evaluate().isNotEmpty,
          what: 'Biblioteca',
        );
        expect(
          find.descendant(
            of: byTypeName('ReadingHome'),
            matching: find.text('Previa uno'),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        // Palabras, Hablar (El colmado is done and has no call: its stop says "Coming soon"), Yo
        await app.openTab('words');
        expect(tester.takeException(), isNull);
        await app.openTab('speak');
        final colmado = find.descendant(
          of: byTypeName('HablarTab'),
          matching: find.text('El colmado'),
        );
        // the journey strip scrolls sideways: bring the fourth stop in
        await tester.scrollUntilVisible(
          colmado,
          100,
          scrollable: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
          ),
        );
        await tester.ensureVisible(colmado);
        await tester.pump();
        await app.tap(colmado);
        expect(
          find.text('Coming soon · El colmado', skipOffstage: false),
          findsOneWidget,
        );
        await app.openTab('me');
        expect(tester.takeException(), isNull);
        // Repaso and the level check open as they do without it
        await app.go(const ReviewRoute());
        expect(byTypeName('RepasoScreen'), findsOneWidget);
        await app.go(const TabRoute('map'));
        await app.go(const LevelCheckRoute());
        expect(byTypeName('LevelCheckScreen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    testWidgets(
      'a preview story whose scene is not in the registry opens on "not in the new app yet", as an unconverted scene does',
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
        await app.until(
          () => find
              .text('This story is not in the new app yet.')
              .evaluate()
              .isNotEmpty,
          what: 'the not-converted screen',
        );
        expect(find.text('Back to the map'), findsOneWidget);
        await app.tap(find.text('Back to the map'));
        await app.settle(rounds: 5);
        expect(app.selectedTab, 'map');
      },
    );
  });
}
