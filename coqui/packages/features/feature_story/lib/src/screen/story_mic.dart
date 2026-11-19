/// The mic button of a speaking turn, and its states (index.html `#mic`, docs/proyecto/09-ui-plan.md "Mic states").
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// `--grn`, the "your turn" green; `#2B2B33`, grey for "the app is speaking or thinking"; `#FF5A5F`, the recording coral;
/// `#3DDC84`, the tick. index.html:42-60
const Color _grey = Color(0xFF2B2B33), _greyIcon = Color(0xFFA7A7B0);
const Color _coral = Color(0xFFFF5A5F), _coralInk = Color(0xFF2B0A0C);
const Color _tick = Color(0xFF3DDC84);

/// The state of the mic button: what `#mic[data-s]` is. [dead] while a line plays, [ready], [listening], [processing]
/// and [ok] (the tick).
enum StoryMicState { dead, ready, listening, processing, ok }

StoryMicState? micStateOf(String s) => switch (s) {
  'dead' => StoryMicState.dead,
  'ready' => StoryMicState.ready,
  'listening' => StoryMicState.listening,
  'processing' => StoryMicState.processing,
  'ok' => StoryMicState.ok,
  _ => null,
};

/// The mic disc: 72 px, the start disc's size and place (index.html `#mic`).
///
/// - dead: grey with a dim mic. ready: green with a white mic. listening: coral with a dark mic, a steady coral ring just
///   outside it and two more that spread (a timer, not the voice level); with reduced motion the rings are still.
///   processing: grey with three pulsing dots. ok: an outline with a green tick, no fill: a status, not a button.
/// - Only a ready mic takes a tap (`aria-disabled`). The label is the old page's: "Micrófono".
// A stand-in: coqui_ui has no mic disc yet (request 15-feature-story-needs-coqui-ui-lesson-mic-disc).
class StoryMicButton extends StatefulWidget {
  const StoryMicButton({
    super.key,
    required this.state,
    required this.onPressed,
    this.reduceMotion = false,
  });

  final StoryMicState state;
  final VoidCallback onPressed;
  final bool reduceMotion;

  @override
  State<StoryMicButton> createState() => _StoryMicButtonState();
}

class _StoryMicButtonState extends State<StoryMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool get _moves =>
      !widget.reduceMotion &&
      (widget.state == StoryMicState.listening ||
          widget.state == StoryMicState.processing);

  @override
  void initState() {
    super.initState();
    if (_moves) _a.repeat();
  }

  @override
  void didUpdateWidget(StoryMicButton old) {
    super.didUpdateWidget(old);
    if (_moves) {
      if (!_a.isAnimating) _a.repeat();
    } else {
      _a.stop();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final ready = s == StoryMicState.ready;
    return Padding(
      padding: const EdgeInsets.only(bottom: CoquiMetrics.s16),
      child: Semantics(
        button: true,
        enabled: ready,
        label: 'Micrófono',
        excludeSemantics: true,
        onTap: ready ? widget.onPressed : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: ready ? widget.onPressed : null,
          child: SizedBox(
            width: 72,
            height: 72,
            child: AnimatedBuilder(
              animation: _a,
              builder: (context, _) => _disc(s),
            ),
          ),
        ),
      ),
    );
  }

  Widget _disc(StoryMicState s) {
    final t = _a.value;
    switch (s) {
      case StoryMicState.ok:
        return Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(BorderSide(color: _tick, width: 3)),
          ),
          child: const CoquiIcon(CoquiIcons.badgeCheck, size: 32, color: _tick),
        );
      case StoryMicState.listening:
        // `#mic[data-s=listening]`: coral, a steady ring 5 px off (the frame's colour between), a second one at 8 px, and
        // two rings that spread from the disc to 1.8 times its size
        final pulse = widget.reduceMotion
            ? 1.0
            : 1 + .06 * (1 - (2 * t - 1).abs());
        Widget ring(double phase) {
          final k = widget.reduceMotion
              ? (phase == 0 ? 1.5 : 0.0)
              : (t + phase) % 1;
          final scale = widget.reduceMotion ? 1.5 : 1 + .8 * k;
          final op = widget.reduceMotion
              ? (phase == 0 ? .8 : 0.0)
              : .95 * (1 - k);
          if (op <= 0) return const SizedBox.shrink();
          return Opacity(
            opacity: op,
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: _coral, width: 4),
                  ),
                ),
              ),
            ),
          );
        }

        return Transform.scale(
          scale: pulse,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ring(0),
              ring(.5),
              Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _coral,
                  boxShadow: [
                    BoxShadow(color: CoquiColors.lessonBg, spreadRadius: 5),
                    BoxShadow(color: _coral, spreadRadius: 8),
                    BoxShadow(
                      color: Color(0x59000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CoquiIcon(
                  CoquiIcons.lessonMic,
                  size: 32,
                  color: _coralInk,
                ),
              ),
            ],
          ),
        );
      case StoryMicState.processing:
        return Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _grey,
            boxShadow: CoquiShadows.startDisc,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _dot(widget.reduceMotion ? 1 : _dotPhase(t, i * .15 / .9 * .9)),
              ],
            ],
          ),
        );
      case StoryMicState.dead:
      case StoryMicState.ready:
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s == StoryMicState.dead ? _grey : CoquiColors.lessonGreen,
            boxShadow: CoquiShadows.startDisc,
          ),
          child: CoquiIcon(
            CoquiIcons.lessonMic,
            size: 32,
            color: s == StoryMicState.dead ? _greyIcon : CoquiColors.lessonInk,
          ),
        );
    }
  }

  // `@keyframes micdot`: 0%, 70%, 100% faint and small; 35% full and a little big (a 0.9 s cycle in a 1.2 s controller)
  double _dotPhase(double t, double delay) {
    final c = (t * 1.2 / .9 - delay) % 1;
    return c < .35
        ? .3 + .7 * (c / .35)
        : c < .7
        ? 1 - .7 * ((c - .35) / .35)
        : .3;
  }

  Widget _dot(double v) => Opacity(
    opacity: v.clamp(.3, 1),
    child: Transform.scale(
      scale: .8 + .35 * ((v - .3) / .7).clamp(0.0, 1.0),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: CoquiColors.lessonInk,
        ),
      ),
    ),
  );
}
