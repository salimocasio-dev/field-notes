// The lessons the tabs open, end to end in the real app: Listen mode, Repaso, the level check, the call.
import 'dart:convert';

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
      await app.tap(findReviewNextButton());
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
                    of: findReviewTileTray().last,
                    matching: findReviewWordTile(),
                  )
                  .at(k),
            );
          }
        case 'MatchItem':
          final order = (s.item.wordOrder as List).cast<int>();
          for (var i = 0; i < 4; i++) {
            await app.tap(findReviewSpeakerTile().at(i));
            await app.tap(findReviewWordTile().at(order.indexOf(i)));
          }
      }
    }
    await app.advance(200);
  }
}

Future<void> _touchChoice(TestApp app, String? kind, int k) async {
  if (kind == 'HearItem') {
    await app.tap(findReviewWordTile().at(k));
    return;
  }
  final g = await app.tester.startGesture(
    app.tester.getCenter(findReviewPictureChoice().at(k)),
  );
  await g.up();
  await app.tester.pump();
}

void main() {
  testWidgets(
    '(f, g) Repaso from the Up next card: plays post-#10 games with no story screenshots, writes ear answers, and ends on Palabras',
    (tester) async {
      final app = TestApp(tester);
      final db = jsonDecode(seed('curso')) as Map<String, dynamic>;
      await app.open(stored: jsonEncode(db), speechAvailable: false);
      expect(app.services.pictures, isA<ScenePictures>());
      final before = answers(app, 'ear');
      // the Up next card's first entry is the review; Palabras' Start review goes the same way (test (m))
      expect(find.text('Review'), findsOneWidget);
      await app.tap(findMapUpNextAction());
      await app.settle();
      expect(app.lessonShown, isTrue);
      expect(byTypeName('RepasoScreen'), findsOneWidget);
      await app.tap(findReviewStartButton());
      final kinds = <String>{};
      await playRepaso(
        app,
        onItem: (s) async {
          kinds.add(s.item.runtimeType.toString());
          expect(find.byType(ErrorWidget), findsNothing);
          expect(findReviewPictureChoice(), findsNothing);
          expect(byTypeName('BookImage'), findsNothing);
        },
      );
      // Issue #10: flashcards remove story-frame screenshots and story-scene crops until
      // dedicated single-word assets exist in content.
      expect(kinds, isNot(contains('CualItem')));
      expect(kinds, isNot(contains('WhereItem')));
      expect(kinds, containsAll(['HearItem', 'BuildItem', 'MatchItem']));
      // ear answers, for the words asked
      final after = answers(app, 'ear');
      final moved = [
        for (final w in after.keys)
          if (after[w] != before[w]) w,
      ];
      expect(moved.length, greaterThanOrEqualTo(5));
      // the session's minutes went to the shared cross-language progress store
      final seedMinutes = jsonDecode(seed('curso'))['minutos'] as num;
      final sharedDb = jsonDecode(app.sharedStored!) as Map<String, dynamic>;
      expect(sharedDb['minutos'] as num, greaterThan(seedMinutes));
      expect(app.services.progress.minutes, greaterThan(seedMinutes));
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
      () => find.text('Start review').evaluate().isNotEmpty,
      what: 'the Repaso action',
    );
    await app.tap(find.text('Start review'));
    await app.settle();
    expect(app.lessonShown, isTrue);
    expect(byTypeName('RepasoScreen'), findsOneWidget);
    await app.tap(findReviewCloseButton());
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
      expect(find.text('1 / 1'), findsOneWidget);
      await app.tap(find.byTooltip('Close'));
      await app.advance(10000);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'library');
      expect(byTypeName('TextReader'), findsNothing);
      // his shelf keeps it and offers Continue reading
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
      expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
      expect(find.text('New story · 4 min'), findsOneWidget);
      await app.openTab('me');
      final start = find.byKey(const Key('yo-level-check'));
      await tester.ensureVisible(start);
      await app.tap(start);
      await app.settle();
      expect(byTypeName('LevelCheckScreen'), findsOneWidget);
      expect(app.lessonShown, isTrue);
      await app.tap(findReviewStartButton());
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
      expect(find.text('New story · 4 min'), findsNothing);
      expect(find.text('Second play · 2 min'), findsOneWidget);
      expect(find.text('You are here'), findsOneWidget);
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
      await app.tap(find.byKey(const Key('speak-call-disc')));
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
