import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_ui/coqui_ui.dart';
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
      expect(declared.values.toSet().length, 4);
      expect(declared[600], 'fonts/Roboto-SemiBold.ttf');
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
        expect(
          _weightClass(File(declared[weight]!).readAsBytesSync()),
          weight,
          reason: '${e.key}: the file for $weight',
        );
      }
      expect(all.values.where((s) => s.fontWeight!.value == 600), isNotEmpty);
    });

    test('the weights the tokens use', () {
      final used = {for (final s in CoquiText.all.values) s.fontWeight!.value};
      expect(used, {400, 500, 600, 700});
    });

    test('Pixelify Sans is removed from pubspec and fonts/', () {
      expect(
        lines.any((l) => l.contains('Pixelify')),
        isFalse,
        reason: 'Pixelify Sans has zero remaining callers (N1.4 / #82)',
      );
      expect(File('fonts/PixelifySans-Regular.ttf').existsSync(), isFalse);
      expect(File('fonts/PixelifySans-Bold.ttf').existsSync(), isFalse);
    });
  });

  group('hairlines: a CSS border as Chrome draws it', () {
    test('1 px, 1.5 px and 4 px at ratio 2.625 and 3', () {
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
}
