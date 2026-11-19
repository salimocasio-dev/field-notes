// One test per behaviour of app.html's `yo` (lines 465 to 480), with the old page's expected values from
// tool/old_expected.mjs (test/support/old_expected.dart): the old functions run in node on the same stored progress.
//
//   Y1  the whole page, for each of the eight reference states, with the recogniser there and without it (line 473-480)
//   Y2  each number and line with other stored values: minutes rounded, singular and plural, the pill that is on,
//       the switches, the level check's line (line 472-479)
//   Y3  each control writes what the old handler writes, and ticks where the old one ticks (line 475-479)
//   Y4  the page draws again whenever the store saves, and "where you are" follows the stories played (line 471, 474)
//   Y5  notaHabla: once a day, again while the page is open, never when the recogniser is there (line 466-470, 478)
//   Y6  "How it works" opens the welcome sheet, an ordinary one, and its X and the page above it close it (line 480)
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/js.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/dev_app.dart';
import 'support/harness.dart';

Map<String, dynamic> m(Object? o) => (o as Map).cast<String, dynamic>();
List<String> strings(Object? o) => (o as List).cast<String>();

void main() {
  // ---- Y1: the whole page ----
  group('Y1 the page, as yo() writes it (app.html:473-480)', () {
    final yo = m(oldExpected['yo']);
    for (final seed in yo.keys) {
      for (final mic in [true, false]) {
        testWidgets('${mic ? 'with' : 'without'} the recogniser, "$seed"', (
          tester,
        ) async {
          final f = fixture(seed: seed, mic: mic);
          await pumpYo(tester, f);
          final want = m(m(yo[seed])[mic ? 'mic' : 'nomic']);
          expect(yoTexts(tester), strings(want['texts']));
          expect(pillsOf(tester), oldPills(want['pills']));
          expect(switchesOf(tester), (want['switches'] as List).cast<bool>());
          expect(
            find.text(
              "Speaking in stories isn't available on this phone right now.",
            ),
            want['note'] as bool ? findsOneWidget : findsNothing,
          );
        });
      }
    }

    testWidgets(
      'everything built so far played: it says place 1 of 10, as the old page does (a fault of the old page, ported)',
      (tester) async {
        final f = fixture(seed: 'todo');
        await pumpYo(tester, f);
        expect(find.text('A1 · place 1 of 10 · La casa'), findsOneWidget);
      },
    );
  });

  // ---- Y2: other stored values ----
  group('Y2 other stored values (app.html:472-479)', () {
    for (final v in (oldExpected['yoVariants'] as List).map(m)) {
      testWidgets('${v['label']}', (tester) async {
        final f = fixture(json: v['stored'] as String);
        await pumpYo(tester, f);
        final want = m(v['facts']);
        expect(yoTexts(tester), strings(want['texts']));
        expect(pillsOf(tester), oldPills(want['pills']));
        expect(switchesOf(tester), (want['switches'] as List).cast<bool>());
      });
    }
  });

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
            of: find.byType(SegmentedPills),
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
          // yo() draws again: the pill and the switches show the new values
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
          expect(textsOf(tester, find.byType(CoquiSheet)), [
            ...strings(w['texts']),
            ...strings(w['footer']),
          ]);
          expect(
            tester.widget<CoquiSheetLayer>(find.byType(CoquiSheetLayer)).open,
            isTrue,
          );
        }
      });
    }

    testWidgets(
      'each switch toggles both ways: todo 0, 1, 0 and habla 1, 0, 1 (the old test is `?0:1` and `===0?1:0`)',
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
  group(
    'Y4 it draws again on progress.changes; where you are (app.html:471, 474)',
    () {
      testWidgets('the numbers follow the store', (tester) async {
        final f = fixture(seed: 'curso');
        await pumpYo(tester, f);
        expect(find.text('109'), findsOneWidget);
        expect(find.text('78'), findsOneWidget);
        f.progress.addMinutes(3);
        f.progress.heard('una palabra nueva');
        await settle(tester);
        expect(find.text('112'), findsOneWidget); // Math.round(108.9 + 3)
        expect(find.text('79'), findsOneWidget);
        expect(find.text('minutes listened'), findsOneWidget);
      });

      testWidgets('place 1 until its eleven stories are played, then place 2', (
        tester,
      ) async {
        final f = fixture(seed: 'vacio');
        await pumpYo(tester, f);
        expect(find.text('A1 · place 1 of 10 · La casa'), findsOneWidget);
        final first = f.services.course.places.first.stories;
        for (final id in first.take(first.length - 1)) {
          f.progress.storyFinished(StoryResult(id: id));
        }
        await settle(tester);
        expect(find.text('A1 · place 1 of 10 · La casa'), findsOneWidget);
        f.progress.storyFinished(StoryResult(id: first.last));
        await settle(tester);
        expect(find.text('A1 · place 2 of 10 · El parque'), findsOneWidget);
      });

      testWidgets(
        'a place with no stories is skipped: place 4 is never "here"',
        (tester) async {
          final f = fixture(seed: 'todo');
          await pumpYo(tester, f);
          expect(find.textContaining('place 4'), findsNothing);
        },
      );
    },
  );

  // ---- Y5: notaHabla ----
  group(
    'Y5 the note that speaking is not available (app.html:466-470, 478)',
    () {
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
              // yo() drawn again on the same page: the store saves something and the page draws
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

      testWidgets(
        'the note sits between the Speak switch and the Level check, and the Level check then has no line over it',
        (tester) async {
          final f = fixture(seed: 'curso', mic: false);
          await pumpYo(tester, f);
          final t = yoTexts(tester);
          final i = t.indexOf(
            "Speaking in stories isn't available on this phone right now.",
          );
          expect(t[i - 1], startsWith("Some of the coquí's lines"));
          expect(t[i + 1], 'Level check');
        },
      );
    },
  );

  // ---- Y6: How it works ----
  group('Y6 "How it works" (app.html:480)', () {
    testWidgets(
      'opens the welcome at step 1, as an ordinary sheet with its X',
      (tester) async {
        final f = fixture(seed: 'vacio');
        await pumpYo(tester, f);
        expect(
          tester.widget<CoquiSheetLayer>(find.byType(CoquiSheetLayer)).open,
          isFalse,
        );
        await tester.tap(find.byKey(const Key('yo-how-it-works')));
        await settle(tester);
        expect(
          tester.widget<CoquiSheetLayer>(find.byType(CoquiSheetLayer)).open,
          isTrue,
        );
        expect(
          tester.widget<CoquiSheet>(find.byType(CoquiSheet)).modal,
          isFalse,
        );
        expect(find.text('Welcome to Coquí'), findsOneWidget);
        expect(find.byType(CoquiCloseButton), findsOneWidget);
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
      await tester.tap(find.byType(CoquiCloseButton));
      await settle(tester);
      expect(
        tester.widget<CoquiSheetLayer>(find.byType(CoquiSheetLayer)).open,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('yo-how-it-works')));
      await settle(tester);
      expect(dotOf(tester), 0);
    });

    testWidgets('a tap on the page above it closes it (fuera)', (tester) async {
      final f = fixture(seed: 'vacio');
      await pumpYo(tester, f, how: 0);
      expect(
        tester.widget<CoquiSheetLayer>(find.byType(CoquiSheetLayer)).open,
        isTrue,
      );
      await tester.tapAt(const Offset(200, 20));
      await settle(tester);
      expect(
        tester.widget<CoquiSheetLayer>(find.byType(CoquiSheetLayer)).open,
        isFalse,
      );
    });

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
