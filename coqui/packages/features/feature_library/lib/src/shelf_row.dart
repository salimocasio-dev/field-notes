/// A row of the shelf, its Read button, its cover, and the "Hear next" card at the top of the shelf.
///
/// The shelf row has one user, this feature, so it lives here (decided; coqui_ui no longer has a `ShelfRow`).
/// Order 27 (the Biblioteca redesign) made the row compact: the cover (the book's first page, 56 wide at its own
/// 196:216 aspect) at the left, the title and a grey line, Listen as the quiet play disc at the right (the place
/// sheet's `.pb.o`: the screen's one green thing is the "Hear next" card's Listen), and Read, only on a book that
/// reads well, under the grey line. A story with no picture (a routine, or a picture that does not load) gets a plain
/// tile with a speaker, never an empty grey square.
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/press.dart';
import 'package:material_ui/material_ui.dart';

/// Which of the two `.btn`s: Listen is green (`.go`), Read the outline.
enum ShelfButtonKind { go, outline }

/// `.bk .btn`: 48 px high at least, 12 px corners, a 1.5 px border, the label 16 px semibold, an icon 20 px before it.
class ShelfButton extends StatelessWidget {
  const ShelfButton({
    super.key,
    required this.label,
    required this.icon,
    required this.kind,
    required this.onPressed,
    required this.semanticLabel,
    this.check = false,
    this.full = false,
  });

  final String label;
  final CoquiIconData icon;
  final ShelfButtonKind kind;
  final VoidCallback onPressed;
  final String semanticLabel;

  /// The green check after the label (the old page's `okc` span), drawn as an icon.
  final bool check;

  /// As wide as it is given, the label in the middle (the "Hear next" card's buttons).
  final bool full;

  /// `.bk .btn{padding:0 16px}`, 12 under 420 px, 10 under 380. app.html:99-101
  static double padX(double width) => width <= 380
      ? 10
      : width <= 420
      ? 12
      : 16;

