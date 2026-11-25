// The lessons the tabs open, end to end in the real app: Listen mode, Repaso and its pictures, the level check, the call.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/src/switches.dart';
import 'package:app/src/voice_test_data.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
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
  final file = scene == testSceneId
      ? File('$testScenePictures/$name.png')
      : index.existsSync()
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

/// Plays a session of Repaso's games through its screen to its end screen, every answer right: the right picture or
/// tile, the words of Arma la frase in order, each sound of Parejas to its word; a shown answer is touched, Next is
/// pressed. [onItem] sees each item when his turn comes.
Future<void> playRepaso(
  TestApp app, {
  Future<void> Function(dynamic session)? onItem,
  int maxMs = 15 * 60 * 1000,
}) async {
  final tester = app.tester;
  Object? acted;
  for (var t = 0; ; t += 200) {
    if (t > maxMs) fail('Repaso did not end');
    final s = stateNamed(tester, 'RepasoScreen').session;
    if ((s.screen as Enum).name == 'end') return;
    final choices = (s.choices as List<dynamic>?) ?? const [];
    final kind = s.item?.runtimeType.toString();
    if (s.canNext as bool) {
      await app.tap(find.widgetWithText(LessonButton, 'Next'));
    } else if (choices.any((c) => c.sign as bool)) {
      final k = choices.indexWhere((c) => c.sign as bool);
      await _touchChoice(app, kind, k);
    } else if ((s.yourTurn as bool) && !identical(acted, s.entry)) {
      acted = s.entry;
      await onItem?.call(s);
      final r = choices.indexWhere((c) => c.right as bool);
      switch (kind) {
        case 'CualItem' || 'HearItem' || 'WhereItem':
          await _touchChoice(app, kind, r);
        case 'BuildItem':
          for (final w in (s.item.order as List).cast<String>()) {
            final k = (s.choices as List<dynamic>).indexWhere(
              (c) => !(c.done as bool) && c.label == w,
            );
            await app.tap(
              find
                  .descendant(
                    of: find.byType(TileTray).last,
                    matching: find.byType(WordTile),
                  )
                  .at(k),
            );
          }
        case 'MatchItem':
          final order = (s.item.wordOrder as List).cast<int>();
          for (var i = 0; i < 4; i++) {
            await app.tap(find.byType(SpeakerTile).at(i));
            await app.tap(find.byType(WordTile).at(order.indexOf(i)));
          }
      }
    }
    await app.advance(200);
  }
}

Future<void> _touchChoice(TestApp app, String? kind, int k) async {
  if (kind == 'HearItem') {
    await app.tap(find.byType(WordTile).at(k));
    return;
  }
  final g = await app.tester.startGesture(
    app.tester.getCenter(find.byType(PictureChoice).at(k)),
  );
  await g.up();
  await app.tester.pump();
}

