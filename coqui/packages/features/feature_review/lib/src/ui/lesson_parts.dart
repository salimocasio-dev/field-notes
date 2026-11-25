/// The pieces cual.html and nivel.html share, built from coqui_ui: the block of pictures with a frame each, the
/// words of a start or end screen (`#fin`), and the one-line semantics of an option.
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/review_session.dart' show OptionRing;
import 'package:feature_review/src/ui/block_layout.dart';
import 'package:material_ui/material_ui.dart';

ChoiceRing choiceRing(OptionRing r) => switch (r) {
  OptionRing.none => ChoiceRing.none,
  OptionRing.ok => ChoiceRing.right,
  OptionRing.bad => ChoiceRing.wrong,
  OptionRing.sel => ChoiceRing.selected,
};

/// The block of pictures (`#stage`): [fit] says how big it is and where each frame is. [cell] draws one.
class PictureBlock extends StatelessWidget {
  const PictureBlock({super.key, required this.fit, required this.cell});

  final BlockFit fit;
  final Widget Function(BuildContext context, int k, CellRect r) cell;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(bottom: fit.marginBottom),
    child: SizedBox(
      width: fit.width,
      height: fit.height,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var k = 0; k < fit.cells.length; k++)
              PositionedDirectional(
                start: fit.cells[k].left,
                top: fit.cells[k].top,
                width: fit.cells[k].width,
                height: fit.cells[k].height,
                child: cell(context, k, fit.cells[k]),
              ),
          ],
        ),
      ),
    ),
  );
}

/// One option: a picture that takes the touch the moment a finger goes down (cual.js: `pointerdown`).
class OptionTouch extends StatelessWidget {
  const OptionTouch({
    super.key,
    required this.index,
    required this.onTouch,
    required this.child,
  });

  final int index;
  final void Function(int k) onTouch;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Picture ${index + 1}',
    onTap: () => onTouch(index),
    child: ExcludeSemantics(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onTouch(index),
        child: child,
      ),
    ),
  );
}

/// What the page's `#main` is, for the layout: the screen less the top bar and the safe area.
class LessonBox {
  const LessonBox({
    required this.width,
    required this.height,
    required this.mainWidth,
    required this.mainHeight,
    required this.landscape,
    required this.dpr,
    required this.safeTop,
  });

  /// The whole screen handed to the lesson.
  final double width;
  final double height;

  /// juego.js: fit(): mw, mh.
  final double mainWidth;
  final double mainHeight;
  final bool landscape;
  final double dpr;
  final double safeTop;

  factory LessonBox.of(BuildContext context, BoxConstraints box) {
    final safe = MediaQuery.paddingOf(context);
    final landscape = CoquiLayout.lessonLandscape(context);
    final w = box.maxWidth;
    final h = box.maxHeight;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (landscape) {
      return LessonBox(
        width: w,
        height: h,
        mainWidth: w - safe.left - safe.right,
        mainHeight: h - safe.top - safe.bottom,
        landscape: true,
        dpr: dpr,
        safeTop: safe.top,
      );
    }
    return LessonBox(
      width: w,
      height: h,
      mainWidth: w - safe.left - safe.right,
      mainHeight: h - safe.bottom - (CoquiMetrics.lessonTopBar + safe.top),
      landscape: false,
      dpr: dpr,
      safeTop: safe.top,
    );
  }

  BlockFit fit(BlockSpec spec) => fitBlock(
    spec,
    dpr: dpr,
    mainWidth: mainWidth,
    mainHeight: mainHeight,
    landscape: landscape,
  );
}

/// `#fin`: the title and the lines of a start or end screen. Portrait: the title sits at about 35% of the screen's
/// height (cual.html:34: `padding-top: calc(35dvh - 56px - env(safe-area-inset-top))`); on its side it is the top
/// of the column beside the picture (`padding: 8px 0 152px`). [children] come under the title, 8 px apart.
class LessonTextScreen extends StatelessWidget {
  const LessonTextScreen({
    super.key,
    required this.box,
    required this.title,
    required this.lines,
  });

  final LessonBox box;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final top = box.landscape
        ? 8.0
        : (0.35 * box.height - CoquiMetrics.lessonTopBar - box.safeTop).clamp(
            0.0,
            double.infinity,
          );
    return Positioned.fill(
      child: ColoredBox(
        color: box.landscape ? const Color(0x00000000) : CoquiColors.lessonBg,
        child: SingleChildScrollView(
          padding: box.landscape
              ? EdgeInsetsDirectional.fromSTEB(0, top, 0, 152)
              : EdgeInsetsDirectional.fromSTEB(16, top, 16, 160),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CoquiMetrics.lessonColumnMax,
              ),
              child: Column(
                // `#fin>*{width:100%;max-width:480px}`: each line is as wide as the column
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: CoquiText.lessonH1),
                  for (final l in lines) ...[
                    const SizedBox(height: 8),
                    Text(l, style: CoquiText.lessonBody),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
