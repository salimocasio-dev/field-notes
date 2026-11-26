/// Noche speaking-turn controls for a story lesson (`Noche-Cuento.dc.html`,
/// `Noche-Cuento-AR.dc.html`, `Noche-Mic.dc.html`): a 48 "hear it again"
/// outline button at the start, [NocheMic] centred in the middle, and an empty
/// 48 spacer at the end.
library;

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:material_ui/material_ui.dart';

/// Maps [StoryView]'s speaking-turn state to [NocheMicState] (or null when no
/// speaking turn is active).
NocheMicState? nocheMicStateOf(StoryView v) => switch (v.mic) {
  'ok' => NocheMicState.right,
  'processing' => NocheMicState.thinking,
  'listening' => NocheMicState.listening,
  'dead' => NocheMicState.theySpeak,
  'ready' =>
    v.speakingNow
        ? NocheMicState.theySpeak
        : (v.micMissed ? NocheMicState.notYet : NocheMicState.ready),
  _ => null,
};

/// 48 × 48 circular "hear it again" outline button on `lessonGround`
/// (`Noche-Cuento.dc.html`: 1 px `lessonBorder` ring, 22 px `replay` icon).
class StoryHearAgainButton extends StatelessWidget {
  const StoryHearAgainButton({
    super.key,
    required this.onPressed,
    required this.language,
  });

  final VoidCallback? onPressed;
  final Language language;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? NocheColors.text : NocheColors.lessonLabel;
    final border = enabled ? NocheColors.lessonBorder : NocheColors.lessonLine;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: NocheA11y.label(
        NocheA11y.hearAgain,
        courseWords: language.a11yWords,
      ),
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.96 : 1,
        child: Container(
          width: NocheSize.touch,
          height: NocheSize.touch,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1),
          ),
          child: NocheIcon(
            NocheIcons.replay,
            size: 22,
            strokeWidth: 2,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// The bottom speaking-turn control row: 48 "hear it again" at the start,
/// [NocheMic] centred in the middle (all 6 states), and an empty 48 spacer at
/// the end so the mic stays centred in both LTR and RTL.
class StoryMicControls extends StatefulWidget {
  const StoryMicControls({
    super.key,
    required this.state,
    required this.language,
    required this.onTapMic,
    this.onHearAgain,
    this.reduceMotion = false,
  });

  final NocheMicState state;
  final Language language;
  final VoidCallback onTapMic;
  final VoidCallback? onHearAgain;
  final bool reduceMotion;

  /// Width reserved for [NocheMic] with five bars on each side:
  /// 36 + 16 + 96 + 16 + 36 = 200. Keeping this fixed prevents the flanking
  /// "hear it again" button from shifting when bars appear or disappear.
  static const double micSlotWidth = 200;

  @override
  State<StoryMicControls> createState() => _StoryMicControlsState();
}

class _StoryMicControlsState extends State<StoryMicControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _levelAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool get _animates => !widget.reduceMotion && widget.state.showsBars;

  @override
  void initState() {
    super.initState();
    if (_animates) _levelAnim.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StoryMicControls old) {
    super.didUpdateWidget(old);
    if (_animates) {
      if (!_levelAnim.isAnimating) _levelAnim.repeat(reverse: true);
    } else {
      _levelAnim.stop();
    }
  }

  @override
  void dispose() {
    _levelAnim.dispose();
    super.dispose();
  }

  double _currentLevel() {
    if (!widget.state.showsBars) return 0.0;
    if (widget.reduceMotion) return 1.0;
    return 0.45 + 0.55 * (0.5 + 0.5 * math.sin(_levelAnim.value * math.pi));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final tappable = s == NocheMicState.ready || s == NocheMicState.notYet;
    final labelGap = widget.language.script == 'Arab' ? 12.0 : 16.0;
    const flankTop = (NocheMic.discSize - NocheSize.touch) / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        // Board metrics at >= 328 px: 48 + 16 + (36 + 16 + 96 + 16 + 36) + 16 + 48 = 328.
        // On narrower portrait/landscape viewports, tighten the gaps symmetrically
        // while keeping both 48x48 touch targets and the 96px mic disc centred.
        final double flankGap;
        final double barGroupGap;
        final double minSlotWidth;
        if (!maxW.isFinite || maxW >= 328) {
          flankGap = 16;
          barGroupGap = NocheMic.defaultBarGroupGap;
          minSlotWidth = StoryMicControls.micSlotWidth;
        } else {
          final extra = math.max(0.0, maxW - (NocheSize.touch * 2 + 168));
          // Distribute available margin evenly across the 4 horizontal gaps (2 flank + 2 barGroup).
          final gap = (extra / 4).clamp(4.0, 16.0);
          flankGap = gap;
          barGroupGap = gap;
          minSlotWidth = math.max(
            NocheMic.discSize,
            math.min(
              StoryMicControls.micSlotWidth,
              maxW - NocheSize.touch * 2 - flankGap * 2,
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: flankTop),
              child: StoryHearAgainButton(
                onPressed: widget.onHearAgain,
                language: widget.language,
              ),
            ),
            SizedBox(width: flankGap),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: minSlotWidth),
              child: IgnorePointer(
                ignoring: s == NocheMicState.right,
                child: AnimatedBuilder(
                  animation: _levelAnim,
                  builder: (context, _) => NocheMic(
                    state: s,
                    language: widget.language,
                    level: _currentLevel(),
                    compactLabel: true,
                    labelGap: labelGap,
                    barGroupGap: barGroupGap,
                    onPressed: tappable ? widget.onTapMic : null,
                  ),
                ),
              ),
            ),
            SizedBox(width: flankGap),
            const ExcludeSemantics(
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: flankTop),
                child: SizedBox(
                  width: NocheSize.touch,
                  height: NocheSize.touch,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
