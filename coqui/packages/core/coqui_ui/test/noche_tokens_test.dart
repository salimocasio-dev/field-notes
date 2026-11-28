import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double _channelLinear(int byte) {
  final c = byte / 255.0;
  return c <= 0.04045
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

/// WCAG 2.1 relative luminance for an opaque colour.
double wcagLuminance(Color color) {
  final argb = color.toARGB32();
  final r = _channelLinear((argb >> 16) & 0xFF);
  final g = _channelLinear((argb >> 8) & 0xFF);
  final b = _channelLinear(argb & 0xFF);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG 2.1 contrast ratio `(lighter + 0.05) / (darker + 0.05)`.
double wcagContrast(Color a, Color b) {
  final la = wcagLuminance(a);
  final lb = wcagLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

Map<String, int> _ttfTables(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  final count = d.getUint16(4);
  final out = <String, int>{};
  for (var i = 0; i < count; i++) {
    final at = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(at, at + 4));
    out[tag] = d.getUint32(at + 8);
  }
  return out;
}

int _os2WeightClass(Uint8List bytes) {
  final tables = _ttfTables(bytes);
  final os2 = tables['OS/2'];
  if (os2 == null) throw StateError('missing OS/2 table');
  return ByteData.sublistView(bytes).getUint16(os2 + 4);
}

Set<int> _cmap(Uint8List font) {
  final d = ByteData.sublistView(font);
  final tables = _ttfTables(font);
  final cmapAt = tables['cmap'];
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
        for (var c = start; c <= end; c++) {
          out.add(c);
        }
      }
      return out;
    }
  }
  throw StateError('no (3, 1) cmap of format 4');
}

Map<String, Map<int, String>> _parsePubspecFonts(String yaml) {
  final out = <String, Map<int, String>>{};
  String? currentFamily;
  String? currentAsset;
  for (final raw in yaml.split('\n')) {
    final familyMatch = RegExp(r'^\s*-\s*family:\s*(.+?)\s*$').firstMatch(raw);
    if (familyMatch != null) {
      currentFamily = familyMatch.group(1)!;
      out[currentFamily] = <int, String>{};
      currentAsset = null;
      continue;
    }
    final assetMatch = RegExp(r'^\s*-\s*asset:\s*(.+?)\s*$').firstMatch(raw);
    if (assetMatch != null) {
      currentAsset = assetMatch.group(1)!;
      continue;
    }
    final weightMatch = RegExp(r'^\s*weight:\s*(\d+)\s*$').firstMatch(raw);
    if (weightMatch != null && currentFamily != null && currentAsset != null) {
      out[currentFamily]![int.parse(weightMatch.group(1)!)] = currentAsset;
      currentAsset = null;
    }
  }
  return out;
}

