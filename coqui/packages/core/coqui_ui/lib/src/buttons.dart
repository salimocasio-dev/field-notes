/// The buttons, each as the old app draws it.
///
/// Light screens (app.html): [CoquiButton] (`.btn`: blue, green `.go`, outline
/// `.out`), [PlayButton] (`.pb`: the round green play control, and `.pb.o` the
/// quiet one), [CoquiCloseButton] (the sheet's X). Lesson screens (cual.html):
/// [LessonButton] (`.pri` green or blue, 56 px; `.sec` outline, 48 px),
/// [LessonStartButton] (`#go`, 72 px), [LessonIconButton], [LessonCloseButton],
/// [LessonSoundButton] (`.ib`). All are dumb: values and callbacks.
library;

import 'package:coqui_ui/src/icons.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Which of the three light-screen buttons.
enum CoquiButtonKind {
  /// `.btn` blue: every primary action that does not start learning. app.html:22
  primary,

  /// `.btn.go` green: anything that starts or continues learning. app.html:23
  go,

  /// `.btn.out` the one secondary button: transparent, 1.5 px ring. app.html:24
  outline,
}

/// `.btn`: 48 px high at least, 24 px of side padding, radius 12, a 1.5 px
/// border, the label 16 px semibold. app.html:22-25
class CoquiButton extends StatelessWidget {
  const CoquiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = CoquiButtonKind.primary,
    this.icon,
    this.full = false,
    this.padX = CoquiMetrics.buttonPadX,
    this.semanticLabel,
  });

  final String label;

  /// Null: the button is disabled (`.btn:disabled`).
  final VoidCallback? onPressed;
  final CoquiButtonKind kind;

  /// A 20 px icon before the label (`.btn svg`, app.html:55).
  final CoquiIconData? icon;

  /// `.btn.full`: the whole width. app.html:23
  final bool full;

  /// 24 by default; the shelf's buttons use 16 (`.bk .btn`, app.html:99).
  final double padX;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final Color bg;
    final Color border;
    final TextStyle style;
    switch (kind) {
      case CoquiButtonKind.primary:
        bg = CoquiColors.info;
        border = const Color(0x00000000);
        style = CoquiText.button;
      case CoquiButtonKind.go:
        bg = CoquiColors.ok;
        border = const Color(0x00000000);
        style = CoquiText.button;
      case CoquiButtonKind.outline:
        bg = const Color(0x00000000);
        border = CoquiColors.line2;
        style = CoquiText.buttonOutline;
    }
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) {
        final fg = disabled ? CoquiColors.mut : style.color!;
        final body = DecoratedBox(
          decoration: BoxDecoration(
            color: disabled ? CoquiColors.disabledFill : bg,
            borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
            border: Border.all(
              color: disabled ? CoquiColors.line : border,
              width: CoquiMetrics.borderButton,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CoquiMetrics.targetMin,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padX),
              child: Row(
                mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    CoquiIcon(icon!, size: 20, color: fg),
                    const SizedBox(width: CoquiMetrics.s8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: style.copyWith(color: fg),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return Transform.scale(scale: pressed ? 0.98 : 1, child: body);
      },
    );
  }
}

/// `.pb`: the one play control, a green 48 px disc with a white triangle
/// (stop: a white square; call: a phone). [quiet] is `.pb.o`: a ring and a dark
/// triangle, for every row after the first unplayed story. app.html:26-28
class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.onPressed,
    this.icon = CoquiIcons.play,
    this.quiet = false,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;

  /// [CoquiIcons.play], [CoquiIcons.stop] or [CoquiIcons.phone].
  final CoquiIconData icon;
  final bool quiet;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: semanticLabel,
    builder: (context, pressed) => Transform.scale(
      scale: pressed ? 0.98 : 1,
      child: Container(
        width: CoquiMetrics.playDisc,
        height: CoquiMetrics.playDisc,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: quiet ? null : CoquiColors.ok,
          border: quiet
              ? Border.all(
                  color: CoquiColors.line2,
                  width: CoquiMetrics.borderButton,
                )
              : null,
        ),
        child: CoquiIcon(
          icon,
          color: quiet ? CoquiColors.ink : CoquiColors.white,
        ),
      ),
    ),
  );
}

