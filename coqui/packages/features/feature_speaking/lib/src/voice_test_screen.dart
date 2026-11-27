/// The voice test screen: Noche progress dashes on top, the line to say in the
/// middle, the shared [NocheMic] and primary Next button in the footer; at the
/// end the result and what was heard for each line.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_look.dart';
import 'package:feature_speaking/src/voice_test_controller.dart';
import 'package:feature_speaking/src/wording.dart';
import 'package:material_ui/material_ui.dart';

/// Maps a [VoiceTestState] (and whether the current attempt was heard right) to
/// the shared [NocheMicState].
NocheMicState nocheMicStateForVoiceTest(
  VoiceTestState state, {
  required bool ok,
}) => switch (state) {
  VoiceTestState.load => NocheMicState.thinking,
  VoiceTestState.ready => NocheMicState.ready,
  VoiceTestState.listen => NocheMicState.listening,
  VoiceTestState.proc => NocheMicState.thinking,
  VoiceTestState.done => ok ? NocheMicState.right : NocheMicState.notYet,
  VoiceTestState.end => NocheMicState.right,
};

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
      language: s.course.language,
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

  /// Heard-right mark: 24 px green circle with check.
  Widget get _tick => Container(
    width: 24,
    height: 24,
    alignment: AlignmentDirectional.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: NocheColors.right,
    ),
    child: const NocheIcon(
      NocheIcons.check,
      size: 14,
      strokeWidth: 3.5,
      color: NocheColors.onAccent,
    ),
  );

  /// Calm miss mark: 24 px muted circle with a horizontal bar (never red).
  Widget get _miss => Container(
    width: 24,
    height: 24,
    alignment: AlignmentDirectional.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: NocheColors.lessonBorder, width: 2),
    ),
    child: Container(
      width: 8,
      height: 2,
      decoration: BoxDecoration(
        color: NocheColors.lessonLabel,
        borderRadius: BorderRadius.circular(1),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final safe = mq.padding;
    final land = CallMetrics.landscape(mq.size);
    final reduce = widget.services.reduceMotion || mq.disableAnimations;
    final ending = c.state == VoiceTestState.end;
    final lang = widget.services.course.language;
    final dir = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : Directionality.of(context);
    return MediaQuery(
      data: mq.copyWith(disableAnimations: reduce),
      child: Directionality(
        textDirection: dir,
        child: ColoredBox(
          key: const Key('voice-test-screen'),
          color: NocheColors.lessonGround,
          child: ending
              ? _end(lang, safe)
              : SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(bottom: safe.bottom),
                    child: Column(
                      children: [
                        _top(safe, land),
                        _ins(lang),
                        Expanded(child: _main(lang, land)),
                        _foot(lang, land),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// Progress bar using shared [NocheDashes] on lesson ground.
  Widget _top(EdgeInsets safe, bool land) => SizedBox(
    height: (land ? 40 : 56) + safe.top,
    child: Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16, safe.top, 16, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Semantics(
            label: _l.progress,
            value: '${c.tried} / ${c.n}',
            excludeSemantics: true,
            child: NocheDashes(
              states: [
                for (var k = 0; k < c.n; k++)
                  c.runLines[k].tried
                      ? NocheDashState.done
                      : k == c.i
                      ? NocheDashState.current
                      : NocheDashState.notYet,
              ],
              onLessonGround: true,
            ),
          ),
        ),
      ),
    ),
  );

  /// The single English instruction line.
  Widget _ins(Language lang) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
    child: Text(
      SpeakWording.voiceTestInstruction(lang.englishName),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      style: CallText.summary,
    ),
  );

  Widget _main(Language lang, bool land) {
    final line = c.line;
    final done = c.state == VoiceTestState.done;
    final run = c.current;
    final hint = line.hint ?? '';
    final courseLocale = Locale(lang.code);
    final lineStyle = NocheType.forScript(CallText.voiceLine, lang.script);
    final hintStyle = NocheType.forScript(CallText.voiceHint, lang.script);
    final heardBase = run.ok ? CallText.voiceHeardRight : CallText.voiceHeard;
    final heardStyle = run.alts.isNotEmpty
        ? NocheType.forScript(heardBase, lang.script)
        : heardBase;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 16).clamp(0.0, double.infinity),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${c.i + 1} / ${c.n}', style: CallText.voiceCount),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Text(
                    line.text,
                    textAlign: TextAlign.center,
                    locale: courseLocale,
                    style: lineStyle,
                  ),
                ),
                if (hint.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    locale: courseLocale,
                    style: hintStyle,
                  ),
                ],
                SizedBox(height: land ? 8 : 20),
                Visibility(
                  visible: done,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 480,
                      minHeight: 24,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        run.ok ? _tick : _miss,
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            run.alts.isNotEmpty
                                ? run.alts.first
                                : SpeakWording.emptyHeard,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            locale: run.alts.isNotEmpty ? courseLocale : null,
                            style: heardStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Footer: status live region, shared [NocheMic], and primary Next button.
  Widget _foot(Language lang, bool land) {
    final s = c.state;
    final showMic =
        s == VoiceTestState.ready ||
        s == VoiceTestState.listen ||
        s == VoiceTestState.proc ||
        s == VoiceTestState.done;
    final Widget? mic = showMic
        ? NocheMic(
            key: const Key('voice-test-mic'),
            state: nocheMicStateForVoiceTest(s, ok: c.current.ok),
            language: lang,
            level: s == VoiceTestState.listen ? 0.6 : 0.0,
            compactLabel: true,
            labelGap: 8,
            barGroupGap: land ? 8 : NocheMic.defaultBarGroupGap,
            onPressed: s == VoiceTestState.ready
                ? () => unawaited(c.onMic())
                : null,
          )
        : null;
    final nextButton = Visibility(
      visible: s == VoiceTestState.done,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: land ? 180 : 480),
        child: NochePrimaryButton(
          key: const Key('voice-test-next'),
          label: _l.next,
          semanticLabel: _l.next,
          onPressed: s == VoiceTestState.done ? c.onNext : null,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, land ? 16 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 16,
            child: Semantics(
              liveRegion: true,
              child: Text(c.status, style: CallText.voiceStatus),
            ),
          ),
          SizedBox(height: land ? 4 : 8),
          if (land)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (mic != null) ...[mic, const SizedBox(width: 16)],
                nextButton,
              ],
            )
          else ...[
            if (mic != null) ...[mic, const SizedBox(height: 16)],
            nextButton,
          ],
        ],
      ),
    );
  }

  /// End screen: result count, optional unavailable note, per-line rows, and retry button.
  Widget _end(Language lang, EdgeInsets safe) {
    final courseLocale = Locale(lang.code);
    final englishAlign = lang.direction == LanguageDirection.rtl
        ? TextAlign.end
        : TextAlign.start;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.fromSTEB(16, 24 + safe.top, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        c.result,
                        textAlign: englishAlign,
                        textDirection: TextDirection.ltr,
                        style: CallText.doneTitle,
                      ),
                    ),
                    if (c.unavailable.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _l.unavailable,
                        locale: courseLocale,
                        style: NocheType.forScript(
                          CallText.summary,
                          lang.script,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    for (final e in c.runLines) _row(lang, courseLocale, e),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24 + safe.bottom),
          decoration: const BoxDecoration(
            color: NocheColors.lessonGround,
            border: Border(top: BorderSide(color: NocheColors.lessonLine)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: NocheOutlineButton(
                key: const Key('voice-test-again'),
                label: _l.again,
                onPressed: () => unawaited(c.start()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Per-line result row: mark, line, best heard (green when right), and extra alternatives.
  Widget _row(Language lang, Locale courseLocale, VoiceLineRun e) {
    final hasAlt = e.alts.isNotEmpty;
    final best = hasAlt ? e.alts.first : SpeakWording.emptyHeard;
    final more = e.alts.skip(1).join(' · ');
    final lineStyle = NocheType.forScript(CallText.voiceRowLine, lang.script);
    final heardBase = e.ok ? CallText.voiceHeardRight : CallText.voiceHeard;
    final heardStyle = hasAlt
        ? NocheType.forScript(heardBase, lang.script)
        : heardBase;
    final altStyle = NocheType.forScript(CallText.voiceRowAlt, lang.script);
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: NocheColors.lessonLine)),
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
                Text(e.line, locale: courseLocale, style: lineStyle),
                Text(
                  best,
                  locale: hasAlt ? courseLocale : null,
                  style: heardStyle,
                ),
                if (more.isNotEmpty)
                  Text(more, locale: courseLocale, style: altStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
