// The lessons the tabs open, end to end in the real app: Listen mode, Repaso and its pictures, the level check, the call.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/src/switches.dart';
import 'package:app/src/voice_test_data.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

Map<String, dynamic> storedDb(TestApp app) =>
    jsonDecode(app.stored!) as Map<String, dynamic>;

/// How many times each word has been answered by [skill] in the stored progress.
Map<String, int> answers(TestApp app, String skill) => {
  for (final e in (storedDb(app)['palabras'] as Map).entries)
    e.key as String: ((e.value as Map)[skill] as Map)['n'] as int,
};

/// The old picture [name] of [scene], as order 06 drew it (coqui/ref/escenas/): RGBA bytes. A scene not converted yet
/// has it among coqui_scenes' assets (its index names the file); El frente's is the reference picture.
Future<Uint8List> oldPicture(
  WidgetTester tester,
  String scene,
  String name,
) async {
  final assets =
      '$repoRoot/coqui/packages/core/coqui_scenes/assets/old_pictures/$scene';
  final index = File('$assets/index.json');
  final file = index.existsSync()
      ? File('$assets/${(jsonDecode(index.readAsStringSync()) as Map)[name]}')
      : File('$repoRoot/coqui/ref/escenas/$scene/pairs/${plain(name)}.png');
  final bytes = file.readAsBytesSync();
  return (await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    return data!.buffer.asUint8List();
  }))!;
}

/// A name with its accents taken off, as the reference pictures' files are named.
String plain(String s) {
  const from = 'áéíóúüñÁÉÍÓÚÜÑ', to = 'aeiouunAEIOUUN';
  return [
    for (final c in s.split('')) from.contains(c) ? to[from.indexOf(c)] : c,
  ].join();
}

/// Answers a Repaso or level-check session through its screen until its end screen, touching the right picture of each
/// ask, or, where [right] says no for the ask's number (from 0), a wrong one. [onAsk] is told each ask's panels.
Future<void> answerRight(
  TestApp app,
  String screen, {
  Future<void> Function(List<dynamic> panels)? onAsk,
  bool Function(int ask)? right,
  int maxMs = 10 * 60 * 1000,
}) async {
  final tester = app.tester;
  Object? last;
  var asks = -1;
  for (var t = 0; ; t += 200) {
    if (t > maxMs) fail('$screen did not end');
    final s = stateNamed(tester, screen).session;
    if ((s.screen as Enum).name == 'end') return;
    final panels = s.panels as List<dynamic>?;
    if (panels != null && (s.screen as Enum).name == 'play') {
      if (!identical(panels, last)) {
        last = panels;
        asks++;
        await app.settle(rounds: 4); // the pictures are read from the assets
        await onAsk?.call(panels);
      }
      final ok = right?.call(asks) ?? true;
      final k = panels.indexWhere((p) => (p.right as bool) == ok);
      final touch = byTypeName('OptionTouch');
      if (touch.evaluate().length > k) {
        await tester.tap(touch.at(k), warnIfMissed: false);
      }
    }
    await app.advance(200);
  }
}

