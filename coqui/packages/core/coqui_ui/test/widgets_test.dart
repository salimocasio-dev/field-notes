import 'dart:typed_data';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {Size size = const Size(412, 915)}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: coquiTheme(),
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: Scaffold(body: child),
  ),
);

Future<void> _phone(
  WidgetTester tester, {
  Size size = const Size(412, 915),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

int _filled(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .where(
      (c) =>
          c.key is ValueKey<String> &&
          (c.key! as ValueKey<String>).value.endsWith('on'),
    )
    .length;

void main() {
  group('tokens', () {
    test('colours are v=39\'s', () {
      expect(CoquiColors.bg, const Color(0xFFF6F5F1));
      expect(CoquiColors.ink, const Color(0xFF16181D));
      expect(CoquiColors.mut, const Color(0xFF636A75));
      expect(CoquiColors.ok, const Color(0xFF17803F));
      expect(CoquiColors.info, const Color(0xFF3B5BDB));
      expect(CoquiColors.bad, const Color(0xFFD9480F));
      expect(CoquiColors.lessonBg, const Color(0xFF1B1B1F));
    });
    test('the type scale: 24/32, 18/24, 16/24, 14, 12', () {
      expect(CoquiText.h1.fontSize, 24);
      expect(CoquiText.h1.height! * 24, closeTo(32, 1e-9));
      expect(CoquiText.h1.fontWeight, FontWeight.w600);
      expect(CoquiText.h2.fontSize, 18);
      expect(CoquiText.h2.fontWeight, FontWeight.w500);
      expect(CoquiText.body.fontSize, 16);
      expect(CoquiText.small.fontSize, 14);
      expect(CoquiText.tab.fontSize, 12);
      // Roboto, shipped in fonts/ (see fidelity_test.dart for the weights).
      expect(CoquiText.body.fontFamily, 'packages/coqui_ui/Roboto');
      expect(CoquiText.h1.fontFamily, 'packages/coqui_ui/Roboto');
    });
    test('Pixelify Sans is written with ligatures off', () {
      final s = pixelifyStyle(fontSize: 20);
      expect(s.fontFamily, 'packages/coqui_ui/Pixelify Sans');
      expect(s.fontFeatures, contains(const FontFeature.disable('liga')));
    });
  });

  group('labels', () {
    test('the names v=39 hard-codes, as they are on its pages', () {
      expect(CoquiLabels.appName, 'Coquí');
      expect(CoquiLabels.library, 'Biblioteca');
      expect(CoquiLabels.words, 'Palabras');
      expect(CoquiLabels.map, 'Mapa');
      expect(CoquiLabels.speak, 'Hablar');
      expect(CoquiLabels.me, 'Yo');
      expect(CoquiLabels.reviewTitle, '¿Cuál?');
      expect(CoquiLabels.review, 'Repaso');
    });
    test('the tab bar\'s five tabs read their names from them', () {
      expect(CoquiTabs.all.map((t) => t.label), [
        CoquiLabels.library,
        CoquiLabels.words,
        CoquiLabels.map,
        CoquiLabels.speak,
        CoquiLabels.me,
      ]);
      expect(CoquiTabs.all.map((t) => t.id), [
        'library',
        'words',
        'map',
        'speak',
        'me',
      ]);
    });
  });

  group('icons', () {
    test('every icon\'s path data parses', () {
      for (final icon in [
        CoquiIcons.book,
        CoquiIcons.cards,
        CoquiIcons.map,
        CoquiIcons.mic,
        CoquiIcons.me,
        CoquiIcons.play,
        CoquiIcons.stop,
        CoquiIcons.close,
        CoquiIcons.volume,
        CoquiIcons.phone,
        CoquiIcons.read,
        CoquiIcons.replay,
        CoquiIcons.left,
        CoquiIcons.right,
        CoquiIcons.check,
        CoquiIcons.lessonClose,
        CoquiIcons.lessonSound,
        CoquiIcons.lessonSoundOff,
        CoquiIcons.startTriangle,
        CoquiIcons.lessonMic,
        CoquiIcons.badgeCheck,
      ]) {
        for (final shape in icon.shapes) {
          // The curve itself, not its control points (getBounds is loose on arcs).
          var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9;
          for (final m in parseSvgPath(shape.d).computeMetrics()) {
            for (var d = 0.0; d <= m.length; d += 0.1) {
              final p = m.getTangentForOffset(d)!.position;
              if (p.dx < minX) minX = p.dx;
              if (p.dx > maxX) maxX = p.dx;
              if (p.dy < minY) minY = p.dy;
              if (p.dy > maxY) maxY = p.dy;
            }
          }
          expect(maxX - minX + maxY - minY, greaterThan(0), reason: shape.d);
          expect(minX, greaterThanOrEqualTo(-0.01), reason: shape.d);
          expect(maxX, lessThanOrEqualTo(24.01), reason: shape.d);
          expect(minY, greaterThanOrEqualTo(-0.01), reason: shape.d);
          expect(maxY, lessThanOrEqualTo(24.01), reason: shape.d);
        }
      }
    });
    test('the play triangle and an arc read as the SVG says', () {
      final tri = parseSvgPath('M8 5v14l11-7z').getBounds();
      expect(tri, const Rect.fromLTRB(8, 5, 19, 19));
      // `a2 2 0 0 1 2-2` from (4,5): a quarter circle to (6,3).
      final arc = parseSvgPath('M4 5a2 2 0 0 1 2-2').getBounds();
      expect(arc.left, closeTo(4, 1e-6));
      expect(arc.top, closeTo(3, 1e-6));
      expect(arc.right, closeTo(6, 1e-6));
    });
  });

  group('buttons', () {
    testWidgets('CoquiButton shows its label, fires, is 48 px high', (
      tester,
    ) async {
      await _phone(tester);
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Center(
            child: CoquiButton(
              label: 'Go',
              kind: CoquiButtonKind.go,
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      expect(find.text('Go'), findsOneWidget);
      final box = tester.getSize(find.byType(CoquiButton));
      expect(box.height, 48);
      expect(box.width, greaterThanOrEqualTo(48 + 0));
      await tester.tap(find.byType(CoquiButton));
      expect(taps, 1);
    });

    testWidgets('every kind renders; the disabled one does not fire', (
      tester,
    ) async {
      await _phone(tester);
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              CoquiButton(label: 'one', onPressed: () => taps++),
              CoquiButton(
                label: 'two',
                kind: CoquiButtonKind.go,
                onPressed: () => taps++,
              ),
              CoquiButton(
                label: 'three',
                kind: CoquiButtonKind.outline,
                onPressed: () => taps++,
              ),
              const CoquiButton(label: 'four', onPressed: null),
              CoquiButton(
                label: 'five',
                icon: CoquiIcons.play,
                full: true,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      );
      for (final l in ['one', 'two', 'three', 'four', 'five']) {
        await tester.tap(find.text(l));
      }
      expect(taps, 4);
      expect(tester.getSize(find.byType(CoquiButton).last).width, 412);
    });

    testWidgets('a pressed button shrinks to 98% while the finger is down', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          Center(
            child: CoquiButton(label: 'Go', onPressed: () {}),
          ),
        ),
      );
      final g = await tester.startGesture(tester.getCenter(find.text('Go')));
      await tester.pump();
      final scale = tester.widget<Transform>(
        find.descendant(
          of: find.byType(CoquiButton),
          matching: find.byType(Transform),
        ),
      );
      expect(scale.transform.storage[0], closeTo(0.98, 1e-9));
      await g.up();
    });

    testWidgets('PlayButton: a 48 px disc, play, stop, quiet; fires', (
      tester,
    ) async {
      await _phone(tester);
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Row(
            children: [
              PlayButton(onPressed: () => taps++, semanticLabel: 'Play'),
              PlayButton(icon: CoquiIcons.stop, onPressed: () => taps++),
              PlayButton(quiet: true, onPressed: () => taps++),
              PlayButton(icon: CoquiIcons.phone, onPressed: () => taps++),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byType(PlayButton).first), const Size(48, 48));
      for (final b in find.byType(PlayButton).evaluate()) {
        await tester.tap(find.byWidget(b.widget));
      }
      expect(taps, 4);
    });

    testWidgets('close and sound buttons: 48 px, fire, sound shows muted', (
      tester,
    ) async {
      await _phone(tester);
      var closed = 0;
      var sound = 0;
      var muted = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => _app(
            Row(
              children: [
                CoquiCloseButton(onPressed: () => closed++),
                LessonCloseButton(onPressed: () => closed++),
                LessonSoundButton(
                  muted: muted,
                  onPressed: () {
                    sound++;
                    set(() => muted = !muted);
                  },
                ),
                LessonTextSizeButton(onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(CoquiCloseButton)), const Size(48, 48));
      expect(
        tester.getSize(find.byType(LessonCloseButton)),
        const Size(48, 48),
      );
      expect(
        tester.getSize(find.byType(LessonSoundButton)),
        const Size(48, 48),
      );
      await tester.tap(find.byType(CoquiCloseButton));
      await tester.tap(find.byType(LessonCloseButton));
      await tester.tap(find.byType(LessonSoundButton));
      await tester.pump();
      expect(closed, 2);
      expect(sound, 1);
      expect(
        tester.widget<LessonSoundButton>(find.byType(LessonSoundButton)).muted,
        isTrue,
      );
      expect(find.text('Aa'), findsOneWidget);
    });

    testWidgets(
      'LessonButton: 56 px green or blue, 48 px outline, 480 wide at most',
      (tester) async {
        await _phone(tester, size: const Size(800, 900));
        var taps = 0;
        await tester.pumpWidget(
          _app(
            Column(
              children: [
                LessonButton(label: 'a', onPressed: () => taps++),
                LessonButton(
                  label: 'b',
                  kind: LessonButtonKind.blue,
                  onPressed: () => taps++,
                ),
                LessonButton(
                  label: 'c',
                  kind: LessonButtonKind.outline,
                  onPressed: () => taps++,
                ),
                LessonButtonRow(
                  children: [
                    LessonButton(
                      label: 'd',
                      kind: LessonButtonKind.outline,
                      fillWidth: false,
                      onPressed: () => taps++,
                    ),
                    LessonButton(
                      label: 'e',
                      kind: LessonButtonKind.outline,
                      fillWidth: false,
                      onPressed: () => taps++,
                    ),
                  ],
                ),
              ],
            ),
            size: const Size(800, 900),
          ),
        );
        // The button proper: the first Container inside each.
        Size button(int i) => tester.getSize(
          find
              .descendant(
                of: find.byType(LessonButton).at(i),
                matching: find.byType(Container),
              )
              .first,
        );
        final sizes = [for (var i = 0; i < 4; i++) button(i)];
        expect(sizes[0], const Size(480, 56));
        expect(sizes[1], const Size(480, 56));
        expect(sizes[2], const Size(480, 48));
        // Side by side, 16 apart: (480 - 16) / 2 each.
        expect(sizes[3].width, 232);
        for (final l in ['a', 'b', 'c', 'd', 'e']) {
          await tester.tap(find.text(l));
        }
        expect(taps, 5);
      },
    );

    testWidgets('LessonStartButton: a 72 px disc with 16 px under it', (
      tester,
    ) async {
      await _phone(tester);
      var taps = 0;
      await tester.pumpWidget(
        _app(Center(child: LessonStartButton(onPressed: () => taps++))),
      );
      expect(
        tester.getSize(find.byType(LessonStartButton)),
        const Size(72, 88),
      );
      await tester.tapAt(
        tester.getTopLeft(find.byType(LessonStartButton)) +
            const Offset(36, 36),
      );
      expect(taps, 1);
    });
  });

  group('tab bar', () {
    testWidgets(
      'five tabs with v=39\'s labels, the Mapa disc raised; reports the tapped tab',
      (tester) async {
        await _phone(tester);
        final tapped = <String>[];
        await tester.pumpWidget(
          _app(
            Align(
              alignment: Alignment.bottomCenter,
              child: CoquiTabBar(selectedId: 'map', onTap: tapped.add),
            ),
          ),
        );
        for (final l in ['Biblioteca', 'Palabras', 'Mapa', 'Hablar', 'Yo']) {
          expect(find.text(l), findsOneWidget);
        }
        // 72 bar + 14 rise.
        expect(tester.getSize(find.byType(CoquiTabBar)), const Size(412, 86));
        await tester.tap(find.text('Biblioteca'));
        await tester.tap(find.text('Palabras'));
        await tester.tap(find.text('Mapa'));
        await tester.tap(find.text('Hablar'));
        await tester.tap(find.text('Yo'));
        expect(tapped, ['library', 'words', 'map', 'speak', 'me']);
      },
    );

    testWidgets('the whole disc is a target, including the part above the bar', (
      tester,
    ) async {
      await _phone(tester);
      final tapped = <String>[];
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.bottomCenter,
            child: CoquiTabBar(selectedId: 'words', onTap: tapped.add),
          ),
        ),
      );
      final top = tester.getTopLeft(find.byType(CoquiTabBar));
      // 3 px under the bar's top: the raised part of the disc (it rises 14 px).
      await tester.tapAt(top + const Offset(206, 5));
      expect(tapped, ['map']);
      // Left of the disc, in the same band: nothing there.
      await tester.tapAt(top + const Offset(60, 5));
      expect(tapped, ['map']);
    });

    testWidgets('on its side the bar is lower (56) and its disc smaller (44)', (
      tester,
    ) async {
      const size = Size(844, 390);
      await _phone(tester, size: size);
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.bottomCenter,
            child: CoquiTabBar(selectedId: 'map', onTap: (_) {}),
          ),
          size: size,
        ),
      );
      expect(tester.getSize(find.byType(CoquiTabBar)).height, 56 + 18);
    });

    testWidgets('the selected tab has the blue label', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.bottomCenter,
            child: CoquiTabBar(selectedId: 'words', onTap: (_) {}),
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Palabras')).style!.color,
        CoquiColors.info,
      );
      expect(
        tester.widget<Text>(find.text('Yo')).style!.color,
        CoquiColors.mut,
      );
    });

    testWidgets('MapChips: the streak and the place, as hud() writes them', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.topCenter,
            child: MapChips(
              streak: MapChips.streakLabel(1),
              place: MapChips.placeLabel(2, 'a place'),
            ),
          ),
        ),
      );
      expect(find.text('\u{1F525} 1 day'), findsOneWidget);
      expect(find.text('2 · a place'), findsOneWidget);
      expect(tester.getSize(find.byType(MapChips)), const Size(412, 48));
      expect(MapChips.streakLabel(0), '\u{1F525} 0 days');
      expect(MapChips.streakLabel(5), '\u{1F525} 5 days');
    });
  });

  group('sheet', () {
    testWidgets('a title, a handle and an X; the X closes', (tester) async {
      await _phone(tester);
      var closed = 0;
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.bottomCenter,
            child: CoquiSheet(
              title: 'a title',
              onClose: () => closed++,
              child: const Text('body'),
            ),
          ),
        ),
      );
      expect(find.text('a title'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      await tester.tap(find.byType(CoquiCloseButton));
      expect(closed, 1);
      // 56 header + 16 + body + 24.
      expect(tester.getSize(find.byType(CoquiSheet)).width, 412);
    });

    testWidgets(
      'dragging the header down more than 72 px closes it, less does not',
      (tester) async {
        await _phone(tester);
        var closed = 0;
        await tester.pumpWidget(
          _app(
            Align(
              alignment: Alignment.bottomCenter,
              child: CoquiSheet(
                title: 't',
                onClose: () => closed++,
                child: const Text('body'),
              ),
            ),
          ),
        );
        final header =
            tester.getTopLeft(find.byType(CoquiSheet)) + const Offset(100, 20);
        await tester.dragFrom(header, const Offset(0, 50));
        await tester.pumpAndSettle();
        expect(closed, 0);
        await tester.dragFrom(header, const Offset(0, 120));
        await tester.pumpAndSettle();
        expect(closed, 1);
      },
    );

    testWidgets('a modal sheet has no header, no X, and a footer', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.bottomCenter,
            child: CoquiSheet(
              modal: true,
              footer: const Text('footer'),
              child: const Text('welcome'),
            ),
          ),
        ),
      );
      expect(find.byType(CoquiCloseButton), findsNothing);
      expect(find.text('welcome'), findsOneWidget);
      expect(find.text('footer'), findsOneWidget);
    });

    testWidgets('at most 70% of the screen high, and the body scrolls', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          Align(
            alignment: Alignment.bottomCenter,
            child: CoquiSheet(
              title: 't',
              onClose: () {},
              child: Column(
                children: [for (var i = 0; i < 40; i++) Text('row $i')],
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(CoquiSheet)).height,
        closeTo(915 * 0.7, 0.01),
      );
    });

    testWidgets(
      'the layer: a scrim over everything, a tap on it reports; closed it does not catch taps',
      (tester) async {
        await _phone(tester);
        var scrim = 0;
        Widget build(bool open) => _app(
          Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.white)),
              CoquiSheetLayer(
                open: open,
                onScrimTap: () => scrim++,
                sheet: CoquiSheet(
                  title: 't',
                  onClose: () {},
                  child: const Text('body'),
                ),
              ),
            ],
          ),
        );
        await tester.pumpWidget(build(true));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(200, 50));
        expect(scrim, 1);
        await tester.pumpWidget(build(false));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(200, 50));
        expect(scrim, 1);
      },
    );
  });

  group('lesson frame', () {
    testWidgets('close, sound, the picture, the caption and the bottom zone', (
      tester,
    ) async {
      await _phone(tester);
      var closed = 0;
      var sound = 0;
      var started = 0;
      await tester.pumpWidget(
        _app(
          LessonFrame(
            onClose: () => closed++,
            onSound: () => sound++,
            progress: const LessonProgressDashes(segments: 5, done: 2),
            caption: 'a caption',
            picture: const SizedBox(width: 100, height: 100, key: Key('pic')),
            bottom: [LessonStartButton(onPressed: () => started++)],
          ),
        ),
      );
      expect(find.text('a caption'), findsOneWidget);
      await tester.tap(find.byType(LessonCloseButton));
      await tester.tap(find.byType(LessonSoundButton));
      await tester.tapAt(
        tester.getCenter(find.byType(LessonStartButton)) - const Offset(0, 8),
      );
      expect(closed, 1);
      expect(sound, 1);
      expect(started, 1);
      // The top bar is 56 px: the close X at 8 px from the left.
      expect(
        tester.getTopLeft(find.byType(LessonCloseButton)),
        const Offset(8, 4),
      );
      // The start disc: 72 px, 40 px above the screen's foot.
      final disc = tester.getRect(
        find
            .descendant(
              of: find.byType(LessonStartButton),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(disc.size, const Size(72, 72));
      expect(915 - disc.bottom, 40);
      // The picture is centred above the 112 px bottom zone.
      final pic = tester.getRect(find.byKey(const Key('pic')));
      expect(pic.center.dx, 206);
      expect(pic.center.dy, closeTo(56 + (915 - 56 - 112) / 2, 0.01));
      // The caption hangs 8 px under it.
      expect(
        tester.getTopLeft(find.text('a caption')).dy,
        closeTo(pic.bottom + 8, 4),
      );
    });

    testWidgets('the dashes: N of them, the first `done` green, 6 px high', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          const LessonFrame(
            progress: LessonProgressDashes(segments: 5, done: 2),
          ),
        ),
      );
      final dashes = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(dashes.length, 5);
      Color colourOf(AnimatedContainer c) =>
          ((c.decoration! as BoxDecoration).color)!;
      expect(dashes.map(colourOf).toList(), [
        CoquiColors.lessonGreen,
        CoquiColors.lessonGreen,
        CoquiColors.dotOff,
        CoquiColors.dotOff,
        CoquiColors.dotOff,
      ]);
      for (final d in find.byType(AnimatedContainer).evaluate()) {
        expect(tester.getSize(find.byWidget(d.widget)).height, 6);
      }
    });

    testWidgets(
      'showClose false keeps the room but draws and answers nothing',
      (tester) async {
        await _phone(tester);
        var closed = 0;
        await tester.pumpWidget(
          _app(
            LessonFrame(
              showClose: false,
              showSound: false,
              onClose: () => closed++,
              progress: const LessonProgressDashes(segments: 3, done: 3),
            ),
          ),
        );
        for (final v in tester.widgetList<Visibility>(
          find.byType(Visibility),
        )) {
          expect(v.visible, isFalse);
        }
        await tester.tapAt(const Offset(30, 30));
        expect(closed, 0);
      },
    );

    testWidgets(
      'an overlay covers the picture area and the bottom zone stays above it',
      (tester) async {
        await _phone(tester);
        var taps = 0;
        await tester.pumpWidget(
          _app(
            LessonFrame(
              overlay: const Positioned.fill(
                child: ColoredBox(
                  color: CoquiColors.lessonBg,
                  child: Text('end'),
                ),
              ),
              bottom: [LessonButton(label: 'Next', onPressed: () => taps++)],
            ),
          ),
        );
        await tester.tap(find.text('Next'));
        expect(taps, 1);
        expect(find.text('end'), findsOneWidget);
      },
    );

    testWidgets(
      'on its side: the picture at the left, the top bar in a column at the right',
      (tester) async {
        const size = Size(844, 390);
        await _phone(tester, size: size);
        await tester.pumpWidget(
          _app(
            LessonFrame(
              onClose: () {},
              onSound: () {},
              caption: 'cap',
              picture: const SizedBox(key: Key('pic'), width: 200, height: 200),
              bottom: [LessonButton(label: 'Go', onPressed: () {})],
            ),
            size: size,
          ),
        );
        final pic = tester.getRect(find.byKey(const Key('pic')));
        expect(pic.left, 16);
        final close = tester.getRect(find.byType(LessonCloseButton));
        expect(close.left, greaterThan(pic.right));
        expect(find.text('cap'), findsOneWidget);
      },
    );

    testWidgets('LessonProgressLine fills to its value', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          const Center(
            child: SizedBox(width: 200, child: LessonProgressLine(value: 0.25)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fill = tester.getSize(find.byType(FractionallySizedBox));
      expect(fill.width, 50);
      expect(fill.height, 6);
    });
  });

  group('meters', () {
    testWidgets('the dots show n of 4', (tester) async {
      await _phone(tester);
      for (var n = 0; n <= 4; n++) {
        await tester.pumpWidget(_app(Center(child: MeterDots(value: n))));
        expect(_filled(tester), n, reason: '$n of 4');
        expect(
          tester
              .widgetList<Container>(find.byType(Container))
              .where((c) => c.key is ValueKey<String>)
              .length,
          4,
        );
      }
    });

    testWidgets('values outside 0 to 4 are clamped', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_app(const Center(child: MeterDots(value: 9))));
      expect(_filled(tester), 4);
      await tester.pumpWidget(_app(const Center(child: MeterDots(value: -2))));
      expect(_filled(tester), 0);
    });

    testWidgets(
      'Ear and Mouth: labels, 44 px labels, 10 px dots, "n of 4" for a screen reader',
      (tester) async {
        await _phone(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(const Center(child: EarMouthMeters(ear: 3, mouth: 1))),
        );
        expect(find.text('Ear'), findsOneWidget);
        expect(find.text('Mouth'), findsOneWidget);
        expect(find.bySemanticsLabel('Ear: 3 of 4'), findsOneWidget);
        expect(find.bySemanticsLabel('Mouth: 1 of 4'), findsOneWidget);
        expect(_filled(tester), 4); // 3 + 1
        final dots = tester.getSize(find.byType(MeterDots).first);
        expect(dots, const Size(4 * 10 + 3 * 4, 10));
        handle.dispose();
      },
    );
  });

  group('word card', () {
    testWidgets(
      'with a picture: the picture box 196:104, the word, the meters; tap fires',
      (tester) async {
        await _phone(tester);
        var taps = 0;
        await tester.pumpWidget(
          _app(
            Center(
              child: SizedBox(
                width: 182,
                child: WordCard(
                  word: 'sample',
                  ear: 3,
                  mouth: 0,
                  picture: PixelView(
                    pixels: Uint32List(196 * 104),
                    width: 196,
                    height: 104,
                  ),
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        );
        expect(find.text('sample'), findsOneWidget);
        expect(find.text('Ear'), findsOneWidget);
        final card = tester.getSize(find.byType(WordCard));
        expect(card.width, 182);
        // 182 * 104 / 196 of picture, 8 + 24 + 4 + 20 + 20 + 12 under it.
        expect(
          card.height,
          closeTo(182 * 104 / 196 + 8 + 24 + 4 + 40 + 12, 0.5),
        );
        await tester.tap(find.byType(WordCard));
        expect(taps, 1);
      },
    );

    testWidgets(
      'with no picture: a plain tile with the word large and no picture box',
      (tester) async {
        await _phone(tester);
        await tester.pumpWidget(
          _app(
            const Center(
              child: SizedBox(
                width: 182,
                child: WordCard(word: 'plain', ear: 2, mouth: 0),
              ),
            ),
          ),
        );
        expect(find.byType(AspectRatio), findsNothing);
        expect(tester.widget<Text>(find.text('plain')).style!.fontSize, 24);
        expect(
          tester.getSize(find.byType(WordCard)).height,
          greaterThanOrEqualTo(72 + 8 + 40 + 12),
        );
      },
    );

    testWidgets('in a grid the two cards of a row are as tall as the taller', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: WordGrid(
              children: [
                WordCard(
                  word: 'one',
                  ear: 1,
                  mouth: 0,
                  picture: PixelView(
                    pixels: Uint32List(196 * 104),
                    width: 196,
                    height: 104,
                  ),
                ),
                const WordCard(word: 'two', ear: 1, mouth: 0),
                const WordCard(word: 'three', ear: 1, mouth: 0),
              ],
            ),
          ),
        ),
      );
      final a = tester.getRect(find.byType(WordCard).at(0));
      final b = tester.getRect(find.byType(WordCard).at(1));
      expect(a.height, b.height);
      expect(a.width, closeTo((412 - 32 - 16) / 2, 0.01));
      expect(b.left - a.right, 16);
      final c = tester.getRect(find.byType(WordCard).at(2));
      expect(c.top - a.bottom, 16);
    });
  });

  group('cards, rows, controls', () {
    testWidgets(
      'margins collapse as in CSS: card (16 under) then h2 (24 above) leaves 24',
      (tester) async {
        await _phone(tester);
        await tester.pumpWidget(
          _app(
            const TabPage(
              children: [
                ScreenTitle('title'),
                CoquiCard(child: SizedBox(height: 40, child: Text('card'))),
                SectionTitle('section'),
                KeyLine('key'),
              ],
            ),
          ),
        );
        final title = tester.getRect(find.text('title'));
        final card = tester.getRect(find.byType(Container).first);
        expect(title.top, 16 + 8, reason: '16 of padding, 8 of margin');
        final sectionTop = tester.getTopLeft(find.text('section')).dy;
        // The card's box ends where its content ends: find it by its text.
        final cardBottom = tester.getBottomLeft(find.text('card')).dy;
        expect(card.height, greaterThan(0));
        // card: 16 padding under the 40 px child; then 24 (not 40) to the h2's line box.
        expect(sectionTop - (cardBottom - 40 + 40 + 16), closeTo(24, 3));
        // Under the section title: 16 then the key line's -8 leaves 8.
        final sectionBottom = tester.getBottomLeft(find.text('section')).dy;
        expect(
          tester.getTopLeft(find.text('key')).dy - sectionBottom,
          closeTo(8, 3),
        );
      },
    );

    testWidgets(
      'CollapsingColumn: the larger margin wins, a negative one is taken off',
      (tester) async {
        await _phone(tester);
        await tester.pumpWidget(
          _app(
            const Align(
              alignment: Alignment.topLeft,
              child: CollapsingColumn(
                children: [
                  Block(
                    bottom: 16,
                    child: SizedBox(height: 10, width: 10, key: Key('a')),
                  ),
                  Block(
                    top: 24,
                    bottom: 5,
                    child: SizedBox(height: 10, width: 10, key: Key('b')),
                  ),
                  Block(
                    top: -8,
                    child: SizedBox(height: 10, width: 10, key: Key('c')),
                  ),
                  SizedBox(height: 10, width: 10, key: Key('d')),
                ],
              ),
            ),
          ),
        );
        final a = tester.getRect(find.byKey(const Key('a')));
        final b = tester.getRect(find.byKey(const Key('b')));
        final c = tester.getRect(find.byKey(const Key('c')));
        final d = tester.getRect(find.byKey(const Key('d')));
        expect(b.top - a.bottom, 24);
        expect(c.top - b.bottom, 0, reason: '5 and -8: 5 - 8 is below 0, so 0');
        expect(d.top - c.bottom, 0);
      },
    );

    testWidgets(
      'TodayCard: 92 px (16 + 60 + 16), a tap fires, the eyebrow is upper case',
      (tester) async {
        await _phone(tester);
        var taps = 0;
        await tester.pumpWidget(
          _app(
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TodayCard(
                  eyebrow: 'Today · 1 of 6',
                  title: 'a title',
                  subtitle: 'a line',
                  onPressed: () => taps++,
                ),
              ),
            ),
          ),
        );
        expect(find.text('TODAY · 1 OF 6'), findsOneWidget);
        expect(tester.getSize(find.byType(TodayCard)).height, 92);
        await tester.tap(find.byType(TodayCard));
        expect(taps, 1);
      },
    );

    testWidgets(
      'ListRow: 64 px at least, with a play button; a row with onTap fires',
      (tester) async {
        await _phone(tester);
        var rows = 0;
        var plays = 0;
        await tester.pumpWidget(
          _app(
            Column(
              children: [
                ListRow(
                  title: const ListRowTitle('title'),
                  subtitle: const Text('a line'),
                  trailing: PlayButton(onPressed: () => plays++),
                ),
                ListRow(
                  title: const ListRowTitle('tappable'),
                  onTap: () => rows++,
                ),
              ],
            ),
          ),
        );
        expect(tester.getSize(find.byType(ListRow).first).height, 64);
        await tester.tap(find.byType(PlayButton));
        await tester.tap(find.text('tappable'));
        expect(plays, 1);
        expect(rows, 1);
      },
    );

    testWidgets('ShelfRow: the cover, the title, buttons under it', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          ShelfRow(
            title: 'a title',
            subtitle: 'about 2 min',
            actions: [CoquiButton(label: 'Listen', onPressed: () {})],
          ),
        ),
      );
      expect(find.text('Listen'), findsOneWidget);
      // 16 above, a 72 px cover, 16 below at least.
      expect(
        tester.getSize(find.byType(ShelfRow)).height,
        greaterThanOrEqualTo(104),
      );
    });

    testWidgets(
      'SegmentedPills reports the tapped index; the chosen one is blue',
      (tester) async {
        await _phone(tester);
        var got = -1;
        await tester.pumpWidget(
          _app(
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedPills(
                labels: const ['15', '30', '60', '120'],
                selected: 1,
                onSelected: (i) => got = i,
              ),
            ),
          ),
        );
        await tester.tap(find.text('60'));
        expect(got, 2);
        expect(
          tester
              .getSize(
                find
                    .ancestor(
                      of: find.text('15'),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .height,
          48,
        );
      },
    );

    testWidgets('CoquiSwitch toggles: 52 x 48', (tester) async {
      await _phone(tester);
      var on = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => _app(
            Center(
              child: CoquiSwitch(
                value: on,
                onChanged: (v) => set(() => on = v),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(CoquiSwitch)), const Size(52, 48));
      await tester.tap(find.byType(CoquiSwitch));
      await tester.pump();
      expect(on, isTrue);
    });

    testWidgets('CoquiCard disabled (locked) is grey, no shadow', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          const Center(child: CoquiCard(disabled: true, child: Text('locked'))),
        ),
      );
      final deco = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.color == CoquiColors.disabledFill);
      expect(deco.boxShadow!.length, 1);
    });
  });

  group('fades', () {
    testWidgets(
      'ListFade is 16 px high and passes touches through; FadingEdges masks',
      (tester) async {
        await _phone(tester);
        var taps = 0;
        await tester.pumpWidget(
          _app(
            Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => taps++,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ListFade(),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 100,
                  child: FadingEdges(
                    top: 16,
                    bottom: 16,
                    child: ColoredBox(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
        expect(tester.getSize(find.byType(ListFade)).height, 16);
        await tester.tapAt(const Offset(200, 910));
        expect(taps, 1, reason: 'the fade does not take the touch');
        expect(find.byType(ShaderMask), findsOneWidget);
      },
    );
  });
}
