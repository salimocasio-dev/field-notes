// One test per behaviour of app.html's `bienvenida` and `listo` (lines 482 to 493, and the start at 498), with the old
// page's expected values from tool/old_expected.mjs.
//
//   W1  each step's text, buttons, minutes pill and lit dot, the first time (modal) and from "How it works" (line 484-492)
//   W2  each control writes what the old one writes, and goes where the old one goes (line 486-490, 493)
//   W3  the first time it is a modal sheet; from Yo an ordinary one (line 491-492)
//   W4  it shows at the start while `bienvenida` is not set (line 498), and it never shows again once it is
//   W5  `WelcomeGate`: the app under it works while it is closed, and does not before
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/dev_app.dart';
import 'support/harness.dart';

Map<String, dynamic> m(Object? o) => (o as Map).cast<String, dynamic>();
List<String> strings(Object? o) => (o as List).cast<String>();

/// The welcome, as `bienvenida(k)` opens it: the gate the first time, "How it works" in Yo afterwards.
Future<void> pumpWelcome(
  WidgetTester tester,
  DevFixture f, {
  required bool seen,
  required int step,
}) => seen ? pumpYo(tester, f, how: step) : pumpGate(tester, f, step: step);

void main() {
  // ---- W1 ----
  group('W1 each step, as bienvenida(k) writes it (app.html:484-492)', () {
    for (final w in (oldExpected['welcome'] as List).map(m)) {
      final seen = w['seen'] == 1;
      testWidgets(
        'step ${(w['k'] as int) + 1}, ${seen ? 'from How it works' : 'the first time'}, minutes ${w['min']}',
        (tester) async {
          final f = fixture(json: w['stored'] as String);
          await pumpWelcome(tester, f, seen: seen, step: w['k'] as int);
          expect(textsOf(tester, find.byType(CoquiSheet)), [
            ...strings(w['texts']),
            ...strings(w['footer']),
          ]);
          if (w['k'] == 1) {
            expect(
              pillsOf(tester, find.byType(CoquiSheet)),
              oldPills(w['pills']),
            );
          }
          expect(dotOf(tester), w['dot']);
          expect(
            tester.widget<CoquiSheet>(find.byType(CoquiSheet)).modal,
            w['modal'],
          );
          expect(sheetOpen(tester), isTrue);
        },
      );
    }

    testWidgets('the Level check paragraph is only in "How it works"', (
      tester,
    ) async {
      final f = fixture(seed: 'vacio');
      await pumpYo(tester, f, how: 0);
      expect(
        find.text('Level check'),
        findsNWidgets(2),
      ); // the card in Yo, the heading in the sheet
      expect(
        find.text(
          'The words of the stories you already understand are yours to keep: each gets one cold check tomorrow, and they are open for speaking now.',
        ),
        findsOneWidget,
      );
      final g = fixture();
      await pumpGate(tester, g);
      expect(find.text('Level check'), findsNothing);
    });
  });

  // ---- W2 ----
  group('W2 the controls (app.html:486-490, 493)', () {
    for (final h in (oldExpected['welcomeHandlers'] as List).map(m)) {
      final seen = h['seen'] == 1;
      testWidgets(
        '${seen ? 'from How it works' : 'first time'}, step ${(h['k'] as int) + 1}: ${h['onclick']} (${h['button']})',
        (tester) async {
          final f = fixture(
            json:
                '{"palabras":{},"dias":{},"cuentos":{},"ajustes":{"min":30,"todo":0,"bienvenida":${seen ? 1 : 0},"habla":1},"minutos":0,"v":1}',
          );
          await pumpWelcome(tester, f, seen: seen, step: h['k'] as int);
          expect(settingsOf(f.progress), m(h['before']));
          await tester.tap(
            find.descendant(
              of: find.byType(CoquiSheet),
              matching: find.text(h['button'] as String),
            ),
          );
          await settle(tester);
          expect(settingsOf(f.progress), m(h['after']));
          expect(
            f.haptics.ticks,
            h['ticks'],
            reason: 'the welcome never ticks',
          );
          expect(
            f.nav.routes,
            h['href'] == 'nivel.html' ? [const LevelCheckRoute()] : isEmpty,
          );
          final w = h['welcome'];
          if (w != null) {
            // bienvenida(n): the sheet shows the next step, or the same one with the pill changed
            final want = m(w);
            expect(textsOf(tester, find.byType(CoquiSheet)), [
              ...strings(want['texts']),
              ...strings(want['footer']),
            ]);
            expect(dotOf(tester), want['dot']);
            if (want['pills'] != null && (want['pills'] as List).isNotEmpty) {
              expect(
                pillsOf(tester, find.byType(CoquiSheet)),
                oldPills(want['pills']),
              );
            }
            expect(sheetOpen(tester), isTrue);
          } else {
            // listo() closes it (cierra); "I understand some Spanish" leaves for the level check
            expect(sheetOpen(tester), isFalse);
          }
        },
      );
    }

    testWidgets(
      'listo() itself: bienvenida is 1, the sheet is closed, nothing else is written',
      (tester) async {
        final f = fixture();
        await pumpGate(tester, f, step: 2);
        final before = settingsOf(f.progress);
        await tapText(tester, "I'm new to Spanish");
        expect(settingsOf(f.progress), {
          ...before,
          ...m(oldExpected['listo'])['after'] as Map<String, dynamic>,
        });
        expect(settingsOf(f.progress)['bienvenida'], 1);
        expect(f.progress.saves, 1);
        expect(sheetOpen(tester), isFalse);
        expect(f.nav.routes, isEmpty);
      },
    );

    testWidgets(
      'the minutes pills of step 2 write `min` at once, and the welcome stays on step 2',
      (tester) async {
        final f = fixture();
        await pumpGate(tester, f, step: 1);
        for (final mins in [15, 60, 120, 30]) {
          await tapText(tester, '$mins min');
          expect(f.progress.setting('min'), mins);
          expect(dotOf(tester), 1);
          expect(
            pillsOf(
              tester,
              find.byType(CoquiSheet),
            ).where((p) => p.on).single.text,
            '$mins min',
          );
        }
        expect(f.progress.setting('bienvenida'), 0);
      },
    );

    testWidgets(
      'from How it works each step starts at the top, as `bienvenida(k)` writes the sheet anew',
      (tester) async {
        final f = fixture(seed: 'curso');
        await pumpYo(tester, f, how: 0);
        // a short phone, so that the body of the sheet scrolls in every step
        tester.view.physicalSize = const Size(412, 360);
        await tester.pump();
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CoquiSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(scroll.position.maxScrollExtent, greaterThan(40));
        scroll.position.jumpTo(40);
        await tester.pump();
        expect(scroll.position.pixels, 40);
        await tapText(tester, 'Next');
        expect(dotOf(tester), 1);
        expect(scroll.position.maxScrollExtent, greaterThan(40));
        expect(scroll.position.pixels, 0);
      },
    );

    testWidgets('Next walks 1, 2, 3 and writes nothing', (tester) async {
      final f = fixture();
      await pumpGate(tester, f);
      final saves = f.progress.saves;
      expect(dotOf(tester), 0);
      await tapText(tester, 'Next');
      expect(dotOf(tester), 1);
      await tapText(tester, 'Next');
      expect(dotOf(tester), 2);
      expect(find.text('Next'), findsNothing);
      expect(f.progress.saves, saves);
    });
  });

  // ---- W3 ----
  group('W3 modal the first time, ordinary from Yo (app.html:491-492)', () {
    testWidgets('the first time: no X, no handle, a tap outside does nothing', (
      tester,
    ) async {
      final f = fixture();
      await pumpGate(tester, f);
      expect(tester.widget<CoquiSheet>(find.byType(CoquiSheet)).modal, isTrue);
      expect(find.byType(CoquiCloseButton), findsNothing);
      await tester.tapAt(const Offset(200, 40)); // the app above the sheet
      await settle(tester);
      expect(sheetOpen(tester), isTrue);
      expect(find.text('Welcome to Coquí'), findsOneWidget);
    });

    testWidgets(
      'from Yo: the X and a tap outside close it, and nothing is written',
      (tester) async {
        final f = fixture(seed: 'curso');
        await pumpYo(tester, f, how: 0);
        final saves = f.progress.saves;
        expect(find.byType(CoquiCloseButton), findsOneWidget);
        await tester.tap(find.byType(CoquiCloseButton));
        await settle(tester);
        expect(sheetOpen(tester), isFalse);
        expect(f.progress.saves, saves);
      },
    );

    testWidgets(
      'from Yo, "I\'m new to Spanish" (listo) closes it and writes bienvenida 1 again',
      (tester) async {
        final f = fixture(seed: 'curso');
        await pumpYo(tester, f, how: 2);
        final saves = f.progress.saves;
        await tapText(tester, "I'm new to Spanish");
        expect(sheetOpen(tester), isFalse);
        expect(f.progress.saves, saves + 1);
        expect(f.progress.setting('bienvenida'), 1);
      },
    );
  });

  // ---- W4 ----
  group('W4 when it shows, and never twice (app.html:498)', () {
    for (final v in [
      ('absent', null),
      ('0', '0'),
      ('null', 'null'),
      ('false', 'false'),
    ]) {
      testWidgets('it shows at the start when bienvenida is ${v.$1}', (
        tester,
      ) async {
        final f = fixture(
          json: v.$2 == null
              ? '{"ajustes":{"min":30}}'
              : '{"ajustes":{"min":30,"bienvenida":${v.$2}}}',
        );
        await pumpGate(tester, f);
        expect(sheetOpen(tester), isTrue);
        expect(find.text('Welcome to Coquí'), findsOneWidget);
        expect(dotOf(tester), 0);
      });
    }

    testWidgets('it does not show when bienvenida is 1', (tester) async {
      final f = fixture(seed: 'vacio');
      await pumpGate(tester, f);
      expect(sheetOpen(tester), isFalse);
    });

    testWidgets(
      'it slides in after the first frame, as the old page adds `on`',
      (tester) async {
        final f = fixture();
        phone(tester);
        await tester.pumpWidget(
          MaterialApp(
            theme: coquiTheme(),
            home: Scaffold(
              body: WelcomeGate(
                services: f.services,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
        expect(sheetOpen(tester), isFalse);
        await tester.pump();
        expect(sheetOpen(tester), isTrue);
      },
    );

    testWidgets(
      '"I\'m new to Spanish" finishes it: a new start does not show it again',
      (tester) async {
        final f = fixture();
        await pumpGate(tester, f, step: 2);
        await tapText(tester, "I'm new to Spanish");
        expect(sheetOpen(tester), isFalse);
        final again = f.reload(); // the app starts again on what was stored
        await pumpGate(tester, again);
        expect(sheetOpen(tester), isFalse);
        expect(again.progress.setting('bienvenida'), 1);
      },
    );

    testWidgets(
      '"I understand some Spanish" finishes it too: it goes to the level check and never comes back',
      (tester) async {
        final f = fixture();
        await pumpGate(tester, f, step: 2);
        await tapText(tester, 'I understand some Spanish');
        expect(f.nav.routes, [const LevelCheckRoute()]);
        expect(sheetOpen(tester), isFalse);
        final again = f.reload();
        await pumpGate(tester, again);
        expect(sheetOpen(tester), isFalse);
      },
    );

    testWidgets(
      'left half way it comes back at step 1 at the next start, with the minutes kept',
      (tester) async {
        final f = fixture();
        await pumpGate(tester, f);
        await tapText(tester, 'Next');
        await tapText(tester, '120 min');
        expect(dotOf(tester), 1);
        final again = f.reload(); // the page is loaded again
        await pumpGate(tester, again);
        expect(sheetOpen(tester), isTrue);
        expect(dotOf(tester), 0);
        expect(again.progress.setting('min'), 120);
        await tapText(tester, 'Next');
        expect(
          pillsOf(tester, find.byType(CoquiSheet)).indexWhere((p) => p.on),
          3,
        );
      },
    );

    testWidgets('once finished it stays closed through every later save', (
      tester,
    ) async {
      final f = fixture();
      await pumpGate(tester, f, step: 2);
      await tapText(tester, "I'm new to Spanish");
      f.progress.setSetting('min', 15);
      f.progress.addMinutes(2);
      await settle(tester);
      expect(sheetOpen(tester), isFalse);
    });
  });

  // ---- W5 ----
  group('W5 WelcomeGate over the app', () {
    testWidgets(
      'while it is up the app under it gets no touch; once closed it does',
      (tester) async {
        var taps = 0;
        final f = fixture();
        await pumpGate(
          tester,
          f,
          child: GestureDetector(
            key: const Key('app'),
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.expand(),
          ),
          step: 2,
        );
        await tester.tapAt(const Offset(200, 40));
        await settle(tester);
        expect(taps, 0);
        await tapText(tester, "I'm new to Spanish");
        await tester.tapAt(const Offset(200, 40));
        await settle(tester);
        expect(taps, 1);
      },
    );

    testWidgets('the shell can wrap the Yo tab in it', (tester) async {
      final f = fixture();
      phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: coquiTheme(),
          home: Scaffold(
            body: WelcomeGate(
              services: f.services,
              child: Builder(
                builder: (context) =>
                    const ProfileModule().tab(f.services)!.builder(context),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      // the gate's sheet is up, in its layer; Yo's own sheet (How it works) is a route, and it is not open
      final layers = tester.widgetList<CoquiSheetLayer>(
        find.byType(CoquiSheetLayer),
      );
      expect(layers.map((l) => l.open).toList(), [true]);
      expect(find.byType(CoquiSheet), findsOneWidget);
      expect(find.text('Yo'), findsOneWidget);
    });
  });
}