void main() {
  testWidgets(
    '(e) Listen on Biblioteca\'s shelf: the story told straight through, '
    'writes listened; its X returns to Biblioteca',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'), speechAvailable: false);
      await app.openTab('library');
      await app.until(
        () => find.text('La lluvia').evaluate().isNotEmpty,
        what: 'the shelf',
      );
      // the Listen button of La lluvia's row
      await app.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('La lluvia'),
            matching: byTypeName('ShelfEntry'),
          ),
          matching: find.text('Listen'),
        ),
      );
      await app.settle(rounds: 5);
      expect(app.lessonShown, isTrue);
      expect(byTypeName('StoryScreen'), findsOneWidget);
      await app.until(
        () => find.byType(LessonStartButton).evaluate().isNotEmpty,
        what: 'the start disc',
      );
      expect(
        (storedDb(app)['oidos'] as Map? ?? const {}).containsKey('la-lluvia'),
        isFalse,
      );
      await app.tap(find.byType(LessonStartButton));
      for (var t = 0; find.text('Play again').evaluate().isEmpty; t += 200) {
        if (t > 5 * 60 * 1000) fail('Listen did not end');
        await app.advance(200);
      }
      // nothing to touch: no decision was logged, and the story's record did not move
      expect(
        ((storedDb(app)['cuentos'] as Map)['la-lluvia'] as Map)['n'],
        jsonDecode(seed('curso'))['cuentos']['la-lluvia']['n'],
      );
      // PAL.oido
      expect((storedDb(app)['oidos'] as Map).containsKey('la-lluvia'), isTrue);
      await app.tap(find.byType(LessonCloseButton));
      await app.settle(rounds: 5);
      expect(app.selectedTab, 'library');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  testWidgets(
    '(f, g) Repaso from the Today card: answered, it writes ear answers; its pictures come from ScenePictures '
    '(El frente: the new scene; another scene: its old picture); it ends on Palabras',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));
      expect(app.services.pictures, isA<ScenePictures>());
      final before = answers(app, 'ear');
      // the Today card's first entry is the review (¿Cuál?); Palabras' Start goes the same way (test (m))
      expect(find.text(CoquiLabels.reviewTitle), findsOneWidget);
      await app.tap(find.byType(TodayCard));
      await app.settle();
      expect(app.lessonShown, isTrue);
      expect(byTypeName('ReviewScreen'), findsOneWidget);
      await app.tap(find.byType(LessonStartButton));
      var frente = 0, old = 0;
      await answerRight(
        app,
        'ReviewScreen',
        onAsk: (panels) async {
          for (var k = 0; k < panels.length; k++) {
            final ref = panels[k].ref as PictureRef;
            final view = find.descendant(
              of: byTypeName('OptionTouch').at(k),
              matching: find.byType(PixelView),
            );
            if (view.evaluate().isEmpty) continue; // not drawn yet
            final px = tester
                .widget<PixelView>(view)
                .pixels
                .buffer
                .asUint8List();
            final was = await oldPicture(tester, ref.scene, ref.name!);
            if (ref.scene == 'frente') {
              // a converted scene: drawn by its engine, not the old picture
              expect(convertedScenes, contains('frente'));
              expect(px, isNot(equals(was)), reason: '${ref.name}');
              frente++;
            } else {
              expect(convertedScenes, isNot(contains(ref.scene)));
              expect(px, equals(was), reason: '${ref.scene} ${ref.name}');
              old++;
            }
          }
        },
      );
      expect(frente, greaterThan(0), reason: 'no El frente picture was asked');
      expect(old, greaterThan(0), reason: 'no picture of another scene');
      // ear answers, for the words asked
      final after = answers(app, 'ear');
      final moved = [
        for (final w in after.keys)
          if (after[w] != before[w]) w,
      ];
      expect(moved.length, greaterThanOrEqualTo(5));
      // "Back to Palabras": Repaso always ends on Palabras (cual.js: SALIDA)
      await app.tap(find.text('Back to Palabras'));
      await app.settle(rounds: 5);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'words');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  testWidgets('(m) Palabras\' Start opens Repaso; its X returns to Palabras', (
    tester,
  ) async {
    final app = TestApp(tester);
    await app.open(stored: seed('curso'));
    await app.openTab('words');
    await app.until(
      () => find.text('Start').evaluate().isNotEmpty,
      what: 'the Repaso card',
    );
    await app.tap(find.text('Start'));
    await app.settle();
    expect(app.lessonShown, isTrue);
    expect(byTypeName('ReviewScreen'), findsOneWidget);
    await app.tap(find.byType(LessonCloseButton));
    await app.settle(rounds: 5);
    expect(app.tabBarShown, isTrue);
    expect(app.selectedTab, 'words');
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets(
    '(n) a book: Read on the shelf and the address #/libro/<id> both open the reader; its X returns to where it was opened from',
    (tester) async {
      // Read, on Biblioteca's shelf (La familia has a book that reads well)
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));
      await app.openTab('library');
      await app.until(
        () => find.text('La familia').evaluate().isNotEmpty,
        what: 'the shelf',
      );
      final read = find.descendant(
        of: find.ancestor(
          of: find.text('La familia'),
          matching: byTypeName('ShelfEntry'),
        ),
        matching: find.text('Read'),
      );
      await tester.ensureVisible(read);
      await app.settle(rounds: 3);
      await app.tap(read);
      await app.until(
        () => byTypeName('BookReader').evaluate().isNotEmpty,
        what: 'the reader',
      );
      await app.settle(rounds: 10);
      expect(app.lessonShown, isTrue);
      expect(find.byType(CoquiTabBar), findsNothing);
      // the pictures are asked for where the shell says: the site's historia/libros/, with the old page's ?v=39
      expect(
        (tester.widget(byTypeName('BookReader')) as dynamic).imageUrl(
          'img/la-familia-1.png',
        ),
        'http://127.0.0.1/field-notes/historia/libros/img/la-familia-1.png?v=39',
      );
      await app.tap(find.byType(LessonIconButton).first); // the reader's X
      await app.advance(10000);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'library');
      expect(byTypeName('BookReader'), findsNothing);

      // the address of a book, opened as it is (a reload): the reader; its X returns to the map
      await tester.pumpWidget(const SizedBox());
      final again = TestApp(tester);
      await again.open(stored: seed('curso'), location: '/libro/la-familia');
      await again.until(
        () => byTypeName('BookReader').evaluate().isNotEmpty,
        what: 'the reader',
      );
      await again.settle(rounds: 10);
      expect(again.lessonShown, isTrue);
      await again.tap(find.byType(LessonIconButton).first);
      await again.advance(10000);
      expect(byTypeName('BookReader'), findsNothing);
      expect(again.tabBarShown, isTrue);
      expect(again.selectedTab, 'map');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  testWidgets(
    '(o) the address #/prueba-voz opens the voice test, made from historia/datos/prueba-voz.json: its first line, the '
    'file\'s mic label; one line said is heard; the system back returns to the map',
    (tester) async {
      final file = VoiceTestData.parse(
        repoFile('historia/datos/prueba-voz.json'),
      );
      final app = TestApp(tester);
      await app.open(
        stored: seed('curso'),
        location: '/prueba-voz',
        micStub: const ['hola abuela'],
      );
      // not the map: the voice test, a lesson screen, on the first of the file's twelve lines
      expect(byTypeName('VoiceTestScreen'), findsOneWidget);
      expect(app.lessonShown, isTrue);
      expect(find.text('1 / 12'), findsOneWidget);
      expect(find.text(file.lines.first.text), findsOneWidget);
      // the file's own words are the screen's: its mic label is the mic disc's
      final mic = find.byWidgetPredicate(
        (x) => x is Semantics && x.properties.label == file.labels['mic'],
      );
      expect(mic, findsOneWidget);
      await app.tap(mic);
      await app.advance(1500);
      // the scripted answer is what the file's first line asks for (hola, abuela): heard
      expect(find.text('hola abuela'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('hola abuela')).style!.color,
        CoquiColors.heard,
      );
      final handled = await tester.binding.handlePopRoute();
      await app.settle(rounds: 5);
      expect(handled, isTrue);
      expect(byTypeName('VoiceTestScreen'), findsNothing);
      expect(app.selectedTab, 'map');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  testWidgets(
    '(h) the level check opened from Yo, answered and finished, calls presume; the map follows',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('vacio'));
      expect(find.text('1 · La casa'), findsOneWidget);
      await app.openTab('me');
      final start = find.byKey(const Key('yo-level-check'));
      await tester.ensureVisible(start);
      await app.tap(start);
      await app.settle();
      expect(byTypeName('LevelCheckScreen'), findsOneWidget);
      expect(app.lessonShown, isTrue);
      await app.tap(find.byType(LessonStartButton));
      // right on the first six pictures, then wrong: the check places him a little way in
      await answerRight(app, 'LevelCheckScreen', right: (n) => n < 6);
      // PAL.presume: the level, and the stories it skipped, presumed played
      final db = storedDb(app);
      expect(db['nivel'], isNotNull);
      final presumed = [
        for (final e in (db['cuentos'] as Map).entries)
          if ((e.value as Map)['presunto'] != null) e.key,
      ];
      expect(presumed, contains('la-lluvia'));
      expect((db['nivel'] as Map)['historias'], presumed.length);
      await app.tap(find.text('To the map'));
      await app.settle(rounds: 5);
      expect(app.selectedTab, 'map');
      // the map follows: La casa is done, the frog has moved on to El parque
      expect(find.text('1 · La casa'), findsNothing);
      expect(find.text('2 · El parque'), findsOneWidget);
      expect(find.byType(MapChips), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  testWidgets(
    '(i) a scripted call (?callstub=1) from Hablar writes mouth answers; it ends on Hablar',
    (tester) async {
      final app = TestApp(tester);
      await app.open(
        stored: seed('curso'),
        switches: AppSwitches.fromQuery(const {'callstub': '1'}),
      );
      final before = answers(app, 'mouth');
      await app.openTab('speak');
      await app.tap(find.text('La casa · about 5 min'));
      await app.settle();
      expect(app.lessonShown, isTrue);
      expect(byTypeName('CallScreen'), findsOneWidget);
      await app.tap(byTypeName('CallMicStage'));
      for (
        var t = 0;
        find.text('Back to Hablar').evaluate().isEmpty;
        t += 200
      ) {
        if (t > 3 * 60 * 1000) fail('the call did not end');
        await app.advance(200);
      }
      expect(app.call.brief?.placeId, 'casa');
      final after = answers(app, 'mouth');
      final said = [
        for (final w in after.keys)
          if (after[w] != (before[w] ?? 0)) w,
      ];
      expect(said, isNotEmpty);
      await app.tap(find.text('Back to Hablar'));
      await app.settle(rounds: 5);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'speak');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
