/// 64-high Noche story header (`Noche-Cuento.dc.html`, `Noche-Cuento-AR.dc.html`,
/// `Noche-Motion-Cuento.dc.html`): 48 × 48 close X at start, [NocheDashes] on
/// `lessonGround` in the middle, and the 56 × 48 TXT captions switch at end.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/motion.dart';
import 'package:feature_story/src/wording.dart';
import 'package:material_ui/material_ui.dart';

/// Close X button in the 64-high story header (`Noche-Cuento.dc.html`: 48 × 48,
/// 24 px X with stroke 2.5 in `NocheColors.text`).
class StoryCloseButton extends StatelessWidget {
  const StoryCloseButton({
    super.key,
    required this.onPressed,
    required this.language,
  });

  final VoidCallback? onPressed;
  final Language language;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    disc: true,
    semanticLabel: NocheA11y.label(
      NocheA11y.close,
      courseWords: language.a11yWords,
    ),
    builder: (context, _) => const SizedBox(
      width: NocheSize.touch,
      height: NocheSize.touch,
      child: Center(
        child: NocheIcon(
          NocheIcons.close,
          size: 24,
          strokeWidth: 2.5,
          color: NocheColors.text,
        ),
      ),
    ),
  );
}

/// TXT captions switch in the 64-high story header (`Noche-Motion-Cuento.dc.html`:
/// 56 × 48, radius 24; fill, text, and border animate in place over `quick`).
class StoryTxtToggle extends StatelessWidget {
  const StoryTxtToggle({
    super.key,
    required this.on,
    required this.onPressed,
    required this.language,
    this.reduceMotion = false,
  });

  final bool on;
  final VoidCallback? onPressed;
  final Language language;
  final bool reduceMotion;

  static const double width = 56;
  static const double height = NocheSize.touch;

  @override
  Widget build(BuildContext context) {
    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: reduceMotion,
    );
    final fillColor = on
        ? NocheColors.text
        : NocheColors.lessonGround.withValues(alpha: 0);
    final borderColor = on ? NocheColors.text : NocheColors.lessonBorder;
    final textColor = on ? NocheColors.lessonGround : NocheColors.text;

    return Pressable(
      onPressed: onPressed,
      selected: on,
      semanticLabel: NocheA11y.label(
        NocheA11y.captions,
        courseWords: language.a11yWords,
      ),
      builder: (context, _) => AnimatedContainer(
        key: const ValueKey('story_txt_toggle_surface'),
        duration: motion.quick,
        curve: motion.enter,
        width: width,
        height: height,
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(NocheSize.pillRadius),
        ),
        child: AnimatedDefaultTextStyle(
          duration: motion.quick,
          curve: motion.enter,
          style: NocheType.buttonStrong.copyWith(
            letterSpacing: 0.84,
            color: textColor,
          ),
          child: const Text(
            StoryWording.txtToggle,
            maxLines: 1,
            softWrap: false,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}

/// 64-high Noche story header (`Noche-Cuento.dc.html`, `Noche-Cuento-AR.dc.html`):
/// close X (48) at start, part dashes (`NocheDashes` on `lessonGround`) in the
/// middle, and the 56 × 48 TXT switch at the end.
class StoryHeader extends StatelessWidget {
  const StoryHeader({
    super.key,
    required this.onClose,
    required this.language,
    this.dots = 5,
    this.dotsLit = 0,
    this.showProgress = true,
    this.showTxt = true,
    this.txtOn = true,
    this.onToggleTxt,
    this.reduceMotion = false,
  });

  static const double height = 64;

  final VoidCallback? onClose;
  final Language language;
  final int dots;
  final int dotsLit;
  final bool showProgress;
  final bool showTxt;
  final bool txtOn;
  final VoidCallback? onToggleTxt;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 16, 0),
      child: Row(
        children: [
          StoryCloseButton(
            key: const Key('story-close-button'),
            onPressed: onClose,
            language: language,
          ),
          if (showProgress) ...[
            const SizedBox(width: 8),
            Expanded(
              child: NocheDashes.progress(
                count: dots,
                done: dotsLit,
                onLessonGround: true,
                gap: dots > 24 ? 1 : 4,
                semanticLabel: NocheA11y.label(
                  NocheA11y.partProgress,
                  courseWords: language.a11yWords,
                  args: {'current': '$dotsLit', 'total': '$dots'},
                ),
              ),
            ),
          ] else
            const Spacer(),
          if (showTxt) ...[
            const SizedBox(width: 16),
            StoryTxtToggle(
              on: txtOn,
              onPressed: onToggleTxt,
              language: language,
              reduceMotion: reduceMotion,
            ),
          ],
        ],
      ),
    ),
  );
}
