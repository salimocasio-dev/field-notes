/// The word card of Palabras (app.html:86-95, 426-427).
library;

import 'package:coqui_ui/src/meters.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// `.wc`: a white card, 16 px corners, a 1 px ring and a faint shadow.
///
/// With a [picture]: a picture area on top, 196:104 and as wide as the card (v=39's
/// `.wc canvas{aspect-ratio:196/104}`, app.html:89), on `#222` (`.wc canvas{background:#222}`,
/// app.html:89, [CoquiColors.pictureBack]). The picture stands in it at the largest whole
/// number of device pixels per picture pixel that fits the card's width ([PixelView]'s own
/// rule: page 11-pixel-engine, decision 3), centred, never stretched and never cropped;
/// the `#222` shows in the bands round it. Then the word (18/24 semibold) and the two
/// meters, padded 8 / 12 / 12. Without: `.np`, a
/// plain tile with the word large (24/32 semibold, centred, at least 72 px high,
/// breaking anywhere in a long word) and the meters under it; no empty picture
/// box. The word is always spelled. app.html:88-92
class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.ear,
    required this.mouth,
    this.picture,
    this.onTap,
  });

  final String word;

  /// Ear stage, 0 to 4.
  final int ear;

  /// Mouth stage, 0 to 4.
  final int mouth;

  /// What the card shows above the word: a [PixelView] of a 196 x 104 picture (any
  /// widget that sizes itself by the width it is given). It is centred in the picture
  /// area at its own whole-number scale. Null: a plain tile.
  final Widget? picture;

  /// The card's tap (opens the word sheet).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meters = Padding(
      padding: const EdgeInsets.fromLTRB(
        CoquiMetrics.s12,
        CoquiMetrics.s8,
        CoquiMetrics.s12,
        CoquiMetrics.s12,
      ),
      child: EarMouthMeters(ear: ear, mouth: mouth),
    );
    final Widget content;
    if (picture != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: CoquiMetrics.wordPictureAspect,
            child: ColoredBox(
              color: CoquiColors.pictureBack,
              child: Center(child: picture),
            ),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: CoquiMetrics.s4),
                  child: Text(word, style: CoquiText.cardWord),
                ),
                EarMouthMeters(ear: ear, mouth: mouth),
              ],
            ),
          ),
        ],
      );
    } else {
      final word_ = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CoquiMetrics.s12,
            CoquiMetrics.s16,
            CoquiMetrics.s12,
            CoquiMetrics.s4,
          ),
          child: Center(
            child: Text(
              word,
              textAlign: TextAlign.center,
              style: CoquiText.cardWordLarge,
            ),
          ),
        ),
      );
      // In a grid row the tile is as tall as its neighbour and the word centres in
      // what is left (`.npw{flex:1}`); on its own it is as tall as its content.
      final inGrid = context.getInheritedWidgetOfExactType<_InGrid>() != null;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (inGrid) Expanded(child: word_) else word_,
          meters,
        ],
      );
    }
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CoquiColors.white,
        borderRadius: BorderRadius.circular(CoquiMetrics.radiusCard),
        boxShadow: CoquiShadows.card,
      ),
      child: content,
    );
    if (onTap == null) return card;
    return Pressable(
      onPressed: onTap,
      semanticLabel:
          '$word: ear ${ear.clamp(0, 4)} of 4, mouth ${mouth.clamp(0, 4)} of 4',
      builder: (context, pressed) => card,
    );
  }
}

/// Tells a [WordCard] it stands in a [WordGrid] row, where its height is given.
class _InGrid extends InheritedWidget {
  const _InGrid({required super.child});

  @override
  bool updateShouldNotify(_InGrid old) => false;
}

/// `.grid`: two columns, 16 px apart in both directions; the two cards of a row
/// are as tall as the taller one (a grid stretches its items). app.html:87
class WordGrid extends StatelessWidget {
  const WordGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
    return _InGrid(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}
