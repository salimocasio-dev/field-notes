/// One line of a page of a book: a button the width of the page, the line as recorded, a small speaker.
/// app.html:373-377 (`lineaEl`), 114-119 (`.lbl`, `.bw`).
library;

import 'dart:ui' as ui;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/press.dart';
import 'package:feature_library/src/word_marks.dart';
import 'package:material_ui/material_ui.dart';

/// A line of a story file (`T.clips[id]`): who says it, and what.
class BookLine {
  const BookLine({required this.id, required this.who, required this.text});

  /// `{who, text}` of the story file's clip entry.
  factory BookLine.fromJson(String id, Map<String, dynamic> j) => BookLine(
    id: id,
    who: j['who'] as String? ?? '',
    text: j['text'] as String? ?? '',
  );

  final String id;

  /// "tu" is the coqui.
  final String who;
  final String text;
}

/// `.lbl` side padding and the gap to the speaker, `.spk` width. app.html:114, 116
abstract final class BookLineMetrics {
  static const double padX = 12;
  static const double padY = 9;
  static const double gap = 12;
  static const double speaker = 24;
  static const double minHeight = 48;
  static const double whoHeight = 16;

  /// The width the text has in a line [lineWidth] wide.
  static double textWidth(double lineWidth) =>
      lineWidth - padX - padX - gap - speaker;
}

/// What a tap on a line meant: the word that has a picture under it (its index in the picture words), or none.
typedef LineTap = void Function(String id, int? k);

/// `.lbl`: the whole line is the target. [lit] is `.now` (the line playing); [underlined] is the picture word
/// whose places on the page are underlined for a moment (`.bw.uw`).
class BookLineView extends StatefulWidget {
  const BookLineView({
    super.key,
    required this.line,
    required this.marks,
    required this.big,
    required this.lit,
    required this.underlined,
    required this.onTap,
  });

  final BookLine line;
  final List<WordMark> marks;

  /// 24 on 36 instead of 20 on 30.
  final bool big;
  final bool lit;
  final int? underlined;
  final LineTap onTap;

  @override
  State<BookLineView> createState() => _BookLineViewState();
}

class _BookLineViewState extends State<BookLineView> {
  final GlobalKey _textKey = GlobalKey();

  TextStyle get _style =>
      widget.big ? CoquiText.bookLineBig : CoquiText.bookLine;

  // the text, in pieces: the words that have a picture are their own spans
  TextSpan _span() {
    final text = widget.line.text;
    final parts = <InlineSpan>[];
    var pos = 0;
    for (final m in widget.marks) {
      if (m.start > pos) {
        parts.add(TextSpan(text: text.substring(pos, m.start)));
      }
      parts.add(TextSpan(text: text.substring(m.start, m.end)));
      pos = m.end;
    }
    if (pos < text.length) parts.add(TextSpan(text: text.substring(pos)));
    return TextSpan(style: _style, children: parts);
  }

