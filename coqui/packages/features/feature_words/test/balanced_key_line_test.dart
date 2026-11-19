// app.html: `.keyl{text-wrap:balance}`, the key line under the first place title.
import 'package:feature_words/src/balanced_key_line.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _style = TextStyle(
  inherit: false,
  fontFamily:
      'Ahem', // flutter_test's font: every letter is a square of the font size
  fontSize: 10,
  height: 1,
);

/// Puts [child] in a box [width] wide and reads the width of each line of the paragraph it draws.
Future<List<double>> _lineWidths(
  WidgetTester tester,
  Widget child,
  double width,
  int length,
) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
  final p = tester.renderObject<RenderParagraph>(find.byType(RichText));
  return [
    for (final b in p.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: length),
    ))
      b.right - b.left,
  ];
}

Future<List<double>> _balanced(
  WidgetTester tester,
  String text,
  double width,
) => _lineWidths(tester, BalancedText(text, style: _style), width, text.length);

Future<List<double>> _plain(WidgetTester tester, String text, double width) =>
    _lineWidths(tester, Text(text, style: _style), width, text.length);

void main() {
  testWidgets('a text that fits on a line is left as it is', (tester) async {
    final lines = await _balanced(tester, 'aa bb cc', 200);
    expect(lines, hasLength(1));
    expect(
      tester.getSize(find.byType(Text)).width,
      200,
      reason: 'no narrowing: the text takes the width it is given',
    );
  });

  testWidgets(
    'a text that wraps comes out in lines of even length (a plain Text leaves a stub)',
    (tester) async {
      // six two-letter words, 20 px each and 10 px between: 170 px in all, and 150 px to put them in
      final lines = await _balanced(tester, 'aa bb cc dd ee ff', 150);
      expect(lines, hasLength(2));
      expect(lines[0], closeTo(90, 0.5)); // aa bb cc and its space
      expect(lines[1], closeTo(80, 0.5)); // dd ee ff
      // the same text in a plain Text: five words (with the space after the fifth) and a stub of one
      expect(
        (await _plain(tester, 'aa bb cc dd ee ff', 150)).map((w) => w.round()),
        [150, 20],
      );
    },
  );

  testWidgets('it never needs more lines than a plain Text does', (
    tester,
  ) async {
    const text = 'aaa bbbbb cc dddd ee fffffff g';
    for (final w in [80.0, 90.0, 120.0, 150.0, 400.0]) {
      final balanced = await _balanced(tester, text, w);
      final plain = await _plain(tester, text, w);
      expect(balanced.length, plain.length, reason: 'width $w');
      expect(
        balanced.fold<double>(0, (a, b) => a > b ? a : b),
        lessThanOrEqualTo(plain.fold<double>(0, (a, b) => a > b ? a : b)),
        reason: 'width $w',
      );
    }
  });

  test(
    'the key line is a block with the margins of .keyl: -8 above, 16 below',
    () {
      const k = BalancedKeyLine('x');
      expect((k.marginTop, k.marginBottom), (-8, 16));
    },
  );
}
