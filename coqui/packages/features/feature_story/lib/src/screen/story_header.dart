/// 64-high Noche story header (`Noche-Cuento.dc.html`, `Noche-Cuento-AR.dc.html`):
/// 48 × 48 close X at start, [NocheDashes] on `lessonGround` in the middle, and
/// the 56 × 48 TXT captions toggle pill at end.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
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
    semanticLabel: NocheA11y.label(
      NocheA11y.close,
      courseWords: language.a11yWords,
    ),
    builder: (context, pressed) => Transform.scale(
      scale: pressed ? 0.94 : 1,
      child: const SizedBox(
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
    ),
  );
}

/// TXT captions toggle pill in the 64-high story header (`Noche-Cuento.dc.html`:
/// 56 × 48, radius 24; on = `text` fill and `lessonGround` text, off = 1 px
/// `lessonBorder` outline and `text` colour).
class StoryTxtToggle extends StatelessWidget {
  const StoryTxtToggle({
    super.key,
    required this.on,
    required this.onPressed,
    required this.language,
  });

  final bool on;
  final VoidCallback? onPressed;
  final Language language;

  static const double width = 56;
  static const double height = NocheSize.touch;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    selected: on,
    semanticLabel: NocheA11y.label(
      NocheA11y.captions,
      courseWords: language.a11yWords,
    ),
    builder: (context, pressed) => Transform.scale(
      scale: pressed ? 0.96 : 1,
      child: Container(
        width: width,
        height: height,
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: on ? NocheColors.text : null,
          border: on
              ? null
              : Border.all(color: NocheColors.lessonBorder, width: 1),
          borderRadius: BorderRadius.circular(NocheSize.pillRadius),
        ),
        child: Text(
          'TXT',
          maxLines: 1,
          softWrap: false,
          textDirection: TextDirection.ltr,
          style: NocheType.buttonStrong.copyWith(
            letterSpacing: 0.84,
            color: on ? NocheColors.lessonGround : NocheColors.text,
          ),
        ),
      ),
    ),
  );
}

/// 64-high Noche story header (`Noche-Cuento.dc.html`, `Noche-Cuento-AR.dc.html`):
/// close X (48) at start, part dashes (`NocheDashes` on `lessonGround`) in the
/// middle, and the 56 × 48 TXT toggle pill at the end.
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

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 16, 0),
      child: Row(
        children: [
          StoryCloseButton(onPressed: onClose, language: language),
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
            ),
          ],
        ],
      ),
    ),
  );
}
