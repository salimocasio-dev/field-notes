// The reader (Leer): the checks of historia/tools/leer_check.py that are about the book, and one test for each
// behaviour of app.html's `leer` ... `cierraTarjeta` the script does not cover.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/book_line.dart';
import 'package:feature_library/src/strings.dart';
import 'package:feature_library/src/word_popup.dart';
import 'package:feature_library/src/reader.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

Finder line(String id) => find.byKey(ValueKey('line:$id'));

Finder closeButton() => find.byWidgetPredicate(
  (w) => w is LessonIconButton && w.semanticLabel == 'Close',
);
Finder nextButton() => find.byWidgetPredicate(
  (w) => w is LessonButton && w.semanticLabel == 'Next page',
);
Finder backButton() => find.byWidgetPredicate(
  (w) => w is LessonButton && w.semanticLabel == 'Previous page',
);

Finder buttonLabelled(String label) => find.byWidgetPredicate(
  (w) => w is LessonButton && w.label == label,
  description: label,
);

/// The paragraph that holds a line's text.
RenderParagraph paragraphOf(WidgetTester tester, String id) {
  final text = lineViews(tester).firstWhere((l) => l.line.id == id).line.text;
  return tester.renderObject<RenderParagraph>(
    find.descendant(
      of: line(id),
      matching: find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == text,
      ),
    ),
  );
}

/// Where the [n]-th occurrence of [word] is on the screen, as the paragraph itself says.
Offset wordAt(WidgetTester tester, String id, String word, {int n = 0}) {
  final p = paragraphOf(tester, id);
  final plain = p.text.toPlainText();
  var at = -1;
  for (var i = 0; i <= n; i++) {
    at = plain.indexOf(word, at + 1);
  }
  final box = p
      .getBoxesForSelection(
        TextSelection(baseOffset: at, extentOffset: at + word.length),
      )
      .first;
  return p.localToGlobal(box.toRect().center);
}

/// Steps the test's time and records each different set of lit lines.
Future<List<List<String>>> litTrace(
  WidgetTester tester, {
  Duration total = const Duration(seconds: 12),
  Duration step = const Duration(milliseconds: 50),
}) async {
  final seen = <List<String>>[lit(tester)];
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
    final now = lit(tester);
    if (now.join(',') != seen.last.join(',')) seen.add(now);
  }
  return seen;
}

/// Lets the page play all its lines.
Future<void> finishPage(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 12));

/// The number on "3 / 9".
String count(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .firstWhere((t) => RegExp(r'^\d+ / \d+$').hasMatch(t));

TextStyle lineStyle(WidgetTester tester, String id) {
  final text = lineViews(tester).firstWhere((l) => l.line.id == id).line.text;
  return tester
      .widget<RichText>(
        find.descendant(
          of: line(id),
          matching: find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == text,
          ),
        ),
      )
      .text
      .style!;
}

