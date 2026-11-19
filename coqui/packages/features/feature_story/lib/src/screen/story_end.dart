/// The end of a story: its title under the last picture (index.html `#fin`, juego.js `finFit`) and the buttons.
library;

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:material_ui/material_ui.dart';

/// The story's title at the end: 24 px semibold, left, 16 px under the picture (which keeps its place: it is the last
/// picture of the story). When it does not fit between the picture and the buttons it is dropped, never the picture. On a
/// phone on its side it sits at the top of the column beside the picture. It takes no touch (`#fin{pointer-events:none}`).
class StoryEndTitle extends StatelessWidget {
  const StoryEndTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();
    final dpr =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    // `#fin>*{width:100%;max-width:480px}` and `#fin h1{text-align:left}`: a column at most 480 px wide, centred, the title at
    // its left. The column is as high as the title is (nothing in it may fill the height it is given).
    final text = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CoquiMetrics.lessonColumnMax),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          title,
          textAlign: TextAlign.left,
          style: CoquiText.lessonH1,
        ),
      ),
    );
    if (CoquiLayout.lessonLandscape(context)) {
      return IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(padding: const EdgeInsets.only(top: 8), child: text),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth - 2 * CoquiMetrics.s16;
        final scale = pixelViewScale(
          availableWidth: w,
          devicePixelRatio: dpr,
          width: displayW,
        );
        final ph = displayH * scale / dpr;
        // the picture is centred in what is left above the 112 px of the bottom zone (LessonFrame)
        final top = (c.maxHeight - CoquiMetrics.lessonFootReserve - ph) / 2;
        final y = top + ph + 16;
        final painter = TextPainter(
          text: TextSpan(text: title, style: CoquiText.lessonH1),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: math.min(w, CoquiMetrics.lessonColumnMax));
        // the buttons: Play again (48), 16, and the main button (56), 24 under them
        final buttonsTop = c.maxHeight - 24 - 48 - 16 - 56;
        if (y + painter.height + 16 > buttonsTop) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          child: Padding(
            padding: EdgeInsets.only(
              top: y,
              left: CoquiMetrics.s16,
              right: CoquiMetrics.s16,
            ),
            child: Align(alignment: Alignment.topCenter, child: text),
          ),
        );
      },
    );
  }
}

/// The buttons of the end screen, from what [StoryFoot] says: "Play again" (outline) with the outline "Map" beside it when a
/// next story waits, then "Next story" (green) or "Map" (blue).
List<Widget> storyEndButtons({
  required StoryFoot foot,
  required VoidCallback onAgain,
  required VoidCallback onNext,
  required VoidCallback onMap,
}) => [
  if (foot.again && foot.map)
    LessonButtonRow(
      children: [
        LessonButton(
          label: 'Play again',
          kind: LessonButtonKind.outline,
          fillWidth: false,
          onPressed: onAgain,
        ),
        LessonButton(
          label: 'Map',
          kind: LessonButtonKind.outline,
          fillWidth: false,
          onPressed: onMap,
        ),
      ],
    )
  else if (foot.again)
    LessonButton(
      label: 'Play again',
      kind: LessonButtonKind.outline,
      onPressed: onAgain,
    ),
  if (foot.next) LessonButton(label: 'Next story', onPressed: onNext),
  if (foot.home)
    LessonButton(label: 'Map', kind: LessonButtonKind.blue, onPressed: onMap),
];