void main() {
  testWidgets(
    '(f, g) Repaso from the Today card: the games of page 15; answered, they write ear answers; ¿Cuál?\'s pictures '
    'come from ScenePictures (El frente: the new scene; another scene: its old picture); it ends on Palabras',
    (tester) async {
      final app = TestApp(tester);
      // the mid-course seed with every word's count of answers made even, so that each word with a picture pair is
      // asked by ¿Cuál? (page 15: ¿Cuál? and ¿Qué oyes? take turns by that count) and its pictures are seen
      final db = jsonDecode(seed('curso')) as Map<String, dynamic>;
      for (final r in (db['palabras'] as Map).values) {
        final ear = (r as Map)['ear'] as Map;
        ear['n'] = (ear['n'] as int) ~/ 2 * 2;
      }
      // and one word of a scene that is not converted: El banco's hombre, its review set put at the test scene (a scene
      // that is never converted, its old pictures order 06's of El banco: harness.dart, testSceneId), so that the test
      // does not depend on which real scenes are converted (order 36b; El banco's own hombre until then, cual-lago's
      // pájaro until order 35b), as the seed's casa but the most overdue, so that the session (up to 10 words, the most
      // overdue first) asks it
      app.editContent = (path, text) => path == 'cuentos/cual-banco.json'
          ? text.replaceFirst('"scene": "banco"', '"scene": "$testSceneId"')
          : text;
      final palabras = db['palabras'] as Map<String, dynamic>;
      final hombre =
          jsonDecode(jsonEncode(palabras['casa'])) as Map<String, dynamic>;
      hombre['w'] = 'hombre';
      (hombre['ear'] as Map<String, dynamic>)['due'] =
          ((palabras['casa'] as Map)['ear'] as Map)['due'] as int;
      for (final r in palabras.values) {
        final due = ((r as Map)['ear'] as Map)['due'] as int;
        final ear = hombre['ear'] as Map<String, dynamic>;
        if (due > 0 && due <= (ear['due'] as int)) ear['due'] = due - 1;
      }
      palabras['hombre'] = hombre;
      await app.open(stored: jsonEncode(db), speechAvailable: false);
      expect(app.services.pictures, isA<ScenePictures>());
      final before = answers(app, 'ear');
      // the Today/Up next card's first entry is the review; Palabras' Start goes the same way (test (m))
      expect(
        find.text(isNocheMap() ? 'Review' : CoquiLabels.reviewTitle),
        findsOneWidget,
      );
      await app.tap(findMapUpNextAction());
      await app.settle();
      expect(app.lessonShown, isTrue);
      expect(byTypeName('RepasoScreen'), findsOneWidget);
      await app.tap(find.byType(LessonStartButton));
      var frente = 0, old = 0;
      final kinds = <String>{};
      await playRepaso(
        app,
        onItem: (s) async {
          kinds.add(s.item.runtimeType.toString());

          if (s.item.runtimeType.toString() != 'CualItem') return;
          await app.settle(rounds: 4); // the pictures are read from the assets
          // no picture failed to draw (coqui_scenes puts its own red box where one does): the pictures of two
          // ¿Cuál? items in a row are each their own, not one picture handed another pair
          expect(
            find.byWidgetPredicate(
              (w) => w is ColoredBox && w.color == const Color(0xFF3A1E24),
            ),
            findsNothing,
          );
          expect(find.byType(ErrorWidget), findsNothing);
          final choices = s.choices as List<dynamic>;
          for (var k = 0; k < choices.length; k++) {
            final pair = s.item.pair as ReviewPair;
            final ref = PictureRef.of(
              pair,
              (choices[k].right as bool) ? pair.yes : pair.no,
            );
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
            if (convertedScenes.contains(ref.scene)) {
              // a converted scene: drawn by its engine, not the old picture
              expect(convertedScenes, contains(ref.scene));
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
      if (kinds.contains('CualItem')) {
        expect(
          frente,
          greaterThan(0),
          reason: 'no El frente picture was asked',
        );
        expect(old, greaterThan(0), reason: 'no picture of another scene');
        // both scored games and the play games came
        expect(
          kinds,
          containsAll(['CualItem', 'HearItem', 'BuildItem', 'MatchItem']),
        );
      } else {
        // Issue #10: flashcards remove story-frame screenshots and story-scene crops until
        // dedicated single-word assets exist in content.
        expect(kinds, isNot(contains('WhereItem')));
        expect(kinds, containsAll(['HearItem', 'BuildItem', 'MatchItem']));
      }
      // ear answers, for the words asked
      final after = answers(app, 'ear');
      final moved = [
        for (final w in after.keys)
          if (after[w] != before[w]) w,
      ];
      expect(moved.length, greaterThanOrEqualTo(5));
      // the session's minutes went to the day
      expect(
        (storedDb(app)['minutos'] as num),
        greaterThan(jsonDecode(seed('curso'))['minutos'] as num),
      );
      // "Back to Palabras": Repaso always ends on Palabras (cual.js: SALIDA)
      await app.tap(find.text('Back to Palabras'));
      await app.settle(rounds: 5);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'words');
      // the praise of the last item, cut short by Next, is a clip of the harness still counting its length
      await app.advance(5000);
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
      () =>
          find.text('Start review').evaluate().isNotEmpty ||
          find.text('Start').evaluate().isNotEmpty,
      what: 'the Repaso action',
    );
    final start = find.text('Start review').evaluate().isNotEmpty
        ? find.text('Start review')
        : find.text('Start');
    await app.tap(start);
    await app.settle();
    expect(app.lessonShown, isTrue);
    expect(byTypeName('RepasoScreen'), findsOneWidget);
    await app.tap(find.byType(LessonCloseButton));
    await app.settle(rounds: 5);
    expect(app.tabBarShown, isTrue);
    expect(app.selectedTab, 'words');
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets(
    '(n) Biblioteca: a book on the shelf opens in the reader, its X returns to Biblioteca; a book\'s address '
    '#/libro/<id> opens its lines as text, its X returns to the map',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));
      await app.services
          .storage('biblioteca')
          .write(
            'texts',
            jsonEncode([
              {
                'id': 'biblioteca-1-0',
                'title': 'Mi cuaderno',
                'body':
                    'Tengo un cuaderno. Es azul. Tiene papel. Escribo aquí.',
                'generated': false,
              },
            ]),
          );
      await app.openTab('library');
      await app.until(
        () => find.text('Mi cuaderno').evaluate().isNotEmpty,
        what: 'Biblioteca',
      );
      await app.tap(find.text('Mi cuaderno').last);
      await app.until(
        () => byTypeName('TextReader').evaluate().isNotEmpty,
        what: 'the reader',
      );
      await app.settle(rounds: 10);
      expect(app.lessonShown, isTrue);
      expect(find.byType(NocheTabBar), findsNothing);
      expect(find.text('Mi cuaderno'), findsOneWidget);
      // Issue #112 (N5.1): dynamic pagination fits these 10 words on 1 page;
      // pre-N5.1 fixed 3-sentence chunking used 2 pages.
      expect(
        find.text(
          find.byType(NocheProgressBar).evaluate().isNotEmpty
              ? '1 / 1'
              : '1 / 2',
        ),
        findsOneWidget,
      );
      await app.tap(find.byTooltip('Close'));
      await app.advance(10000);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'library');
      expect(byTypeName('TextReader'), findsNothing);
      // his shelf keeps it and offers Keep reading
      expect(find.text('Mi cuaderno'), findsWidgets);
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Continue reading'), findsOneWidget);

      // the address of a book, opened as it is (a reload): its lines as text; its X returns to the map
      await tester.pumpWidget(const SizedBox());
      final again = TestApp(tester);
      await again.open(stored: seed('curso'), location: '/libro/la-familia');
      await again.until(
        () => byTypeName('TextReader').evaluate().isNotEmpty,
        what: 'the reader',
      );
      await again.until(
        () => find.textContaining(' / ').evaluate().isNotEmpty,
        what: 'the book\'s pages',
      );
      expect(again.lessonShown, isTrue);
      expect(find.byType(Image), findsNothing);
      await again.tap(find.byTooltip('Close'));
      await again.advance(10000);
      expect(byTypeName('TextReader'), findsNothing);
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
      if (isNocheMap()) {
        expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
        expect(find.text('New story · 4 min'), findsOneWidget);
      } else {
        expect(find.text('1 · La casa'), findsOneWidget);
      }
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
      if (isNocheMap()) {
        expect(find.text('New story · 4 min'), findsNothing);
        expect(find.text('Second play · 2 min'), findsOneWidget);
        expect(find.text('You are here'), findsOneWidget);
      } else {
        expect(find.text('1 · La casa'), findsNothing);
        expect(find.text('2 · El parque'), findsOneWidget);
      }
      expect(findMapTopChips(), findsOneWidget);
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
      await app.tap(find.text('Start call'));
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
