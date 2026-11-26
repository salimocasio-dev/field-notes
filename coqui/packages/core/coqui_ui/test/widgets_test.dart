import 'dart:io';

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
    test(
      'the book and the shelf: Fin, Otra vez, Cuento con dibujos, Haz esto',
      () {
        expect(CoquiLabels.fin, 'Fin');
        expect(CoquiLabels.again, 'Otra vez');
        expect(CoquiLabels.pictureStory, 'Cuento con dibujos');
        expect(CoquiLabels.routine, 'Haz esto');
      },
    );
    test('each label is copied from the line of the old page it names', () {
      final lines = File('../../../../historia/app.html').readAsLinesSync();
      String line(int n) => lines[n - 1];
      expect(line(7), contains('<title>${CoquiLabels.appName}</title>'));
      expect(line(374), contains('"${CoquiLabels.appName}"'));
      expect(line(331), contains('"${CoquiLabels.pictureStory}"'));
      expect(line(331), contains('"${CoquiLabels.routine}"'));
      expect(line(365), contains('>${CoquiLabels.fin}</div>'));
      expect(line(365), contains('${CoquiLabels.again}</button>'));
      expect(line(365), contains('>${CoquiLabels.library}</button>'));
    });
    test('CoquiTabs defines the five tab ids and fallback labels', () {
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
      final arc = parseSvgPath('M4 5a2 2 0 0 1 2-2').getBounds();
      expect(arc.left, closeTo(4, 1e-6));
      expect(arc.top, closeTo(3, 1e-6));
      expect(arc.right, closeTo(6, 1e-6));
    });
  });

  group('kept legacy lesson buttons & frames', () {
    testWidgets('LessonCloseButton is 48 px and fires', (tester) async {
      await _phone(tester);
      var closed = 0;
      await tester.pumpWidget(
        _app(Center(child: LessonCloseButton(onPressed: () => closed++))),
      );
      expect(
        tester.getSize(find.byType(LessonCloseButton)),
        const Size(48, 48),
      );
      await tester.tap(find.byType(LessonCloseButton));
      await tester.pump();
      expect(closed, 1);
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
              ],
            ),
            size: const Size(800, 900),
          ),
        );
        Size button(int i) => tester.getSize(
          find
              .descendant(
                of: find.byType(LessonButton).at(i),
                matching: find.byType(Container),
              )
              .first,
        );
        final sizes = [for (var i = 0; i < 3; i++) button(i)];
        expect(sizes[0], const Size(480, 56));
        expect(sizes[1], const Size(480, 56));
        expect(sizes[2], const Size(480, 48));
        for (final l in ['a', 'b', 'c']) {
          await tester.tap(find.text(l));
        }
        expect(taps, 3);
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

    testWidgets('PictureFrame clips with rounded corners on pictureBack', (
      tester,
    ) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          const Center(
            child: PictureFrame(child: SizedBox(width: 196, height: 104)),
          ),
        ),
      );
      expect(tester.getSize(find.byType(PictureFrame)), const Size(196, 104));
    });
  });

  group('fades', () {
    testWidgets('FadingEdges wraps its child in a ShaderMask', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 200,
            height: 100,
            child: FadingEdges(
              top: 16,
              bottom: 16,
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      );
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });
}
