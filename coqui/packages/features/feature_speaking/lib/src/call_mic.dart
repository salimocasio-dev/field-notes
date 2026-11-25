/// The call's mic disc with its states (llamada.js: `.lmic`, `.ldisc`, `.lw`, `.lg`, `.dts`): a green disc with a
/// phone to start, pulsing while it calls, blue rings spreading while Danny speaks, a green ring that follows the
/// microphone's level on the learner's turn, three dots while the call thinks.
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_controller.dart';
import 'package:feature_speaking/src/call_look.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

class CallMicStage extends StatefulWidget {
  const CallMicStage({
    super.key,
    required this.state,
    required this.ring,
    required this.wave,
    required this.reduceMotion,
    required this.semanticLabel,
    required this.onTap,
  });

  final CallState state;

  /// `--rt`: the level ring's thickness, px.
  final double ring;

  /// `--wv`: how far Danny's rings spread, as a scale.
  final double wave;

  /// `prefers-reduced-motion`: no animation, no transition. llamada.js:148
  final bool reduceMotion;

  /// What a screen reader says (`aria-label`: "Start call" before the call, then the state's label).
  final String semanticLabel;

  /// The tap on the disc (llamada.js: only in the idle state starts a call).
  final VoidCallback onTap;

  @override
  State<CallMicStage> createState() => _CallMicStageState();
}

class _CallMicStageState extends State<CallMicStage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => setState(() => _elapsed = d));
    _sync(restart: false);
  }

  @override
  void didUpdateWidget(CallMicStage old) {
    super.didUpdateWidget(old);
    _sync(restart: old.state != widget.state);
  }

  bool get _animated =>
      !widget.reduceMotion &&
      (widget.state == CallState.connecting ||
          widget.state == CallState.danny ||
          widget.state == CallState.proc);

  // A CSS animation starts again when the state attribute changes: so does this clock.
  void _sync({required bool restart}) {
    if (restart && _ticker.isActive) _ticker.stop();
    if (_animated && !_ticker.isActive) {
      _elapsed = Duration.zero;
      _ticker.start();
    } else if (!_animated && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // `@keyframes lpul{50%{transform:scale(1.1)}}`, .9s ease-in-out infinite
  double get _pulse {
    final p = (_elapsed.inMicroseconds % 900000) / 900000;
    final t = p < .5 ? p * 2 : (1 - p) * 2;
    return 1 + .1 * Curves.easeInOut.transform(t);
  }

  // `.lw`: 1.5 s ease-out infinite, the second ring .5 s late and the third 1 s late (before its delay a
  // ring is as the base style has it: opacity 0). `@keyframes lwave`: scale 1 to `--wv`, opacity .85 to 0.
  Widget _ringOf(int k) {
    final t = _elapsed.inMicroseconds - k * 500000;
    if (t < 0) return const SizedBox.shrink();
    final p = (t % 1500000) / 1500000;
    final e = Curves.easeOut.transform(p);
    return PositionedDirectional(
      start: 12,
      top: 12,
      child: IgnorePointer(
        child: Opacity(
          opacity: .85 * (1 - e),
          child: Transform.scale(
            scale: 1 + (widget.wave - 1) * e,
            child: Container(
              width: CallMetrics.disc,
              height: CallMetrics.disc,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CoquiColors.lessonBlue, width: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // `@keyframes ldot`: 0%, 70%, 100% opacity .3 scale .8; 35% opacity 1 scale 1.15; 1 s, ease, the dots
  // .18 s and .36 s late.
  Widget _dot(int k) {
    var opacity = 1.0;
    var scale = 1.0;
    if (_animated) {
      final t = _elapsed.inMicroseconds - k * 180000;
      if (t >= 0) {
        final p = (t % 1000000) / 1000000;
        const ease = Cubic(.25, .1, .25, 1);
        double up(double a, double b, double f) =>
            a + (b - a) * ease.transform(f);
        if (p < .35) {
          opacity = up(.3, 1, p / .35);
          scale = up(.8, 1.15, p / .35);
        } else if (p < .7) {
          opacity = up(1, .3, (p - .35) / .35);
          scale = up(1.15, .8, (p - .35) / .35);
        } else {
          opacity = .3;
          scale = .8;
        }
      }
    }
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: CoquiColors.lessonInk,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final reduce = widget.reduceMotion;
    final quiet = s == CallState.danny || s == CallState.proc;
    final Widget icon;
    if (s == CallState.proc) {
      icon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var k = 0; k < 3; k++) ...[
            if (k > 0) const SizedBox(width: 6),
            _dot(k),
          ],
        ],
      );
    } else if (s == CallState.danny || s == CallState.you) {
      icon = CoquiIcon(
        CoquiIcons.mic,
        size: 32,
        color: s == CallState.danny ? CallColors.grey : CoquiColors.lessonInk,
      );
    } else {
      icon = const CoquiIcon(
        CoquiIcons.phone,
        size: 32,
        color: CoquiColors.lessonInk,
      );
    }
    Widget disc = AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
      width: CallMetrics.disc,
      height: CallMetrics.disc,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: quiet ? CallColors.discQuiet : CoquiColors.lessonGreen,
      ),
      child: icon,
    );
    if (s == CallState.connecting && !reduce) {
      disc = Transform.scale(scale: _pulse, child: disc);
    }
    return SizedBox(
      width: CallMetrics.micBox,
      height: CallMetrics.micBox,
      child: Stack(
        alignment: AlignmentDirectional.center,
        clipBehavior: Clip.none,
        children: [
          if (s == CallState.danny && !reduce)
            for (var k = 0; k < 3; k++) _ringOf(k),
          // `.lg`: a ring of box-shadow, its thickness the level, only on the learner's turn
          PositionedDirectional(
            start: 12,
            top: 12,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 80),
                curve: Curves.linear,
                width: CallMetrics.disc,
                height: CallMetrics.disc,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: s == CallState.you
                      ? [
                          BoxShadow(
                            color: CallColors.levelRing,
                            spreadRadius: widget.ring,
                          ),
                        ]
                      : const [],
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: widget.semanticLabel,
            enabled: s == CallState.idle,
            onTap: s == CallState.idle ? widget.onTap : null,
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: s == CallState.idle ? widget.onTap : null,
                child: disc,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
