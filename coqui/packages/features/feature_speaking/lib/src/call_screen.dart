/// The call screen: `#llam` of llamada.js, on a [CallController].
library;

import 'dart:async';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_controller.dart';
import 'package:feature_speaking/src/call_look.dart';
import 'package:feature_speaking/src/call_mic.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:material_ui/material_ui.dart';

/// The call with Danny for one place (`CallRoute`): full screen, calm dark grey, the tab bar is the shell's to hide.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.services, required this.placeId});

  final Services services;
  final String placeId;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final CallController c;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final s = widget.services;
    c = CallController(
      session: s.call,
      clock: s.clock,
      course: s.course,
      progress: s.progress,
      placeId: widget.placeId,
      clips: s.clips,
      onClose: s.nav.back,
    );
    c.open();
    c.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _syncTicker();
  }

  // llamada.js: `LOOP=setInterval(bucle,50)` from the moment it connects until it is over.
  void _syncTicker() {
    if (c.ticking && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(milliseconds: tickMs),
        (_) => c.tick(),
      );
    } else if (!c.ticking && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    c.removeListener(_changed);
    c.dispose(); // leaves a live call as the old page's pagehide did
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final land = CallMetrics.landscape(size);
    final safe = mq.padding;
    final reduce = widget.services.reduceMotion || mq.disableAnimations;
    final done = c.state == CallState.done;
    final err = c.state == CallState.err;
    final live = !done && !err;
    return Semantics(
      container: true,
      label: CallTexts.callDanny,
      child: ColoredBox(
        color: CoquiColors.lessonBg,
        child: Padding(
          padding: EdgeInsets.only(top: land ? 0 : safe.top),
          child: land
              ? _landscape(context, size, safe, reduce, live)
              : _portrait(context, size, safe, reduce, live),
        ),
      ),
    );
  }

  // ---- the pieces ----

  /// `.lb`: the X at the left, the timer at the right; 8 px above, 16 at the right, 8 at the left.
  Widget _bar(EdgeInsets safe) => SizedBox(
    height: CallMetrics.bar,
    child: Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          LessonCloseButton(onPressed: c.closeX),
          const Spacer(),
          Visibility(
            visible: c.state != CallState.done,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: ExcludeSemantics(
              child: Text(c.timerText, style: CallText.timer),
            ),
          ),
        ],
      ),
    ),
  );

  /// `.lp`: the picture Danny shows, whole-number scaled; with none it keeps its room (`visibility:hidden`).
  Widget _picture(Size size, double dpr) {
    final s = CallMetrics.pictureScale(size: size, devicePixelRatio: dpr);
    final w = CallMetrics.pictureW * s / dpr;
    final h = CallMetrics.pictureH * s / dpr;
    final pair = c.picturePair;
    return SizedBox(
      width: w,
      height: h,
      child: c.pictureShown && pair != null
          ? DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(color: CoquiColors.lessonLine, spreadRadius: 1.5),
                ],
              ),
              child: PictureFrame(
                radius: 0,
                child: widget.services.pictures.of(
                  PictureRef.of(pair, pair.yes),
                ),
              ),
            )
          : null,
    );
  }

  /// `.ltx`: Danny's line (two lines at most) and what the app heard under it.
  Widget _texts({required TextAlign align}) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: CallMetrics.textMax),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: CallMetrics.lineBox,
          child: Text(
            c.dannyLine,
            textAlign: align,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: c.lineMuted ? CallText.lineMuted : CallText.line,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: CallMetrics.heardBox,
          child: Text(
            c.heardLine,
            textAlign: align,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: CallText.heard,
          ),
        ),
      ],
    ),
  );

  /// `.lhelp`: the outline Help button; it keeps its room before the call (`visibility:hidden`).
  Widget _help() {
    final show = c.state != CallState.idle && c.state != CallState.connecting;
    return Visibility(
      visible: show,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: SizedBox(
        width: CallMetrics.helpWidth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.helpPressed ? CallColors.helpPressed : null,
            borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
          ),
          child: LessonButton(
            kind: LessonButtonKind.outline,
            fillWidth: false,
            semanticLabel: CallTexts.help,
            onPressed: show ? c.help : null,
            child: Text(CallTexts.help, style: CoquiText.lessonButton),
          ),
        ),
      ),
    );
  }

  Widget _mic(bool reduce) => CallMicStage(
    state: c.state,
    ring: c.ring,
    wave: c.wave,
    reduceMotion: reduce,
    semanticLabel: c.state == CallState.idle ? CallTexts.startCall : c.label,
    onTap: () => unawaited(c.start()),
  );

  Widget _label({required TextAlign align}) => Semantics(
    liveRegion: true,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: Text(c.label, textAlign: align, style: CallText.label),
    ),
  );

  Widget _note({required TextAlign align}) => Semantics(
    liveRegion: true,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 20),
      child: Text(c.note, textAlign: align, style: CallText.note),
    ),
  );

  /// `.lerr`: one plain line, in the middle.
  Widget _error() => Semantics(
    liveRegion: true,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          c.errorLine,
          textAlign: TextAlign.center,
          style: CallText.error,
        ),
      ),
    ),
  );

  /// `.lsum`: "Call done", "N min · M words said", the words as chips, a blue "Back to Hablar".
  Widget _summary(Size size, EdgeInsets safe, {required bool land}) {
    final top = land ? 8.0 : size.height * .35 - 56;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: CallMetrics.textMax),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + safe.bottom),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: top < 0 ? 0 : top),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(CallTexts.done, style: CoquiText.lessonH1),
                      const SizedBox(height: 8),
                      Text(c.summaryLine, style: CoquiText.lessonBody),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final w in c.said) _chip(w)],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LessonButton(
                kind: LessonButtonKind.blue,
                label: 'Back to ${CoquiLabels.speak}',
                onPressed: c.close,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `.lchips span`: at least 32 high, 12 px at the sides, a 1.5 px ring, a pill.
  Widget _chip(String word) => Container(
    constraints: const BoxConstraints(minHeight: 32),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: CoquiColors.lessonLine,
        width: CoquiLayout.border(context, 1.5),
      ),
    ),
    child: Text(CallTexts.chip(word), style: CallText.chip),
  );

  // ---- portrait ----

  Widget _portrait(
    BuildContext context,
    Size size,
    EdgeInsets safe,
    bool reduce,
    bool live,
  ) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Column(
      children: [
        _bar(safe),
        Expanded(
          child: c.state == CallState.err
              ? _error()
              : c.state == CallState.done
              ? _summary(size, safe, land: false)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _picture(size, dpr),
                        const SizedBox(height: 16),
                        _texts(align: TextAlign.center),
                      ],
                    ),
                  ),
                ),
        ),
        if (live)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 32 + safe.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mic(reduce),
                const SizedBox(height: 8),
                _label(align: TextAlign.center),
                const SizedBox(height: 4),
                _note(align: TextAlign.center),
                const SizedBox(height: 12),
                _help(),
              ],
            ),
          ),
      ],
    );
  }

  // ---- on its side (`@media (orientation:landscape) and (max-height:500px)`) ----

  Widget _landscape(
    BuildContext context,
    Size size,
    EdgeInsets safe,
    bool reduce,
    bool live,
  ) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (!live) {
      return Column(
        children: [
          _bar(safe),
          Expanded(
            child: c.state == CallState.err
                ? _error()
                : _summary(size, safe, land: true),
          ),
        ],
      );
    }
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: _picture(size, dpr)),
        ),
        Expanded(
          child: Column(
            children: [
              _bar(safe),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _texts(align: TextAlign.left),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 16, 16 + safe.bottom),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _mic(reduce),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(align: TextAlign.left),
                          _note(align: TextAlign.left),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _help(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
