// The call screen, state by state, as the reference pictures show each (coqui/ref/pantallas/*/102 to 119), on the
// scripted fake call. The screen makes its own controller; the test moves the clock and the fake time together.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_look.dart';
import 'package:feature_speaking/src/call_mic.dart';
import 'package:feature_speaking/src/call_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/world.dart';

Future<World> pump(
  WidgetTester tester, {
  Phone phone = Phone.android,
  Set<String> stub = const {'manual'},
  bool reduce = true,
  String? seed = 'todo',
}) async {
  phone.use(tester);
  final w = await World.create(seed: seed, stub: stub, reduceMotion: reduce);
  await tester.pumpWidget(
    w.app(CallScreen(services: w.services, placeId: 'casa')),
  );
  await tester.pump();
  return w;
}

Future<void> tapDisc(WidgetTester tester) async {
  await tester.tap(find.byType(CallMicStage));
  await tester.pump();
}

Rect rectOf(WidgetTester tester, Finder f) => tester.getRect(f.first);

TextStyle styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

bool helpVisible(WidgetTester tester) {
  final v = tester.widget<Visibility>(
    find.ancestor(of: find.text('Help'), matching: find.byType(Visibility)),
  );
  return v.visible;
}

/// The call up to the learner's turn: connected, Danny's line, his turn.
Future<void> toYourTurn(WidgetTester tester, World w) async {
  await tapDisc(tester);
  w.call.go('connect');
  await w.elapse(tester, 100);
  w.call.go('danny1');
  await w.elapse(tester, 2400);
  w.call.go('you1');
  await w.elapse(tester, 300);
}