  /// `.btn{gap:8px}`, 6 under 420 px. app.html:22, 100
  static double gap(double width) => width <= 420 ? 6 : 8;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final go = kind == ShelfButtonKind.go;
    final style = go ? CoquiText.button : CoquiText.buttonOutline;
    final fg = style.color!;
    return PressTarget(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.98 : 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: CoquiMetrics.targetMin),
          padding: EdgeInsets.symmetric(horizontal: padX(width)),
          decoration: BoxDecoration(
            color: go ? CoquiColors.ok : null,
            borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
            border: Border.all(
              color: go ? const Color(0x00000000) : CoquiColors.line2,
              width: CoquiLayout.border(context, CoquiMetrics.borderButton),
            ),
          ),
          child: Row(
            mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CoquiIcon(icon, size: 20, color: fg),
              SizedBox(width: gap(width)),
              Flexible(child: Text(label, style: style)),
              if (check) ...[
                // the old page's `okc` span: a green check after the label, the button's gap away; drawn, not a glyph,
                // so that it looks the same on every device (a font's own check differs)
                SizedBox(width: gap(width)),
                // the glyph's own width is 13 px (it sets how wide the button is); the drawn check is 12 px wide, in the middle of it
                SizedBox(
                  width: 13,
                  height: 20,
                  child: OverflowBox(
                    maxWidth: 20,
                    maxHeight: 20,
                    child: CoquiIcon(
                      CoquiIcons.check,
                      size: 20,
                      color: CoquiColors.ok,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A book's cover: the picture (the book's first page) [width] wide at its own aspect (196:216), 8 px corners, a 1 px
/// ring; or, with no picture, the plain tile: the cover's warm grey with a speaker in the middle (something to hear,
/// not an empty box).
class ShelfCover extends StatelessWidget {
  const ShelfCover({super.key, required this.width, this.picture});

  /// The cover's width; its height follows the page's aspect.
  final double width;

  /// The picture, or null for the plain tile.
  final Widget? picture;

  /// A book page is 196 x 216 picture pixels (historia/libros/img).
  static const double aspect = 196 / 216;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: width / aspect,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: CoquiColors.coverFill,
      borderRadius: BorderRadius.circular(CoquiMetrics.radiusPicture),
      boxShadow: const [BoxShadow(color: CoquiColors.line, spreadRadius: 1)],
    ),
    child:
        picture ??
        Center(
          child: CoquiIcon(
            CoquiIcons.volume,
            size: width >= 72 ? 32 : 24,
            color: CoquiColors.dotOutline,
          ),
        ),
  );
}

/// [line] with the spaces inside each of its parts made non-breaking, so that it wraps only between parts.
String keepTogether(String line) =>
    line.split(' · ').map((p) => p.replaceAll(' ', ' ')).join(' · ');

/// A grey line that wraps only between its parts ("Cuento con dibujos · about 2 min" never leaves "min" alone on a
/// line). A line that fits is drawn as it is written.
class GreyLine extends StatelessWidget {
  const GreyLine(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout(maxWidth: c.maxWidth);
      final fits = !tp.didExceedMaxLines;
      tp.dispose();
      return Text(fits ? text : keepTogether(text), style: style);
    },
  );
}

/// One row of the shelf: the cover, the title and its grey line, Read under them when the book reads well, and
/// Listen (the quiet play disc) at the right. 12 px above and below.
class ShelfEntry extends StatelessWidget {
  const ShelfEntry({
    super.key,
    required this.title,
    required this.subtitle,
    required this.listen,
    this.read,
    this.cover,
  });

  final String title;
  final String subtitle;

  /// The picture drawn [coverWidth] wide, or null for the plain tile.
  final Widget? cover;

  /// The Listen control (the quiet play disc).
  final Widget listen;

  /// The Read button, only for a book that reads well.
  final Widget? read;

  /// The cover's width: 56 at every phone width (an 8-point size; about seven rows fit a 390 x 844 screen).
  static const double coverWidth = 56;

  @override
  Widget build(BuildContext context) {
    const coverHeight = coverWidth / ShelfCover.aspect;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoquiMetrics.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShelfCover(width: coverWidth, picture: cover),
          const SizedBox(width: CoquiMetrics.s12),
          Expanded(
            child: ConstrainedBox(
              // a short title and its line sit in the middle of the cover's height
              constraints: const BoxConstraints(minHeight: coverHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CoquiText.rowBold),
                  GreyLine(subtitle, style: CoquiText.smallMuted),
                  if (read != null)
                    Padding(
                      padding: const EdgeInsets.only(top: CoquiMetrics.s8),
                      child: read,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: CoquiMetrics.s12),
          // the disc in the middle of the cover's height
          Padding(
            padding: const EdgeInsets.only(
              top: (coverHeight - CoquiMetrics.playDisc) / 2,
            ),
            child: listen,
          ),
        ],
      ),
    );
  }
}

/// The card at the top of the shelf: the one story to hear next, with the screen's one green button.
/// An eyebrow, a larger cover (80 wide), the title (18 semibold), a grey line saying why, then Listen and, for a book
/// that reads well, Read beside it, the two sharing the width.
class ShelfNextCard extends StatelessWidget {
  const ShelfNextCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.listen,
    this.read,
    this.cover,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? cover;

  /// The green Listen button.
  final Widget listen;

  /// The Read button, only for a book that reads well.
  final Widget? read;

  static const double coverWidth = 80;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShelfCover(width: coverWidth, picture: cover),
          const SizedBox(width: CoquiMetrics.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EyebrowLabel(eyebrow),
                const SizedBox(height: CoquiMetrics.s4),
                Text(title, style: CoquiText.todayTitle),
                GreyLine(subtitle, style: CoquiText.todaySub),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: CoquiMetrics.s16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: listen),
          if (read != null) ...[
            const SizedBox(width: CoquiMetrics.s16),
            Expanded(child: read!),
          ],
        ],
      ),
    ],
  );
}
