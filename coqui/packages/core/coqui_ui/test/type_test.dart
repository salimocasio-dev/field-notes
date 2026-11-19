import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The code points a TrueType file draws: its `cmap` (format 4, the Basic Multilingual Plane).
Set<int> _cmap(Uint8List font) {
  final d = ByteData.sublistView(font);
  final tables = d.getUint16(4);
  int? cmapAt;
  for (var i = 0; i < tables; i++) {
    final at = 12 + i * 16;
    if (String.fromCharCodes(font.sublist(at, at + 4)) == 'cmap') {
      cmapAt = d.getUint32(at + 8);
    }
  }
  if (cmapAt == null) throw StateError('no cmap table');
  final subtables = d.getUint16(cmapAt + 2);
  for (var i = 0; i < subtables; i++) {
    final platform = d.getUint16(cmapAt + 4 + i * 8);
    final encoding = d.getUint16(cmapAt + 6 + i * 8);
    final at = cmapAt + d.getUint32(cmapAt + 8 + i * 8);
    if (platform == 3 && encoding == 1 && d.getUint16(at) == 4) {
      final segX2 = d.getUint16(at + 6);
      final ends = at + 14;
      final starts = ends + segX2 + 2;
      final out = <int>{};
      for (var s = 0; s < segX2 ~/ 2; s++) {
        final end = d.getUint16(ends + s * 2);
        final start = d.getUint16(starts + s * 2);
        if (start == 0xFFFF) continue;
        // A segment may map to glyph 0 (missing) through its idRangeOffset; the files here use
        // plain deltas or range offsets that name real glyphs, so a listed code is a drawn one.
        for (var c = start; c <= end; c++) {
          out.add(c);
        }
      }
      return out;
    }
  }
  throw StateError('no (3, 1) cmap of format 4');
}

/// Every character the app shows, as text: Basic Latin, all of Latin-1 (Spanish accents, ñ, ü, ¿ ¡ « »),
/// the curly quotes, the dashes, the ellipsis, the middle dot and the digits.
Set<int> get _needed => {
  for (var c = 0x20; c <= 0x7E; c++) c,
  for (var c = 0xA0; c <= 0xFF; c++) c,
  for (final c in '‘’“”–—…·0123456789'.runes) c,
};

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: coquiTheme(),
  home: Scaffold(
    backgroundColor: const Color(0xFFFFFFFF),
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

Future<Uint32List> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final out = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = (await image.toByteData())!;
    final view = ByteData.sublistView(data);
    final px = Uint32List(image.width * image.height);
    for (var i = 0; i < px.length; i++) {
      px[i] = view.getUint32(i * 4, Endian.little);
    }
    image.dispose();
    return px;
  });
  return out!;
}

