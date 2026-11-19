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

/// `usWeightClass` of the OS/2 table of a TrueType file.
int _weightClass(Uint8List font) {
  final d = ByteData.sublistView(font);
  final tables = d.getUint16(4);
  for (var i = 0; i < tables; i++) {
    final at = 12 + i * 16;
    final tag = String.fromCharCodes(font.sublist(at, at + 4));
    if (tag == 'OS/2') {
      final offset = d.getUint32(at + 8);
      return d.getUint16(offset + 4);
    }
  }
  throw StateError('no OS/2 table');
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

    test('each weight has a file of its own, cut from one source, and the licence is the OFL', () {
      for (final f in declared.values) {
        expect(File(f).existsSync(), isTrue, reason: f);
        expect(File(f).lengthSync(), greaterThan(30000), reason: f);
      }
      // Four weights, four different files: 600 is SemiBold, never Bold.
      expect(declared.values.toSet().length, 4);
      expect(declared[600], 'fonts/Roboto-SemiBold.ttf');
      // The weight each file says it is (OS/2 usWeightClass), so a file cannot sit under the wrong weight.
      for (final e in declared.entries) {
        expect(
          _weightClass(File(e.value).readAsBytesSync()),
          e.key,
          reason: e.value,
        );
      }
      final licence = File('fonts/LICENSE-roboto.txt').readAsStringSync();
      expect(licence, contains('SIL OPEN FONT LICENSE Version 1.1'));
      expect(licence, isNot(contains('Apache License')));
    });

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
        // The file under that weight really is that weight (600 is SemiBold, not Bold).
        expect(
          _weightClass(File(declared[weight]!).readAsBytesSync()),
          weight,
          reason: '${e.key}: the file for $weight',
        );
      }
      // 600 is drawn by styles of the tokens, and by a file of its own.
      expect(all.values.where((s) => s.fontWeight!.value == 600), isNotEmpty);
    });

    test('the weights the tokens use', () {
      final used = {for (final s in CoquiText.all.values) s.fontWeight!.value};
      expect(used, {400, 500, 600, 700});
    });
  });

  group('hairlines: a CSS border as Chrome draws it', () {
    test('1 px, 1.5 px and 4 px at ratio 2.625 and 3', () {
      // Chrome floors the CSS width (1.5 to 1) and draws exactly that, unrounded: 2.625 device pixels at
      // ratio 2.625 (two solid rows and a partial one, as the reference pictures show), 3 at ratio 3.
      expect(cssBorderWidth(1, 2.625) * 2.625, closeTo(2.625, 1e-9));
      expect(cssBorderWidth(1.5, 2.625) * 2.625, closeTo(2.625, 1e-9));
      expect(cssBorderWidth(4, 2.625) * 2.625, closeTo(10.5, 1e-9));
      expect(cssBorderWidth(1, 3) * 3, closeTo(3, 1e-9));
      expect(cssBorderWidth(1.5, 3) * 3, closeTo(3, 1e-9));
      expect(cssBorderWidth(4, 3) * 3, closeTo(12, 1e-9));
    });
    test('never below one device pixel', () {
      expect(cssBorderWidth(0.2, 2.625) * 2.625, closeTo(2.625, 1e-9));
      expect(cssBorderWidth(1, 1) * 1, closeTo(1, 1e-9));
      expect(cssBorderWidth(1, 0.5) * 0.5, closeTo(1, 1e-9));
    });

    for (final ratio in [2.625, 3.0]) {
      testWidgets(
        'the outline button\'s border is 1 CSS pixel, not rounded, at $ratio',
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
          // The left edge, mid height: solid border pixels (line2, #C9C6BB), then, at 2.625, one row that
          // is 62% covered (2 + 0.625 = 2.625 device pixels), then nothing: the pill is empty inside.
          const line2 = 0xFFBBC6C9;
          var run = 0;
          while (run < 12 && px.px[y * w + run] == line2) {
            run++;
          }
          if (ratio == 3.0) {
            expect(run, 3, reason: 'border thickness in whole device pixels');
            expect(px.px[y * w + run] >>> 24, 0, reason: 'empty inside');
          } else {
            expect(run, 2, reason: 'two solid border pixels');
            final partial = px.px[y * w + run] >>> 24;
            expect(
              partial,
              closeTo(0.625 * 255, 6),
              reason: 'then 62.5% covered',
            );
            expect(px.px[y * w + run + 1] >>> 24, 0, reason: 'empty inside');
          }
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

  group('a plain button keeps the CSS padding', () {
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

  group('the end of a Repaso: the grid of word pictures (cual.js cualGrid)', () {
    test(
      'Android 412 at 2.625: three to a row at scale 1, 196 device pixels each',
      () {
        final p = lessonGridPlan(
          contentWidth: 412 - 32,
          devicePixelRatio: 2.625,
          pictureWidth: 196,
        );
        expect((p.columns, p.scale), (3, 1));
        expect(p.cellWidth * 2.625, closeTo(196, 1e-9));
        expect(p.blockWidth, closeTo(3 * 196 / 2.625 + 32, 1e-9));
      },
    );
    test(
      'iPhone 390 at 3: two to a row at scale 2, 392 device pixels each',
      () {
        final p = lessonGridPlan(
          contentWidth: 390 - 32,
          devicePixelRatio: 3,
          pictureWidth: 196,
        );
        expect((p.columns, p.scale), (2, 2));
        expect(p.cellWidth * 3, closeTo(392, 1e-9));
        expect(p.blockWidth, closeTo(2 * 392 / 3 + 16, 1e-9));
      },
    );
    test(
      'a picture is at most about 140 px wide; the column is at most 480',
      () {
        // 600 wide at ratio 2: 480 of room, but 140 px at ratio 2 is 280 device pixels: scale 1 only.
        final wide = lessonGridPlan(
          contentWidth: 568,
          devicePixelRatio: 2,
          pictureWidth: 196,
        );
        expect((wide.columns, wide.scale), (3, 1));
        // A 360 wide phone at 3: two to a row at scale 2.
        final small = lessonGridPlan(
          contentWidth: 328,
          devicePixelRatio: 3,
          pictureWidth: 196,
        );
        expect((small.columns, small.scale), (2, 2));
      },
    );
    test('where not even two fit at scale 1: one to a row', () {
      final p = lessonGridPlan(
        contentWidth: 100,
        devicePixelRatio: 1,
        pictureWidth: 196,
      );
      expect((p.columns, p.scale), (1, 1));
    });

    for (final (size, ratio, columns, devicePx) in [
      (const Size(412, 915), 2.625, 3, 196.0),
      (const Size(390, 844), 3.0, 2, 392.0),
    ]) {
      testWidgets(
        '${size.width.toInt()} wide: $columns columns, each picture $devicePx device pixels wide, filling its cell',
        (tester) async {
          _phone(tester, size, ratio);
          final plan = lessonGridPlan(
            contentWidth: size.width - 32,
            devicePixelRatio: ratio,
            pictureWidth: 196,
          );
          final pixels = Uint32List(196 * 104);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LessonPictureGrid(
                      plan: plan,
                      cells: [
                        for (var i = 0; i < 7; i++)
                          LessonGridCell(
                            picture: PixelView(
                              pixels: pixels,
                              width: 196,
                              height: 104,
                            ),
                            word: 'w$i',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          final pics = tester
              .widgetList<PixelView>(find.byType(PixelView))
              .length;
          expect(pics, 7);
          final rects = [
            for (var i = 0; i < 7; i++)
              tester.getRect(find.byType(PixelView).at(i)),
          ];
          // The picture is exactly as wide as its cell, at a whole scale: no strip beside it.
          expect(rects[0].width * ratio, closeTo(devicePx, 1e-6));
          expect(rects[0].height * ratio, closeTo(devicePx * 104 / 196, 1e-6));
          // `columns` to a row, 16 px apart, then the next row 8 + 24 + 16 px lower.
          final firstRow = rects.where((r) => r.top == rects[0].top).length;
          expect(firstRow, columns);
          expect(rects[1].left - rects[0].right, closeTo(16, 1e-6));
          final rowHeight = rects[0].height + 8 + 24 + 16;
          expect(rects[columns].top - rects[0].top, closeTo(rowHeight, 1e-6));
        },
      );
    }
  });

  group('a story\'s end: the title hangs 16 px under the picture', () {
    for (final size in const [Size(412, 915), Size(390, 844), Size(360, 740)]) {
      testWidgets('${size.width.toInt()} x ${size.height.toInt()}', (
        tester,
      ) async {
        _phone(tester, size);
        await tester.pumpWidget(
          _app(
            LessonFrame(
              progress: const LessonProgressDashes(segments: 5, done: 5),
              picture: const SizedBox(key: Key('pic'), width: 300, height: 330),
              underPicture: const Text('Story title', key: Key('title')),
              bottom: [LessonButton(label: 'Next story', onPressed: () {})],
            ),
            size: size,
          ),
        );
        final pic = tester.getRect(find.byKey(const Key('pic')));
        final title = tester.getRect(find.byKey(const Key('title')));
        // The picture is centred above the 112 px of the bottom zone, under the 56 px top bar.
        expect(pic.center.dy, closeTo(56 + (size.height - 56 - 112) / 2, 1e-6));
        // The title: 16 px under the picture, at the left of the 16 px margins.
        expect(title.top - pic.bottom, closeTo(16, 1e-6));
        expect(title.left, 16);
      });
    }
  });
}
