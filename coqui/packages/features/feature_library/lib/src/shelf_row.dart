/// A row of the shelf and its buttons, as `.bk` and `.btn` draw them in app.html:97-101.
///
/// coqui_ui's `ShelfRow` and `CoquiButton` come close, but not on a phone: the cover is as tall as
/// its picture (72 wide, the book's first page at 196:216, so 79 high: `.cov img{height:auto}`), the
/// buttons have 12 px of side padding and 6 px between the icon and the label under 420 px (and 10
/// px, a 12 px gap and a 64 px cover under 380), and Read carries a green check once the book was
/// read. Request 22-feature-library-needs-coqui-ui-shelf-row-phone.
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
  });

  final String label;
  final CoquiIconData icon;
  final ShelfButtonKind kind;
  final VoidCallback onPressed;
  final String semanticLabel;

  /// The green check after the label (`<span class="okc">✓</span>`), drawn as an icon.
  final bool check;

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
              width: CoquiMetrics.borderButton,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CoquiIcon(icon, size: 20, color: fg),
              SizedBox(width: gap(width)),
              Flexible(child: Text(label, style: style)),
              if (check) ...[
                // `<span class="okc">✓</span>`: a green check after the label, the button's gap away; drawn, not a glyph,
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

/// `.bk`: a cover (72 px wide, the picture at its own height, at least 72 high, 8 px corners, a 1 px ring,
/// grey until it has a picture), the title, a grey line, the buttons under them; 16 px above and below and 16 apart (12 under 380 px).
class ShelfEntry extends StatelessWidget {
  const ShelfEntry({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.cover,
  });

  final String title;
  final String subtitle;

  /// The picture drawn 72 wide (64 under 380 px) with the aspect it has, or null for the grey tile.
  final Widget? cover;
  final List<Widget> actions;

  /// `.cov{width:72px}`, 64 under 380 px. app.html:98, 101
  static double coverWidth(double width) =>
      width <= 380 ? CoquiMetrics.coverSmall : CoquiMetrics.cover;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cw = coverWidth(width);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoquiMetrics.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: cw,
            constraints: BoxConstraints(minHeight: cw),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: CoquiColors.coverFill,
              borderRadius: BorderRadius.circular(CoquiMetrics.radiusPicture),
              boxShadow: const [
                BoxShadow(color: CoquiColors.line, spreadRadius: 1),
              ],
            ),
            child: cover,
          ),
          SizedBox(width: width <= 380 ? 12 : CoquiMetrics.s16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CoquiText.rowBold),
                Text(subtitle, style: CoquiText.smallMuted),
                Padding(
                  padding: const EdgeInsets.only(top: CoquiMetrics.s8),
                  child: Wrap(
                    spacing: CoquiMetrics.s16,
                    runSpacing: CoquiMetrics.s8,
                    children: actions,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
