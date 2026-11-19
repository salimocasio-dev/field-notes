/// The voice test screen (habla-prueba.html): a thin bar on top, the line to say in the middle, the mic disc in the
/// bottom third; at the end the result and what was heard for each line.
library;

import 'dart:async';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_look.dart';
import 'package:feature_speaking/src/voice_test_controller.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

/// habla-prueba.html's colours and shapes that coqui_ui has no widget for yet (listed in
/// coqui/requests/24-feature-speaking-needs-coqui-ui-call-screen.md).
abstract final class _Test {
  /// `.dot.cur` the dash of the line he is on. habla-prueba.html:20
  static const dotCurrent = Color(0xFF7A7A84);

  /// `#rows li` and `#finfoot` hairlines. habla-prueba.html:59, 66
  static const hairline = Color(0xFF2C2C33);

  /// MISS: the ring and the dash. habla-prueba.html:134
  static const missRing = Color(0xFF6B6B75);
  static const missDash = Color(0xFF9A9AA3);

  /// The mic, filled (`.mi`). habla-prueba.html:88
  static const mic = CoquiIconData([
    IconShape(
      'M12 14a3 3 0 0 0 3-3V6a3 3 0 0 0-6 0v5a3 3 0 0 0 3 3zm5-3a5 5 0 0 1-10 0H5a7 7 0 0 0 6 6.92V21h2v-3.08A7 7 0 0 0 19 11z',
      fill: true,
      stroke: false,
    ),
  ]);

  /// The arrow of the next disc (stroke 2.4). habla-prueba.html:89
  static const next = CoquiIconData([
    IconShape('M5 12h14M13 6l6 6-6 6'),
  ], strokeWidth: 2.4);

  /// The tick of TICK (stroke 2.4). habla-prueba.html:133
  static const tick = CoquiIconData([
    IconShape('M7 12.5l3.2 3.2L17 9'),
  ], strokeWidth: 2.4);

  /// The dash of MISS (stroke 2.4). habla-prueba.html:134
  static const dash = CoquiIconData([IconShape('M8 12h8')], strokeWidth: 2.4);

  static final n = CoquiText.lessonStateLabel.copyWith(letterSpacing: .04 * 12);
  static final hint = CoquiText.lessonBody;
  static final heardText = CoquiText.lessonBody;
  static final rowLine = CoquiText.lessonBody.copyWith(
    fontWeight: FontWeight.w600,
    color: CoquiColors.lessonInk,
  );
  static final rowAlt = CoquiText.lessonStateLabel.copyWith(
    color: CoquiColors.lessonInk3,
    fontWeight: FontWeight.w400,
  );
}

class VoiceTestScreen extends StatefulWidget {
  const VoiceTestScreen({
    super.key,
    required this.services,
    required this.content,
  });

  final Services services;
  final VoiceTestContent content;

  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  late final VoiceTestController c;

  @override
  void initState() {
    super.initState();
    final s = widget.services;
    c = VoiceTestController(
      speech: s.speech,
      clock: s.clock,
      content: widget.content,
      store: s.storage(voiceTestSpace),
    )..addListener(_changed);
    unawaited(c.start());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    c.dispose();
    super.dispose();
  }

  VoiceTestLabels get _l => widget.content.labels;

