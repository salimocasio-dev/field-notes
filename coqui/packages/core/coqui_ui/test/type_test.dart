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

/// The text of every string literal of Dart [src], escapes decoded (`\u{1F525}` is the flame emoji),
/// raw strings as written. Comments are skipped. Code inside `${...}` is skipped, but a string inside it is
/// a literal of its own.
List<String> stringLiterals(String src) {
  final out = <String>[];
  var i = 0;

  bool isIdent(String c) => RegExp(r'[A-Za-z0-9_$]').hasMatch(c);

  // Skips a comment starting at [i] if there is one; returns the new index or [i].
  int comment(int i) {
    if (src.startsWith('//', i)) {
      final nl = src.indexOf('\n', i);
      return nl < 0 ? src.length : nl;
    }
    if (src.startsWith('/*', i)) {
      var depth = 0;
      var j = i;
      while (j < src.length) {
        if (src.startsWith('/*', j)) {
          depth++;
          j += 2;
        } else if (src.startsWith('*/', j)) {
          depth--;
          j += 2;
          if (depth == 0) return j;
        } else {
          j++;
        }
      }
      return src.length;
    }
    return i;
  }

  // Reads the string whose opening quote is at [start]; returns the index after its closing quote.
  int readString(int start, {required bool raw}) {
    final q = src[start];
    final triple = src.startsWith(q * 3, start);
    var j = start + (triple ? 3 : 1);
    final text = StringBuffer();
    final close = triple ? q * 3 : q;
    while (j < src.length) {
      if (src.startsWith(close, j)) {
        out.add(text.toString());
        return j + close.length;
      }
      final c = src[j];
      if (!raw && c == r'\') {
        final n = src[j + 1];
        if (n == 'u') {
          if (src[j + 2] == '{') {
            final end = src.indexOf('}', j);
            text.writeCharCode(int.parse(src.substring(j + 3, end), radix: 16));
            j = end + 1;
          } else {
            text.writeCharCode(
              int.parse(src.substring(j + 2, j + 6), radix: 16),
            );
            j += 6;
          }
        } else if (n == 'x') {
          text.writeCharCode(int.parse(src.substring(j + 2, j + 4), radix: 16));
          j += 4;
        } else if ('nrtbfv'.contains(n)) {
          j += 2;
        } else {
          text.write(n);
          j += 2;
        }
      } else if (!raw && c == r'$') {
        if (src[j + 1] == '{') {
          // Code: skip to the matching brace; strings inside are literals of their own.
          var depth = 1;
          j += 2;
          while (j < src.length && depth > 0) {
            final k = comment(j);
            if (k != j) {
              j = k;
              continue;
            }
            final d = src[j];
            if (d == '{') {
              depth++;
            } else if (d == '}') {
              depth--;
            } else if (d == "'" || d == '"') {
              j = readString(
                j,
                raw: j > 0 && src[j - 1] == 'r' && !isIdent(src[j - 2]),
              );
              continue;
            }
            j++;
          }
        } else {
          j++;
          while (j < src.length && isIdent(src[j]) && src[j] != r'$') {
            j++;
          }
        }
      } else {
        text.write(c);
        j++;
      }
    }
    out.add(text.toString());
    return src.length;
  }

  while (i < src.length) {
    final k = comment(i);
    if (k != i) {
      i = k;
      continue;
    }
    final c = src[i];
    if (c == "'" || c == '"') {
      final raw = i > 0 && src[i - 1] == 'r' && (i < 2 || !isIdent(src[i - 2]));
      i = readString(i, raw: raw);
    } else {
      i++;
    }
  }
  return out;
}

/// Every character a string literal under `lib/` holds that the shipped fonts lack.
Map<String, Set<String>> missingInLib() {
  final fonts = [
    for (final f in coquiFontFiles.values) _cmap(File(f).readAsBytesSync()),
  ];
  final missing = <String, Set<String>>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    for (final text in stringLiterals(entity.readAsStringSync())) {
      for (final c in text.runes) {
        if (c < 0x20) continue; // a line break or a tab is not drawn
        if (fonts.every((f) => f.contains(c))) continue;
        (missing[entity.path] ??= {}).add(
          'U+${c.toRadixString(16).toUpperCase().padLeft(4, '0')} '
          '${String.fromCharCode(c)}',
        );
      }
    }
  }
  return missing;
}

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

  group('no string literal under lib/ holds a character the fonts lack', () {
    test(
      'the scanner reads escapes, raw strings, interpolation and comments',
      () {
        const src = r"""
// 'not a literal' with a flame \u{1F525}
final a = '\u{1F525} $days day${days == 1 ? '' : 's'}';
final b = r'raw \u{1F525} text';
final c = "a \u00e9 ${'nested \u2713'} done"; /* 'in a comment' */
final d = 'plain \\ \' quote';
""";
        final lits = stringLiterals(src);
        expect(
          lits,
          contains(
            '\u{1F525} '
            r' day',
          ),
        );
        expect(lits, contains(r'raw \u{1F525} text'));
        expect(lits, contains('nested \u2713'));
        expect(lits, contains('a \u00e9  done'));
        expect(lits.any((l) => l.contains('not a literal')), isFalse);
        expect(lits.any((l) => l.contains('in a comment')), isFalse);
      },
    );

    test('a flame emoji or a check mark in a literal would be found', () {
      final fonts = [
        for (final f in coquiFontFiles.values) _cmap(File(f).readAsBytesSync()),
      ];
      bool lacks(int c) => !fonts.every((f) => f.contains(c));
      expect(lacks(0x1F525), isTrue);
      expect(lacks(0x2713), isTrue);
      expect(lacks(0x2192), isTrue);
      expect(lacks(0x00B7), isFalse, reason: 'the middle dot is in Roboto');
      expect(lacks(0x00E9), isFalse);
      expect(lacks(0x00BF), isFalse);
    });

    test('lib/ holds none', () {
      expect(missingInLib(), isEmpty);
    });
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