void main() {
  group('idle: before the tap', () {
    testWidgets(
      'dark #1B1B1F screen, label Start call, X 48 px, timer 12 px, disc 72 px, Help hidden, the dialog is named Call Danny',
      (tester) async {
        final handle = tester.ensureSemantics();
        final w = await pump(tester);
        expect(
          find.byWidgetPredicate(
            (x) => x is ColoredBox && x.color == const Color(0xFF1B1B1F),
          ),
          findsWidgets,
        );
        expect(find.text('Start call'), findsOneWidget);
        expect(
          tester.getSize(find.byType(LessonCloseButton)),
          const Size(48, 48),
        );
        expect(styleOf(tester, '00:00').fontSize, 12);
        expect(styleOf(tester, '00:00').color, CallColors.grey);
        expect(tester.getSize(find.byType(CallMicStage)), const Size(96, 96));
        final disc = tester.getSize(
          find
              .descendant(
                of: find.byType(CallMicStage),
                matching: find.byType(AnimatedContainer),
              )
              .last,
        );
        expect(disc, const Size(72, 72));
        expect(helpVisible(tester), isFalse);
        expect(find.bySemanticsLabel(RegExp('Call Danny')), findsWidgets);
        handle.dispose();
        // "La casa · about 5 min", grey, 16 px, where Danny's line will be
        expect(styleOf(tester, 'La casa · about 5 min').color, CallColors.grey);
        expect(styleOf(tester, 'La casa · about 5 min').fontSize, 16);
        await w.close(tester);
      },
    );

    for (final phone in [
      Phone.android,
      Phone.iphone,
      Phone.small,
      Phone.side,
    ]) {
      testWidgets(
        'the picture is a whole number of device pixels per art pixel, and the layout is inside the screen with no overlaps: ${phone.name}',
        (tester) async {
          final w = await pump(tester, phone: phone);
          expect(tester.takeException(), isNull);
          final pic = tester.getSize(find.byType(PictureFrame));
          final kx = pic.width * phone.ratio / 196;
          final ky = pic.height * phone.ratio / 104;
          expect((kx - kx.round()).abs(), lessThan(1e-6));
          expect((ky - ky.round()).abs(), lessThan(1e-6));
          expect(kx.round(), ky.round());
          expect(
            kx.round(),
            CallMetrics.pictureScale(
              size: Size(phone.width, phone.height),
              devicePixelRatio: phone.ratio,
            ),
          );
          final screen = Rect.fromLTWH(0, 0, phone.width, phone.height);
          final parts = <String, Rect>{
            'picture': rectOf(tester, find.byType(PictureFrame)),
            'line': rectOf(tester, find.text('La casa · about 5 min')),
            'mic': rectOf(tester, find.byType(CallMicStage)),
            'label': rectOf(tester, find.text('Start call')),
            'x': rectOf(tester, find.byType(LessonCloseButton)),
            'timer': rectOf(tester, find.text('00:00')),
          };
          parts.forEach((k, r) {
            expect(
              screen.contains(r.topLeft) &&
                  screen.contains(r.bottomRight - const Offset(.01, .01)),
              isTrue,
              reason: '$k $r in ${phone.name}',
            );
          });
          final names = parts.keys.toList();
          for (var i = 0; i < names.length; i++) {
            for (var j = i + 1; j < names.length; j++) {
              final o = parts[names[i]]!.intersect(parts[names[j]]!);
              expect(
                o.width > 1 && o.height > 1,
                isFalse,
                reason: '${names[i]} and ${names[j]} overlap in ${phone.name}',
              );
            }
          }
          await w.close(tester);
        },
      );
    }

    testWidgets(
      'on its side the picture is at the left, the lines and the mic at the right',
      (tester) async {
        final w = await pump(tester, phone: Phone.side);
        final pic = rectOf(tester, find.byType(PictureFrame));
        final mic = rectOf(tester, find.byType(CallMicStage));
        final line = rectOf(tester, find.text('La casa · about 5 min'));
        // the picture's column is as wide as the picture and its two 16 px margins (grid-template-columns: auto ...)
        expect(pic.left, 16);
        expect(pic.right, lessThan(16 + 196 * 7 / 3 + 1));
        expect(mic.left, greaterThan(pic.right));
        expect(line.left, greaterThan(pic.right));
        await w.close(tester);
      },
    );

    testWidgets(
      'the X before the call closes the screen (back), the call was never started',
      (tester) async {
        final w = await pump(tester);
        await tester.tap(find.byType(LessonCloseButton));
        await tester.pump();
        expect(w.nav.backs, 1);
        expect(w.call.starts, 0);
        await w.close(tester);
      },
    );
  });

  group('the states of the call', () {
    testWidgets(
      'connecting: shows within 200 ms, label Calling…, the disc pulses (not when motion is off)',
      (tester) async {
        final w = await pump(tester, reduce: false);
        await tapDisc(tester);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Calling…'), findsOneWidget);
        final scales = <double>{};
        for (var i = 0; i < 12; i++) {
          await w.elapse(tester, 75);
          final t = tester.widget<Transform>(
            find
                .descendant(
                  of: find.byType(CallMicStage),
                  matching: find.byType(Transform),
                )
                .first,
          );
          scales.add(
            double.parse(t.transform.getMaxScaleOnAxis().toStringAsFixed(3)),
          );
        }
        expect(scales.length, greaterThan(3), reason: 'it pulses');
        expect(
          scales.reduce((a, b) => a > b ? a : b),
          lessThanOrEqualTo(1.1001),
        );
        expect(helpVisible(tester), isFalse);
        await w.close(tester);
      },
    );

    testWidgets('connecting with motion off: the disc does not pulse', (
      tester,
    ) async {
      final w = await pump(tester, reduce: true);
      await tapDisc(tester);
      await w.elapse(tester, 400);
      expect(find.text('Calling…'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CallMicStage),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
      await w.close(tester);
    });

    testWidgets(
      'danny: label Danny, blue rings #3B5BDB spread from the disc with motion; Danny\'s line white 18 px, two lines at most; Help visible, 48 px; the timer 00:00 at the start',
      (tester) async {
        final w = await pump(tester, reduce: false);
        await tapDisc(tester);
        w.call.go('connect');
        await w.elapse(tester, 120);
        expect(find.text('Danny'), findsOneWidget);
        expect(find.text('00:00'), findsOneWidget);
        await w.elapse(tester, 1500);
        final rings = find.byWidgetPredicate(
          (x) =>
              x is Container &&
              x.decoration is BoxDecoration &&
              (x.decoration! as BoxDecoration).border?.top.color ==
                  CoquiColors.lessonBlue,
        );
        expect(rings, findsNWidgets(3));
        w.call.go('danny1');
        await w.elapse(tester, 200);
        final s = styleOf(tester, '¡Hola! Soy Danny. ¿Cómo estás?');
        expect(s.fontSize, 18);
        expect(s.color, const Color(0xFFFFFFFF));
        expect(
          tester
              .widget<Text>(find.text('¡Hola! Soy Danny. ¿Cómo estás?'))
              .maxLines,
          2,
        );
        expect(helpVisible(tester), isTrue);
        expect(tester.getSize(find.byType(LessonButton)).height, 48);
        await w.close(tester);
      },
    );

    testWidgets('danny with motion off: no rings', (tester) async {
      final w = await pump(tester, reduce: true);
      await tapDisc(tester);
      w.call.go('connect');
      await w.elapse(tester, 1500);
      final rings = find.byWidgetPredicate(
        (x) =>
            x is Container &&
            x.decoration is BoxDecoration &&
            (x.decoration! as BoxDecoration).border?.top.color ==
                CoquiColors.lessonBlue,
      );
      expect(rings, findsNothing);
      await w.close(tester);
    });

    testWidgets(
      'your turn: green ring (#3FAE6B) thicker as he talks; label Your turn; Help 48 px',
      (tester) async {
        final w = await pump(tester);
        await toYourTurn(tester, w);
        expect(find.text('Your turn'), findsOneWidget);
        double ring() {
          final c = tester.widget<AnimatedContainer>(
            find
                .descendant(
                  of: find.byType(CallMicStage),
                  matching: find.byType(AnimatedContainer),
                )
                .first,
          );
          final shadows = (c.decoration! as BoxDecoration).boxShadow!;
          expect(shadows.single.color, CallColors.levelRing);
          return shadows.single.spreadRadius;
        }

        expect(ring(), 3);
        w.call.go('talk1');
        await w.elapse(tester, 600);
        expect(ring(), greaterThan(5));
        expect(tester.getSize(find.byType(LessonButton)).height, 48);
        await w.close(tester);
      },
    );

    testWidgets(
      'one moment: three dots, label One moment, no ring; what the app heard in #9AD5A8, 16 px',
      (tester) async {
        final w = await pump(tester);
        await toYourTurn(tester, w);
        w.call.go('talk1');
        await w.elapse(tester, 1200);
        w.call.go('quiet1');
        await w.elapse(tester, 800);
        expect(find.text('One moment'), findsOneWidget);
        final dots = find.byWidgetPredicate(
          (x) =>
              x is Container &&
              x.constraints?.maxWidth == 9 &&
              x.constraints?.maxHeight == 9,
        );
        expect(dots, findsNWidgets(3));
        w.call.go('heard1');
        await w.elapse(tester, 100);
        final s = styleOf(tester, 'Hola. Bien, gracias.');
        expect(s.fontSize, 16);
        expect(s.color, CoquiColors.heard);
        await w.close(tester);
      },
    );

    testWidgets(
      'show_picture: the picture of the word asked for is shown; an unknown key changes nothing',
      (tester) async {
        final w = await pump(tester);
        final pics = w.services.pictures as FakePictureSource;
        await tapDisc(tester);
        w.call.go('connect');
        await w.elapse(tester, 300);
        w.call.emit(const Tool('show_picture', {'picture': 'zzz'}));
        await w.elapse(tester, 100);
        final shownBefore = pics.shown.length;
        w.call.emit(const Tool('show_picture', {'picture': 'puerta'}));
        await w.elapse(tester, 100);
        expect(pics.shown.length, greaterThan(shownBefore));
        final pair = w.course.pairFor('puerta')!;
        expect(pics.shown.last.cam, pair.yes.cam);
        await w.close(tester);
      },
    );

    testWidgets('Help sends (ayuda), the note says so and goes after 5 s', (
      tester,
    ) async {
      final w = await pump(tester);
      await toYourTurn(tester, w);
      await tester.tap(find.text('Help'));
      await w.elapse(tester, 200);
      expect(w.call.sent, ['(ayuda)']);
      expect(find.text('Danny will say it again, slowly.'), findsOneWidget);
      await w.elapse(tester, 5200);
      expect(find.text('Danny will say it again, slowly.'), findsNothing);
      await w.close(tester);
    });

    testWidgets('the timer counts in mm:ss', (tester) async {
      final w = await pump(tester);
      await toYourTurn(tester, w);
      expect(find.text('00:02'), findsOneWidget);
      await w.elapse(tester, 1000);
      expect(find.text('00:03'), findsOneWidget);
      await w.close(tester);
    });
  });

  group('the end', () {
    testWidgets(
      'the X ends a live call with the summary: Call done, N min · M words said, the words as chips, a blue Back to Hablar of at least 48 px that goes back',
      (tester) async {
        final w = await pump(tester);
        await toYourTurn(tester, w);
        w.call.emit(const Heard('Hola. Bien, gracias.'));
        await w.elapse(tester, 100);
        await tester.tap(find.byType(LessonCloseButton));
        await w.elapse(tester, 100);
        expect(find.text('Call done'), findsOneWidget);
        expect(find.text('1 min · 3 words said'), findsOneWidget);
        for (final word in ['hola', 'gracias', 'bien']) {
          expect(find.text(word), findsOneWidget);
        }
        expect(find.text('Start call'), findsNothing);
        expect(find.text('Help'), findsNothing);
        final back = find.widgetWithText(LessonButton, 'Back to Hablar');
        expect(back, findsOneWidget);
        expect(tester.widget<LessonButton>(back).kind, LessonButtonKind.blue);
        expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
        expect(w.call.ended, isTrue);
        expect(w.nav.backs, 0);
        await tester.tap(back);
        await tester.pump();
        expect(w.nav.backs, 1);
        await w.close(tester);
      },
    );

    testWidgets('the summary fits the screen at every size', (tester) async {
      for (final phone in [
        Phone.android,
        Phone.iphone,
        Phone.small,
        Phone.side,
      ]) {
        final w = await pump(tester, phone: phone);
        await toYourTurn(tester, w);
        w.call.emit(const Heard('Hola. Bien, gracias.'));
        await w.elapse(tester, 100);
        await tester.tap(find.byType(LessonCloseButton));
        await w.elapse(tester, 100);
        expect(tester.takeException(), isNull, reason: phone.name);
        final back = rectOf(
          tester,
          find.widgetWithText(LessonButton, 'Back to Hablar'),
        );
        expect(
          back.bottom,
          lessThanOrEqualTo(phone.height),
          reason: phone.name,
        );
        expect(back.right, lessThanOrEqualTo(phone.width), reason: phone.name);
        await w.close(tester);
      }
    });

    testWidgets(
      'the natural call ends by itself with the summary (the goodbye)',
      (tester) async {
        final w = await pump(tester, stub: const {});
        await tapDisc(tester);
        for (var t = 0; t < 30000; t += 100) {
          await w.elapse(tester, 100);
          if (find.text('Call done').evaluate().isNotEmpty) break;
        }
        expect(find.text('Call done'), findsOneWidget);
        expect(find.text('1 min · 7 words said'), findsOneWidget);
        expect(w.call.sent, ['(fin)']);
        await w.close(tester);
      },
    );

    testWidgets(
      'refused microphone: one plain line, the X (and the timer) stay',
      (tester) async {
        final w = await pump(tester, stub: const {'mic'});
        await tapDisc(tester);
        await w.elapse(tester, 600);
        expect(
          find.text('The microphone is off. Allow it in your browser to call.'),
          findsOneWidget,
        );
        expect(find.byType(LessonCloseButton), findsOneWidget);
        expect(find.text('00:00'), findsOneWidget);
        expect(find.byType(CallMicStage), findsNothing);
        await tester.tap(find.byType(LessonCloseButton));
        await tester.pump();
        expect(w.nav.backs, 1);
        await w.close(tester);
      },
    );

    testWidgets('failed start: the plain line', (tester) async {
      final w = await pump(tester, stub: const {'fail'});
      await tapDisc(tester);
      await w.elapse(tester, 800);
      expect(
        find.text(
          'The call did not start. Check your connection and try again.',
        ),
        findsOneWidget,
      );
      await w.close(tester);
    });

    testWidgets(
      'leaving the screen in a live call ends the call and counts its minutes',
      (tester) async {
        final w = await pump(tester);
        await toYourTurn(tester, w);
        await tester.pumpWidget(w.app(const SizedBox()));
        expect(w.call.ended, isTrue);
        expect(w.progress.minutes, greaterThan(0));
        await w.close(tester);
      },
    );
  });
}
