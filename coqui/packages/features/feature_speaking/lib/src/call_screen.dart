/// The live speaking call screen, powered by [CallController] and shared Noche components.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_controller.dart';
import 'package:feature_speaking/src/call_look.dart';
import 'package:feature_speaking/src/call_mic.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:feature_speaking/src/motion.dart';
import 'package:feature_speaking/src/wording.dart';
import 'package:material_ui/material_ui.dart';

class _OutgoingLiveSnapshot {
  const _OutgoingLiveSnapshot({
    required this.picturePair,
    required this.pictureShown,
    required this.dannyLine,
    required this.lineMuted,
    required this.heardLine,
    required this.micState,
    required this.ring,
    required this.wave,
    required this.label,
  });

  final ReviewPair? picturePair;
  final bool pictureShown;
  final String dannyLine;
  final bool lineMuted;
  final String heardLine;
  final CallState micState;
  final double ring;
  final double wave;
  final String label;
}

/// Full-screen speaking call for one place (`CallRoute`) on [NocheColors.lessonGround].
class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.services,
    required this.placeId,
    this.callId,
  });

  final Services services;
  final String placeId;
  final String? callId;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late final CallController c;
  Timer? _ticker;

  late final AnimationController _enterController = AnimationController(
    vsync: this,
  );
  bool _enterStarted = false;
  NocheMotionData _enterMotion = NocheMotion.normal;
  Duration _enterTotal = Duration.zero;

  late final AnimationController _pictureSwapController = AnimationController(
    vsync: this,
    value: 1.0,
  );
  NocheMotionData _pictureSwapMotion = NocheMotion.normal;
  String? _lastPictureWord;

  late final AnimationController _exitController = AnimationController(
    vsync: this,
    value: 1.0,
  )..addStatusListener(_handleExitStatus);
  NocheMotionData _exitMotion = NocheMotion.normal;
  bool _prevLive = true;
  _OutgoingLiveSnapshot? _lastLiveSnapshot;
  _OutgoingLiveSnapshot? _outgoingSnapshot;

  String _lastDannyLine = '';
  bool _lastDannyMuted = false;
  int _dannyLineSeq = 0;
  String _lastHeardLine = '';
  int _heardLineSeq = 0;
  String _lastNote = '';
  int _noteSeq = 0;

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
      callId: widget.callId,
      entitlements: s.entitlements,
      clips: s.clips,
      onClose: s.nav.back,
    );
    c.open();
    _lastPictureWord = c.pictureWord;
    _lastDannyLine = c.dannyLine;
    _lastDannyMuted = c.lineMuted;
    _lastHeardLine = c.heardLine;
    _lastNote = c.note;
    _prevLive = c.state != CallState.done && c.state != CallState.err;
    if (_prevLive) {
      _lastLiveSnapshot = _captureLiveSnapshot();
    }
    c.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enterStarted) return;
    _enterStarted = true;
    _enterMotion = SpeakingMotion.resolve(
      context,
      serviceReduceMotion: widget.services.reduceMotion,
    );
    final chromeEnd = SpeakingMotion.callChromeAfter + _enterMotion.quick;
    final pictureEnd = SpeakingMotion.callPictureAfter + _enterMotion.move;
    _enterTotal = chromeEnd > pictureEnd ? chromeEnd : pictureEnd;
    if (_enterTotal <= Duration.zero) {
      _enterController.value = 1.0;
    } else {
      _enterController.duration = _enterTotal;
      _enterController.forward(from: 0.0);
    }
  }

  _OutgoingLiveSnapshot _captureLiveSnapshot() => _OutgoingLiveSnapshot(
    picturePair: c.picturePair,
    pictureShown: c.pictureShown,
    dannyLine: c.dannyLine,
    lineMuted: c.lineMuted,
    heardLine: c.heardLine,
    micState: c.state,
    ring: c.ring,
    wave: c.wave,
    label: c.label,
  );

  void _handleExitStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _outgoingSnapshot != null &&
        mounted) {
      setState(() {
        _outgoingSnapshot = null;
      });
    }
  }

  void _changed() {
    if (!mounted) return;
    final nowLive = c.state != CallState.done && c.state != CallState.err;

    if (c.pictureWord != _lastPictureWord) {
      _lastPictureWord = c.pictureWord;
      if (_enterStarted && nowLive && c.pictureWord != null && c.pictureShown) {
        _pictureSwapMotion = SpeakingMotion.resolve(
          context,
          serviceReduceMotion: widget.services.reduceMotion,
        );
        _pictureSwapController.duration = _pictureSwapMotion.move;
        _pictureSwapController.forward(from: 0.0);
      }
    }

    if (c.dannyLine != _lastDannyLine || c.lineMuted != _lastDannyMuted) {
      _lastDannyLine = c.dannyLine;
      _lastDannyMuted = c.lineMuted;
      if (!c.lineMuted && c.dannyLine.isNotEmpty) {
        _dannyLineSeq++;
      }
    }

    if (c.heardLine != _lastHeardLine) {
      _lastHeardLine = c.heardLine;
      if (c.heardLine.isNotEmpty) {
        _heardLineSeq++;
      }
    }

    if (c.note != _lastNote) {
      _lastNote = c.note;
      if (c.note.isNotEmpty) {
        _noteSeq++;
      }
    }

    if (_prevLive && !nowLive) {
      _outgoingSnapshot = _lastLiveSnapshot;
      _exitMotion = SpeakingMotion.resolve(
        context,
        serviceReduceMotion: widget.services.reduceMotion,
      );
      _exitController.duration = _exitMotion.quick;
      _exitController.forward(from: 0.0);
    } else if (nowLive) {
      _lastLiveSnapshot = _captureLiveSnapshot();
    }
    _prevLive = nowLive;

    setState(() {});
    _syncTicker();
  }

  void _syncTicker() {
    if (c.ticking && _ticker == null) {
      _ticker = Timer.periodic(SpeakingMotion.callTick, (_) => c.tick());
    } else if (!c.ticking && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    c.removeListener(_changed);
    c.dispose();
    _enterController.dispose();
    _pictureSwapController.dispose();
    _exitController
      ..removeStatusListener(_handleExitStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final land = CallMetrics.landscape(size);
    final safe = mq.padding;
    final reduce = widget.services.reduceMotion || mq.disableAnimations;
    final motion = SpeakingMotion.resolve(
      context,
      serviceReduceMotion: widget.services.reduceMotion,
    );
    final done = c.state == CallState.done;
    final err = c.state == CallState.err;
    final live = !done && !err;
    final lang = widget.services.course.language;
    final dir = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : Directionality.of(context);
    return MediaQuery(
      data: mq.copyWith(disableAnimations: reduce),
      child: Directionality(
        textDirection: dir,
        child: Semantics(
          key: const Key('call-screen'),
          container: true,
          label: CallTexts.callPartner(lang.partnerName),
          child: ColoredBox(
            color: NocheColors.lessonGround,
            child: Padding(
              padding: EdgeInsetsDirectional.only(top: land ? 0 : safe.top),
              child: land
                  ? _landscape(context, lang, size, safe, reduce, motion, live)
                  : _portrait(context, lang, size, safe, reduce, motion, live),
            ),
          ),
        ),
      ),
    );
  }

  // ---- the pieces ----

  /// Top bar: 48x48 close button at the start, tabular mm:ss timer at the end.
  Widget _bar(Language lang) => AnimatedBuilder(
    animation: _enterController,
    builder: (context, child) {
      final elapsedUs =
          _enterController.value * _enterTotal.inMicroseconds.toDouble();
      final opacity = _enterController.isCompleted
          ? 1.0
          : SpeakingMotion.segmentProgressUs(
              elapsedUs: elapsedUs,
              start: SpeakingMotion.callChromeAfter,
              duration: _enterMotion.quick,
              curve: _enterMotion.enter,
            );
      return Opacity(
        key: const ValueKey('call-bar-opacity'),
        opacity: opacity,
        child: child,
      );
    },
    child: SizedBox(
      height: CallMetrics.bar,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 0),
        child: Row(
          children: [
            Pressable(
              key: const Key('call-close'),
              onPressed: c.closeX,
              semanticLabel: NocheA11y.label(
                NocheA11y.close,
                courseWords: lang.a11yWords,
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
            ),
            const Spacer(),
            Visibility(
              visible: c.state != CallState.done,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: ExcludeSemantics(
                child: NocheLtr(
                  child: Text(c.timerText, style: CallText.timer),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _pictureBox(
    Size size,
    double dpr, {
    required ReviewPair? pair,
    required bool shown,
  }) {
    final s = CallMetrics.pictureScale(size: size, devicePixelRatio: dpr);
    final w = CallMetrics.pictureW * s / dpr;
    final h = CallMetrics.pictureH * s / dpr;
    return SizedBox(
      width: w,
      height: h,
      child: shown && pair != null
          ? DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(color: NocheColors.lessonLine, spreadRadius: 1.5),
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

  /// The picture the partner shows, whole-number scaled; keeps its room when hidden.
  Widget _picture(Size size, double dpr) {
    final box = _pictureBox(
      size,
      dpr,
      pair: c.picturePair,
      shown: c.pictureShown,
    );
    return AnimatedBuilder(
      animation: Listenable.merge([_enterController, _pictureSwapController]),
      builder: (context, child) {
        final double p;
        final double row;
        if (_pictureSwapController.isAnimating) {
          p = _pictureSwapMotion.enter
              .transform(_pictureSwapController.value)
              .clamp(0.0, 1.0);
          row = _pictureSwapMotion.row;
        } else {
          final elapsedUs =
              _enterController.value * _enterTotal.inMicroseconds.toDouble();
          p = _enterController.isCompleted
              ? 1.0
              : SpeakingMotion.segmentProgressUs(
                  elapsedUs: elapsedUs,
                  start: SpeakingMotion.callPictureAfter,
                  duration: _enterMotion.move,
                  curve: _enterMotion.enter,
                );
          row = _enterMotion.row;
        }
        final dy = row * (1.0 - p);
        return Transform.translate(
          key: const ValueKey('call-picture-motion'),
          offset: Offset(0, dy),
          child: Opacity(opacity: p, child: child),
        );
      },
      child: box,
    );
  }

  /// Partner's line (two lines at most) and what the app heard under it.
  Widget _texts(Language lang, {required TextAlign align}) {
    final courseLocale = Locale(lang.code);
    final lineStyle = c.lineMuted
        ? CallText.lineMuted
        : NocheType.forScript(CallText.line, lang.script);
    final heardStyle = NocheType.forScript(CallText.heard, lang.script);
    final partnerKey = (!c.lineMuted && c.dannyLine.isNotEmpty)
        ? '${_dannyLineSeq}_${c.dannyLine}'
        : null;
    final heardKey = c.heardLine.isNotEmpty
        ? '${_heardLineSeq}_${c.heardLine}'
        : null;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CallMetrics.textMax),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CallMetrics.lineBox),
            child: _RisingLine(
              contentKey: partnerKey,
              animateInitial: partnerKey != null,
              motionKey: const ValueKey('call-partner-line-motion'),
              child: Text(
                c.dannyLine,
                textAlign: align,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                locale: c.lineMuted ? null : courseLocale,
                style: lineStyle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CallMetrics.heardBox),
            child: _RisingLine(
              contentKey: heardKey,
              animateInitial: heardKey != null,
              motionKey: const ValueKey('call-heard-line-motion'),
              child: Text(
                c.heardLine,
                textAlign: align,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                locale: courseLocale,
                style: heardStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Outline Help button; keeps its room before the call connects.
  Widget _help(NocheMotionData motion) {
    final show = c.state != CallState.idle && c.state != CallState.connecting;
    return Visibility(
      visible: show,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: AnimatedOpacity(
        opacity: show ? 1.0 : 0.0,
        duration: motion.quick,
        curve: motion.enter,
        child: SizedBox(
          width: CallMetrics.helpWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.helpPressed ? CallColors.helpPressed : null,
              borderRadius: BorderRadius.circular(NocheSize.pillRadius),
            ),
            child: NocheOutlineButton(
              label: CallTexts.help,
              semanticLabel: CallTexts.help,
              expand: true,
              onPressed: show ? c.help : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicHeroShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Center(
          child: SizedBox(
            width: NocheSize.mic,
            height: NocheSize.mic,
            child: NochePlayDisc(
              size: NocheSize.mic,
              icon: NocheIcons.mic,
              halo: true,
              semanticLabel: CallTexts.startCall,
              onPressed: null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _mic(
    BuildContext context,
    Language lang,
    bool reduce,
    NocheMotionData motion, {
    required bool land,
    required bool live,
  }) {
    Widget mic = CallMicStage(
      key: const Key('call-mic-stage'),
      state: c.state,
      language: lang,
      ring: c.ring,
      wave: c.wave,
      reduceMotion: reduce,
      labelGap: 8,
      barGroupGap: land ? 8 : NocheMic.defaultBarGroupGap,
      semanticLabel: c.state == CallState.idle ? CallTexts.startCall : c.label,
      onTap: () => unawaited(c.start()),
    );
    if (!reduce && TickerMode.valuesOf(context).enabled && live) {
      mic = Hero(
        tag: SpeakingMotion.callMicHeroTag,
        curve: motion.travel,
        createRectTween: (begin, end) => RectTween(begin: begin, end: end),
        flightShuttleBuilder: _buildMicHeroShuttle,
        child: mic,
      );
    }
    return mic;
  }

  TextAlign _englishAlign(Language lang, TextAlign align) =>
      lang.direction == LanguageDirection.rtl && align == TextAlign.start
      ? TextAlign.end
      : align;

  Widget _label(Language lang, {required TextAlign align}) => Semantics(
    liveRegion: true,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: Text(
        c.label,
        textAlign: _englishAlign(lang, align),
        textDirection: TextDirection.ltr,
        style: CallText.label,
      ),
    ),
  );

  Widget _note(Language lang, {required TextAlign align}) {
    final noteKey = c.note.isNotEmpty ? '${_noteSeq}_${c.note}' : null;
    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        key: const ValueKey('call-note'),
        constraints: const BoxConstraints(minHeight: 20),
        child: _RisingLine(
          contentKey: noteKey,
          animateInitial: noteKey != null,
          motionKey: const ValueKey('call-note-motion'),
          child: c.note.isEmpty
              ? const SizedBox.shrink()
              : Text(
                  c.note,
                  textAlign: _englishAlign(lang, align),
                  textDirection: TextDirection.ltr,
                  style: CallText.note,
                ),
        ),
      ),
    );
  }

  /// One plain error line in the middle with calm arrival.
  Widget _error() => _CallErrorArrival(errorLine: c.errorLine);

  /// End summary: "Call done", "N min · M words said", 40-high outline word
  /// pills, and primary back button.
  Widget _summary(
    Language lang,
    Size size,
    EdgeInsets safe, {
    required bool land,
  }) {
    final top = land ? 8.0 : size.height * .35 - 56;
    final speakTabName = lang.tabNames[CoquiTabs.speakId] ?? CoquiLabels.speak;
    return _CallDoneSummary(
      lang: lang,
      summaryLine: c.summaryLine,
      said: c.said,
      speakTabName: speakTabName,
      topPadding: top < 0 ? 0 : top,
      bottomSafe: safe.bottom,
      summaryAlign: _englishAlign(lang, TextAlign.start),
      onBack: c.close,
    );
  }

  Widget _outgoingLiveVisual(
    _OutgoingLiveSnapshot snap,
    Language lang,
    Size size,
    double dpr,
    EdgeInsets safe, {
    required bool land,
  }) {
    final courseLocale = Locale(lang.code);
    final lineStyle = snap.lineMuted
        ? CallText.lineMuted
        : NocheType.forScript(CallText.line, lang.script);
    final heardStyle = NocheType.forScript(CallText.heard, lang.script);
    final align = land ? TextAlign.start : TextAlign.center;
    final texts = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CallMetrics.textMax),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CallMetrics.lineBox),
            child: Text(
              snap.dannyLine,
              textAlign: align,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              locale: snap.lineMuted ? null : courseLocale,
              style: lineStyle,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CallMetrics.heardBox),
            child: Text(
              snap.heardLine,
              textAlign: align,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              locale: courseLocale,
              style: heardStyle,
            ),
          ),
        ],
      ),
    );
    final pic = _pictureBox(
      size,
      dpr,
      pair: snap.picturePair,
      shown: snap.pictureShown,
    );
    final passiveMic = MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: NocheMic(
        state: nocheMicStateForCall(snap.micState),
        language: lang,
        level: callMicLevel(
          state: snap.micState,
          ring: snap.ring,
          wave: snap.wave,
        ),
        compactLabel: true,
        labelGap: 8,
        barGroupGap: land ? 8 : NocheMic.defaultBarGroupGap,
        onPressed: null,
      ),
    );

    if (land) {
      return Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: Center(child: pic),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 16),
                      child: texts,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    0,
                    0,
                    16,
                    16 + safe.bottom,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: passiveMic,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [pic, const SizedBox(height: 16), texts],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 24 + safe.bottom),
          child: passiveMic,
        ),
      ],
    );
  }

  Widget _nonLiveArea(
    Language lang,
    Size size,
    double dpr,
    EdgeInsets safe, {
    required bool land,
  }) {
    final incoming = c.state == CallState.err
        ? _error()
        : _summary(lang, size, safe, land: land);
    final snap = _outgoingSnapshot;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (snap != null)
          IgnorePointer(
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _exitController,
                builder: (context, child) {
                  final opacity =
                      (1.0 - _exitMotion.exit.transform(_exitController.value))
                          .clamp(0.0, 1.0);
                  return Opacity(
                    key: const ValueKey('call-exit-fade'),
                    opacity: opacity,
                    child: child,
                  );
                },
                child: _outgoingLiveVisual(
                  snap,
                  lang,
                  size,
                  dpr,
                  safe,
                  land: land,
                ),
              ),
            ),
          ),
        incoming,
      ],
    );
  }

  // ---- portrait ----

  Widget _portrait(
    BuildContext context,
    Language lang,
    Size size,
    EdgeInsets safe,
    bool reduce,
    NocheMotionData motion,
    bool live,
  ) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Column(
      children: [
        _bar(lang),
        Expanded(
          child: !live
              ? _nonLiveArea(lang, size, dpr, safe, land: false)
              : Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _picture(size, dpr),
                        const SizedBox(height: 16),
                        _texts(lang, align: TextAlign.center),
                      ],
                    ),
                  ),
                ),
        ),
        if (live)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              16,
              0,
              16,
              24 + safe.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mic(context, lang, reduce, motion, land: false, live: live),
                const SizedBox(height: 4),
                _label(lang, align: TextAlign.center),
                const SizedBox(height: 4),
                _note(lang, align: TextAlign.center),
                const SizedBox(height: 12),
                _help(motion),
              ],
            ),
          ),
      ],
    );
  }

  // ---- landscape ----

  Widget _landscape(
    BuildContext context,
    Language lang,
    Size size,
    EdgeInsets safe,
    bool reduce,
    NocheMotionData motion,
    bool live,
  ) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (!live) {
      return Column(
        children: [
          _bar(lang),
          Expanded(child: _nonLiveArea(lang, size, dpr, safe, land: true)),
        ],
      );
    }
    return Row(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          child: Center(child: _picture(size, dpr)),
        ),
        Expanded(
          child: Column(
            children: [
              _bar(lang),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: _texts(lang, align: TextAlign.start),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  0,
                  0,
                  16,
                  16 + safe.bottom,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _mic(context, lang, reduce, motion, land: true, live: live),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(lang, align: TextAlign.start),
                          _note(lang, align: TextAlign.start),
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _help(motion),
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

/// Rises a newly arrived partner line, heard line, or help note by `motion.row`
/// (`0` under reduced motion) and fades `0 -> 1` in `motion.move` on `enter`.
class _RisingLine extends StatefulWidget {
  const _RisingLine({
    required this.contentKey,
    required this.animateInitial,
    required this.motionKey,
    required this.child,
  });

  final Object? contentKey;
  final bool animateInitial;
  final Key motionKey;
  final Widget child;

  @override
  State<_RisingLine> createState() => _RisingLineState();
}

class _RisingLineState extends State<_RisingLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  );
  NocheMotionData _motion = NocheMotion.normal;
  bool _didInit = false;

  void _startRise() {
    _motion = NocheMotion.of(context);
    _controller.duration = _motion.move;
    _controller.forward(from: 0.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    if (widget.animateInitial && widget.contentKey != null) {
      _startRise();
    }
  }

  @override
  void didUpdateWidget(_RisingLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentKey != null &&
        widget.contentKey != oldWidget.contentKey) {
      _startRise();
    } else if (widget.contentKey == null) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final p = _controller.isCompleted
            ? 1.0
            : _motion.enter.transform(_controller.value).clamp(0.0, 1.0);
        final dy = _motion.row * (1.0 - p);
        return Transform.translate(
          key: widget.motionKey,
          offset: Offset(0, dy),
          child: Opacity(opacity: p, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Staggered `"Call done"` summary: title, `NocheLtr` summary line, 40-high
/// outline word pills (staggered `stagger` apart for indices 0..4; index >= 5
/// shares index 4's start), and orange Back button landing last (`nextDelay`).
class _CallDoneSummary extends StatefulWidget {
  const _CallDoneSummary({
    required this.lang,
    required this.summaryLine,
    required this.said,
    required this.speakTabName,
    required this.topPadding,
    required this.bottomSafe,
    required this.summaryAlign,
    required this.onBack,
  });

  final Language lang;
  final String summaryLine;
  final List<String> said;
  final String speakTabName;
  final double topPadding;
  final double bottomSafe;
  final TextAlign summaryAlign;
  final VoidCallback onBack;

  @override
  State<_CallDoneSummary> createState() => _CallDoneSummaryState();
}

class _CallDoneSummaryState extends State<_CallDoneSummary>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  NocheMotionData _motion = NocheMotion.normal;
  bool _started = false;
  Duration _total = Duration.zero;

  Duration _titleStart() => SpeakingMotion.doneStartAfter;

  Duration _summaryStart() => SpeakingMotion.doneStartAfter + _motion.stagger;

  Duration _wordStart(int index) =>
      SpeakingMotion.doneStartAfter +
      _motion.stagger * (2 + math.min(index, 4));

  Duration _backStart() {
    final lastRowStart = widget.said.isEmpty
        ? _summaryStart()
        : _wordStart(widget.said.length - 1);
    return lastRowStart + _motion.nextDelay;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _motion = NocheMotion.of(context);
    _total = _backStart() + _motion.move;
    if (_total <= Duration.zero) {
      _controller.value = 1.0;
    } else {
      _controller.duration = _total;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _progressFor(Duration start) {
    if (_controller.isCompleted) return 1.0;
    final elapsedUs = _controller.value * _total.inMicroseconds.toDouble();
    return SpeakingMotion.segmentProgressUs(
      elapsedUs: elapsedUs,
      start: start,
      duration: _motion.move,
      curve: _motion.enter,
    );
  }

  Widget _arrive({
    required Key motionKey,
    required Duration start,
    required Widget child,
  }) {
    final p = _progressFor(start);
    final dy = _motion.row * (1.0 - p);
    return Transform.translate(
      key: motionKey,
      offset: Offset(0, dy),
      child: Opacity(opacity: p, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseLocale = Locale(widget.lang.code);
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: CallMetrics.textMax),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            16,
            0,
            16,
            24 + widget.bottomSafe,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsetsDirectional.only(
                        top: widget.topPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _arrive(
                            motionKey: const ValueKey('call-done-title-motion'),
                            start: _titleStart(),
                            child: Text(
                              CallTexts.done,
                              textAlign: widget.summaryAlign,
                              textDirection: TextDirection.ltr,
                              style: CallText.doneTitle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _arrive(
                            motionKey: const ValueKey(
                              'call-done-summary-motion',
                            ),
                            start: _summaryStart(),
                            child: NocheLtr(
                              child: Text(
                                widget.summaryLine,
                                textAlign: widget.summaryAlign,
                                textDirection: TextDirection.ltr,
                                style: CallText.summary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < widget.said.length; i++)
                                _arrive(
                                  motionKey: ValueKey(
                                    'call-done-word-motion-$i',
                                  ),
                                  start: _wordStart(i),
                                  child: Container(
                                    key: ValueKey('call-done-word-$i'),
                                    height: 40,
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                          horizontal: 16,
                                        ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: NocheColors.lessonBorder,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          CallTexts.chip(widget.said[i]),
                                          maxLines: 1,
                                          softWrap: false,
                                          locale: courseLocale,
                                          style: NocheType.forScript(
                                            NocheType.rowTitle.copyWith(
                                              fontWeight: FontWeight.w600,
                                              height: 1,
                                            ),
                                            widget.lang.script,
                                          ).copyWith(color: NocheColors.text),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _arrive(
                    motionKey: const ValueKey('call-done-back-motion'),
                    start: _backStart(),
                    child: NochePrimaryButton(
                      key: const Key('call-end-back'),
                      label: SpeakWording.backToSpeak(widget.speakTabName),
                      onPressed: widget.onBack,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Calm arrival for the plain error line after the live call fades out.
class _CallErrorArrival extends StatefulWidget {
  const _CallErrorArrival({required this.errorLine});

  final String errorLine;

  @override
  State<_CallErrorArrival> createState() => _CallErrorArrivalState();
}

class _CallErrorArrivalState extends State<_CallErrorArrival>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  NocheMotionData _motion = NocheMotion.normal;
  bool _started = false;
  Duration _total = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _motion = NocheMotion.of(context);
    _total = SpeakingMotion.doneStartAfter + _motion.move;
    if (_total <= Duration.zero) {
      _controller.value = 1.0;
    } else {
      _controller.duration = _total;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final elapsedUs =
                  _controller.value * _total.inMicroseconds.toDouble();
              final p = _controller.isCompleted
                  ? 1.0
                  : SpeakingMotion.segmentProgressUs(
                      elapsedUs: elapsedUs,
                      start: SpeakingMotion.doneStartAfter,
                      duration: _motion.move,
                      curve: _motion.enter,
                    );
              final dy = _motion.row * (1.0 - p);
              return Transform.translate(
                key: const ValueKey('call-error-motion'),
                offset: Offset(0, dy),
                child: Opacity(opacity: p, child: child),
              );
            },
            child: Text(
              widget.errorLine,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: CallText.error,
            ),
          ),
        ),
      ),
    );
  }
}