void main() {
  setUpAll(makeTestPicture);

  group('opening', () {
    testWidgets(
      'leer_check: book opens full screen (the tab bar is the shell\'s: nothing of it here)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        expect(tester.getSize(find.byType(BookReader)), const Size(412, 915));
        expect(find.byType(CoquiTabBar), findsNothing);
        expect(pageIds(tester), isNotEmpty);
      },
    );

    testWidgets(
      'leer_check: book: up to three lines on the page (every page)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        for (var p = 0; p < 4; p++) {
          expect(pageIds(tester).length, inInclusiveRange(1, 3));
          if (p < 3) {
            await tester.tap(nextButton());
            await settle(tester);
          }
        }
      },
    );

    testWidgets(
      'leer: a book that is not there goes back (the old page did not open one)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig, book: 'cinco');
        expect(rig.nav.backs, 1);
        expect(rig.progress.hasRead('cinco'), isFalse);
      },
    );

    testWidgets('leer: a book whose story file is not there goes back', (
      tester,
    ) async {
      final course = TestCourse(stories: {});
      final rig = Rig(course: course);
      await pumpReader(tester, rig);
      expect(rig.nav.backs, 1);
    });

    testWidgets(
      'leer: a late fetch drops itself when the book is closed first (LEERT)',
      (tester) async {
        final slow = _SlowBook();
        final rig = Rig(course: slow);
        await pumpReader(tester, rig);
        // the screen goes before the book arrives
        await tester.pumpWidget(const SizedBox());
        slow.gate.complete();
        await settle(tester);
        expect(rig.clips.played, isEmpty);
        expect(rig.nav.backs, 0);
        expect(rig.progress.hasRead('uno'), isFalse);
      },
    );

    testWidgets(
      'leer: a line the story file does not know is left out of the page (idsPag)',
      (tester) async {
        final course = TestCourse(
          books: {
            'uno': Book(
              id: 'uno',
              title: 'uno',
              readable: true,
              pages: [
                BookPage(
                  image: 'img/uno-1.png',
                  clips: ['u1', 'no_such_line', 'u2'],
                ),
              ],
            ),
          },
        );
        final rig = Rig(course: course);
        await pumpReader(tester, rig);
        expect(pageIds(tester), ['u1', 'u2']);
      },
    );

    testWidgets(
      'leer_check: page 1 plays its lines in order, each lit in turn',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        // the first line is lit at once
        expect(lit(tester), ['u1']);
        final seen = await litTrace(tester);
        expect(seen, [
          ['u1'],
          ['u2'],
          ['u3'],
          <String>[],
        ]);
        expect(rig.clips.played, ['u1', 'u2', 'u3']);
      },
    );

    testWidgets('leer_check: page waits at its end (no auto-advance)', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      await finishPage(tester);
      await tester.pump(const Duration(seconds: 30));
      expect(count(tester), '1 / 4');
      expect(rig.clips.played, ['u1', 'u2', 'u3']);
    });

    testWidgets(
      'leer_check: audio is loaded per page (this page\'s clips and the next page\'s, not the story)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await finishPage(tester);
        final allowed = {'u1', 'u2', 'u3', 'u4'};
        final got = rig.clips.preloaded.toSet();
        expect(got, isNotEmpty);
        expect(allowed.containsAll(got), isTrue, reason: 'asked for: $got');
        expect(got.length, lessThan(7));
      },
    );
  });

  group('the page', () {
    testWidgets('leer_check: picture whole-number scaled, pixelated, in view', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      final pv = find.byType(PixelView);
      expect(pv, findsOneWidget);
      final r = tester.getRect(pv);
      final k = r.width * 2.625 / 196;
      expect((k - k.roundToDouble()).abs(), lessThan(1e-6));
      expect(k, greaterThanOrEqualTo(1));
      expect(r.height * 2.625 / 216, closeTo(k, 1e-6));
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(412));
      expect(r.top, greaterThanOrEqualTo(0));
      expect(r.bottom, lessThanOrEqualTo(915));
      // it is the picture of page 1, asked for with the version tag
      expect(rig.images.asked, contains('libros/img/uno-1.png?v=39'));
      expect(rig.images.asked, contains('libros/img/uno-2.png?v=39'));
    });

    testWidgets(
      'leer_check: close and text-size buttons 48 px, arrows 48 px or more',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        expect(tester.getSize(closeButton()), const Size(48, 48));
        expect(
          tester.getSize(find.byType(LessonTextSizeButton)),
          const Size(48, 48),
        );
        expect(tester.getSize(nextButton()).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(backButton()).height, greaterThanOrEqualTo(48));
      },
    );

    testWidgets(
      'leer_check: lines are 48 px targets; text 20 px on 30; thin progress bar',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        for (final l in lineViews(tester)) {
          expect(
            tester.getSize(line(l.line.id)).height,
            greaterThanOrEqualTo(48),
          );
          final st = lineStyle(tester, l.line.id);
          expect(st.fontSize, 20);
          expect(st.fontSize! * st.height!, closeTo(30, 1e-9));
        }
        // the bar itself: its widget is as high as the bar's row, the line inside it is 6 px
        final bar = find.descendant(
          of: find.byType(LessonProgressLine),
          matching: find.byType(Container),
        );
        expect(tester.getSize(bar.first).height, lessThanOrEqualTo(8));
      },
    );

    testWidgets(
      'leer_check: speaker label: a Coquí line has "Coquí", the text is exactly as recorded',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        for (final l in lineViews(tester)) {
          final who = find.descendant(
            of: line(l.line.id),
            matching: find.text(LibraryStrings.coqui),
          );
          expect(who, l.line.who == 'tu' ? findsOneWidget : findsNothing);
          expect(
            paragraphOf(tester, l.line.id).text.toPlainText(),
            l.line.text,
          );
        }
      },
    );

    testWidgets(
      'leer_check: a multi-word word is one span (phrase, accents ignored)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        final u2 = lineViews(tester).firstWhere((l) => l.line.id == 'u2');
        final phrase = u2.marks
            .where((m) => u2.line.text.substring(m.start, m.end).contains(' '))
            .toList();
        expect(phrase, hasLength(1));
        expect(
          normalize(
            u2.line.text.substring(phrase.single.start, phrase.single.end),
          ).trim(),
          'como estas',
        );
      },
    );

    testWidgets('leer_check: each line has a small speaker icon', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      for (final l in lineViews(tester)) {
        final icons = find.descendant(
          of: line(l.line.id),
          matching: find.byType(CoquiIcon),
        );
        final spk = tester
            .widgetList<CoquiIcon>(icons)
            .where((i) => identical(i.data, CoquiIcons.volume));
        expect(spk, hasLength(1));
        expect(spk.single.size, inInclusiveRange(14, 24));
      }
    });

    testWidgets('leer_check: page count 1 / N beside the progress bar', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      expect(count(tester), '1 / 4');
      final bar = tester.getRect(find.byType(LessonProgressLine));
      final cnt = tester.getRect(find.text('1 / 4'));
      final aa = tester.getRect(find.byType(LessonTextSizeButton));
      expect(cnt.left, greaterThanOrEqualTo(bar.right));
      expect(cnt.right, lessThanOrEqualTo(aa.left + 1));
      expect((cnt.center.dy - bar.center.dy).abs(), lessThan(8));
    });

    testWidgets(
      'leer_check: words that have a picture carry a faint dotted underline',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        final u1 = lineViews(tester).firstWhere((l) => l.line.id == 'u1');
        expect(u1.marks, isNotEmpty);
        final style = lineStyle(tester, 'u1');
        final tp = TextPainter(
          text: TextSpan(text: u1.line.text, style: style),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 300);
        final us = markUnderlines(tp, u1.marks, null);
        expect(us, isNotEmpty);
        expect(us.every((u) => !u.solid), isTrue);
        // 5 px under the baseline, 2 px high
        final base = tp.computeLineMetrics().first.baseline;
        expect(us.first.rect.top, closeTo(base + 5, 1e-9));
        expect(us.first.rect.height, 2);
      },
    );

    testWidgets(
      'leer_check: a tap on a line plays that line (lit), and only it',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await finishPage(tester);
        rig.clips.played.clear();
        // the left edge of the second line, away from any word
        await tester.tapAt(tester.getTopLeft(line('u2')) + const Offset(4, 20));
        await tester.pump();
        expect(lit(tester), ['u2']);
        final seen = await litTrace(tester, total: const Duration(seconds: 3));
        expect(seen, [
          ['u2'],
          <String>[],
        ]);
        expect(rig.clips.played, ['u2']);
      },
    );
  });

  group('turning the page', () {
    testWidgets('leer_check: next arrow: page 2, its lines play in order', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      await finishPage(tester);
      rig.clips.played.clear();
      await tester.tap(nextButton());
      await settle(tester);
      expect(count(tester), '2 / 4');
      expect(pageIds(tester), ['u4']);
      await finishPage(tester);
      expect(rig.clips.played, ['u4']);
    });

    testWidgets('leer_check: back arrow: page 1', (tester) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      await tester.tap(nextButton());
      await settle(tester);
      await tester.tap(backButton());
      await settle(tester);
      expect(count(tester), '1 / 4');
    });

    testWidgets(
      'leer_check: swipe left: next page; swipe right: previous page',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await swipe(tester, -220);
        await settle(tester);
        expect(count(tester), '2 / 4');
        await swipe(tester, 220);
        await settle(tester);
        expect(count(tester), '1 / 4');
      },
    );

    testWidgets('leer_check: a short drag does not turn the page', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      await swipe(tester, 30);
      await swipe(tester, -40);
      await swipe(tester, -100, dy: 100); // more down than across
      await settle(tester);
      expect(count(tester), '1 / 4');
    });

    testWidgets('leer_check: back arrow disabled on page 1', (tester) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      expect(tester.widget<LessonButton>(backButton()).onPressed, isNull);
      await tester.tap(nextButton());
      await settle(tester);
      expect(tester.widget<LessonButton>(backButton()).onPressed, isNotNull);
    });

    testWidgets(
      'leer_check: the line playing is lit on every page, the first at once',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        for (var p = 0; p < 3; p++) {
          // lit in the same frame the page turns, before anything has loaded
          final first = pageIds(tester).first;
          expect(lit(tester), [first]);
          await tester.tap(nextButton());
          await tester.pump();
        }
        expect(lit(tester), [pageIds(tester).first]);
      },
    );

    testWidgets(
      'leer_check: page change: the playing line is cut off and the new page\'s lines follow',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await tester.pump(const Duration(milliseconds: 400)); // u1 is playing
        expect(rig.clips.now, 'u1');
        final stops = rig.clips.stops;
        await tester.tap(nextButton());
        await settle(tester);
        expect(rig.clips.stops, greaterThan(stops));
        expect(rig.clips.now, 'u4');
        await finishPage(tester);
        // u1 was cut off; nothing of page 1 played after it
        expect(rig.clips.played, ['u1', 'u4']);
      },
    );

    testWidgets(
      'leer_check: closing the book stops the sound and goes back to the shelf; nothing starts again after the close',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await tester.pump(const Duration(milliseconds: 400));
        expect(rig.clips.now, 'u1');
        await tester.tap(closeButton());
        await tester.pump();
        expect(rig.nav.backs, 1);
        expect(rig.clips.now, isNull);
        final played = List.of(rig.clips.played);
        await tester.pump(const Duration(seconds: 20));
        expect(rig.clips.played, played);
        expect(lit(tester), isEmpty);
      },
    );

    testWidgets(
      'leer: leaving the screen stops the sound (the system back button)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpWidget(const SizedBox());
        expect(rig.clips.now, isNull);
        final played = List.of(rig.clips.played);
        await tester.pump(const Duration(seconds: 20));
        expect(rig.clips.played, played);
      },
    );

    testWidgets(
      'leer: Escape closes, the arrow keys turn the page (the keys of the old page)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await settle(tester);
        expect(count(tester), '2 / 4');
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await settle(tester);
        expect(count(tester), '1 / 4');
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await settle(tester);
        expect(count(tester), '1 / 4'); // there is no page before the first
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        expect(rig.nav.backs, 1);
      },
    );

    testWidgets('leer: the buttons tick, a swipe and a key do not', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      await tester.tap(nextButton());
      await settle(tester);
      expect(rig.haptics.ticks, 1);
      await tester.tap(backButton());
      await settle(tester);
      expect(rig.haptics.ticks, 2);
      await tester.tap(find.byType(LessonTextSizeButton));
      await tester.pump();
      expect(rig.haptics.ticks, 3);
      await swipe(tester, -220);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(rig.haptics.ticks, 3);
      await tester.tap(closeButton());
      expect(rig.haptics.ticks, 4);
    });

    testWidgets(
      'leer: a tap right after a swipe does nothing (SWIPED, 400 ms)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await finishPage(tester);
        rig.clips.played.clear();
        await swipe(tester, -220);
        await settle(tester);
        // page 2 has one line; tap it at once
        await tester.tapAt(tester.getTopLeft(line('u4')) + const Offset(4, 20));
        await tester.pump();
        expect(lit(tester), ['u4']); // only the page's own sequence
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 500));
        final before = rig.clips.played.where((c) => c == 'u4').length;
        expect(before, 1);
      },
    );

    testWidgets(
      'leer: a line with no recording is read in its own time (dur), lit all the while',
      (tester) async {
        final rec = {'u1', 'u2', 'u3', 'u4', 'u5', 'u6'}; // u7 has none
        final rig = Rig(course: TestCourse(recorded: rec));
        await pumpReader(tester, rig);
        for (var i = 0; i < 3; i++) {
          await tester.tap(nextButton());
          await settle(tester);
        }
        expect(pageIds(tester), ['u7']);
        expect(lit(tester), ['u7']);
        // "Fin del cuento." is 3 words: (360*3+300) ms = 1380 ms
        await tester.pump(const Duration(milliseconds: 1300));
        expect(lit(tester), ['u7']);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 400));
        expect(lit(tester), isEmpty);
        expect(rig.clips.played, isNot(contains('u7')));
      },
    );
  });

  group('text size', () {
    testWidgets(
      'leer_check: size button: 24 px on 36, remembered; size persists after closing and opening again and after a reload; toggles back to 20',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        expect(lineStyle(tester, 'u1').fontSize, 20);
        await tester.tap(find.byType(LessonTextSizeButton));
        await tester.pump();
        final st = lineStyle(tester, 'u1');
        expect(st.fontSize, 24);
        expect(st.fontSize! * st.height!, closeTo(36, 1e-9));
        expect(
          tester
              .widget<LessonTextSizeButton>(find.byType(LessonTextSizeButton))
              .big,
          isTrue,
        );
        // in this feature's own storage space, under the key the old page used (coqui.leer.tam)
        expect(rig.spaces['leer']!.values['tam'], '24');
        // closed and opened again, and a new start of the app with the same storage
        final again = Rig(spaces: rig.spaces);
        await pumpReader(tester, again);
        expect(lineStyle(tester, 'u1').fontSize, 24);
        await tester.tap(find.byType(LessonTextSizeButton));
        await tester.pump();
        expect(lineStyle(tester, 'u1').fontSize, 20);
        expect(rig.spaces['leer']!.values['tam'], '20');
      },
    );

    testWidgets(
      'leer: the old value is found (only "24" is large, anything else is 20)',
      (tester) async {
        final rig = Rig(
          spaces: {
            'leer': FakeKeyValueStore({'tam': '18'}),
          },
        );
        await pumpReader(tester, rig);
        expect(lineStyle(tester, 'u1').fontSize, 20);
        final big = Rig(
          spaces: {
            'leer': FakeKeyValueStore({'tam': '24'}),
          },
        );
        await pumpReader(tester, big);
        expect(lineStyle(tester, 'u1').fontSize, 24);
      },
    );
  });

  group('the word card', () {
    testWidgets('leer_check: a page has a word with a picture (a .bw)', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      expect(lineViews(tester).any((l) => l.marks.isNotEmpty), isTrue);
    });

    testWidgets(
      'leer_check: tap on a picture word: a card with its picture and the word',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await finishPage(tester);
        await tester.tapAt(wordAt(tester, 'u1', 'hermana'));
        await tester.pump();
        final card = find.byType(WordPopup);
        expect(card, findsOneWidget);
        expect(tester.widget<WordPopup>(card).word.word, 'hermana');
        expect(
          find.descendant(of: card, matching: find.text('hermana')),
          findsOneWidget,
        );
        // its picture is the "si" picture of the word's pair
        expect(rig.pictures.shown, hasLength(1));
        expect(rig.pictures.shown.single.cam, [10, 0]);
      },
    );

    testWidgets(
      'leer_check: the word card\'s scrim is light: the page stays readable behind it',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await finishPage(tester);
        await tester.tapAt(wordAt(tester, 'u1', 'hermana'));
        await tester.pump();
        expect(WordPopup.scrim.a, inInclusiveRange(0.0, 0.4));
        expect(WordPopup.scrim.a, greaterThan(0));
      },
    );

    testWidgets(
      'leer_check: every place the word is on the page is underlined; the tapped word\'s underline is solid green; the tap plays nothing',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await finishPage(tester);
        rig.clips.played.clear();
        await tester.tapAt(wordAt(tester, 'u1', 'hermana'));
        await tester.pump();
        // "hermana" is twice in the first line: both are underlined, the other words are not
        final views = lineViews(tester);
        final k = views.first.underlined;
        expect(k, isNotNull);
        expect(views.every((v) => v.underlined == k), isTrue);
        final u1 = views.firstWhere((v) => v.line.id == 'u1');
        expect(u1.marks.where((m) => m.k == k), hasLength(2));
        expect(rig.clips.played, isEmpty);
        expect(lit(tester), isEmpty);
        final style = lineStyle(tester, 'u1');
        final tp = TextPainter(
          text: TextSpan(text: u1.line.text, style: style),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 300);
        final solid = markUnderlines(
          tp,
          u1.marks,
          k,
        ).where((u) => u.solid).toList();
        expect(solid, hasLength(2));
        expect(solid.first.rect.height, 3);
      },
    );

    testWidgets(
      'leer_check: the card closes on any tap (and that tap does nothing else)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await finishPage(tester);
        rig.clips.played.clear();
        await tester.tapAt(wordAt(tester, 'u1', 'hermana'));
        await tester.pump();
        expect(find.byType(WordPopup), findsOneWidget);
        // a tap on a line (it is under the scrim) and on the next arrow
        await tester.tapAt(tester.getTopLeft(line('u2')) + const Offset(4, 20));
        await tester.pump();
        expect(find.byType(WordPopup), findsNothing);
        expect(rig.clips.played, isEmpty);
        expect(count(tester), '1 / 4');
        await tester.tapAt(wordAt(tester, 'u1', 'hermana'));
        await tester.pump();
        await tester.tap(nextButton(), warnIfMissed: false);
        await tester.pump();
        expect(find.byType(WordPopup), findsNothing);
        expect(count(tester), '1 / 4');
      },
    );

    testWidgets('leer_check: the underline goes after a moment', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      await finishPage(tester);
      await tester.tapAt(wordAt(tester, 'u1', 'hermana'));
      await tester.pump();
      expect(lineViews(tester).first.underlined, isNotNull);
      await tester.pump(const Duration(milliseconds: 2300));
      expect(lineViews(tester).first.underlined, isNotNull);
      await tester.pump(const Duration(milliseconds: 200));
      expect(lineViews(tester).first.underlined, isNull);
      // the card is still there: it closes by a tap, not by time
      expect(find.byType(WordPopup), findsOneWidget);
    });

    testWidgets('leer_check: tap on another word plays the line, no card', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      await finishPage(tester);
      rig.clips.played.clear();
      await tester.tapAt(wordAt(tester, 'u1', 'Carmen'));
      await tester.pump();
      expect(find.byType(WordPopup), findsNothing);
      expect(lit(tester), ['u1']);
      await finishPage(tester);
      expect(rig.clips.played, ['u1']);
    });

    testWidgets(
      'leer: a word tap does not stop the sound that is playing (the old page does not)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await tester.pump(const Duration(milliseconds: 400));
        expect(rig.clips.now, 'u1');
        await tester.tapAt(wordAt(tester, 'u1', 'hermana'));
        await tester.pump();
        expect(rig.clips.now, 'u1');
        expect(find.byType(WordPopup), findsOneWidget);
      },
    );

    testWidgets('leer: turning the page closes the card and the underline', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      await finishPage(tester);
      await tester.tapAt(wordAt(tester, 'u1', 'hermana'));
      await tester.pump();
      // the card covers the arrows; a key still turns the page
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      expect(count(tester), '2 / 4');
      expect(find.byType(WordPopup), findsNothing);
      expect(lineViews(tester).every((v) => v.underlined == null), isTrue);
    });
  });

  group('the last page', () {
    Future<void> toLast(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        await tester.tap(nextButton());
        await settle(tester);
      }
    }

    testWidgets(
      'leer_check: last page: "Fin" above its buttons, both green (no blue), "Otra vez" with a replay icon',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await toLast(tester);
        expect(count(tester), '4 / 4');
        final fin = find.text(LibraryStrings.fin);
        expect(fin, findsOneWidget);
        final againBtn = find.byWidgetPredicate(
          (w) =>
              w is LessonButton &&
              w.child is Row &&
              w.kind == LessonButtonKind.go,
        );
        final shelfBtn = buttonLabelled(LibraryStrings.shelf);
        expect(againBtn, findsOneWidget);
        expect(shelfBtn, findsOneWidget);
        expect(tester.widget<LessonButton>(againBtn).kind, LessonButtonKind.go);
        expect(tester.widget<LessonButton>(shelfBtn).kind, LessonButtonKind.go);
        expect(find.text(LibraryStrings.again), findsOneWidget);
        expect(
          find.descendant(of: againBtn, matching: find.byType(CoquiIcon)),
          findsOneWidget,
        );
        expect(
          tester
              .widget<CoquiIcon>(
                find.descendant(of: againBtn, matching: find.byType(CoquiIcon)),
              )
              .data,
          same(CoquiIcons.replay),
        );
        expect(
          tester.getRect(fin).bottom,
          lessThanOrEqualTo(tester.getRect(againBtn).top + 1),
        );
        // none of the foot's buttons is the blue one
        expect(
          tester
              .widgetList<LessonButton>(find.byType(LessonButton))
              .where((b) => b.kind == LessonButtonKind.blue),
          isEmpty,
        );
      },
    );

    testWidgets(
      'leer_check: last page: "Fin" has 16 px more space above and below',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await toLast(tester);
        final fin = tester.getRect(find.text(LibraryStrings.fin));
        final lines = tester.getRect(find.byType(ListView));
        final row = tester.getRect(buttonLabelled(LibraryStrings.shelf));
        // the box of "Fin" is 32 high with 16 around it
        expect(row.top - fin.bottom, greaterThanOrEqualTo(16));
        expect(fin.top - lines.bottom, greaterThanOrEqualTo(16));
      },
    );

    testWidgets(
      'leer_check: last page: its line is lit while it plays, the count reads N / N',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await toLast(tester);
        expect(lit(tester), ['u7']);
        expect(count(tester), '4 / 4');
      },
    );

    testWidgets(
      'leer_check: read check stored when the last page is reached; reading writes no word record',
      (tester) async {
        final rig = Rig();
        final before = rig.store.export();
        await pumpReader(tester, rig);
        await toLast(tester);
        expect(rig.progress.hasRead('uno'), isTrue);
        final after = rig.store.raw;
        expect((after['leidos'] as Map).keys, ['uno']);
        // palabras, dias, cuentos: unchanged
        expect(after['palabras'], <String, dynamic>{});
        expect(after['dias'], <String, dynamic>{});
        expect(after['cuentos'], <String, dynamic>{});
        expect(before.contains('leidos'), isFalse);
      },
    );

    testWidgets(
      'leer_check: Otra vez: back to page 1; the last page offers Otra vez and Biblioteca',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await toLast(tester);
        await tester.tap(find.text(LibraryStrings.again));
        await settle(tester);
        expect(count(tester), '1 / 4');
        expect(find.text(LibraryStrings.fin), findsNothing);
      },
    );

    testWidgets('leer_check: Biblioteca: the book closes on the shelf', (
      tester,
    ) async {
      final rig = Rig();
      await pumpReader(tester, rig);
      await toLast(tester);
      await tester.tap(buttonLabelled(LibraryStrings.shelf));
      await tester.pump();
      expect(rig.nav.backs, 1);
    });

    testWidgets(
      'leer: the book is marked read once, however often its last page is shown',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig);
        await toLast(tester);
        final saves = rig.store.saves;
        await tester.tap(find.text(LibraryStrings.again));
        await settle(tester);
        await toLast(tester);
        expect(rig.store.saves, saves);
      },
    );

    testWidgets(
      'leer: a one-page book is read when it opens (the last page is the first)',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig, book: 'cuatro');
        expect(count(tester), '1 / 1');
        expect(rig.progress.hasRead('cuatro'), isTrue);
        expect(find.text(LibraryStrings.fin), findsOneWidget);
        // the back arrow is the small one, disabled; there is no next
        expect(tester.widget<LessonButton>(backButton()).onPressed, isNull);
        expect(nextButton(), findsNothing);
      },
    );

    testWidgets(
      'leer: a book already read stays read, its record is not written again',
      (tester) async {
        final rig = Rig()..played([], read: ['uno']);
        final saves = rig.store.saves;
        await pumpReader(tester, rig);
        await toLast(tester);
        expect(rig.store.saves, saves);
      },
    );
  });

  group('the room', () {
    for (final big in [false, true]) {
      testWidgets(
        'leer_check: the picture keeps the same place and size on every page, ${big ? "large" : "normal"} text; the text area is as tall on every page (reserved, "Fin" too)',
        (tester) async {
          final rig = Rig(
            spaces: {
              'leer': FakeKeyValueStore({'tam': big ? '24' : '20'}),
            },
          );
          await pumpReader(tester, rig);
          final rects = <Rect>[];
          final heights = <double>[];
          final counts = <int>[];
          for (var p = 0; p < 4; p++) {
            await settle(tester);
            rects.add(tester.getRect(find.byType(PixelView)));
            heights.add(tester.getSize(find.byType(ListView)).height);
            counts.add(pageIds(tester).length);
            if (p < 3) {
              await tester.tap(nextButton());
              await tester.pump();
            }
          }
          expect(counts.toSet().length, greaterThan(1));
          for (final r in rects) {
            expect(r.left, closeTo(rects.first.left, 0.6));
            expect(r.top, closeTo(rects.first.top, 0.6));
            expect(r.width, closeTo(rects.first.width, 0.6));
            expect(r.height, closeTo(rects.first.height, 0.6));
          }
          for (final h in heights) {
            expect(h, closeTo(heights.first, 0.6));
          }
        },
      );
    }

    for (final big in [false, true]) {
      testWidgets(
        'leer_check: 360x640: the book has no horizontal scroll, the picture clears the text and the buttons${big ? " (large text)" : ""}',
        (tester) async {
          final rig = Rig(
            spaces: {
              'leer': FakeKeyValueStore({'tam': big ? '24' : '20'}),
            },
          );
          await pumpReader(tester, rig, size: const Size(360, 640), ratio: 3);
          for (var p = 0; p < 4; p++) {
            await settle(tester);
            expect(tester.takeException(), isNull);
            final pic = tester.getRect(find.byType(PixelView));
            final text = tester.getRect(find.byType(ListView));
            final back = tester.getRect(backButton());
            expect(pic.bottom, lessThanOrEqualTo(text.top + 1));
            expect(text.bottom, lessThanOrEqualTo(back.top + 1));
            expect(pic.left, greaterThanOrEqualTo(0));
            expect(pic.right, lessThanOrEqualTo(360));
            if (p < 3) {
              await tester.tap(nextButton());
              await tester.pump();
            }
          }
        },
      );
    }

    testWidgets(
      'leer: the text area never takes more than 55% of the page, and scrolls',
      (tester) async {
        final long = List.generate(8, (i) => 'palabra $i ' * 8).join();
        final course = TestCourse(
          stories: {
            'uno': {
              'title': 'uno',
              'clips': {
                'u1': line2('abuela', long),
                'u2': line2('abuela', long),
                'u3': line2('abuela', long),
              },
            },
          },
          books: {
            'uno': Book(
              id: 'uno',
              title: 'uno',
              readable: true,
              pages: [
                BookPage(image: 'img/uno-1.png', clips: ['u1', 'u2', 'u3']),
              ],
            ),
          },
        );
        final rig = Rig(course: course);
        await pumpReader(tester, rig, size: const Size(360, 640), ratio: 3);
        final text = tester.getSize(find.byType(ListView)).height;
        expect(text, lessThanOrEqualTo(640 * 0.55 + 1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'leer: on its side the picture is at the left, the lines and buttons in a column at the right',
      (tester) async {
        final rig = Rig();
        await pumpReader(tester, rig, size: const Size(844, 390), ratio: 3);
        await settle(tester);
        expect(tester.takeException(), isNull);
        final pic = tester.getRect(find.byType(PixelView));
        final text = tester.getRect(find.byType(ListView));
        expect(pic.right, lessThanOrEqualTo(text.left));
        expect(text.width, greaterThanOrEqualTo(280));
        expect(
          tester.getRect(nextButton()).left,
          greaterThanOrEqualTo(text.left),
        );
      },
    );
  });
}

Map<String, dynamic> line2(String who, String text) => {
  'who': who,
  'text': text,
};

/// A course whose book arrives when the test says.
class _SlowBook extends TestCourse {
  final Completer<void> gate = Completer<void>();

  @override
  Future<Book?> book(String id) async {
    await gate.future;
    return super.book(id);
  }
}
