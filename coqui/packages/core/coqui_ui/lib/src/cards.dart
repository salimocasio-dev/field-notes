/// Cards, rows, headings and small controls of the light screens (app.html:15-33,
/// 54-58, 96-101, 130-132).
library;

import 'package:coqui_ui/src/buttons.dart';
import 'package:coqui_ui/src/icons.dart';
import 'package:coqui_ui/src/layout.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// A block with margins, as CSS has them: the vertical margins of two blocks in
/// a row do not add, they collapse: the gap is the larger of the two (a negative
/// one is taken off). A [CollapsingColumn] (and so a [TabPage]) lays its
/// [BlockWidget]s out that way; anywhere else a block draws its own margins.
abstract class BlockWidget extends StatelessWidget {
  const BlockWidget({super.key});

  /// The margin above, in px (may be negative inside a [CollapsingColumn]).
  double get marginTop;

  /// The margin below.
  double get marginBottom;

  /// The block itself, without its margins.
  Widget get content;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: marginTop < 0 ? 0 : marginTop,
      bottom: marginBottom < 0 ? 0 : marginBottom,
    ),
    child: content,
  );
}

/// Any widget with CSS-style vertical margins.
class Block extends BlockWidget {
  const Block({super.key, this.top = 0, this.bottom = 0, required this.child});
  final double top;
  final double bottom;
  final Widget child;

  @override
  double get marginTop => top;
  @override
  double get marginBottom => bottom;
  @override
  Widget get content => child;
}

/// A column that collapses the margins between its [BlockWidget] children the way
/// CSS block layout does: `.card{margin:0 0 16px}` above `h2{margin:24px 0 16px}`
/// leaves 24 px, not 40. Other children have no margins.
class CollapsingColumn extends StatelessWidget {
  const CollapsingColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    double? prevBottom;
    for (final child in children) {
      final top = child is BlockWidget ? child.marginTop : 0.0;
      final bottom = child is BlockWidget ? child.marginBottom : 0.0;
      final gap = prevBottom == null
          ? (top < 0 ? 0.0 : top)
          : _collapse(prevBottom, top);
      if (gap > 0) items.add(SizedBox(height: gap));
      items.add(child is BlockWidget ? child.content : child);
      prevBottom = bottom;
    }
    if (prevBottom != null && prevBottom > 0) {
      items.add(SizedBox(height: prevBottom));
    }
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }

  /// Adjoining margins: the largest positive plus the most negative.
  static double _collapse(double a, double b) {
    final pos = [a, b, 0.0].reduce((x, y) => x > y ? x : y);
    final neg = [a, b, 0.0].reduce((x, y) => x < y ? x : y);
    final gap = pos + neg;
    return gap < 0 ? 0 : gap;
  }
}

/// A tab's page: scrolls, 16 px side padding, at most 560 px wide and centred,
/// with room at the foot so the raised Mapa disc never covers content
/// (`.tab`: `padding:16px 16px calc(var(--navh) + safe + 68px)`). Its children
/// are laid out with CSS margins ([CollapsingColumn]). app.html:15
class TabPage extends StatelessWidget {
  const TabPage({super.key, required this.children, this.controller});

  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CoquiMetrics.columnMax),
      child: SingleChildScrollView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
          CoquiMetrics.s16,
          CoquiMetrics.s16,
          CoquiMetrics.s16,
          CoquiLayout.tabPageFoot(context),
        ),
        child: CollapsingColumn(children: children),
      ),
    ),
  );
}

/// `h1`: a screen's title, 24/32 semibold, 8 px above and 16 below. app.html:17
class ScreenTitle extends BlockWidget {
  const ScreenTitle(this.text, {super.key});
  final String text;

  @override
  double get marginTop => CoquiMetrics.s8;
  @override
  double get marginBottom => CoquiMetrics.s16;
  @override
  Widget get content => Text(text, style: CoquiText.h1);
}

/// `h2`: a section's title, 18/24 medium, 24 px above and 16 below. app.html:18
class SectionTitle extends BlockWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  double get marginTop => CoquiMetrics.s24;
  @override
  double get marginBottom => CoquiMetrics.s16;
  @override
  Widget get content => Text(text, style: CoquiText.h2);
}

