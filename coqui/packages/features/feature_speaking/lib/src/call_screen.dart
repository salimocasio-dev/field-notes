/// The live speaking call screen, powered by [CallController] and shared Noche components.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_controller.dart';
import 'package:feature_speaking/src/call_look.dart';
import 'package:feature_speaking/src/call_mic.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:feature_speaking/src/wording.dart';
import 'package:material_ui/material_ui.dart';

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
      callId: widget.callId,
      entitlements: s.entitlements,
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
    c.dispose();
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
                  ? _landscape(context, lang, size, safe, reduce, live)
                  : _portrait(context, lang, size, safe, reduce, live),
            ),
          ),
        ),
      ),
    );
  }

  // ---- the pieces ----

  /// Top bar: 48x48 close button at the start, tabular mm:ss timer at the end.
  Widget _bar(Language lang) => SizedBox(
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
              child: Text(c.timerText, style: CallText.timer),
            ),
          ),
        ],
      ),
    ),
  );

  /// The picture the partner shows, whole-number scaled; keeps its room when hidden.
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

  /// Partner's line (two lines at most) and what the app heard under it.
  Widget _texts(Language lang, {required TextAlign align}) {
    final courseLocale = Locale(lang.code);
    final lineStyle = c.lineMuted
        ? CallText.lineMuted
        : NocheType.forScript(CallText.line, lang.script);
    final heardStyle = NocheType.forScript(CallText.heard, lang.script);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CallMetrics.textMax),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CallMetrics.lineBox),
            child: Text(
              c.dannyLine,
              textAlign: align,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              locale: c.lineMuted ? null : courseLocale,
              style: lineStyle,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CallMetrics.heardBox),
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
        ],
      ),
    );
  }

  /// Outline Help button; keeps its room before the call connects.
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
    );
  }

  Widget _mic(Language lang, bool reduce, {required bool land}) => CallMicStage(
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

  Widget _note(Language lang, {required TextAlign align}) => Semantics(
    liveRegion: true,
    child: ConstrainedBox(
      key: const ValueKey('call-note'),
      constraints: const BoxConstraints(minHeight: 20),
      child: c.note.isEmpty
          ? const SizedBox.shrink()
          : Text(
              c.note,
              textAlign: _englishAlign(lang, align),
              textDirection: TextDirection.ltr,
              style: CallText.note,
            ),
    ),
  );

  /// One plain error line in the middle.
  Widget _error() => Semantics(
    liveRegion: true,
    child: Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
        child: Text(
          c.errorLine,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: CallText.error,
        ),
      ),
    ),
  );

  /// End summary: "Call done", "N min · M words said", said word chips, and primary back button.
  Widget _summary(
    Language lang,
    Size size,
    EdgeInsets safe, {
    required bool land,
  }) {
    final top = land ? 8.0 : size.height * .35 - 56;
    final courseLocale = Locale(lang.code);
    final speakTabName = lang.tabNames[CoquiTabs.speakId] ?? CoquiLabels.speak;
    final summaryAlign = _englishAlign(lang, TextAlign.start);
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: CallMetrics.textMax),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 24 + safe.bottom),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.only(top: top < 0 ? 0 : top),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        CallTexts.done,
                        textAlign: summaryAlign,
                        textDirection: TextDirection.ltr,
                        style: CallText.doneTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.summaryLine,
                        textAlign: summaryAlign,
                        textDirection: TextDirection.ltr,
                        style: CallText.summary,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final w in c.said)
                            NocheChip(
                              label: CallTexts.chip(w),
                              script: lang.script,
                              locale: courseLocale,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              NochePrimaryButton(
                key: const Key('call-end-back'),
                label: SpeakWording.backToSpeak(speakTabName),
                onPressed: c.close,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- portrait ----

  Widget _portrait(
    BuildContext context,
    Language lang,
    Size size,
    EdgeInsets safe,
    bool reduce,
    bool live,
  ) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Column(
      children: [
        _bar(lang),
        Expanded(
          child: c.state == CallState.err
              ? _error()
              : c.state == CallState.done
              ? _summary(lang, size, safe, land: false)
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
                _mic(lang, reduce, land: false),
                const SizedBox(height: 4),
                _label(lang, align: TextAlign.center),
                const SizedBox(height: 4),
                _note(lang, align: TextAlign.center),
                const SizedBox(height: 12),
                _help(),
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
    bool live,
  ) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (!live) {
      return Column(
        children: [
          _bar(lang),
          Expanded(
            child: c.state == CallState.err
                ? _error()
                : _summary(lang, size, safe, land: true),
          ),
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
                    _mic(lang, reduce, land: true),
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