  // `txt.onclick`: a tap on a word that has a picture shows its card; a tap anywhere else on the line plays the line
  void _tapUp(TapUpDetails d) {
    int? hit;
    final box = _textKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      final local = box.globalToLocal(d.globalPosition);
      hit = pictureWordAt(
        span: _span(),
        width: box.size.width,
        marks: widget.marks,
        at: local,
        textScaler: MediaQuery.textScalerOf(context),
      );
    }
    widget.onTap(widget.line.id, hit);
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final span = _span();
    final who = widget.line.who == 'tu';
    return PressTarget(
      onPressed: null,
      onTapUp: _tapUp,
      semanticLabel: widget.line.text,
      builder: (context, pressed) => CustomPaint(
        painter: _LitPainter(lit: widget.lit, pressed: pressed),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: BookLineMetrics.minHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BookLineMetrics.padX,
              vertical: BookLineMetrics.padY,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (who)
                        SizedBox(
                          height: BookLineMetrics.whoHeight,
                          child: Text(
                            CoquiLabels.appName,
                            style: CoquiText.bookWho,
                          ),
                        ),
                      CustomPaint(
                        painter: _MarksPainter(
                          span: span,
                          marks: widget.marks,
                          solid: widget.underlined,
                          textScaler: scaler,
                        ),
                        child: RichText(
                          key: _textKey,
                          text: span,
                          textScaler: scaler,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BookLineMetrics.gap),
                SizedBox.square(
                  dimension: BookLineMetrics.speaker,
                  child: Center(
                    child: CoquiIcon(
                      CoquiIcons.volume,
                      size: 20,
                      color: widget.lit
                          ? CoquiColors.bookLineLitBar
                          : CoquiColors.bookSpeaker,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.lbl.now{background:#245A3B;box-shadow:inset 4px 0 0 #3DDC84}` and `.lbl:active{background:#2A2A32}`, in a 12 px rounded box.
class _LitPainter extends CustomPainter {
  _LitPainter({required this.lit, required this.pressed});
  final bool lit;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    if (lit) {
      canvas.drawRRect(box, Paint()..color = CoquiColors.bookLineLit);
      // an inset shadow 4 px to the right: the part of the box that the box moved 4 px right leaves bare
      final inner = box.shift(const Offset(4, 0));
      final bar = Path.combine(
        PathOperation.difference,
        Path()..addRRect(box),
        Path()..addRRect(inner),
      );
      canvas.drawPath(bar, Paint()..color = CoquiColors.bookLineLitBar);
    } else if (pressed) {
      canvas.drawRRect(box, Paint()..color = CoquiColors.bookLinePressed);
    }
  }

  @override
  bool shouldRepaint(_LitPainter old) =>
      old.lit != lit || old.pressed != pressed;
}

/// The faint dotted line under a word that has a picture (`.bw`), solid green and thicker for a moment after a tap (`.bw.uw`).
/// The line starts 5 px under the baseline (`text-underline-offset:5px`); the dots are 2 px, 4 px apart, as Chrome draws a 1.5 px dotted line.
class _MarksPainter extends CustomPainter {
  _MarksPainter({
    required this.span,
    required this.marks,
    required this.solid,
    required this.textScaler,
  });

  final TextSpan span;
  final List<WordMark> marks;
  final int? solid;
  final TextScaler textScaler;

  /// `text-underline-offset`. app.html:118
  static const double offset = 5;

  /// `text-decoration-thickness` of `.bw.uw`. app.html:119
  static const double solidThickness = 3;

  /// Chrome's dotted dots (see the reference pictures: 6 device px at 3x, 5.5 at 2.625x).
  static const double dot = 2;

  /// `rgba(255,255,255,.45)`. app.html:118
  static const Color dotted = Color(0x73FFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (marks.isEmpty) return;
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: size.width);
    for (final u in markUnderlines(tp, marks, solid)) {
      if (u.solid) {
        canvas.drawRect(u.rect, Paint()..color = CoquiColors.bookLineLitBar);
      } else {
        final paint = Paint()..color = dotted;
        for (var x = u.rect.left; x < u.rect.right; x += 2 * dot) {
          final r = x + dot > u.rect.right ? u.rect.right : x + dot;
          canvas.drawRect(
            Rect.fromLTRB(x, u.rect.top, r, u.rect.bottom),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MarksPainter old) =>
      old.span != span ||
      old.solid != solid ||
      old.textScaler != textScaler ||
      !_same(old.marks, marks);

  static bool _same(List<WordMark> a, List<WordMark> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One line under a word that has a picture: where it is, and whether it is the solid green one.
class MarkUnderline {
  const MarkUnderline(this.rect, {required this.solid});

  /// The line itself: as wide as the word's letters, 2 px high when dotted, 3 px when solid; its top 5 px under the baseline.
  final Rect rect;
  final bool solid;
}

/// The underlines of [marks] in the laid-out text [tp]: one for each line a word is on; [solid] is the picture word that
/// has been tapped (`.bw.uw`), the others are dotted (`.bw`).
List<MarkUnderline> markUnderlines(
  TextPainter tp,
  List<WordMark> marks,
  int? solid,
) {
  final lines = tp.computeLineMetrics();
  final out = <MarkUnderline>[];
  for (final m in marks) {
    final isSolid = m.k == solid;
    for (final b in markBoxes(tp, m)) {
      var base = b.bottom;
      for (final l in lines) {
        if (l.baseline >= b.top - 0.5 && l.baseline <= b.bottom + 0.5) {
          base = l.baseline;
          break;
        }
      }
      final top = base + _MarksPainter.offset;
      out.add(
        MarkUnderline(
          Rect.fromLTRB(
            b.left,
            top,
            b.right,
            top + (isSolid ? _MarksPainter.solidThickness : _MarksPainter.dot),
          ),
          solid: isSolid,
        ),
      );
    }
  }
  return out;
}

/// The boxes a mark's letters take, one for each line the word is on (as tight as the glyphs' own height).
List<TextBox> markBoxes(TextPainter tp, WordMark m) => tp.getBoxesForSelection(
  TextSelection(baseOffset: m.start, extentOffset: m.end),
  boxHeightStyle: ui.BoxHeightStyle.tight,
);

/// The index (`data-k`) of the picture word under [at], a point in the text's box, or null.
int? pictureWordAt({
  required TextSpan span,
  required double width,
  required List<WordMark> marks,
  required Offset at,
  required TextScaler textScaler,
}) {
  if (marks.isEmpty) return null;
  final tp = TextPainter(
    text: span,
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(maxWidth: width);
  for (final m in marks) {
    for (final b in markBoxes(tp, m)) {
      if (b.toRect().contains(at)) return m.k;
    }
  }
  return null;
}