/// The sheet's X: 48 px, no fill, the ink X at 24 px. app.html:80-81
class CoquiCloseButton extends StatelessWidget {
  const CoquiCloseButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: 'Close',
    builder: (context, pressed) => const SizedBox.square(
      dimension: CoquiMetrics.iconButton,
      child: Center(child: CoquiIcon(CoquiIcons.close, color: CoquiColors.ink)),
    ),
  );
}

/// Which of the lesson's full-width buttons.
enum LessonButtonKind {
  /// `.pri` green: continue learning. cual.html:55
  go,

  /// `.pri.blu` blue: any other main action. cual.html:56
  blue,

  /// `.sec` the outline button, 1.5 px `--line`. cual.html:58
  outline,
}

/// `.pri` and `.sec` of the lesson screens: 56 px (primary) or 48 px (outline)
/// high, radius 12, at most 480 px wide, centred. cual.html:55-59
class LessonButton extends StatelessWidget {
  const LessonButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.kind = LessonButtonKind.go,
    this.height,
    this.fillWidth = true,
    this.semanticLabel,
  });

  /// The text. Or give [child] (an arrow, an icon and a label).
  final String? label;
  final Widget? child;
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
                    width: CoquiMetrics.borderButton,
                  )
                : null,
          ),
          child: DefaultTextStyle(
            style: style,
            child: child ?? Text(label ?? '', style: style),
          ),
        );
        if (!outline && pressed) {
          // `.pri:active{filter:brightness(.92)}`. cual.html:57
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

/// Two outline buttons side by side, 16 px apart (`#duo.two`). cual.html:61-62
class LessonButtonRow extends StatelessWidget {
  const LessonButtonRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    widthFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CoquiMetrics.lessonColumnMax),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: CoquiMetrics.s16),
            Expanded(child: children[i]),
          ],
        ],
      ),
    ),
  );
}

/// `#go`: the start disc of a lesson, 72 px, green, a white 32 px triangle, a
/// soft shadow, 16 px under it (so 40 px above the screen's edge). cual.html:53-54
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
    padding: const EdgeInsets.only(bottom: CoquiMetrics.s16),
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

/// `.ib`: a 48 px round icon button on the dark frame, the icon in `--ink2`,
/// a faint white disc while pressed. cual.html:17-18
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

/// The lesson's close X (`#close`, 24 px, stroke 2.4). cual.html:101
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

/// The lesson's sound button (`#snd`): the speaker with waves, or with a cross
/// when [muted] (`#snd.off`). cual.html:103, 22-24
class LessonSoundButton extends StatelessWidget {
  const LessonSoundButton({
    super.key,
    required this.onPressed,
    this.muted = false,
  });
  final VoidCallback? onPressed;
  final bool muted;

  @override
  Widget build(BuildContext context) => LessonIconButton(
    onPressed: onPressed,
    semanticLabel: 'Sound',
    child: CoquiIcon(
      muted ? CoquiIcons.lessonSoundOff : CoquiIcons.lessonSound,
      color: CoquiColors.lessonInk2,
    ),
  );
}

/// `.ib.aa`: the "Aa" text size button of the book. app.html:107
class LessonTextSizeButton extends StatelessWidget {
  const LessonTextSizeButton({
    super.key,
    required this.onPressed,
    this.big = false,
  });
  final VoidCallback? onPressed;

  /// `aria-pressed`: the large text is on.
  final bool big;

  @override
  Widget build(BuildContext context) => LessonIconButton(
    onPressed: onPressed,
    semanticLabel: 'Text size',
    selected: big,
    child: Text('Aa', style: CoquiText.lessonAa),
  );
}