  /// TICK: a green disc with a white tick, 24 px. habla-prueba.html:133
  Widget get _tick => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: CoquiColors.lessonGreen,
    ),
    child: const CoquiIcon(_Test.tick, size: 24, color: CoquiColors.lessonInk),
  );

  /// MISS: a grey ring with a short dash, 24 px. habla-prueba.html:134
  Widget get _miss => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: _Test.missRing, width: 2),
    ),
    child: const CoquiIcon(_Test.dash, size: 20, color: _Test.missDash),
  );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final safe = mq.padding;
    final land = CoquiLayout.lessonLandscape(context);
    final ending = c.state == VoiceTestState.end;
    return ColoredBox(
      color: CoquiColors.lessonBg,
      child: ending
          ? _end(safe)
          : Padding(
              padding: EdgeInsets.fromLTRB(
                safe.left,
                0,
                safe.right,
                safe.bottom,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      _top(safe, land),
                      _ins(),
                      Expanded(child: _main(land)),
                    ],
                  ),
                  Positioned(left: 0, right: 0, bottom: 0, child: _foot(land)),
                ],
              ),
            ),
    );
  }

  /// `#top` and `#bar`: the progress as dashes, green for a line tried, a lighter grey for the one he is on.
  Widget _top(EdgeInsets safe, bool land) => SizedBox(
    height: (land ? 40 : 56) + safe.top,
    child: Padding(
      padding: EdgeInsets.fromLTRB(16, safe.top, 16, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: CoquiMetrics.lessonBarMax,
          ),
          child: Semantics(
            label: _l.progress,
            value: '${c.tried} / ${c.n}',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var k = 0; k < c.n; k++) ...[
                  if (k > 0) const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: CoquiMetrics.dotHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: c.runLines[k].tried
                            ? CoquiColors.lessonGreen
                            : k == c.i
                            ? _Test.dotCurrent
                            : CoquiColors.dotOff,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  /// `#ins`: the one English line.
  Widget _ins() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      'Tap the mic and say each Spanish line.',
      textAlign: TextAlign.center,
      style: CoquiText.lessonBody,
    ),
  );

  Widget _main(bool land) {
    final line = c.line;
    final done = c.state == VoiceTestState.done;
    final run = c.current;
    final hint = line.hint ?? '';
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, land ? 104 : 112),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${c.i + 1} / ${c.n}', style: _Test.n),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                style: CoquiText.lessonLine,
              ),
            ),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(hint, textAlign: TextAlign.center, style: _Test.hint),
            ],
            SizedBox(height: land ? 8 : 24),
            // `#heard`: hidden (but there) until the line has been tried
            Visibility(
              visible: done,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, minHeight: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    run.ok ? _tick : _miss,
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        run.alts.isNotEmpty ? run.alts.first : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: run.ok
                            ? _Test.heardText.copyWith(color: CoquiColors.heard)
                            : _Test.heardText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `#foot`: the state label, and the mic disc, or the next disc once the line is tried.
  Widget _foot(bool land) {
    final s = c.state;
    final reduce =
        widget.services.reduceMotion ||
        MediaQuery.of(context).disableAnimations;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        land ? 16 + MediaQuery.paddingOf(context).bottom : 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 16,
            child: Semantics(
              liveRegion: true,
              child: Text(c.status, style: CoquiText.lessonStateLabel),
            ),
          ),
          SizedBox(height: land ? 4 : 8),
          if (s == VoiceTestState.ready ||
              s == VoiceTestState.listen ||
              s == VoiceTestState.proc)
            _VoiceMicDisc(
              state: s,
              reduceMotion: reduce,
              semanticLabel: _l.mic,
              onTap: () => unawaited(c.onMic()),
            )
          else if (s == VoiceTestState.done)
            _Disc(
              semanticLabel: _l.next,
              onTap: c.onNext,
              child: const CoquiIcon(
                _Test.next,
                size: 32,
                color: CoquiColors.lessonInk,
              ),
            ),
        ],
      ),
    );
  }

  /// `#fin`: "Heard right: N of 12", a note if the recogniser cannot work, what was heard for each line, and "Otra
  /// vez".
  Widget _end(EdgeInsets safe) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(c.result, style: CoquiText.lessonH1),
                  ),
                  if (c.unavailable.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_l.unavailable, style: CoquiText.lessonBody),
                  ],
                  const SizedBox(height: 16),
                  for (final e in c.runLines) _row(e),
                ],
              ),
            ),
          ),
        ),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + safe.bottom),
        decoration: const BoxDecoration(
          color: CoquiColors.lessonBg,
          border: Border(top: BorderSide(color: _Test.hairline)),
        ),
        child: LessonButton(
          kind: LessonButtonKind.outline,
          label: _l.again,
          onPressed: () => unawaited(c.start()),
        ),
      ),
    ],
  );

  /// `#rows li`: the mark, the line, what was heard (green when right), and the other things it heard.
  Widget _row(VoiceLineRun e) {
    final best = e.alts.isNotEmpty ? e.alts.first : '—';
    final more = e.alts.skip(1).join(' · ');
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _Test.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          e.ok ? _tick : _miss,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.line, style: _Test.rowLine),
                Text(
                  best,
                  style: e.ok
                      ? _Test.heardText.copyWith(color: CoquiColors.heard)
                      : _Test.heardText,
                ),
                if (more.isNotEmpty) Text(more, style: _Test.rowAlt),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.disc`: a 72 px green disc with a soft shadow. habla-prueba.html:34
class _Disc extends StatelessWidget {
  const _Disc({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.color = CoquiColors.lessonGreen,
    this.ringShadow = const [],
  });

  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final Color color;
  final List<BoxShadow> ringShadow;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    onTap: onTap,
    child: ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: CallMetrics.disc,
          height: CallMetrics.disc,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [...ringShadow, ...CoquiShadows.startDisc],
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// The mic disc with its states: ready, listening (a ring spreads from the disc), thinking (blue, three dots).
class _VoiceMicDisc extends StatefulWidget {
  const _VoiceMicDisc({
    required this.state,
    required this.reduceMotion,
    required this.semanticLabel,
    required this.onTap,
  });

  final VoiceTestState state;
  final bool reduceMotion;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  State<_VoiceMicDisc> createState() => _VoiceMicDiscState();
}

class _VoiceMicDiscState extends State<_VoiceMicDisc>
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
  void didUpdateWidget(_VoiceMicDisc old) {
    super.didUpdateWidget(old);
    _sync(restart: old.state != widget.state);
  }

  bool get _animated =>
      !widget.reduceMotion &&
      (widget.state == VoiceTestState.listen ||
          widget.state == VoiceTestState.proc);

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

  // `@keyframes blink{0%,100%{opacity:.3}50%{opacity:1}}`, 1 s ease-in-out infinite, the dots .15 s apart
  Widget _dot(int k) {
    var o = widget.reduceMotion ? .8 : 1.0;
    if (_animated) {
      final t = _elapsed.inMicroseconds - k * 150000;
      if (t >= 0) {
        final p = (t % 1000000) / 1000000;
        final f = p < .5 ? p * 2 : (1 - p) * 2;
        o = .3 + .7 * Curves.easeInOut.transform(f);
      }
    }
    return Opacity(
      opacity: o,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: CoquiColors.lessonInk,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    List<BoxShadow> ring = const [];
    if (s == VoiceTestState.listen) {
      if (widget.reduceMotion) {
        // `prefers-reduced-motion`: a still ring, `0 0 0 6px rgba(23,128,63,.45)`
        ring = const [BoxShadow(color: Color(0x7317803F), spreadRadius: 6)];
      } else {
        // `@keyframes ring`: 1.4 s ease-out, `0 0 0 0 rgba(23,128,63,.55)` to `0 0 0 28px rgba(23,128,63,0)`
        final p = (_elapsed.inMicroseconds % 1400000) / 1400000;
        final e = Curves.easeOut.transform(p);
        ring = [
          BoxShadow(
            color: Color.fromRGBO(23, 128, 63, .55 * (1 - e)),
            spreadRadius: 28 * e,
          ),
        ];
      }
    }
    return _Disc(
      semanticLabel: widget.semanticLabel,
      onTap: s == VoiceTestState.ready ? widget.onTap : null,
      color: s == VoiceTestState.proc
          ? CoquiColors.lessonBlue
          : CoquiColors.lessonGreen,
      ringShadow: ring,
      child: s == VoiceTestState.proc
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var k = 0; k < 3; k++) ...[
                  if (k > 0) const SizedBox(width: 6),
                  _dot(k),
                ],
              ],
            )
          : const CoquiIcon(_Test.mic, size: 32, color: CoquiColors.lessonInk),
    );
  }
}
