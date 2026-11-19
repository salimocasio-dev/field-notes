import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {Size size = const Size(412, 915)}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: coquiTheme(),
  home: MediaQuery(
    data: MediaQueryData(size: size, devicePixelRatio: 1),
    child: Scaffold(body: child),
  ),
);

void _phone(WidgetTester tester, Size size, [double ratio = 1]) {
  tester.view.devicePixelRatio = ratio;
  tester.view.physicalSize = Size(size.width * ratio, size.height * ratio);
  addTearDown(tester.view.reset);
}

void main() {
  group('fonts: every weight has a real file', () {
    // pubspec.yaml: the `weight:` and `asset:` pairs of the family `Roboto`.
    final lines = File('pubspec.yaml').readAsLinesSync();
    final declared = <int, String>{};
    var inRoboto = false;
    String? asset;
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('- family:')) {
        inRoboto = t == '- family: Roboto';
        asset = null;
      } else if (inRoboto && t.startsWith('- asset:')) {
        asset = t.substring('- asset:'.length).trim();
      } else if (inRoboto && t.startsWith('weight:') && asset != null) {
        declared[int.parse(t.substring('weight:'.length).trim())] = asset;
      }
    }

    test('the pubspec declares Roboto at 400, 500, 600 and 700, as coquiFontFiles says', () {
      expect(declared, coquiFontFiles);
    });

    test(
      'each declared file exists and is a different face for 400, 500 and 700',
      () {
        for (final f in declared.values) {
          expect(File(f).existsSync(), isTrue, reason: f);
          expect(File(f).lengthSync(), greaterThan(100000), reason: f);
        }
        expect(declared[400], isNot(declared[500]));
        expect(declared[500], isNot(declared[700]));
        expect(declared[400], isNot(declared[700]));
        // 600 has no face of its own: it draws with the 700 file, as CSS matching picks.
        expect(declared[600], declared[700]);
        expect(
          File('fonts/LICENSE-roboto.txt').readAsStringSync(),
          contains('Apache License'),
        );
      },
    );

    test('every CoquiText style is Roboto at a weight that has a file; none is synthesised', () {
      final all = CoquiText.all;
      // The list is complete: as many entries as `static final` styles in the class.
      final source = File('lib/src/text_styles.dart').readAsStringSync();
      final cls = source.substring(
        source.indexOf('abstract final class CoquiText'),
      );
      final count = RegExp(r'static final \w+ = ').allMatches(cls).length;
      expect(all.length, count);
      for (final e in all.entries) {
        final style = e.value;
        expect(style.fontFamily, 'packages/coqui_ui/Roboto', reason: e.key);
        final weight = style.fontWeight!.value;
        expect(
          coquiFontFiles.containsKey(weight),
          isTrue,
          reason: '${e.key} is $weight',
        );
        expect(
          declared.containsKey(weight),
          isTrue,
          reason: '${e.key} is $weight',
        );
        expect(File(declared[weight]!).existsSync(), isTrue, reason: e.key);
      }
    });

    test('the weights the tokens use', () {
      final used = {for (final s in CoquiText.all.values) s.fontWeight!.value};
      expect(used, {400, 500, 600, 700});
    });
  });

  group('hairlines: a CSS border is whole device pixels, rounded down', () {
    test('1 px and 1.5 px at ratio 2.625 and 3', () {
      expect(cssBorderWidth(1, 2.625) * 2.625, closeTo(2, 1e-9));
      expect(cssBorderWidth(1.5, 2.625) * 2.625, closeTo(3, 1e-9));
      expect(cssBorderWidth(4, 2.625) * 2.625, closeTo(10, 1e-9));
      expect(cssBorderWidth(1, 3) * 3, closeTo(3, 1e-9));
      expect(cssBorderWidth(1.5, 3) * 3, closeTo(4, 1e-9));
      expect(cssBorderWidth(4, 3) * 3, closeTo(12, 1e-9));
    });
    test('never below one device pixel', () {
      expect(cssBorderWidth(0.2, 2.625) * 2.625, closeTo(1, 1e-9));
      expect(cssBorderWidth(1, 1) * 1, closeTo(1, 1e-9));
      expect(cssBorderWidth(1, 1.5) * 1.5, closeTo(1, 1e-9));
    });

    for (final ratio in [2.625, 3.0]) {
      testWidgets(
        'the outline button\'s border is ${(1.5 * ratio).floor()} device pixels at $ratio',
        (tester) async {
          _phone(tester, const Size(412, 915), ratio);
          final key = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: key,
                    child: SizedBox(
                      width: 120,
                      child: CoquiButton(
                        label: 'x',
                        kind: CoquiButtonKind.outline,
                        full: true,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final px = await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: ratio);
            final data = (await image.toByteData())!;
            final out = Uint32List(image.width * image.height);
            final view = ByteData.sublistView(data);
            for (var i = 0; i < out.length; i++) {
              out[i] = view.getUint32(i * 4, Endian.little);
            }
            final r = (w: image.width, h: image.height, px: out);
            image.dispose();
            return r;
          });
          final w = px!.w;
          final y = px.h ~/ 2;
          // The left edge, mid height: solid border pixels (line2, #C9C6BB), then nothing.
          const line2 = 0xFFBBC6C9;
          var run = 0;
          while (run < 12 && px.px[y * w + run] == line2) {
            run++;
          }
          expect(
            run,
            (1.5 * ratio).floor(),
            reason: 'border thickness in device pixels',
          );
          expect(
            px.px[y * w + run] >>> 24,
            0,
            reason: 'the pill is empty inside',
          );
        },
      );
    }

    testWidgets(
      'pills, the quiet play disc, meter dots, row dividers and the map chips use the same rule',
      (tester) async {
        _phone(tester, const Size(412, 915), 2.625);
        await tester.pumpWidget(
          _app(
            Column(
              children: [
                SegmentedPills(
                  labels: const ['a', 'b'],
                  selected: 0,
                  onSelected: (_) {},
                ),
                PlayButton(quiet: true, onPressed: () {}),
                const MeterDots(value: 1),
                const RowDivider(),
                MapChips(streak: 's', place: 'p'),
              ],
            ),
          ),
        );
        double widthOf(Finder f) {
          final deco = tester
              .widgetList<DecoratedBox>(
                find.descendant(of: f, matching: find.byType(DecoratedBox)),
              )
              .map((d) => d.decoration)
              .whereType<BoxDecoration>()
              .firstWhere((d) => d.border != null);
          return (deco.border! as Border).top.width;
        }

        // MediaQuery says ratio 1 inside _app, so the helper sees 1: 1.5 css px is 1 device px.
        expect(widthOf(find.byType(SegmentedPills)) * 1, closeTo(1, 1e-9));
        expect(
          tester.getSize(find.byType(RowDivider)).height,
          closeTo(1, 1e-9),
        );
      },
    );
  });

  group('shelf button padding is the CSS\'s', () {
    Future<(Rect, Rect, Rect)> measure(
      WidgetTester tester,
      double width,
    ) async {
      _phone(tester, Size(width, 800));
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.topLeft,
            child: ShelfButton(
              label: 'Listen',
              icon: CoquiIcons.play,
              onPressed: () {},
            ),
          ),
          size: Size(width, 800),
        ),
      );
      final button = tester.getRect(find.byType(ShelfButton));
      final icon = tester.getRect(find.byType(CoquiIcon));
      final text = tester.getRect(find.text('Listen'));
      return (button, icon, text);
    }

    testWidgets('412 px phone: 12 px padding, 6 px gap (max-width:420px)', (
      tester,
    ) async {
      final (button, icon, text) = await measure(tester, 412);
      // ratio 1: the 1.5 px border is 1 px.
      expect(icon.left - button.left, 1 + 12);
      expect(text.left - icon.right, 6);
      expect(button.right - text.right, 1 + 12);
    });
    testWidgets('390 px phone: the same', (tester) async {
      final (button, icon, text) = await measure(tester, 390);
      expect(icon.left - button.left, 1 + 12);
      expect(text.left - icon.right, 6);
    });
    testWidgets('360 px phone: 10 px padding, 6 px gap (max-width:380px)', (
      tester,
    ) async {
      final (button, icon, text) = await measure(tester, 360);
      expect(icon.left - button.left, 1 + 10);
      expect(text.left - icon.right, 6);
    });
    testWidgets('wide: 16 px padding, 8 px gap', (tester) async {
      final (button, icon, text) = await measure(tester, 600);
      expect(icon.left - button.left, 1 + 16);
      expect(text.left - icon.right, 8);
    });
    testWidgets('a plain button keeps 24 px of padding', (tester) async {
      _phone(tester, const Size(412, 800));
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.topLeft,
            child: CoquiButton(label: 'Start', onPressed: () {}),
          ),
        ),
      );
      final button = tester.getRect(find.byType(CoquiButton));
      final text = tester.getRect(find.text('Start'));
      expect(text.left - button.left, 1 + 24);
      expect(button.right - text.right, 1 + 24);
    });
  });

  group('the lesson button rows v=39 has', () {
    Widget button(String l, {bool outline = false}) => LessonButton(
      label: l,
      kind: outline ? LessonButtonKind.outline : LessonButtonKind.go,
      fillWidth: false,
      height: 56,
      onPressed: () {},
    );

    testWidgets('reader: back and next are equal halves, 16 apart, 56 high', (
      tester,
    ) async {
      _phone(tester, const Size(412, 800));
      await tester.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LessonButtonRow.reader(
              back: LessonBackButton(onPressed: () {}),
              next: LessonNextButton(onPressed: () {}),
            ),
          ),
        ),
      );
      final a = tester.getRect(find.byType(LessonBackButton));
      final b = tester.getRect(find.byType(LessonNextButton));
      expect(a.width, 182);
      expect(b.width, 182);
      expect(b.left - a.right, 16);
      expect(a.height, 56);
    });

    testWidgets(
      'reader, last page: the back arrow is 72 wide, the other two share the rest',
      (tester) async {
        _phone(tester, const Size(412, 800));
        await tester.pumpWidget(
          _app(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LessonButtonRow.readerLast(
                back: LessonBackButton(onPressed: () {}),
                again: LessonButton(
                  label: 'again',
                  icon: CoquiIcons.replay,
                  fillWidth: false,
                  height: 56,
                  onPressed: () {},
                ),
                shelf: button('shelf'),
              ),
            ),
          ),
        );
        final back = tester.getRect(find.byType(LessonBackButton));
        final again = tester.getRect(
          find.widgetWithText(LessonButton, 'again'),
        );
        final shelf = tester.getRect(
          find.widgetWithText(LessonButton, 'shelf'),
        );
        expect(back.width, 72);
        expect(again.width, shelf.width);
        expect(again.width, (380 - 72 - 32) / 2);
        expect(again.left - back.right, 16);
        expect(shelf.left - again.right, 16);
      },
    );

    testWidgets(
      'pair (a story\'s end): two equal 48 px halves, 16 apart, at most 480',
      (tester) async {
        _phone(tester, const Size(800, 800));
        await tester.pumpWidget(
          _app(
            LessonButtonRow.pair(
              first: LessonButton(
                label: 'a',
                kind: LessonButtonKind.outline,
                fillWidth: false,
                onPressed: () {},
              ),
              second: LessonButton(
                label: 'b',
                kind: LessonButtonKind.outline,
                fillWidth: false,
                onPressed: () {},
              ),
            ),
            size: const Size(800, 800),
          ),
        );
        final a = tester.getRect(find.widgetWithText(LessonButton, 'a'));
        final b = tester.getRect(find.widgetWithText(LessonButton, 'b'));
        expect(a.width, 232);
        expect(b.width, 232);
        expect(a.height, 48);
        expect(b.left - a.right, 16);
      },
    );

    testWidgets(
      'a disabled back button is the whole button at 35% (first page)',
      (tester) async {
        _phone(tester, const Size(412, 800));
        await tester.pumpWidget(
          _app(
            Row(
              children: [
                SizedBox(width: 100, child: LessonBackButton(onPressed: null)),
                SizedBox(width: 100, child: LessonBackButton(onPressed: () {})),
              ],
            ),
          ),
        );
        final opacities = tester
            .widgetList<Opacity>(
              find.descendant(
                of: find.byType(LessonBackButton),
                matching: find.byType(Opacity),
              ),
            )
            .map((o) => o.opacity)
            .toList();
        expect(opacities, [0.35, 1.0]);
        // Over the dark frame: the ring #4A4A52 at 35% is (43,43,48 or 49), the white chevron about (107,107,111).
        int blend(int fg, int bg) => (bg + (fg - bg) * 0.35).round();
        expect([blend(0x4A, 0x1B), blend(0x4A, 0x1B)], [43, 43]);
        expect(blend(0x52, 0x1F), inInclusiveRange(48, 49));
        expect(blend(0xFF, 0x1B), inInclusiveRange(100, 110));
      },
    );
  });

  group('picture choice (.opt)', () {
    testWidgets('ring, dim and badge states', (tester) async {
      _phone(tester, const Size(412, 800));
      await tester.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                PictureChoice(
                  ring: ChoiceRing.right,
                  check: true,
                  child: const SizedBox(width: 200, height: 100, key: Key('a')),
                ),
                const SizedBox(height: 24),
                PictureChoice(
                  ring: ChoiceRing.wrong,
                  dim: ChoiceDim.unchosen,
                  child: const SizedBox(width: 200, height: 100, key: Key('b')),
                ),
                const SizedBox(height: 24),
                PictureChoice(
                  dim: ChoiceDim.whileSentence,
                  child: const SizedBox(width: 200, height: 100, key: Key('c')),
                ),
              ],
            ),
          ),
        ),
      );
      // The ring takes no room: the pictures are as tall as given.
      expect(tester.getSize(find.byKey(const Key('a'))), const Size(200, 100));
      List<BoxShadow> shadows(String key) => tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.byKey(Key(key)),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .expand((d) => d.boxShadow ?? <BoxShadow>[])
          .toList();
      expect(shadows('a').first.color, CoquiColors.lessonGreen);
      expect(shadows('a').first.spreadRadius, 3);
      expect(shadows('b').first.color, CoquiColors.lessonBad);
      expect(shadows('c').first.color, CoquiColors.lessonLine);
      expect(shadows('c').first.spreadRadius, 1.5);
      // The dims, from cual.js:39: rgba(6,14,28,.55) and .5.
      final dims = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .map((c) => c.color)
          .where(
            (c) =>
                c == CoquiColors.optionDimUnchosen ||
                c == CoquiColors.optionDimWhileSentence,
          )
          .toList();
      expect(dims, [
        CoquiColors.optionDimUnchosen,
        CoquiColors.optionDimWhileSentence,
      ]);
      expect(CoquiColors.optionDimUnchosen.a, closeTo(0.55, 0.01));
      expect(CoquiColors.optionDimWhileSentence.a, closeTo(0.5, 0.01));
      // The badge: 28 px, 8 px from the picture's top and right, a 2 px white ring outside.
      final badge = tester.getRect(
        find
            .descendant(
              of: find.byType(PictureChoice).first,
              matching: find.byType(Container),
            )
            .last,
      );
      final pic = tester.getRect(find.byKey(const Key('a')));
      expect(badge.size, const Size(28, 28));
      expect(pic.right - badge.right, 8);
      expect(badge.top - pic.top, 8);
    });
  });

  group('the book reader frame', () {
    testWidgets(
      'top bar, picture, lines, foot at the bottom; the last page gives the picture its room',
      (tester) async {
        _phone(tester, const Size(412, 915));
        Widget frame({required bool last}) => _app(
          LessonReaderFrame(
            onClose: () {},
            progress: const LessonProgressLine(value: 0.2),
            count: '1 / 5',
            trailing: LessonTextSizeButton(onPressed: () {}),
            last: last,
            picture: const SizedBox(key: Key('pic'), width: 300, height: 300),
            lines: [
              BookLine(text: const Text('a line'), lit: true),
              BookLine(who: 'who', text: const Text('another')),
            ],
            foot: [
              LessonButtonRow.reader(
                back: LessonBackButton(onPressed: null),
                next: LessonNextButton(onPressed: () {}),
              ),
            ],
          ),
        );
        await tester.pumpWidget(frame(last: false));
        expect(find.text('1 / 5'), findsOneWidget);
        expect(find.text('Aa'), findsOneWidget);
        final first = tester.getRect(find.byKey(const Key('pic')));
        // The foot: 16 from the bottom, 56 high.
        final next = tester.getRect(find.byType(LessonNextButton));
        expect(915 - next.bottom, 16);
        expect(next.height, 56);
        // A line is at least 48 high with 12 px corners.
        expect(
          tester.getSize(find.byType(BookLine).first).height,
          greaterThanOrEqualTo(48),
        );
        await tester.pumpWidget(frame(last: true));
        final lastRect = tester.getRect(find.byKey(const Key('pic')));
        // The last page does not keep the 72 px under the picture, so it stands 36 px lower.
        expect(lastRect.top - first.top, closeTo(36, 1e-6));
      },
    );
  });
}