Future<Uint32List> _capturePixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final out = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
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
  setUpAll(() async {
    for (final entry in nocheFontFiles.entries) {
      for (final prefix in ['', 'packages/coqui_ui/']) {
        final loader = FontLoader('$prefix${entry.key}');
        for (final path in entry.value.values) {
          loader.addFont(
            Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
          );
        }
        await loader.load();
      }
    }
  });

  group('NocheColors exact hex literals', () {
    test('every colour matches its specification hex literal', () {
      expect(NocheColors.ground, const Color(0xFF0C1926));
      expect(NocheColors.panel, const Color(0xFF152A3D));
      expect(NocheColors.chip, const Color(0xFF213D57));
      expect(NocheColors.line, const Color(0xFF33506B));
      expect(NocheColors.bar, const Color(0xFF4A6C8C));
      expect(NocheColors.text, const Color(0xFFEEF3F7));
      expect(NocheColors.label, const Color(0xFFA7B8C8));
      expect(NocheColors.dimLine, const Color(0xFF8FA2B5));

      expect(NocheColors.lessonGround, const Color(0xFF12171D));
      expect(NocheColors.lessonLine, const Color(0xFF37424D));
      expect(NocheColors.lessonBorder, const Color(0xFF4A5663));
      expect(NocheColors.lessonLabel, const Color(0xFF8C99A6));
      expect(NocheColors.lessonPanel, const Color(0xFF1B232C));
      expect(NocheColors.litSentence, const Color(0xFF24313F));

      expect(NocheColors.onAccent, const Color(0xFF14110F));
      expect(NocheColors.next, const Color(0xFFE69F00));
      expect(NocheColors.callHalo, const Color(0xFF3D2E0F));
      expect(NocheColors.listening, const Color(0xFF56B4E9));
      expect(NocheColors.listeningSoft, const Color(0xFF1D3A52));
      expect(NocheColors.other, const Color(0xFFCC79A7));
      expect(NocheColors.otherSoft, const Color(0xFF3A2433));
      expect(NocheColors.right, const Color(0xFF009E73));
      expect(NocheColors.micResting, const Color(0xFF28323C));
      expect(NocheColors.scrim, const Color(0xB80C1926));

      expect(NocheColors.sepiaPage, const Color(0xFFF2E8D5));
      expect(NocheColors.sepiaText, const Color(0xFF2E2519));
      expect(NocheColors.sepiaLabel, const Color(0xFF6B5B45));
      expect(NocheColors.sepiaRule, const Color(0xFFB9A682));
      expect(NocheColors.dayPage, const Color(0xFFFAF8F3));
      expect(NocheColors.dayText, const Color(0xFF1B1B1B));
      expect(NocheColors.nightText, const Color(0xFFD8DEE4));
      expect(NocheColors.dayLabel, const Color(0xFF5C5C5C));
      expect(NocheColors.dayRule, const Color(0xFFC9C4B8));
      expect(NocheColors.dayLit, const Color(0xFFE9E4D8));
      expect(NocheColors.sepiaLit, const Color(0xFFE4D6BA));

      expect(NocheColors.coverPlum.spine, const Color(0xFF6B4059));
      expect(NocheColors.coverPlum.face, const Color(0xFF3A2433));
      expect(NocheColors.coverPlum.mark, const Color(0xFFCC79A7));
      expect(NocheColors.coverBlue.spine, const Color(0xFF4A6C8C));
      expect(NocheColors.coverBlue.face, const Color(0xFF213D57));
      expect(NocheColors.coverBlue.mark, const Color(0xFFE69F00));
    });
  });

  group('WCAG 2.1 contrast ratios (>= 4.5:1)', () {
    final pairs = <(String, Color, Color)>[
      ('text on panel', NocheColors.text, NocheColors.panel),
      ('label on panel', NocheColors.label, NocheColors.panel),
      ('next on panel', NocheColors.next, NocheColors.panel),
      ('onAccent on next', NocheColors.onAccent, NocheColors.next),
      (
        'listening on lessonGround',
        NocheColors.listening,
        NocheColors.lessonGround,
      ),
      ('other on lessonGround', NocheColors.other, NocheColors.lessonGround),
      ('right on lessonGround', NocheColors.right, NocheColors.lessonGround),
      (
        'nightText on lessonGround',
        NocheColors.nightText,
        NocheColors.lessonGround,
      ),
      (
        'lessonLabel on lessonGround',
        NocheColors.lessonLabel,
        NocheColors.lessonGround,
      ),
      ('text on litSentence', NocheColors.text, NocheColors.litSentence),
      (
        'nightText on litSentence',
        NocheColors.nightText,
        NocheColors.litSentence,
      ),
      ('sepiaText on sepiaPage', NocheColors.sepiaText, NocheColors.sepiaPage),
      (
        'sepiaLabel on sepiaPage',
        NocheColors.sepiaLabel,
        NocheColors.sepiaPage,
      ),
      ('sepiaText on sepiaLit', NocheColors.sepiaText, NocheColors.sepiaLit),
      ('dayText on dayPage', NocheColors.dayText, NocheColors.dayPage),
      ('dayLabel on dayPage', NocheColors.dayLabel, NocheColors.dayPage),
      ('dayText on dayLit', NocheColors.dayText, NocheColors.dayLit),
      ('text on ground', NocheColors.text, NocheColors.ground),
      ('label on ground', NocheColors.label, NocheColors.ground),
    ];

    for (final (name, fg, bg) in pairs) {
      test('$name meets WCAG AA (>= 4.5:1)', () {
        final ratio = wcagContrast(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$name contrast ratio was ${ratio.toStringAsFixed(2)}:1',
        );
      });
    }
  });

  group('Noche font files, pubspec, licences, cmap and golden rendering', () {
    test('pubspec.yaml declares every Noche family twice with matching weights and assets', () {
      final yaml = File('pubspec.yaml').readAsStringSync();
      final declared = _parsePubspecFonts(yaml);
      for (final entry in nocheFontFiles.entries) {
        final family = entry.key;
        final pkgFamily = 'packages/coqui_ui/$family';
        expect(declared.containsKey(family), isTrue, reason: 'missing $family');
        expect(
          declared.containsKey(pkgFamily),
          isTrue,
          reason: 'missing $pkgFamily',
        );
        expect(declared[family], equals(entry.value), reason: family);
        expect(declared[pkgFamily], equals(entry.value), reason: pkgFamily);
      }
    });

    test('every .ttf is a static font with matching OS/2 usWeightClass and OFL licence', () {
      const licences = [
        'fonts/LICENSE-atkinson-hyperlegible-next.txt',
        'fonts/LICENSE-bricolage-grotesque.txt',
        'fonts/LICENSE-literata.txt',
        'fonts/LICENSE-lexend.txt',
        'fonts/LICENSE-noto-sans-arabic.txt',
      ];
      for (final lic in licences) {
        final file = File(lic);
        expect(file.existsSync(), isTrue, reason: 'missing $lic');
        expect(
          file.readAsStringSync(),
          contains('SIL OPEN FONT LICENSE'),
          reason: lic,
        );
      }

      for (final family in nocheFontFiles.entries) {
        for (final weightEntry in family.value.entries) {
          final weight = weightEntry.key;
          final path = weightEntry.value;
          final file = File(path);
          expect(file.existsSync(), isTrue, reason: 'missing $path');
          final bytes = file.readAsBytesSync();
          final tables = _ttfTables(bytes);
          expect(
            tables.containsKey('fvar'),
            isFalse,
            reason: '$path should be a static instance without fvar',
          );
          expect(
            _os2WeightClass(bytes),
            equals(weight),
            reason: '$path OS/2 usWeightClass mismatch',
          );
        }
      }
    });

    test('cmap covers Latin/Spanish for the 6 Latin families and Arabic+Tashkeel for Noto Sans Arabic', () {
      final latinNeeded = <int>{
        for (var c = 0x20; c <= 0x7E; c++) c,
        for (var c = 0xC0; c <= 0xFF; c++) c,
        for (final c in '¿¡«»‘’“”–—…·0123456789'.runes) c,
      };
      final arabicNeeded = <int>{
        for (var c = 0x20; c <= 0x7E; c++) c,
        // Core Arabic letters & Tashkeel (fathatan..sukun U+064B..U+0652)
        for (var c = 0x0621; c <= 0x063A; c++) c,
        for (var c = 0x0641; c <= 0x0652; c++) c,
      };

      for (final family in nocheFontFiles.entries) {
        final isArabic = family.key == nocheFontNotoSansArabic;
        final needed = isArabic ? arabicNeeded : latinNeeded;
        for (final path in family.value.values) {
          final have = _cmap(File(path).readAsBytesSync());
          final missing = needed.where((c) => !have.contains(c)).toList();
          expect(
            missing
                .map((c) => 'U+${c.toRadixString(16).toUpperCase()}')
                .toList(),
            isEmpty,
            reason: '$path missing required codepoints',
          );
        }
      }
    });

    testWidgets(
      'renders all Noche family+weight combinations and matches golden',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(520, 680);
        addTearDown(tester.view.reset);

        final rows = <(String, String, int, String)>[
          (
            'Atkinson 400',
            nocheFontAtkinson,
            400,
            'Coquí Noche — ¿Dónde está el café? 123',
          ),
          (
            'Atkinson 500',
            nocheFontAtkinson,
            500,
            'Coquí Noche — ¿Dónde está el café? 123',
          ),
          (
            'Atkinson 600',
            nocheFontAtkinson,
            600,
            'Coquí Noche — ¿Dónde está el café? 123',
          ),
          (
            'Atkinson 700',
            nocheFontAtkinson,
            700,
            'Coquí Noche — ¿Dónde está el café? 123',
          ),
          (
            'Atkinson 800',
            nocheFontAtkinson,
            800,
            'Coquí Noche — ¿Dónde está el café? 123',
          ),
          ('Bricolage 700', nocheFontBricolage, 700, 'San Juan — Islas 78'),
          ('Bricolage 800', nocheFontBricolage, 800, 'San Juan — Islas 78'),
          ('Bricolage Display 800', nocheFontBricolageDisplay, 800, '142 días'),
          (
            'Literata 400',
            nocheFontLiterata,
            400,
            'Había una vez en la plaza vieja…',
          ),
          (
            'Literata 500',
            nocheFontLiterata,
            500,
            'Había una vez en la plaza vieja…',
          ),
          (
            'Literata 600',
            nocheFontLiterata,
            600,
            'Había una vez en la plaza vieja…',
          ),
          (
            'Literata Italic 400',
            nocheFontLiterataItalic,
            400,
            '«Buenas noches», dijo ella.',
          ),
          ('Lexend 400', nocheFontLexend, 400, 'Lectura clara y sencilla'),
          ('Lexend 500', nocheFontLexend, 500, 'Lectura clara y sencilla'),
          (
            'Noto Sans Arabic 500',
            nocheFontNotoSansArabic,
            500,
            'مَرْحَبًا بِكُمْ فِي اللَّيْلِ',
          ),
          (
            'Noto Sans Arabic 700',
            nocheFontNotoSansArabic,
            700,
            'مَرْحَبًا بِكُمْ فِي اللَّيْلِ',
          ),
        ];

        final key = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: key,
                child: Container(
                  width: 520,
                  height: 680,
                  color: NocheColors.ground,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final (_, family, weight, sample) in rows)
                        Text(
                          sample,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            inherit: false,
                            fontFamily: family,
                            package: coquiFontPackage,
                            fontWeight: FontWeight.values[weight ~/ 100 - 1],
                            fontSize: 18,
                            height: 1.3,
                            color: NocheColors.text,
                            decoration: TextDecoration.none,
                            fontFeatures: coquiNoLigatures,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(key),
          matchesGoldenFile('goldens/noche_fonts.png'),
        );

        // Direct pixel verification: heavier weights paint more non-ground pixels than lighter weights.
        Future<int> litPixels(String family, int weight, String sample) async {
          final probeKey = GlobalKey();
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: probeKey,
                  child: Container(
                    width: 360,
                    height: 60,
                    color: NocheColors.ground,
                    child: Text(
                      sample,
                      style: TextStyle(
                        inherit: false,
                        fontFamily: family,
                        package: coquiFontPackage,
                        fontWeight: FontWeight.values[weight ~/ 100 - 1],
                        fontSize: 28,
                        color: NocheColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          final px = await _capturePixels(tester, probeKey);
          final bg = px[0];
          var count = 0;
          for (final p in px) {
            if (p != bg) count++;
          }
          return count;
        }

        final atkinson400 = await litPixels(
          nocheFontAtkinson,
          400,
          'Coqui Noche',
        );
        final atkinson800 = await litPixels(
          nocheFontAtkinson,
          800,
          'Coqui Noche',
        );
        expect(atkinson400, greaterThan(100));
        expect(atkinson800, greaterThan(atkinson400));

        final arabic500 = await litPixels(
          nocheFontNotoSansArabic,
          500,
          'مَرْحَبًا',
        );
        final arabic700 = await litPixels(
          nocheFontNotoSansArabic,
          700,
          'مَرْحَبًا',
        );
        expect(arabic500, greaterThan(50));
        expect(arabic700, greaterThan(arabic500));
      },
    );
  });

  group('NocheType styles and forScript', () {
    test('every style in NocheType matches its exact spec and uses a bundled font file', () {
      final expected = <String, (String, FontWeight, double, double, double)>{
        'pageTitle': (nocheFontBricolage, FontWeight.w700, 24, 24, 0),
        'sheetTitle': (nocheFontBricolage, FontWeight.w700, 20, 24, 0),
        'bigNumber': (nocheFontBricolageDisplay, FontWeight.w800, 64, 64, 0),
        'statNumber': (nocheFontBricolageDisplay, FontWeight.w800, 56, 48, 0),
        'label': (nocheFontAtkinson, FontWeight.w600, 12, 12, 0.72),
        'labelStrong': (nocheFontAtkinson, FontWeight.w700, 12, 12, 0.72),
        'tabLabel': (nocheFontAtkinson, FontWeight.w600, 12, 12, 0),
        'tabLabelOn': (nocheFontAtkinson, FontWeight.w700, 12, 12, 0),
        'button': (nocheFontAtkinson, FontWeight.w600, 14, 14, 0),
        'buttonStrong': (nocheFontAtkinson, FontWeight.w700, 14, 14, 0),
        'primary': (nocheFontAtkinson, FontWeight.w700, 18, 18, 0),
        'primarySmall': (nocheFontAtkinson, FontWeight.w700, 17, 17, 0),
        'body': (nocheFontAtkinson, FontWeight.w500, 14, 20, 0),
        'bodySmall': (nocheFontAtkinson, FontWeight.w500, 13, 16, 0),
        'bodyLarge': (nocheFontAtkinson, FontWeight.w500, 16, 24, 0),
        'row': (nocheFontAtkinson, FontWeight.w600, 18, 24, 0),
        'cardTitle': (nocheFontAtkinson, FontWeight.w700, 22, 24, 0),
        'rowTitle': (nocheFontAtkinson, FontWeight.w700, 16, 20, 0),
        'placeTitle': (nocheFontAtkinson, FontWeight.w800, 32, 40, 0),
        'lessonLine': (nocheFontAtkinson, FontWeight.w600, 28, 36, 0),
        'lessonPrompt': (nocheFontAtkinson, FontWeight.w500, 18, 24, 0),
        'transcript': (nocheFontAtkinson, FontWeight.w500, 17, 24, 0),
        'transcriptNow': (nocheFontAtkinson, FontWeight.w700, 24, 32, 0),
        'bookTitle': (nocheFontLiterata, FontWeight.w600, 26, 32, 0),
        'bookBody': (nocheFontLiterata, FontWeight.w400, 19, 31, 0),
        'bookBodyAtkinson': (nocheFontAtkinson, FontWeight.w400, 19, 31, 0),
        'bookBodyLexend': (nocheFontLexend, FontWeight.w400, 19, 31, 0),
        'dropCap': (nocheFontLiterata, FontWeight.w600, 60, 52, 0),
        'cover': (nocheFontLiterata, FontWeight.w600, 13, 16, 0),
        'coverSmall': (nocheFontLiterata, FontWeight.w600, 10, 12, 0),
      };

      final all = NocheType.all;
      expect(all.keys, unorderedEquals(expected.keys));

      for (final entry in expected.entries) {
        final style = all[entry.key]!;
        final (family, weight, size, line, tracking) = entry.value;
        expect(style.inherit, isFalse, reason: entry.key);
        expect(
          style.fontFamily,
          equals('packages/coqui_ui/$family'),
          reason: entry.key,
        );
        expect(style.fontWeight, equals(weight), reason: entry.key);
        expect(style.fontSize, equals(size), reason: entry.key);
        expect(style.height, closeTo(line / size, 1e-9), reason: entry.key);
        expect(style.color, isNull, reason: entry.key);
        expect(style.letterSpacing, closeTo(tracking, 1e-9), reason: entry.key);
        expect(
          style.leadingDistribution,
          equals(TextLeadingDistribution.even),
          reason: entry.key,
        );
        expect(
          style.decoration,
          equals(TextDecoration.none),
          reason: entry.key,
        );
        expect(
          style.fontFeatures,
          containsAll(coquiNoLigatures),
          reason: entry.key,
        );
        expect(
          nocheFontFiles[family]?.containsKey(weight.value),
          isTrue,
          reason: '${entry.key} uses unbundled $family ${weight.value}',
        );
      }
    });

    test('primary and primarySmall include Noto Sans Arabic font fallback', () {
      expect(
        NocheType.primary.fontFamilyFallback,
        equals(['packages/coqui_ui/$nocheFontNotoSansArabic']),
      );
      expect(
        NocheType.primarySmall.fontFamilyFallback,
        equals(['packages/coqui_ui/$nocheFontNotoSansArabic']),
      );
    });

    testWidgets(
      'primary and primarySmall render Arabic glyphs alongside English via fallback',
      (tester) async {
        Future<int> litPixelsForStyle(TextStyle style, String sample) async {
          final probeKey = GlobalKey();
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: probeKey,
                  child: Container(
                    width: 360,
                    height: 60,
                    color: NocheColors.ground,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      sample,
                      style: style.copyWith(color: NocheColors.text),
                    ),
                  ),
                ),
              ),
            ),
          );
          final px = await _capturePixels(tester, probeKey);
          final bg = px[0];
          var count = 0;
          for (final p in px) {
            if (p != bg) count++;
          }
          return count;
        }

        for (final style in [NocheType.primary, NocheType.primarySmall]) {
          final englishOnly = await litPixelsForStyle(style, 'Back to ');
          final mixedArabic = await litPixelsForStyle(style, 'Back to تكلّم');
          expect(englishOnly, greaterThan(50));
          expect(mixedArabic, greaterThan(englishOnly + 50));
        }
      },
    );

    test('NocheType.forScript handles Latn, Arab, and unbundled scripts', () {
      expect(
        identical(
          NocheType.forScript(NocheType.lessonLine, 'Latn'),
          NocheType.lessonLine,
        ),
        isTrue,
      );

      final arabLine = NocheType.forScript(NocheType.lessonLine, 'Arab');
      expect(
        arabLine.fontFamily,
        equals('packages/coqui_ui/$nocheFontNotoSansArabic'),
      );
      expect(arabLine.fontSize, equals(30));
      expect(arabLine.height, closeTo(52 / 30, 1e-9));
      expect(arabLine.fontWeight, equals(FontWeight.w700));
      expect(arabLine.letterSpacing, equals(0));

      final arabPrompt = NocheType.forScript(NocheType.lessonPrompt, 'Arab');
      expect(
        arabPrompt.fontFamily,
        equals('packages/coqui_ui/$nocheFontNotoSansArabic'),
      );
      expect(arabPrompt.fontSize, equals(20));
      expect(arabPrompt.height, closeTo(36 / 20, 1e-9));
      expect(arabPrompt.fontWeight, equals(FontWeight.w500));
      expect(arabPrompt.letterSpacing, equals(0));

      for (final base in [
        NocheType.label,
        NocheType.labelStrong,
        NocheType.tabLabel,
        NocheType.tabLabelOn,
      ]) {
        final arab = NocheType.forScript(base, 'Arab');
        expect(arab.fontSize, equals(14));
        expect(arab.height, closeTo(24 / 14, 1e-9));
        expect(arab.fontWeight, equals(FontWeight.w700));
        expect(arab.letterSpacing, equals(0));
      }

      NocheType.unbundledScripts.clear();
      final reported = <String>[];
      NocheType.onUnbundledScript = reported.add;
      addTearDown(() => NocheType.onUnbundledScript = null);

      final cyrl = NocheType.forScript(NocheType.body, 'Cyrl');
      expect(cyrl.fontFamily, isNull);
      expect(cyrl.fontSize, equals(NocheType.body.fontSize));
      expect(cyrl.fontWeight, equals(NocheType.body.fontWeight));
      expect(NocheType.unbundledScripts, contains('Cyrl'));
      expect(reported, equals(['Cyrl']));
    });
  });

  group('NocheSize tokens', () {
    test('every size token matches its exact specification value', () {
      expect(NocheSize.touch, 48);
      expect(NocheSize.pill, 24);
      expect(NocheSize.pillRadius, 24);
      expect(NocheSize.card, 24);
      expect(NocheSize.cardRadius, 24);
      expect(NocheSize.tile, 16);
      expect(NocheSize.tileRadius, 16);
      expect(NocheSize.chip, 32);
      expect(NocheSize.chipHeight, 32);
      expect(NocheSize.chipRadius, 16);
      expect(NocheSize.tabBar, 64);
      expect(NocheSize.tabBarHeight, 64);
      expect(NocheSize.tabBarRadius, 32);
      expect(NocheSize.tabBarInset, 16);
      expect(NocheSize.primary, 56);
      expect(NocheSize.primaryHeight, 56);
      expect(NocheSize.primaryRadius, 28);
      expect(NocheSize.playBar, 72);
      expect(NocheSize.playBarHeight, 72);
      expect(NocheSize.playBarRadius, 36);
      expect(NocheSize.mic, 96);
      expect(NocheSize.disc, 64);
      expect(NocheSize.aboveTabBar, 104);
      expect(NocheSize.grid, 8);
    });
  });
}
