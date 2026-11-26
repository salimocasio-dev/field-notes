/// Legacy lesson buttons still referenced by `feature_speaking` and
/// `coqui/app/tool/` scripts pending their Noche migration.
///
/// Unused v=39 buttons (`CoquiButton`, `PlayButton`, `CoquiCloseButton`,
/// `LessonButtonRow`, `LessonBackButton`, `LessonNextButton`,
/// `LessonSoundButton`, `LessonTextSizeButton`) were removed in N1.4 (#82).
library;

import 'package:coqui_ui/src/icons.dart';
import 'package:coqui_ui/src/layout.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Which of the lesson's full-width buttons.
enum LessonButtonKind {
  /// `.pri` green: continue learning.
  go,

  /// `.pri.blu` blue: any other main action.
  blue,

  /// `.sec` the outline button, 1.5 px `--line`.
  outline,
}

/// `.pri` and `.sec` of the lesson screens: 56 px (primary) or 48 px (outline)
/// high, radius 12, at most 480 px wide, centred.
class LessonButton extends StatelessWidget {
  const LessonButton({
    super.key,
    this.label,
    this.child,
    this.icon,
    required this.onPressed,
    this.kind = LessonButtonKind.go,
    this.height,
    this.fillWidth = true,
    this.semanticLabel,
  });

  /// The text. Or give [child].
  final String? label;
  final Widget? child;

  /// A 20 px icon before the [label], 8 px from it, white.
  final CoquiIconData? icon;
  final VoidCallback? onPressed;
  final LessonButtonKind kind;

  /// 56 for [LessonButtonKind.go] and [LessonButtonKind.blue], 48 for outline.
  final double? height;

  /// True: the whole width up to 480 px, centred. False: as wide as its row gives.
  final bool fillWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final outline = kind == LessonButtonKind.outline;
    final h =
        height ??
        (outline ? CoquiMetrics.secondaryHeight : CoquiMetrics.primaryHeight);
    final style = outline
        ? CoquiText.lessonButtonOutline
        : CoquiText.lessonButton;
    final enabled = onPressed != null;
    final bg = switch (kind) {
      LessonButtonKind.go => CoquiColors.lessonGreen,
      LessonButtonKind.blue => CoquiColors.lessonBlue,
      LessonButtonKind.outline => const Color(0x00000000),
    };
    Widget button = Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) {
        Widget box = Container(
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: outline && pressed ? CoquiColors.secondaryPressed : bg,
            borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
            border: outline
                ? Border.all(
                    color: CoquiColors.lessonLine,
                    width: CoquiLayout.border(
                      context,
                      CoquiMetrics.borderButton,
                    ),
                  )
                : null,
          ),
          child: DefaultTextStyle(
            style: style,
            child:
                child ??
                (icon == null
                    ? Text(label ?? '', style: style)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CoquiIcon(
                            icon!,
                            size: 20,
                            color: CoquiColors.lessonInk,
                          ),
                          const SizedBox(width: CoquiMetrics.s8),
                          Text(label ?? '', style: style),
                        ],
                      )),
          ),
        );
        if (!outline && pressed) {
          box = ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.92, 0, 0, 0, 0, //
              0, 0.92, 0, 0, 0, //
              0, 0, 0.92, 0, 0, //
              0, 0, 0, 1, 0,
            ]),
            child: box,
          );
        }
        return Opacity(opacity: enabled ? 1 : 0.35, child: box);
      },
    );
    if (fillWidth) {
      button = Center(
        widthFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: CoquiMetrics.lessonColumnMax,
          ),
          child: SizedBox(width: double.infinity, child: button),
        ),
      );
      button = SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// `#go`: the start disc of a lesson, 72 px, green, a white 32 px triangle.
class LessonStartButton extends StatelessWidget {
  const LessonStartButton({
    super.key,
    required this.onPressed,
    this.icon = CoquiIcons.startTriangle,
    this.semanticLabel = 'Start',
  });

  final VoidCallback? onPressed;
  final CoquiIconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: CoquiMetrics.s16),
    child: Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.96 : 1,
        child: Container(
          width: CoquiMetrics.startDisc,
          height: CoquiMetrics.startDisc,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: CoquiColors.lessonGreen,
            boxShadow: CoquiShadows.startDisc,
          ),
          child: CoquiIcon(icon, size: 32, color: CoquiColors.lessonInk),
        ),
      ),
    ),
  );
}

/// `.ib`: a 48 px round icon button on the dark frame.
class LessonIconButton extends StatelessWidget {
  const LessonIconButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool? selected;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: semanticLabel,
    selected: selected,
    builder: (context, pressed) => Container(
      width: CoquiMetrics.iconButton,
      height: CoquiMetrics.iconButton,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pressed ? CoquiColors.iconPressed : null,
      ),
      child: child,
    ),
  );
}

/// The lesson's close X (`#close`, 24 px, stroke 2.4).
class LessonCloseButton extends StatelessWidget {
  const LessonCloseButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => LessonIconButton(
    onPressed: onPressed,
    semanticLabel: 'Close',
    child: const CoquiIcon(
      CoquiIcons.lessonClose,
      color: CoquiColors.lessonInk2,
    ),
  );
}