void main() {
  // `flutter test` does not load the fonts of the pubspec (every glyph would be an Ahem square, with no
  // ligature to find), so the four files are loaded here under the family name the styles use.
  setUpAll(() async {
    final loader = FontLoader('packages/coqui_ui/Roboto');
    for (final f in coquiFontFiles.values) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  });

  group('the four Roboto files hold every character the app shows', () {
    for (final e in coquiFontFiles.entries) {
      test('${e.value} (weight ${e.key})', () {
        final have = _cmap(File(e.value).readAsBytesSync());
        final missing = _needed.where((c) => !have.contains(c)).toList();
        expect(
          missing.map((c) => 'U+${c.toRadixString(16).toUpperCase()}').toList(),
          isEmpty,
        );
      });
    }
  });

  group('ligatures are off: "fi", "fl", "ffi" and "ffl" draw plain letters', () {
    test('every CoquiText style, pixelifyStyle and the theme\'s text styles say so', () {
      for (final e in CoquiText.all.entries) {
        expect(
          e.value.fontFeatures,
          containsAll(coquiNoLigatures),
          reason: e.key,
        );
      }
      expect(pixelifyStyle().fontFeatures, containsAll(coquiNoLigatures));
      expect(
        pixelifyStyle(fontWeight: FontWeight.w700).fontFeatures,
        containsAll(coquiNoLigatures),
      );
      expect(coquiNoLigatures, contains(const FontFeature.disable('liga')));
      expect(coquiNoLigatures, contains(const FontFeature.disable('clig')));
      // A style that asks for another feature (the page count's tabular figures) keeps both.
      expect(
        CoquiText.lessonCount.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      final t = coquiTheme().textTheme;
      for (final s in [
        t.displayLarge,
        t.displayMedium,
        t.displaySmall,
        t.headlineLarge,
        t.headlineMedium,
        t.headlineSmall,
        t.titleLarge,
        t.titleMedium,
        t.titleSmall,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
        t.labelSmall,
      ]) {
        expect(s!.fontFeatures, containsAll(coquiNoLigatures));
      }
      expect(
        coquiTheme().primaryTextTheme.bodyMedium!.fontFeatures,
        containsAll(coquiNoLigatures),
      );
    });

    // Two measures, both on the real font. The advance: a run "fi" is exactly as wide as "f" plus "i"
    // (Roboto has no kerning between f, i and l); a ligature glyph is narrower. The rendered pixels:
    // "fi" in one run is the same picture as "f" and "i" drawn on their own, each at the advance of the
    // letters before it, so no glyph joined them and the i has its own dot. The same text with ligatures
    // ON is a different picture and a different width (the control: it proves the font has the
    // ligatures and that both checks can see them).
    for (final weight in coquiFontFiles.keys) {
      testWidgets(
        '"fi fl ffi ffl" at weight $weight: the pixels of each word are its letters drawn apart',
        (tester) async {
          tester.view.devicePixelRatio = 2;
          tester.view.physicalSize = const Size(1200, 400);
          addTearDown(tester.view.reset);

          final base = CoquiText.body.copyWith(
            fontSize: 48,
            height: 1.5,
            fontWeight: FontWeight.values[weight ~/ 100 - 1],
            color: const Color(0xFF000000),
          );
          final withLigatures = base.copyWith(fontFeatures: const []);

          double advance(String s) {
            final p = TextPainter(
              text: TextSpan(text: s, style: base),
              textDirection: TextDirection.ltr,
            )..layout();
            return p.width;
          }

          for (final word in ['fi', 'fl', 'ffi', 'ffl']) {
            // The advance.
            final letters = [for (final c in word.split('')) advance(c)];
            expect(
              advance(word),
              closeTo(letters.reduce((a, b) => a + b), 1e-9),
              reason: '"$word" at $weight: one run as wide as its letters',
            );
            final ligatedWidth = (TextPainter(
              text: TextSpan(text: word, style: withLigatures),
              textDirection: TextDirection.ltr,
            )..layout()).width;
            expect(
              ligatedWidth,
              lessThan(advance(word) - 0.1),
              reason: '"$word" at $weight: the ligature control is narrower',
            );

            Future<Uint32List> draw(Widget child) async {
              final key = GlobalKey();
              await tester.pumpWidget(
                _app(
                  RepaintBoundary(
                    key: key,
                    child: SizedBox(width: 300, height: 100, child: child),
                  ),
                ),
              );
              return _pixels(tester, key);
            }

            final run = await draw(Stack(children: [Text(word, style: base)]));
            final apart = await draw(
              Stack(
                children: [
                  for (var i = 0; i < word.length; i++)
                    Positioned(
                      left: advance(word.substring(0, i)),
                      top: 0,
                      child: Text(word[i], style: base),
                    ),
                ],
              ),
            );
            final ligated = await draw(
              Stack(children: [Text(word, style: withLigatures)]),
            );

            var differ = 0;
            for (var i = 0; i < run.length; i++) {
              if (run[i] != apart[i]) differ++;
            }
            expect(
              differ,
              0,
              reason:
                  '"$word" at $weight: pixels that differ from its letters drawn apart',
            );
            var control = 0;
            for (var i = 0; i < run.length; i++) {
              if (run[i] != ligated[i]) control++;
            }
            expect(
              control,
              greaterThan(40),
              reason:
                  '"$word" at $weight: the ligature control must look different',
            );
          }
        },
      );
    }

    testWidgets(
      'a Text with no style of its own, under coquiTheme, has no ligature either',
      (tester) async {
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = const Size(1200, 400);
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(
          _app(
            RepaintBoundary(
              key: key,
              child: const SizedBox(width: 300, height: 100, child: Text('fi')),
            ),
          ),
        );
        final style = DefaultTextStyle.of(tester.element(find.text('fi')))
            .style;
        expect(style.fontFeatures, containsAll(coquiNoLigatures));
        expect(style.fontFamily, 'packages/coqui_ui/Roboto');
      },
    );
  });
}
