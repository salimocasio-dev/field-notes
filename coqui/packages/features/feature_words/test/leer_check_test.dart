// The Palabras checks of historia/tools/leer_check.py, each as a widget test on the fakes. Each name says the old
// check. Where the old check read the real course, these read stories 1 to 3 of the sample course (coqui_testing).
//
// Not here: "the Today card on the map has the same cap" (the map's, feature_map) and "the place sheet (any bottom
// sheet): above the tab bar..." (the map's place sheet); both are named in the report.

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/add_box.dart';
import 'package:feature_words/src/words_view.dart';
import 'package:feature_words/src/word_tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// The leer_check.py set-up: every word has stages 1 + i % 4 (ear) and i % 4 (mouth), and comes back in
/// 1 + i % 3 days.
Future<({Rig rig, List<String> words})> mixed() async {
  final rig = Rig();
  final words = await rig.playSampleStories();
  for (var i = 0; i < words.length; i++) {
    rig.word(
      words[i],
      ear: 1 + i % 4,
      mouth: i % 4,
      mouthN: i % 4,
      due: (1 + i % 3).toDouble(),
    );
  }
  await rig.course.load();
  return (rig: rig, words: words);
}

void main() {
  group('leer_check.py, Palabras', () {
    testWidgets('"Palabras: every word he has heard has a card"', (
      tester,
    ) async {
      final m = await mixed();
      await pumpTab(tester, m.rig);
      final cards = [
        for (final c in tester.widgetList<WordTile>(find.byType(WordTile)))
          c.word,
      ];
      expect(cards..sort(), [...m.words]..sort());
      expect(cards.length, greaterThanOrEqualTo(8));
    });

    testWidgets(
      '"every word is spelled on its card, whatever its stage (no \'?\')"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        var lowStage = false;
        for (final w in m.words) {
          final c = tester.widget<WordTile>(card(w));
          expect(
            find.descendant(of: card(w), matching: find.text(w)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: card(w), matching: find.text('?')),
            findsNothing,
          );
          if (c.ear < 2) lowStage = true;
        }
        expect(lowStage, isTrue);
      },
    );

    testWidgets('"Ear and Mouth meters: four dots, filled by stage"', (
      tester,
    ) async {
      final m = await mixed();
      await pumpTab(tester, m.rig);
      for (final w in m.words) {
        final r = m.rig.progress.word(w)!;
        final c = card(w);
        // order 27: the two meters stand in one row, each an icon and four small dots
        final meters = find.descendant(of: c, matching: find.byType(SkillDot));
        expect(meters, findsNWidgets(2));
        expect(tester.widget<SkillDot>(meters.at(0)).skill, 'Ear');
        expect(tester.widget<SkillDot>(meters.at(1)).skill, 'Mouth');
        for (final i in [0, 1]) {
          expect(
            find.descendant(of: meters.at(i), matching: find.byType(SmallDots)),
            findsOneWidget,
          );
          final all = find.descendant(
            of: meters.at(i),
            matching: find.byWidgetPredicate(
              (x) =>
                  x.key is ValueKey &&
                  '${(x.key! as ValueKey).value}'.startsWith('dot'),
            ),
          );
          expect(all, findsNWidgets(4));
        }
        expect(dots(tester, c), [r.ear.etapa, r.mouth.etapa]);
      }
    });

    testWidgets(
      '"a picture on a pair word"; order 27: on the others, the shortest line he heard the word in, in a grey panel of the picture\'s size',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        final pairWords = {for (final p in m.rig.course.pairs) p.word};
        final played = [
          for (final l in m.rig.course.places)
            for (final c in l.stories)
              if (m.rig.progress.played(c)) c,
        ];
        var pictured = 0;
        var plain = 0;
        double? panel;
        for (final w in m.words) {
          final c = tester.widget<WordTile>(card(w));
          if (pairWords.contains(w)) {
            pictured++;
            expect(c.picture, isNotNull, reason: w);
            panel ??= tester
                .getSize(
                  find.descendant(
                    of: card(w),
                    matching: find.byType(WordPictureArea),
                  ),
                )
                .height;
          } else {
            plain++;
            expect(c.picture, isNull, reason: w);
            final lines = await m.rig.course.linesWith(w, played);
            expect(c.line, shortestLine(lines, w)?.text, reason: w);
            if (c.line != null) {
              expect(lines.map((l) => l.text), contains(c.line), reason: w);
            }
          }
        }
        expect(pictured, greaterThan(0));
        expect(plain, greaterThan(0));
        // the panel of a word with no picture is as tall as a picture
        final noPicture = m.words.firstWhere((w) => !pairWords.contains(w));
        final box = find.descendant(
          of: card(noPicture),
          matching: find.byWidgetPredicate(
            (x) => x is ColoredBox && x.color == CoquiColors.coverFill,
          ),
        );
        expect(tester.getSize(box).height, panel);
      },
    );

    testWidgets(
      'order 27: the key of the two icons stands once, above the first place title and its cards',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        final title = tester.getTopLeft(find.text('La casa')).dy;
        final firstCard = tester.getTopLeft(find.byType(WordTile).first).dy;
        for (final line in [SkillKey.ear, SkillKey.mouth]) {
          expect(find.text(line), findsOneWidget);
          final key = tester.getTopLeft(find.text(line)).dy;
          expect(key < title && key < firstCard, isTrue);
        }
      },
    );

    testWidgets('"the pictures are drawn"', (tester) async {
      final m = await mixed();
      await pumpTab(tester, m.rig);
      final drawn = m.rig.pictures.shown.map((r) => r.toString()).toSet();
      final pairs = {for (final p in m.rig.course.pairs) p.word: p};
      for (final w in m.words) {
        final p = pairs[w];
        if (p != null) {
          expect(
            drawn,
            contains(PictureRef.of(p, p.yes).toString()),
            reason: w,
          );
        }
      }
    });

    testWidgets('"words grouped by place, in story order"', (tester) async {
      final m = await mixed();
      m.rig.word('zorro', ear: 1); // a word no played story brings
      await pumpTab(tester, m.rig);
      // the old check: the first story (in the course's order) that brings a word, as a focus word first
      final where = <String>[];
      for (final key in ['focus_words', 'back_again']) {
        for (final id in ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro']) {
          final t = await m.rig.course.story(id);
          for (final w in ((t[key] as List?) ?? const []).cast<String>()) {
            if (!where.contains(w)) where.add(w);
          }
        }
      }
      expect(cardOrder(tester), [...where, 'zorro']);
      expect(placeHeadings(tester), ['La casa', 'More words']);
    });

    testWidgets('"place headings are h2 in place order"', (tester) async {
      final rig = Rig(
        course: madeCourse(
          places: [
            place('a', 1, 'Place one', ['s1']),
            place('b', 2, 'Place two', ['s2']),
            place('c', 3, 'Place three', ['s3']),
          ],
          stories: {
            's1': {
              'focus_words': ['uno'],
            },
            's2': {
              'focus_words': ['dos'],
            },
            's3': {
              'focus_words': ['tres'],
            },
          },
        ),
      );
      for (final id in ['s3', 's1', 's2']) {
        rig.played(id);
      }
      rig.word('tres');
      rig.word('uno');
      rig.word('dos');
      await pumpTab(tester, rig);
      expect(placeHeadings(tester), ['Place one', 'Place two', 'Place three']);
      expect(
        tester.getTopLeft(find.text('Place one')).dy <
            tester.getTopLeft(find.text('Place two')).dy,
        isTrue,
      );
    });

    testWidgets(
      '"Repaso card, nothing due: \'Nothing due today\' and Practice"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        final r = repaso(tester);
        expect((r.line, r.button), ('Nothing due today', 'Practice'));
        expect(find.text(CoquiLabels.review), findsOneWidget);
      },
    );

    testWidgets(
      '"Repaso card, words due: N is the session size (at most 10), \'N words today · about M min\', and Start"',
      (tester) async {
        final m = await mixed();
        m.rig.clock.advance(const Duration(days: 3));
        await pumpTab(tester, m.rig);
        final due = m.rig.progress
            .due(Skill.ear)
            .where((w) => m.rig.course.pairs.any((p) => p.word == w));
        expect(due.length, greaterThan(10));
        final r = repaso(tester);
        expect(r.line, '10 words today · about 2 min');
        expect(r.button, 'Start');
        expect(r.enabled, isTrue);
      },
    );

    testWidgets('"Repaso card with fewer than 10 due: N is the due count"', (
      tester,
    ) async {
      final m = await mixed();
      final pairWords = [
        for (final w in m.words)
          if (m.rig.course.pairs.any((p) => p.word == w)) w,
      ];
      // every pair word comes back in 30 days but three
      for (final w in pairWords.skip(3)) {
        m.rig.word(w, ear: 3, due: 30);
      }
      for (final w in pairWords.take(3)) {
        m.rig.word(w, ear: 3, due: 1);
      }
      m.rig.clock.advance(const Duration(days: 3));
      await pumpTab(tester, m.rig);
      expect(repaso(tester).line, '3 words today · about 1 min');
    });

    testWidgets('"word sheet: big picture, the word, Ear and Mouth meters"', (
      tester,
    ) async {
      final m = await mixed();
      await pumpTab(tester, m.rig);
      final pair = m.rig.course.pairs.firstWhere(
        (p) => m.words.contains(p.word),
      );
      await tapCard(tester, pair.word);
      final r = m.rig.progress.word(pair.word)!;
      expect(sheet, findsOneWidget);
      // the big picture: asked of the picture source, framed with its 12 px corners, at least 196 wide
      final ref = PictureRef.of(pair, pair.yes).toString();
      expect(m.rig.pictures.shown.map((x) => x.toString()), contains(ref));
      final frame = inSheet(find.byType(PictureFrame));
      expect(frame, findsOneWidget);
      expect(tester.widget<PictureFrame>(frame).radius, 12);
      expect(tester.getSize(frame).width, greaterThanOrEqualTo(196));
      expect(inSheet(find.text(pair.word)), findsWidgets);
      final meters = inSheet(find.byType(SkillMeter));
      expect(meters, findsNWidgets(2));
      expect(dots(tester, sheet), [r.ear.etapa, r.mouth.etapa]);
    });

    testWidgets(
      '"word sheet: scrolled, the word stays in its header (hidden while the big word shows)"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        await tapCard(tester, 'casa');
        double title() => tester
            .widget<AnimatedOpacity>(inSheet(find.byType(AnimatedOpacity)))
            .opacity;
        final scroller = inSheet(find.byType(SingleChildScrollView));
        expect(
          tester
              .state<ScrollableState>(inSheet(find.byType(Scrollable)))
              .position
              .maxScrollExtent,
          greaterThan(0),
          reason: 'the sheet scrolls',
        );
        expect(title(), 0);
        await tester.drag(scroller, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(title(), 1);
        // the word is in the header: inside the 56 px bar at the top of the sheet
        final head = tester.getTopLeft(sheet).dy;
        final t = tester.getRect(
          find.descendant(
            of: sheet,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Text &&
                  w.data == 'casa' &&
                  w.style!.fontSize == 24 &&
                  w.maxLines == 1,
            ),
          ),
        );
        expect(t.top >= head && t.bottom <= head + 56, isTrue);
        await tester.drag(scroller, const Offset(0, 800));
        await tester.pumpAndSettle();
        expect(title(), 0);
      },
    );

    testWidgets(
      '"word sheet: the word is bold inside each \'Heard in\' line (text unchanged)"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        await tapCard(tester, 'casa');
        final lines = await m.rig.course.linesWith('casa', [
          'la-lluvia',
          'el-bizcocho',
          'donde-esta-el-pajaro',
        ]);
        expect(lines, isNotEmpty);
        final rich = tester
            .widgetList<RichText>(inSheet(find.byType(RichText)))
            .where((r) => lines.any((l) => r.text.toPlainText() == l.text))
            .toList();
        expect(rich.length, lines.length);
        for (final r in rich) {
          final bold = <String>[];
          r.text.visitChildren((s) {
            if (s is TextSpan &&
                s.text != null &&
                s.style?.fontWeight == FontWeight.w700) {
              bold.add(s.text!);
            }
            return true;
          });
          expect(bold, isNotEmpty);
          for (final b in bold) {
            expect(normalize(b).trim(), 'casa');
          }
          expect(r.text.toPlainText(), lines[rich.indexOf(r)].text);
        }
      },
    );

    testWidgets(
      '"word sheet: sits fully above the tab bar and the Mapa disc, the scrim dims both"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        await tapCard(tester, 'casa');
        const h = 844.0;
        // --navh 72 + --rise 14: the sheet's foot is where the Mapa disc starts
        expect(tester.getRect(sheet).bottom, lessThanOrEqualTo(h - 72 - 14));
        // the scrim covers the whole screen: the tab bar and the disc under it
        final scrim = find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == CoquiColors.scrim,
        );
        expect(tester.getRect(scrim), const Rect.fromLTWH(0, 0, 390, h));
      },
    );

    testWidgets(
      '"word sheet: scrolled to its end, the last line clears the tab bar and the Mapa disc"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        await tapCard(tester, 'casa');
        final pos = tester
            .state<ScrollableState>(inSheet(find.byType(Scrollable)))
            .position;
        pos.jumpTo(pos.maxScrollExtent);
        await tester.pumpAndSettle();
        final lastCard = tester.getRect(inSheet(find.byType(DividedRows)).last);
        expect(lastCard.bottom, lessThanOrEqualTo(844 - 72 - 14 - 8));
      },
    );

    testWidgets('"word sheet: next return in English"', (tester) async {
      final m = await mixed();
      await pumpTab(tester, m.rig);
      await tapCard(tester, 'casa');
      final texts = tester
          .widgetList<Text>(inSheet(find.byType(Text)))
          .map((t) => t.data);
      expect(
        texts.where(
          (t) =>
              t != null &&
              RegExp(r'^Comes back (today|in \d+ days?)$').hasMatch(t),
        ),
        hasLength(1),
      );
    });

    testWidgets(
      '"word sheet: each \'Heard in\' line has the title of its story under it in small grey"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        await tapCard(tester, 'casa');
        final lines = await m.rig.course.linesWith('casa', [
          'la-lluvia',
          'el-bizcocho',
          'donde-esta-el-pajaro',
        ]);
        for (final l in lines) {
          final text = find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == l.text,
          );
          expect(text, findsOneWidget);
          final row = find.ancestor(of: text, matching: find.byType(ListRow));
          final title = find.descendant(
            of: row,
            matching: find.text(l.storyTitle),
          );
          expect(title, findsOneWidget);
          // the grey line takes its style from the row: small and grey
          final style = tester
              .widget<DefaultTextStyle>(
                find
                    .ancestor(
                      of: title,
                      matching: find.byType(DefaultTextStyle),
                    )
                    .first,
              )
              .style;
          expect(style.fontSize, 14);
          expect(style.color, CoquiColors.mut);
          expect(
            tester.getTopLeft(title).dy,
            greaterThanOrEqualTo(tester.getBottomLeft(text).dy - 1),
          );
        }
      },
    );

    testWidgets(
      '"word sheet: \'Heard in\', up to five lines that contain the word, each with a 48 px play button"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        await tapCard(tester, 'casa');
        expect(inSheet(find.text('Heard in')), findsOneWidget);
        final buttons = inSheet(find.byType(PlayButton));
        final n = buttons.evaluate().length;
        expect(n, inInclusiveRange(1, 5));
        for (var i = 0; i < n; i++) {
          expect(tester.getSize(buttons.at(i)), const Size(48, 48));
        }
        final lines = await m.rig.course.linesWith('casa', [
          'la-lluvia',
          'el-bizcocho',
          'donde-esta-el-pajaro',
        ]);
        for (final l in lines) {
          expect(normalize(l.text), contains(normalize('casa')));
        }
        expect(lines, hasLength(n));
      },
    );

    testWidgets('"a \'Heard in\' line plays its own recording"', (
      tester,
    ) async {
      final m = await mixed();
      await pumpTab(tester, m.rig);
      await tapCard(tester, 'casa');
      final lines = await m.rig.course.linesWith('casa', [
        'la-lluvia',
        'el-bizcocho',
        'donde-esta-el-pajaro',
      ]);
      await tester.tap(inSheet(find.byType(PlayButton)).first);
      await tester.pump();
      expect(m.rig.clips.played, [lines.first.clipId]);
      expect(m.rig.clips.preloaded, [lines.first.clipId]);
    });

    testWidgets('"a second touch stops it"', (tester) async {
      final clips = GateClips();
      final m = await mixed2(clips);
      await pumpTab(tester, m.rig);
      await tapCard(tester, 'casa');
      final play = inSheet(find.byType(PlayButton)).first;
      await tester.tap(play);
      await tester.pump();
      expect(tester.widget<PlayButton>(play).icon, CoquiIcons.stop);
      final stops = clips.stops;
      await tester.tap(play);
      await tester.pump();
      expect(clips.stops, greaterThan(stops));
      expect(tester.widget<PlayButton>(play).icon, CoquiIcons.play);
      expect(
        clips.played,
        hasLength(1),
        reason: 'the second touch plays nothing',
      );
    });

    testWidgets('"closing the sheet stops the sound"', (tester) async {
      final clips = GateClips();
      final m = await mixed2(clips);
      await pumpTab(tester, m.rig);
      await tapCard(tester, 'casa');
      await tester.tap(inSheet(find.byType(PlayButton)).first);
      await tester.pump();
      expect(clips.open.where((c) => !c.isCompleted), hasLength(1));
      final stops = clips.stops;
      await tester.tap(find.byType(CoquiCloseButton));
      await tester.pumpAndSettle();
      expect(clips.stops, greaterThan(stops));
      expect(clips.open.where((c) => !c.isCompleted), isEmpty);
      expect(sheet, findsNothing);
    });

    testWidgets(
      '"word with no picture: sheet without a picture, with its meters"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        expect(tester.widget<WordTile>(card('toca')).picture, isNull);
        await tapCard(tester, 'toca');
        expect(sheet, findsOneWidget);
        expect(inSheet(find.byType(PictureFrame)), findsNothing);
        expect(inSheet(find.byType(SkillMeter)), findsNWidgets(2));
      },
    );

    testWidgets('"the Add button is green like every other primary button"', (
      tester,
    ) async {
      final m = await mixed();
      await pumpTab(tester, m.rig);
      final add = find.byWidgetPredicate(
        (w) => w is CoquiButton && w.label == 'Add',
      );
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      expect(tester.widget<CoquiButton>(add).kind, CoquiButtonKind.go);
      final fill = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: add, matching: find.byType(DecoratedBox)),
          )
          .map((d) => (d.decoration as BoxDecoration).color)
          .first;
      expect(fill, const Color(0xFF17803F)); // rgb(23, 128, 63)
    });

    testWidgets('"add a word or a goal: honest text and the saved list"', (
      tester,
    ) async {
      final m = await mixed();
      await pumpTab(tester, m.rig);
      expect(find.text('Saved. Material for it comes later.'), findsNothing);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'talk to my 1-year-old');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Saved. Material for it comes later.'), findsOneWidget);
      expect(find.text('· talk to my 1-year-old'), findsOneWidget);
      expect(m.rig.progress.added, ['talk to my 1-year-old']);
      expect(m.rig.progress.raw['extra'], ['talk to my 1-year-old']);
    });

    testWidgets(
      '"Palabras: a 16 px fade from the background colour over the list at the tab bar\'s edge"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        final fade = find.byType(ListFade);
        expect(
          tester.widget<ListFade>(fade).visible,
          isTrue,
        ); // the page scrolls, so there is more
        expect(tester.widget<ListFade>(fade).color, CoquiColors.bg);
        expect(
          tester
              .widget<AnimatedOpacity>(
                find.descendant(
                  of: fade,
                  matching: find.byType(AnimatedOpacity),
                ),
              )
              .opacity,
          1,
        );
        final r = tester.getRect(
          find.descendant(of: fade, matching: find.byType(Container)),
        );
        expect(r.height, 16);
        expect(r.bottom, 844 - 72); // the tab bar's top edge: --navh
      },
    );

    testWidgets('"Palabras: the fade is gone at the end of the list"', (
      tester,
    ) async {
      final m = await mixed();
      await pumpTab(tester, m.rig);
      final pos = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      pos.jumpTo(pos.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.widget<ListFade>(find.byType(ListFade)).visible, isFalse);
      pos.jumpTo(0);
      await tester.pumpAndSettle();
      expect(tester.widget<ListFade>(find.byType(ListFade)).visible, isTrue);
    });

    testWidgets(
      '"Palabras scrolled to its end: nothing under the tab bar or the Mapa disc"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        final pos = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        pos.jumpTo(pos.maxScrollExtent);
        await tester.pumpAndSettle();
        final last = tester.getRect(find.byType(AddBox).last);
        expect(last.bottom, lessThanOrEqualTo(844 - 72 - 14 - 8));
      },
    );

    testWidgets(
      '"Palabras: the last grid ends above the \'Add a word or a goal\' title"',
      (tester) async {
        final m = await mixed();
        await pumpTab(tester, m.rig);
        final grid = tester.getRect(find.byType(TileGrid).last);
        final add = tester.getRect(find.text('Add a word or a goal'));
        expect(grid.bottom, lessThanOrEqualTo(add.top));
      },
    );

    testWidgets('"390 px: no horizontal scroll (Palabras)"', (tester) async {
      final m = await mixed();
      await pumpTab(tester, m.rig);
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<SingleChildScrollView>(
              find.byType(SingleChildScrollView).first,
            )
            .scrollDirection,
        Axis.vertical,
      );
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        final r = tester.getRect(find.byWidget(t));
        expect(r.right, lessThanOrEqualTo(390.5));
        expect(r.left, greaterThanOrEqualTo(-0.5));
      }
    });

    testWidgets('"360 px: Palabras has no horizontal scroll"', (tester) async {
      final m = await mixed();
      await pumpTab(tester, m.rig, size: const Size(360, 640));
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<SingleChildScrollView>(
              find.byType(SingleChildScrollView).first,
            )
            .scrollDirection,
        Axis.vertical,
      );
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        final r = tester.getRect(find.byWidget(t));
        expect(r.right, lessThanOrEqualTo(360.5));
        expect(r.left, greaterThanOrEqualTo(-0.5));
      }
    });

    testWidgets('"360 px: the word sheet\'s last line clears the Mapa disc"', (
      tester,
    ) async {
      final m = await mixed();
      await pumpTab(tester, m.rig, size: const Size(360, 640));
      await tapCard(tester, 'casa');
      final pos = tester
          .state<ScrollableState>(inSheet(find.byType(Scrollable)))
          .position;
      pos.jumpTo(pos.maxScrollExtent);
      await tester.pumpAndSettle();
      final last = tester.getRect(inSheet(find.byType(DividedRows)).last);
      expect(last.bottom, lessThanOrEqualTo(640 - 72 - 14 - 8));
    });

    testWidgets('"360 px: the word sheet has no horizontal scroll"', (
      tester,
    ) async {
      final m = await mixed();
      await pumpTab(tester, m.rig, size: const Size(360, 640));
      await tapCard(tester, 'casa');
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<SingleChildScrollView>(
              inSheet(find.byType(SingleChildScrollView)),
            )
            .scrollDirection,
        Axis.vertical,
      );
      for (final t in tester.widgetList<Text>(inSheet(find.byType(Text)))) {
        final r = tester.getRect(find.byWidget(t));
        expect(r.right, lessThanOrEqualTo(360.5));
      }
    });
  });
}

/// [mixed] on a given clip player.
Future<({Rig rig, List<String> words})> mixed2(FakeClipPlayer clips) async {
  final rig = Rig(clips: clips);
  final words = await rig.playSampleStories();
  for (var i = 0; i < words.length; i++) {
    rig.word(
      words[i],
      ear: 1 + i % 4,
      mouth: i % 4,
      mouthN: i % 4,
      due: (1 + i % 3).toDouble(),
    );
  }
  await rig.course.load();
  return (rig: rig, words: words);
}
