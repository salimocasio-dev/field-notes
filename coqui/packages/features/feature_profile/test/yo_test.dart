// Preserved behaviours of Yo (app.html:465-480) on the Noche Me screen (N4.7):
//
//   Y1  every reference seed renders the right numbers, switches, pills, and notaHabla
//   Y2  edge-case stored values (minutes rounded, unusual min pill, switches, level check help line)
//   Y3  each control writes what the old handler writes, and ticks where the old one ticks
//   Y4  the page draws again whenever the store saves, and place progress follows stories played
//   Y5  notaHabla: once a day, stays while open, never when the recogniser is available
//   Y6  "How Coquí works" opens the welcome sheet, ordinary, scrim covers the tab bar
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/js.dart';
import 'package:feature_profile/src/yo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/dev_app.dart';
import 'support/harness.dart';

Map<String, dynamic> m(Object? o) => (o as Map).cast<String, dynamic>();
List<String> strings(Object? o) => (o as List).cast<String>();

void main() {
  // ---- Y1: every reference seed ----
  group('Y1 reference seeds render accurately with and without recogniser', () {
    final yo = m(oldExpected['yo']);
    for (final seed in yo.keys) {
      for (final mic in [true, false]) {
        testWidgets('${mic ? 'with' : 'without'} the recogniser, "$seed"', (
          tester,
        ) async {
          final f = fixture(seed: seed, mic: mic);
          await pumpYo(tester, f);
          final want = m(m(yo[seed])[mic ? 'mic' : 'nomic']);

          expect(pillsOf(tester), oldPills(want['pills']));
          expect(switchesOf(tester), (want['switches'] as List).cast<bool>());
          expect(
            find.text(
              "Speaking in stories isn't available on this phone right now.",
            ),
            want['note'] as bool ? findsOneWidget : findsNothing,
          );
          expect(
            tester.widget<Text>(find.byKey(const Key('me-total-minutes'))).data,
            '${jsRound(f.progress.minutes)}',
          );
          final streak = f.progress.streak;
          expect(
            find.byKey(const Key('me-streak')),
            streak > 0 ? findsOneWidget : findsNothing,
          );
        });
      }
    }

    testWidgets(
      'everything built so far played: current place stays place 1 of 10 (La casa)',
      (tester) async {
        final f = fixture(seed: 'todo');
        await pumpYo(tester, f);
        expect(find.text('A1 · place 1 of 10'), findsOneWidget);
        expect(find.text('La casa'), findsOneWidget);
      },
    );
  });

  // ---- Y2: other stored values ----
  group(
    'Y2 other stored values (minutes rounding, pills, switches, level check)',
    () {
      for (final v in (oldExpected['yoVariants'] as List).map(m)) {
        testWidgets('${v['label']}', (tester) async {
          final f = fixture(json: v['stored'] as String);
          await pumpYo(tester, f);
          final want = m(v['facts']);
          final expectedTexts = strings(want['texts']);
          final levelHelpWant = expectedTexts.firstWhere(
            (t) =>
                t.startsWith('For people who already understand some Spanish'),
          );

          expect(pillsOf(tester), oldPills(want['pills']));
          expect(switchesOf(tester), (want['switches'] as List).cast<bool>());
          expect(
            tester.widget<Text>(find.byKey(const Key('me-total-minutes'))).data,
            '${jsRound(f.progress.minutes)}',
          );
          expect(find.text(levelHelpWant), findsOneWidget);
        });
      }
    },
  );

  // ---- Y3: the controls ----
  group('Y3 the controls write what the old handlers write', () {
    final handlers = (oldExpected['yoHandlers'] as List).map(m).toList();
    for (final h in handlers) {
      final onclick = h['onclick'] as String;
      final label =
          '${h['onclick']}   on ${jsonEncode(h['patch'])} (${h['seed']})';
      testWidgets(label, (tester) async {
        final f = fixture(json: h['stored'] as String);
        await pumpYo(tester, f);
        final Finder control;
        if (onclick.startsWith('AJ().min=')) {
          control = find.descendant(
            of: find.byKey(const Key('yo-minutes-segmented')),
            matching: find.text(h['button'] as String),
          );
        } else if (onclick.startsWith('AJ().todo')) {
          control = find.byKey(const Key('yo-todo'));
        } else if (onclick.startsWith('AJ().habla')) {
          control = find.byKey(const Key('yo-habla'));
        } else if (onclick.contains('nivel.html')) {
          control = find.byKey(const Key('yo-level-check'));
        } else {
          expect(onclick, 'bienvenida(0)');
          control = find.byKey(const Key('yo-how-it-works'));
        }
        final before = settingsOf(f.progress);
        expect(
          before,
          m(h['before']),
          reason: 'the stored settings are the old page\'s',
        );
        await tester.tap(control);
        await settle(tester);
        final after = m(h['after']);
        expect(settingsOf(f.progress), after);
        expect(
          f.haptics.ticks,
          h['ticks'],
          reason: 'tick() as the old handler',
        );
        expect(
          f.nav.routes,
          h['href'] == 'nivel.html' ? [const LevelCheckRoute()] : isEmpty,
        );
        if (onclick.startsWith('AJ().')) {
          expect(
            pillsOf(tester).indexWhere((p) => p.on),
            _pillOn(after['min']),
          );
          expect(switchesOf(tester), [
            jsTruthy(after['todo']),
            after['habla'] != 0,
          ]);
        }
        if (onclick == 'bienvenida(0)') {
          final w = m(h['welcome']);
          expect(textsOf(tester, find.byType(NocheSheet)), [
            ...strings(w['texts']),
            ...strings(w['footer']),
          ]);
          expect(sheetOpen(tester), isTrue);
        }
      });
    }

    testWidgets(
      'each switch toggles both ways: todo 0, 1, 0 and habla 1, 0, 1',
      (tester) async {
        final f = fixture(seed: 'vacio');
        await pumpYo(tester, f);
        final todo = <Object?>[];
        final habla = <Object?>[];
        for (var i = 0; i < 2; i++) {
          await tester.tap(find.byKey(const Key('yo-todo')));
          await settle(tester);
          todo.add(f.progress.setting('todo'));
          await tester.tap(find.byKey(const Key('yo-habla')));
          await settle(tester);
          habla.add(f.progress.setting('habla'));
        }
        expect(todo, [1, 0]);
        expect(habla, [0, 1]);
        expect(f.haptics.ticks, 4);
      },
    );
  });

  // ---- Y4: drawing again, and where he is ----
  group('Y4 redraws on progress.changes; place progress follows stories', () {
    testWidgets('the numbers follow the store', (tester) async {
      final f = fixture(seed: 'curso');
      final good = f.progress.words.where((w) => w.ear.etapa >= 4).length;
      await pumpYo(tester, f);
      expect(
        tester.widget<Text>(find.byKey(const Key('me-total-minutes'))).data,
        '109',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('me-skill-listening')),
          matching: find.text('$good of 78 good'),
        ),
        findsOneWidget,
      );
      f.progress.addMinutes(3);
      f.progress.heard('una palabra nueva');
      await settle(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('me-total-minutes'))).data,
        '112',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('me-skill-listening')),
          matching: find.text('$good of 79 good'),
        ),
        findsOneWidget,
      );
      expect(find.text('minutes listened'), findsOneWidget);
    });

    testWidgets('place 1 until its eleven stories are played, then place 2', (
      tester,
    ) async {
      final f = fixture(seed: 'vacio');
      await pumpYo(tester, f);
      expect(find.text('A1 · place 1 of 10'), findsOneWidget);
      expect(find.text('La casa'), findsOneWidget);
      final first = f.services.course.places.first.stories;
      for (final id in first.take(first.length - 1)) {
        f.progress.storyFinished(StoryResult(id: id));
      }
      await settle(tester);
      expect(find.text('A1 · place 1 of 10'), findsOneWidget);
      expect(find.text('La casa'), findsOneWidget);
      f.progress.storyFinished(StoryResult(id: first.last));
      await settle(tester);
      expect(find.text('A1 · place 2 of 10'), findsOneWidget);
      expect(find.text('El parque'), findsOneWidget);
    });

    testWidgets('a place with no stories is skipped: place 4 is never "here"', (
      tester,
    ) async {
      final f = fixture(seed: 'todo');
      await pumpYo(tester, f);
      expect(find.textContaining('place 4'), findsNothing);
    });
  });

  // ---- Y5: notaHabla ----
  group('Y5 the note that speaking is not available', () {
    for (final run in (oldExpected['note'] as List).map(m)) {
      testWidgets('${run['name']}', (tester) async {
        final f0 = fixture(seed: 'vacio');
        var f = f0;
        for (final st in (run['steps'] as List).map(m)) {
          f0.clock.now = referenceNowMs + (st['day'] as int) * 86400000;
          if (st['reload'] == true) {
            f = f0.reload(mic: st['mic'] as bool);
            await pumpYo(tester, f);
          } else {
            f.progress.setSetting('min', f.progress.setting('min')!);
            await settle(tester);
          }
          expect(
            find.text(
              "Speaking in stories isn't available on this phone right now.",
            ),
            st['note'] as bool ? findsOneWidget : findsNothing,
            reason: '${st['day']} ${st['reload']}',
          );
          expect(f.progress.setting('notaHabla'), st['notaHabla']);
        }
      });
    }

    testWidgets('the note sits between the Speak switch and the Level check', (
      tester,
    ) async {
      final f = fixture(seed: 'curso', mic: false);
      await pumpYo(tester, f);
      final t = yoTexts(tester);
      final i = t.indexOf(
        "Speaking in stories isn't available on this phone right now.",
      );
      expect(i, greaterThan(0));
      expect(t[i - 1], startsWith("Some of the coquí's lines"));
      expect(t[i + 1], 'Level check');
    });
  });

  // ---- Y6: How Coquí works ----
  group('Y6 "How Coquí works" (opens the Noche welcome sheet)', () {
    testWidgets(
      'opens the welcome at step 1, as an ordinary sheet with its X',
      (tester) async {
        final f = fixture(seed: 'vacio');
        await pumpYo(tester, f);
        expect(sheetOpen(tester), isFalse);
        await tester.tap(find.byKey(const Key('yo-how-it-works')));
        await settle(tester);
        expect(sheetOpen(tester), isTrue);
        expect(
          tester.widget<NocheSheet>(find.byType(NocheSheet)).onClose,
          isNotNull,
        );
        expect(find.text('Welcome to Coquí'), findsOneWidget);
        expect(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.closeSheet)),
          findsOneWidget,
        );
        expect(dotOf(tester), 0);
      },
    );

    testWidgets('the X closes it, and it opens again at step 1', (
      tester,
    ) async {
      final f = fixture(seed: 'vacio');
      await pumpYo(tester, f);
      await tester.tap(find.byKey(const Key('yo-how-it-works')));
      await settle(tester);
      await tapText(tester, 'Next');
      expect(dotOf(tester), 1);
      await tester.tap(
        find.bySemanticsLabel(NocheA11y.label(NocheA11y.closeSheet)),
      );
      await settle(tester);
      expect(sheetOpen(tester), isFalse);
      await tester.tap(find.byKey(const Key('yo-how-it-works')));
      await settle(tester);
      expect(dotOf(tester), 0);
    });

    testWidgets('a tap on the page above it closes it', (tester) async {
      final f = fixture(seed: 'vacio');
      await pumpYo(tester, f, how: 0);
      expect(sheetOpen(tester), isTrue);
      await tester.tapAt(const Offset(200, 20));
      await settle(tester);
      expect(sheetOpen(tester), isFalse);
    });

    testWidgets(
      'its scrim covers the tab bar: a tap on a tab only closes it; About does the same',
      (tester) async {
        for (final about in [false, true]) {
          final f = fixture(seed: 'curso');
          phone(tester);
          final taps = <String>[];
          final lang = f.services.course.language;
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            MaterialApp(
              theme: coquiTheme(),
              home: Scaffold(
                backgroundColor: NocheColors.ground,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    YoScreen(
                      services: f.services,
                      howItWorksStep: about ? null : 0,
                      aboutOpen: about,
                    ),
                    Align(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: NocheTabBar(
                        selectedId: NocheTabs.me,
                        tabNames: lang.tabNames,
                        script: lang.script,
                        languageCode: lang.code,
                        onTap: taps.add,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await settle(tester);
          expect(sheetOpen(tester), isTrue, reason: 'about: $about');
          final bar = tester.getRect(find.byType(NocheTabBar));
          await tester.tapAt(Offset(bar.center.dx - 120, bar.center.dy));
          await settle(tester);
          expect(taps, isEmpty);
          // NocheSheet extends to the bottom over the tab bar; tapping the scrim above it closes it.
          await tester.tapAt(const Offset(200, 20));
          await settle(tester);
          expect(sheetOpen(tester), isFalse);
          await tester.tapAt(Offset(bar.center.dx - 120, bar.center.dy));
          await tester.pump();
          expect(taps, hasLength(1));
        }
      },
    );

    testWidgets('it does not write anything, and it does not tick', (
      tester,
    ) async {
      final f = fixture(seed: 'curso');
      await pumpYo(tester, f);
      final saves = f.progress.saves;
      await tester.tap(find.byKey(const Key('yo-how-it-works')));
      await settle(tester);
      expect(f.progress.saves, saves);
      expect(f.haptics.ticks, 0);
    });
  });
}

int _pillOn(Object? min) =>
    min is num ? const [15, 30, 60, 120].indexOf(min.toInt()) : -1;
