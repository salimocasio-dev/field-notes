/// The word card of Palabras (order 27): a picture, or the line he heard the word in; the word; and its two meters
/// in one row, the ear's and the mouth's, each a small icon and four dots.
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/text_rules.dart';
import 'package:material_ui/material_ui.dart';

/// The picture size of a review picture, in picture pixels (`PictureSource.of`'s default).
const int _picW = 196;
const int _picH = 104;

/// One card. [picture] is a picture of [_picW] x [_picH] picture pixels (a widget that sizes itself by the width it
/// is given, as `PictureSource.of` does); with none, [line] (the line he heard the word in) stands in its place, and
/// with neither the word itself, large. [today]: today's Repaso asks it, and the card says so.
class WordTile extends StatelessWidget {
  const WordTile({
    super.key,
    required this.word,
    required this.ear,
    required this.mouth,
    this.picture,
    this.line,
    this.today = false,
    this.onTap,
  });

  final String word;

  /// Ear stage, 0 to 4.
  final int ear;

  /// Mouth stage, 0 to 4.
  final int mouth;
  final Widget? picture;

  /// The line's text, exactly as recorded; the word is bold in it.
  final String? line;
  final bool today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget top;
    final p = picture;
    final l = line;
    if (p != null) {
      top = WordPictureArea(picture: p);
    } else {
      top = _LineArea(word: word, line: l);
    }
    final showWord = p != null || l != null;
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CoquiColors.white,
        borderRadius: BorderRadius.circular(CoquiMetrics.radiusCard),
        boxShadow: CoquiShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              top,
              if (today)
                const Positioned(
                  left: CoquiMetrics.s8,
                  top: CoquiMetrics.s8,
                  child: TodayTag(),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CoquiMetrics.s12,
              CoquiMetrics.s8,
              CoquiMetrics.s12,
              CoquiMetrics.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showWord)
                  Padding(
                    padding: const EdgeInsets.only(bottom: CoquiMetrics.s4),
                    child: Text(word, style: CoquiText.cardWord),
                  ),
                SkillDots(ear: ear, mouth: mouth),
              ],
            ),
          ),
        ],
      ),
    );
    final label = [
      word,
      'ear ${ear.clamp(0, 4)} of 4, mouth ${mouth.clamp(0, 4)} of 4',
      if (today) 'in today\'s Repaso',
    ].join(': ').replaceFirst(': in', ', in');
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}

/// The picture area of a card: as wide as the card, as tall as the picture ([TileGrid] works the height out). The
/// picture is drawn at a whole number of device pixels per picture pixel (page 11-pixel-engine, decision 3), centred.
class WordPictureArea extends StatelessWidget {
  const WordPictureArea({super.key, required this.picture});
  final Widget picture;

  /// The scale (device pixels per picture pixel) for a card [width] css px wide at [dpr]: the largest whole scale
  /// that fits; or, when that would leave the picture under three quarters of the card's width (a phone at 2 device
  /// pixels per css pixel: 98 css px in a 171 px card), one scale larger, its sides cut by the card's edges.
  static int scaleFor(double width, double dpr) {
    final k = pixelViewScale(
      availableWidth: width,
      devicePixelRatio: dpr,
      width: _picW,
    );
    return _picW * k / dpr < 0.75 * width ? k + 1 : k;
  }

  @override
  Widget build(BuildContext context) {
    final a = _Area.of(context);
    return SizedBox(
      height: a.height,
      child: ClipRect(
        child: OverflowBox(
          minWidth: a.pictureWidth,
          maxWidth: a.pictureWidth,
          minHeight: a.height,
          maxHeight: a.height,
          child: picture,
        ),
      ),
    );
  }
}

/// The size of the picture area of every card of a [TileGrid].
class _Area extends InheritedWidget {
  const _Area({
    required this.height,
    required this.pictureWidth,
    required super.child,
  });

  final double height;
  final double pictureWidth;

  /// Outside a grid: the picture at scale 1 css px per picture pixel.
  static _Area of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Area>() ??
      _Area(
        height: _picH.toDouble(),
        pictureWidth: _picW.toDouble(),
        child: const SizedBox.shrink(),
      );

  @override
  bool updateShouldNotify(_Area old) =>
      old.height != height || old.pictureWidth != pictureWidth;
}

/// Two columns of [WordTile]s, 16 px apart both ways; the two cards of a row are as tall as the taller one. Every
/// card's top area (picture or line) has the same height, worked out here from the card's width.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final cardW = (c.maxWidth - CoquiMetrics.s16) / 2;
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final k = WordPictureArea.scaleFor(cardW, dpr);
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += 2) {
        if (i > 0) rows.add(const SizedBox(height: CoquiMetrics.s16));
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: CoquiMetrics.s16),
                Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }
      return _Area(
        height: _picH * k / dpr,
        pictureWidth: _picW * k / dpr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      );
    },
  );
}

