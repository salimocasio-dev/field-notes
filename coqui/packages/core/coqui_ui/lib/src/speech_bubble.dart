/// Lesson speech bubble and language-direction helpers.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/src/noche_tokens.dart';
import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// UI layout helpers for [LanguageDirection].
extension LanguageDirectionUi on LanguageDirection {
  /// Flutter [TextDirection] for this language direction.
  TextDirection get textDirection =>
      this == LanguageDirection.rtl ? TextDirection.rtl : TextDirection.ltr;
}

/// UI direction and locale helpers for [Language].
extension LanguageUi on Language {
  /// Flutter [TextDirection] for [Language.direction].
  TextDirection get textDirection => direction.textDirection;

  /// BCP-47 [Locale] for [Language.code].
  Locale get locale => Locale(code);
}

/// Which side of a [LessonSpeechBubble] holds the speech tail.
enum BubbleTailSide { bottom, start, end, none }

/// A speech bubble rendered in lesson or Noche styling, with script-aware type
/// and directional tail placement.
class LessonSpeechBubble extends StatelessWidget {
  const LessonSpeechBubble({
    super.key,
    required this.text,
    this.language,
    this.tailSide = BubbleTailSide.bottom,
    this.textAlign = TextAlign.start,
    this.maxWidth,
    this.dark = false,
  });

  final String text;
  final Language? language;
  final BubbleTailSide tailSide;
  final TextAlign textAlign;
  final double? maxWidth;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final textDirection =
        language?.textDirection ??
        Directionality.maybeOf(context) ??
        TextDirection.ltr;
    final script = language?.script ?? 'Latn';
    final locale = language?.locale;

    final baseStyle = dark
        ? NocheType.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: NocheColors.text,
          )
        : CoquiText.lessonCaption.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            height: 1.2,
            color: NocheColors.onAccent,
          );
    final style = NocheType.forScript(baseStyle, script);

    final fillColor = dark ? NocheColors.panel : CoquiColors.white;
    final borderColor = dark ? NocheColors.line : NocheColors.onAccent;
    final borderWidth = dark ? 1.5 : 3.0;

    final body = Container(
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: maxWidth!)
          : null,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 7),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        style: style,
      ),
    );

    final Widget? tail = switch (tailSide) {
      BubbleTailSide.bottom => PositionedDirectional(
        start: 0,
        end: 0,
        bottom: -9,
        child: Center(
          child: CustomPaint(
            size: const Size(16, 10),
            painter: _BubbleTailPainter(
              side: BubbleTailSide.bottom,
              fillColor: fillColor,
              borderColor: borderColor,
              borderWidth: borderWidth,
            ),
          ),
        ),
      ),
      BubbleTailSide.start => PositionedDirectional(
        start: -9,
        top: 0,
        bottom: 0,
        child: Center(
          child: Transform.flip(
            flipX: textDirection == TextDirection.rtl,
            child: CustomPaint(
              size: const Size(10, 16),
              painter: _BubbleTailPainter(
                side: BubbleTailSide.start,
                fillColor: fillColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
              ),
            ),
          ),
        ),
      ),
      BubbleTailSide.end => PositionedDirectional(
        end: -9,
        top: 0,
        bottom: 0,
        child: Center(
          child: Transform.flip(
            flipX: textDirection == TextDirection.rtl,
            child: CustomPaint(
              size: const Size(10, 16),
              painter: _BubbleTailPainter(
                side: BubbleTailSide.end,
                fillColor: fillColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
              ),
            ),
          ),
        ),
      ),
      BubbleTailSide.none => null,
    };

    return Directionality(
      textDirection: textDirection,
      child: Stack(clipBehavior: Clip.none, children: [body, ?tail]),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({
    required this.side,
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  final BubbleTailSide side;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPath = Path();
    final strokePath = Path();
    switch (side) {
      case BubbleTailSide.bottom:
        fillPath
          ..moveTo(borderWidth * 0.5, -borderWidth)
          ..lineTo(size.width - borderWidth * 0.5, -borderWidth)
          ..lineTo(size.width, 0.5)
          ..lineTo(size.width / 2, size.height - 0.5)
          ..lineTo(0, 0.5)
          ..close();
        strokePath
          ..moveTo(0, 0.5)
          ..lineTo(size.width / 2, size.height - 0.5)
          ..lineTo(size.width, 0.5);
      case BubbleTailSide.start:
        fillPath
          ..moveTo(size.width + borderWidth, borderWidth * 0.5)
          ..lineTo(size.width + borderWidth, size.height - borderWidth * 0.5)
          ..lineTo(size.width - 0.5, size.height)
          ..lineTo(0.5, size.height / 2)
          ..lineTo(size.width - 0.5, 0)
          ..close();
        strokePath
          ..moveTo(size.width - 0.5, 0)
          ..lineTo(0.5, size.height / 2)
          ..lineTo(size.width - 0.5, size.height);
      case BubbleTailSide.end:
        fillPath
          ..moveTo(-borderWidth, borderWidth * 0.5)
          ..lineTo(-borderWidth, size.height - borderWidth * 0.5)
          ..lineTo(0.5, size.height)
          ..lineTo(size.width - 0.5, size.height / 2)
          ..lineTo(0.5, 0)
          ..close();
        strokePath
          ..moveTo(0.5, 0)
          ..lineTo(size.width - 0.5, size.height / 2)
          ..lineTo(0.5, size.height);
      case BubbleTailSide.none:
        return;
    }

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      strokePath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) =>
      old.side != side ||
      old.fillColor != fillColor ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth;
}