/// `.keyl`: the one grey line under a section title (`.small.mut`, `margin:-8px 0
/// 16px`: 8 px under the title). app.html:91
class KeyLine extends BlockWidget {
  const KeyLine(this.text, {super.key});
  final String text;

  @override
  double get marginTop => -CoquiMetrics.s8;
  @override
  double get marginBottom => CoquiMetrics.s16;
  @override
  Widget get content => Text(text, style: CoquiText.smallMuted);
}

/// A picture in its frame: rounded corners ([radius] 8, or 12 for the word
/// sheet's big picture) on the `#222` that shows behind a picture. Whole-number
/// scaled pictures go inside it. app.html:95, 112; cual.html:30
class PictureFrame extends StatelessWidget {
  const PictureFrame({
    super.key,
    required this.child,
    this.radius = CoquiMetrics.radiusPicture,
    this.background = CoquiColors.pictureBack,
  });
  final Widget child;
  final double radius;
  final Color background;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: ColoredBox(color: background, child: child),
  );
}

/// `.lab`: a 12 px eyebrow above a title: medium, secondary, upper case, letters
/// spaced .02em. The text is upcased here. app.html:19
class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: CoquiText.label);
}

/// `.card`: white, 16 px corners, 16 px padding, a 1 px ring and a faint shadow,
/// 16 px of space under it. app.html:20
class CoquiCard extends BlockWidget {
  const CoquiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CoquiMetrics.s16),
    this.marginBottom = CoquiMetrics.s16,
    this.disabled = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  final double marginBottom;

  /// `.cc.lk`: a locked card, grey (`#F2F1EC`), a ring and no shadow. app.html:132
  final bool disabled;

  @override
  double get marginTop => 0;

  @override
  Widget get content => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: disabled ? CoquiColors.disabledFill : CoquiColors.card,
      borderRadius: BorderRadius.circular(CoquiMetrics.radiusCard),
      boxShadow: disabled
          ? const [BoxShadow(color: CoquiColors.line, spreadRadius: 1)]
          : CoquiShadows.card,
    ),
    child: child,
  );
}

/// `.row`: children in a line, centred, 16 px apart, at least 56 px high. app.html:21
class CoquiRow extends StatelessWidget {
  const CoquiRow({super.key, required this.children, this.minHeight = 56});
  final List<Widget> children;
  final double minHeight;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: minHeight),
    child: Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: CoquiMetrics.s16),
          children[i],
        ],
      ],
    ),
  );
}

/// `.row + .row` / `.li + .li`: a 1 px `--line` between rows. app.html:21, 29
class RowDivider extends StatelessWidget {
  const RowDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 1, child: ColoredBox(color: CoquiColors.line));
}

/// Puts a [RowDivider] between [rows].
class DividedRows extends StatelessWidget {
  const DividedRows({super.key, required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) const RowDivider(),
        rows[i],
      ],
    ],
  );
}

/// `.li`: a list row: a title and a grey line (a [Widget], e.g. built with
/// [CoquiText.smallMuted]) on the left, an optional control on the right (a
/// [PlayButton]); at least 64 px high, 8 px above and below, 16 px between. A tap
/// anywhere on a row that has [onTap] (`.li.rd`). app.html:29
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  /// The title: a [ListRowTitle] (bold, `<b>`), or any text.
  final Widget title;

  /// The grey line under it (`small mut`).
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: CoquiMetrics.listRowMin),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CoquiMetrics.s8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null)
                    DefaultTextStyle(
                      style: CoquiText.smallMuted,
                      child: subtitle!,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: CoquiMetrics.s16),
              trailing!,
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Pressable(onPressed: onTap, builder: (context, pressed) => row);
  }
}

/// The bold title of a [ListRow] (`<b>`, 16 px, 700). app.html:29
class ListRowTitle extends StatelessWidget {
  const ListRowTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: CoquiText.rowBold);
}

/// `.bk`: a row of the shelf: a cover (72 px, 8 px corners, a 1 px ring, grey
/// until it has a picture), the title, a grey line, and the buttons under them,
/// 8 px above and 16 apart; 16 px above and below. app.html:97-99
class ShelfRow extends StatelessWidget {
  const ShelfRow({
    super.key,
    required this.title,
    this.subtitle,
    this.cover,
    this.actions = const [],
    this.coverSize = CoquiMetrics.cover,
  });