/// Where a word with no picture has its picture: a calm grey panel of the same shape, with the line he heard the word
/// in (the word bold), or with no line the word itself, large.
class _LineArea extends StatelessWidget {
  const _LineArea({required this.word, required this.line});
  final String word;
  final String? line;

  @override
  Widget build(BuildContext context) {
    final height = _Area.of(context).height;
    const pad = CoquiMetrics.s8;
    final style = CoquiText.small;
    // as many lines as the panel holds, three at most (the end of a longer line gives way to "…")
    final lineH =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
    final fit = ((height - 2 * pad) / lineH).floor().clamp(1, 3);
    return SizedBox(
      height: height,
      child: ColoredBox(
        color: CoquiColors.coverFill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CoquiMetrics.s12,
            vertical: pad,
          ),
          child: Center(
            child: line == null
                ? Text(
                    word,
                    textAlign: TextAlign.center,
                    style: CoquiText.cardWordLarge,
                  )
                : Text.rich(
                    lineSpan(
                      line!,
                      word,
                      style,
                      style.copyWith(fontWeight: FontWeight.w700),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: fit,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
      ),
    );
  }
}

/// [text] with [word] in [bold] wherever it stands in it as a word (accents and case ignored), the rest in [style].
TextSpan lineSpan(String text, String word, TextStyle style, TextStyle bold) {
  final spans = <TextSpan>[];
  var pos = 0;
  for (final o in occurrences(text, [wordTokens(word)])) {
    if (o.a > pos) spans.add(TextSpan(text: text.substring(pos, o.a)));
    spans.add(TextSpan(text: text.substring(o.a, o.z), style: bold));
    pos = o.z;
  }
  if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
  return TextSpan(style: style, children: spans);
}

/// "Today" on a card: a small blue tag (blue: the app's colour for the system's own state), for the words today's
/// Repaso asks.
class TodayTag extends StatelessWidget {
  const TodayTag({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: CoquiMetrics.s8,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: CoquiColors.info,
      borderRadius: BorderRadius.circular(CoquiMetrics.radiusPicture),
    ),
    child: Text(
      'Today',
      style: CoquiText.meterLabel.copyWith(color: CoquiColors.white),
    ),
  );
}

/// The two meters of a card in one row: the speaker (Ear: he knows it when he hears it) and the microphone (Mouth: he
/// can say it), each with its four dots ([MeterDots]). Each says "Ear: 3 of 4" / "Mouth: 0 of 4" to a screen reader.
class SkillDots extends StatelessWidget {
  const SkillDots({super.key, required this.ear, required this.mouth});
  final int ear;
  final int mouth;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: CoquiMetrics.s12,
    runSpacing: CoquiMetrics.s4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SkillDot(skill: 'Ear', icon: CoquiIcons.volume, value: ear),
      SkillDot(skill: 'Mouth', icon: CoquiIcons.mic, value: mouth),
    ],
  );
}

/// One skill's icon and dots.
class SkillDot extends StatelessWidget {
  const SkillDot({
    super.key,
    required this.skill,
    required this.icon,
    required this.value,
  });

  /// `Ear` or `Mouth`.
  final String skill;
  final CoquiIconData icon;
  final int value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$skill: ${value.clamp(0, 4)} of 4',
    image: true,
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CoquiIcon(icon, size: 16, color: CoquiColors.mut),
        const SizedBox(width: CoquiMetrics.s4),
        SmallDots(value: value),
      ],
    ),
  );
}

/// [MeterDots] made small for the card's one row: four 8 px dots 3 px apart, [value] of them filled green, the
/// others a ring of the same grey. Keys as [MeterDots] has them (`dot<i>on`, `dot<i>off`).
class SmallDots extends StatelessWidget {
  const SmallDots({super.key, required this.value});
  final int value;

  static const double size = 8;
  static const double gap = 3;

  @override
  Widget build(BuildContext context) {
    final n = value.clamp(0, 4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 4; i++) ...[
          if (i > 1) const SizedBox(width: gap),
          Container(
            key: ValueKey('dot$i${i <= n ? 'on' : 'off'}'),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= n ? CoquiColors.ok : null,
              border: Border.all(
                color: i <= n ? CoquiColors.ok : CoquiColors.dotOutline,
                width: CoquiLayout.border(context, CoquiMetrics.dotBorder),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// What the two icons of a card mean, once above the cards: the speaker and Ear, the microphone and Mouth.
class SkillKey extends StatelessWidget {
  const SkillKey({super.key});

  static const ear = 'Ear: you know it when you hear it.';
  static const mouth = 'Mouth: you can say it.';

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: CoquiMetrics.s16,
    children: [
      for (final (icon, text) in [
        (CoquiIcons.volume, ear),
        (CoquiIcons.mic, mouth),
      ])
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: CoquiIcon(icon, size: 16, color: CoquiColors.mut),
            ),
            const SizedBox(width: CoquiMetrics.s4),
            Flexible(child: Text(text, style: CoquiText.smallMuted)),
          ],
        ),
    ],
  );
}