  final String title;
  final String? subtitle;

  /// The cover's picture, or null for the grey tile. It is drawn
  /// [coverSize] wide.
  final Widget? cover;
  final List<Widget> actions;

  /// 72, or 64 on a 360 px phone (`@media (max-width:380px)`). app.html:101
  final double coverSize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CoquiMetrics.s16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: coverSize,
          height: coverSize,
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
        const SizedBox(width: CoquiMetrics.s16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: CoquiText.rowBold),
              if (subtitle != null)
                Text(subtitle!, style: CoquiText.smallMuted),
              if (actions.isNotEmpty)
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

/// `.play`: the Today card. The whole card is the button: at least 80 px high, 16
/// px padding, 16 px corners, white, a deep soft shadow; the green 48 px disc, then
/// an eyebrow (12 px upper case), the title (18 semibold) and a grey line (14). app.html:54-58
class TodayCard extends StatelessWidget {
  const TodayCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  /// e.g. `Today · 1 of 6`; upcased by the widget.
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    builder: (context, pressed) => Transform.scale(
      scale: pressed ? 0.98 : 1,
      child: Container(
        constraints: const BoxConstraints(minHeight: CoquiMetrics.todayMin),
        padding: const EdgeInsets.all(CoquiMetrics.s16),
        decoration: BoxDecoration(
          color: CoquiColors.white,
          borderRadius: BorderRadius.circular(CoquiMetrics.radiusCard),
          boxShadow: CoquiShadows.today,
        ),
        child: Row(
          children: [
            Container(
              width: CoquiMetrics.playDisc,
              height: CoquiMetrics.playDisc,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CoquiColors.ok,
              ),
              child: const CoquiIcon(CoquiIcons.play, color: CoquiColors.white),
            ),
            const SizedBox(width: CoquiMetrics.s16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow.toUpperCase(), style: CoquiText.eyebrow),
                  Text(title, style: CoquiText.todayTitle),
                  Text(subtitle, style: CoquiText.todaySub),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A stat of Yo: a card with a big number and a grey word under it, centred, no
/// space under it (the grid puts 16 px between). app.html:472
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => CoquiCard(
    marginBottom: 0,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: CoquiText.stat, textAlign: TextAlign.center),
        Text(label, style: CoquiText.smallMuted, textAlign: TextAlign.center),
      ],
    ),
  );
}

/// `.seg`: pills in a row of equal width, 16 px apart; the chosen one is blue
/// with white text, the others have a 1.5 px ring. 48 px high, 12 px corners.
/// app.html:31
class SegmentedPills extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;

  /// The chosen index, or -1.
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < labels.length; i++) ...[
        if (i > 0) const SizedBox(width: CoquiMetrics.s16),
        Expanded(
          child: Pressable(
            onPressed: () => onSelected(i),
            selected: i == selected,
            builder: (context, pressed) {
              final on = i == selected;
              return Container(
                height: CoquiMetrics.targetMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? CoquiColors.info : null,
                  borderRadius: BorderRadius.circular(
                    CoquiMetrics.radiusButton,
                  ),
                  border: Border.all(
                    color: on ? CoquiColors.info : CoquiColors.line2,
                    width: CoquiMetrics.borderButton,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: CoquiText.segment.copyWith(
                    color: on ? CoquiColors.white : CoquiColors.ink,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ],
  );
}

/// `.sw`: a switch. A 52 x 48 touch target holding a 52 x 32 track (grey, green
/// when on) and a 24 px white knob that slides in 150 ms. app.html:32-33
class CoquiSwitch extends StatelessWidget {
  const CoquiSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onChanged == null ? null : () => onChanged!(!value),
    semanticLabel: semanticLabel,
    selected: value,
    builder: (context, pressed) => SizedBox(
      width: CoquiMetrics.switchWidth,
      height: CoquiMetrics.targetMin,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: CoquiMetrics.switchWidth,
              height: CoquiMetrics.switchTrackHeight,
              decoration: BoxDecoration(
                color: value ? CoquiColors.ok : CoquiColors.switchOff,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            top: 12,
            left: value ? 24 : 4,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CoquiColors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
