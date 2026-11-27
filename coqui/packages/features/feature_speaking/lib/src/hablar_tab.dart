/// The Noche Speak tab (story N4.6, issue #106, board `Noche-Hablar.dc.html`,
/// and story N3.3, issue #97, board `Noche-Hablar-Plan.dc.html`):
/// header with language label, "Speak" title and tappable words-ready count,
/// reached place pills plus one dashed-locked next place pill, featured
/// next-call card (with open-word chips when calls are in the plan, or a
/// "Course + Calls" tag when not), 2-per-row other calls, and the pinned
/// 96 px orange mic disc or calm plan card above the floating tab bar.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:feature_speaking/src/hablar_model.dart';
import 'package:feature_speaking/src/speech_note.dart';
import 'package:feature_speaking/src/wording.dart';
import 'package:material_ui/material_ui.dart';

class HablarTab extends StatefulWidget {
  const HablarTab({
    super.key,
    required this.services,
    this.callsLater,
    this.voiceTestLabel,
    this.showSpeechNote = false,
    this.completedCallIds = const {},
    this.shortCallsEnabled = false,
  });

  final Services services;

  /// Line shown when this build cannot place calls (`call.available == false`).
  final String? callsLater;

  /// Optional entry label for `VoiceTestRoute`.
  final String? voiceTestLabel;

  /// Shows `notaHabla` on the Speak tab when requested.
  final bool showSpeechNote;

  /// Optional override/test set of completed call IDs, merged with
  /// `services.progress.callDone(callId)`.
  final Set<String> completedCallIds;

  /// Enables starting smaller calls via `CallRoute(placeId, callId:)` once
  /// the shell's address router preserves `callId` (default `false`).
  final bool shortCallsEnabled;

  @override
  State<HablarTab> createState() => _HablarTabState();
}

class _HablarTabState extends State<HablarTab> {
  StreamSubscription<void>? _sub;
  StreamSubscription<void>? _entitlementSub;
  String? _note;
  bool _callsFailed = false;
  bool _openingWords = false;
  String? _selectedPlaceId;

  @override
  void initState() {
    super.initState();
    _sub = widget.services.progress.changes.listen((_) {
      if (mounted) setState(() {});
    });
    _entitlementSub = widget.services.entitlements.changes.listen((_) {
      _callsFailed = false;
      if (mounted) setState(() {});
    });
    unawaited(_loadNote());
  }

  @override
  void didUpdateWidget(HablarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final courseChanged = !identical(
      oldWidget.services.course,
      widget.services.course,
    );
    final progressChanged = !identical(
      oldWidget.services.progress,
      widget.services.progress,
    );
    final entitlementsChanged = !identical(
      oldWidget.services.entitlements,
      widget.services.entitlements,
    );
    if (entitlementsChanged) {
      unawaited(_entitlementSub?.cancel());
      _callsFailed = false;
      _entitlementSub = widget.services.entitlements.changes.listen((_) {
        _callsFailed = false;
        if (mounted) setState(() {});
      });
    }
    if (courseChanged || progressChanged) {
      unawaited(_sub?.cancel());
      _sub = widget.services.progress.changes.listen((_) {
        if (mounted) setState(() {});
      });
      _selectedPlaceId = null;
      _callsFailed = false;
      _note = null;
      unawaited(_loadNote());
    } else if (oldWidget.showSpeechNote != widget.showSpeechNote) {
      if (widget.showSpeechNote) {
        unawaited(_loadNote());
      } else {
        _note = null;
      }
    }
  }

  Future<void> _loadNote() async {
    if (!widget.showSpeechNote) return;
    final s = widget.services;
    final note = await speechNote(
      speech: s.speech,
      progress: s.progress,
      clock: s.clock,
    );
    if (mounted && note != _note) setState(() => _note = note);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_entitlementSub?.cancel());
    super.dispose();
  }

  bool _callsAvailable() {
    if (_callsFailed) return false;
    final available = widget.services.call.available;
    if (!available) _callsFailed = true;
    return available;
  }

  void _startCall(HablarCallItem item) {
    if (!widget.services.entitlements.has(Feature.calls) || !item.canStart) {
      return;
    }
    widget.services.haptics.tick();
    widget.services.nav.go(
      item.spec.isMain
          ? CallRoute(item.place.id)
          : CallRoute(item.place.id, callId: item.spec.id),
    );
  }

  void _openPlans() {
    widget.services.haptics.tick();
    widget.services.nav.go(const PlansRoute());
  }

  void _selectPlace(String placeId) {
    widget.services.haptics.tick();
    setState(() {
      _selectedPlaceId = placeId;
    });
  }

  Future<void> _showWordsSheet(
    BuildContext context,
    List<String> openWords,
    Language lang,
    Locale courseLocale,
  ) async {
    if (_openingWords) return;
    _openingWords = true;
    widget.services.haptics.tick();
    final textDirection = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    try {
      await showNocheSheet<void>(
        context,
        title: SpeakWording.wordsTitle,
        builder: (ctx, close) => Directionality(
          textDirection: textDirection,
          child: openWords.isEmpty
              ? Text(
                  SpeakWording.wordsNone,
                  textDirection: TextDirection.ltr,
                  style: NocheType.body.copyWith(color: NocheColors.label),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final w in openWords)
                      NocheChip(
                        label: CallTexts.chip(w),
                        script: lang.script,
                        locale: courseLocale,
                      ),
                  ],
                ),
        ),
      );
    } finally {
      _openingWords = false;
    }
  }

  Widget _header(
    BuildContext context,
    Language lang,
    List<String> openWords,
    Locale courseLocale,
  ) {
    final wordsLabel = SpeakWording.wordsReadyToSay(openWords.length);
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.englishName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: NocheType.label.copyWith(color: NocheColors.label),
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    header: true,
                    child: Text(
                      SpeakWording.screenTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: NocheType.pageTitle.copyWith(
                        color: NocheColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Pressable(
              key: const Key('speak-words-button'),
              onPressed: () => unawaited(
                _showWordsSheet(context, openWords, lang, courseLocale),
              ),
              semanticLabel: SpeakWording.wordsButtonSemantic(openWords.length),
              builder: (context, pressed) => ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: NocheSize.touch,
                  minWidth: NocheSize.touch,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  widthFactor: 1,
                  child: Opacity(
                    opacity: pressed ? 0.7 : 1,
                    child: Text(
                      wordsLabel,
                      maxLines: 1,
                      softWrap: false,
                      textDirection: TextDirection.ltr,
                      style: NocheType.button.copyWith(
                        color: NocheColors.label,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placePills(
    BuildContext context,
    HablarSnapshot snap,
    PlaceJourneyStop? selectedStop,
    Language lang,
    Locale courseLocale,
  ) {
    final reached = snap.reachedStops;
    final nextLocked = snap.nextLockedStop;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: Semantics(
        container: true,
        role: ui.SemanticsRole.tabBar,
        label: SpeakWording.placeTabListLabel,
        child: Row(
          children: [
            for (var i = 0; i < reached.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _placePill(
                stop: reached[i],
                isSelected: selectedStop?.place.id == reached[i].place.id,
                lang: lang,
                courseLocale: courseLocale,
              ),
            ],
            if (nextLocked != null) ...[
              const SizedBox(width: 8),
              Semantics(
                container: true,
                role: ui.SemanticsRole.tab,
                selected: false,
                enabled: false,
                child: NochePill.dashedLocked(
                  key: const Key('speak-locked-place-pill'),
                  semanticLabel: SpeakWording.lockedPlaceLabel(
                    nextLocked.place.name,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placePill({
    required PlaceJourneyStop stop,
    required bool isSelected,
    required Language lang,
    required Locale courseLocale,
  }) {
    return Semantics(
      container: true,
      role: ui.SemanticsRole.tab,
      selected: isSelected,
      child: isSelected
          ? NochePill.selected(
              label: stop.place.name,
              script: lang.script,
              locale: courseLocale,
              onPressed: () => _selectPlace(stop.place.id),
            )
          : NochePill.outline(
              label: stop.place.name,
              foregroundColor: NocheColors.label,
              script: lang.script,
              locale: courseLocale,
              onPressed: () => _selectPlace(stop.place.id),
            ),
    );
  }

  Widget _nextCallCard(
    BuildContext context,
    HablarCallItem featured,
    List<String> previewWords,
    Language lang,
    Locale courseLocale, {
    required bool callsEntitled,
  }) {
    final isRtl = lang.direction == LanguageDirection.rtl;
    final englishAlign = isRtl ? TextAlign.end : TextAlign.start;
    final isDone = featured.state == HablarCallState.done;
    final eyebrow =
        (isDone
                ? SpeakWording.doneCallEyebrow(
                    lang.partnerName,
                    featured.spec.minutes,
                  )
                : SpeakWording.nextCallEyebrow(
                    lang.partnerName,
                    featured.spec.minutes,
                  ))
            .toUpperCase();
    final eyebrowText = Text(
      eyebrow,
      textAlign: englishAlign,
      textDirection: TextDirection.ltr,
      style: NocheType.label.copyWith(
        color: featured.state == HablarCallState.ready
            ? NocheColors.next
            : NocheColors.label,
      ),
    );
    final titleStyle = NocheType.forScript(
      NocheType.placeTitle.copyWith(height: 36 / 32),
      lang.script,
    ).copyWith(color: NocheColors.text);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
      child: NocheCard(
        key: const Key('speak-next-call-card'),
        padding: const EdgeInsetsDirectional.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (callsEntitled)
              eyebrowText
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: eyebrowText),
                  const SizedBox(width: 8),
                  const NochePill.planTag(
                    key: Key('speak-plan-tag'),
                    label: SpeakWording.planTag,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              featured.spec.titleEs,
              locale: courseLocale,
              style: titleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              featured.spec.jobEn,
              textDirection: TextDirection.ltr,
              style: NocheType.bodyLarge.copyWith(color: NocheColors.label),
            ),
            if (callsEntitled && previewWords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                SpeakWording.wordsYouCanUse.toUpperCase(),
                textDirection: TextDirection.ltr,
                style: NocheType.label.copyWith(color: NocheColors.label),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in previewWords)
                    NocheChip(
                      label: CallTexts.chip(w),
                      script: lang.script,
                      locale: courseLocale,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _otherCallsGrid(
    BuildContext context,
    List<HablarCallItem> others,
    Language lang,
    Locale courseLocale,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < others.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 16));
      final first = others[i];
      final second = i + 1 < others.length ? others[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _otherCallCard(first, lang, courseLocale)),
              const SizedBox(width: 16),
              Expanded(
                child: second != null
                    ? _otherCallCard(second, lang, courseLocale)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }

  Widget _otherCallCard(
    HablarCallItem item,
    Language lang,
    Locale courseLocale,
  ) {
    final isReachedCard =
        item.canStart || item.state == HablarCallState.tierLocked;
    final titleColor = isReachedCard ? NocheColors.text : NocheColors.label;
    final titleStyle = NocheType.forScript(
      NocheType.rowTitle,
      lang.script,
    ).copyWith(color: titleColor);
    final metaStyle = NocheType.body.copyWith(
      height: 1,
      color: NocheColors.label,
    );

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.spec.titleEs,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            locale: courseLocale,
            style: titleStyle,
          ),
          const SizedBox(height: 2),
          Text(
            item.cardMetaLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
            style: metaStyle,
          ),
        ],
      ),
    );

    if (item.canStart) {
      return NocheCard(
        key: Key('speak-other-call-${item.spec.id}'),
        variant: NocheCardVariant.standard,
        padding: const EdgeInsetsDirectional.all(15),
        onPressed: () => _startCall(item),
        semanticLabel: SpeakWording.otherCallSemantic(
          item.spec.titleEs,
          item.cardMetaLine,
        ),
        child: content,
      );
    }
    if (item.state == HablarCallState.tierLocked) {
      return NocheCard(
        key: Key('speak-other-call-${item.spec.id}'),
        variant: NocheCardVariant.standard,
        padding: const EdgeInsetsDirectional.all(15),
        child: content,
      );
    }
    return NocheCard(
      key: Key('speak-other-call-${item.spec.id}'),
      variant: NocheCardVariant.dashed,
      padding: const EdgeInsetsDirectional.all(15),
      child: content,
    );
  }

  Widget? _footerControl(
    HablarCallItem? featured,
    Language lang, {
    required bool callsEntitled,
  }) {
    if (!callsEntitled) {
      final isRtl = lang.direction == LanguageDirection.rtl;
      final englishAlign = isRtl ? TextAlign.end : TextAlign.start;
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
        child: NocheCard(
          key: const Key('speak-plan-card'),
          variant: NocheCardVariant.highlight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    SpeakWording.planCardTitle,
                    textAlign: englishAlign,
                    textDirection: TextDirection.ltr,
                    style: NocheType.sheetTitle.copyWith(
                      color: NocheColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Text(
                  SpeakWording.planCardBody(lang.partnerName),
                  textAlign: englishAlign,
                  textDirection: TextDirection.ltr,
                  style: NocheType.body.copyWith(color: NocheColors.label),
                ),
              ),
              const SizedBox(height: 16),
              NochePrimaryButton(
                key: const Key('speak-see-plans-button'),
                label: SpeakWording.seePlans,
                onPressed: _openPlans,
              ),
            ],
          ),
        ),
      );
    }
    if (featured == null) return null;
    if (featured.canStart) {
      final label = SpeakWording.callPartner(lang.partnerName);
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textDirection: TextDirection.ltr,
              style: NocheType.rowTitle.copyWith(
                height: 1,
                color: NocheColors.text,
              ),
            ),
            const SizedBox(height: 16),
            NochePlayDisc(
              key: const Key('speak-call-disc'),
              size: NocheSize.mic,
              icon: NocheIcons.mic,
              halo: true,
              semanticLabel: SpeakWording.callDiscSemantic(
                lang.partnerName,
                featured.spec.titleEs,
              ),
              onPressed: () => _startCall(featured),
            ),
          ],
        ),
      );
    }
    if (featured.statusLine.isNotEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
        child: NocheCard(
          key: const Key('speak-locked-status'),
          variant: NocheCardVariant.dashed,
          child: Text(
            featured.statusLine,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: NocheType.body.copyWith(color: NocheColors.label),
          ),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    final lang = s.course.language;
    final textDirection = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final courseLocale = Locale(lang.code);
    final pad = MediaQuery.paddingOf(context);

    final snap = buildHablarSnapshot(
      course: s.course,
      progress: s.progress,
      callsAvailable: _callsAvailable,
      entitlements: s.entitlements,
      completedCallIds: widget.completedCallIds,
      callsLater: widget.callsLater,
      shortCallsEnabled: widget.shortCallsEnabled,
    );
    final selectedStop =
        snap.stopById(_selectedPlaceId) ?? snap.defaultSelectedStop;
    final featured = selectedStop?.featuredCall;
    final others = selectedStop?.otherCalls ?? const <HablarCallItem>[];
    final voiceTest = widget.voiceTestLabel;
    final footer = _footerControl(
      featured,
      lang,
      callsEntitled: snap.callsEntitled,
    );

    return Directionality(
      textDirection: textDirection,
      child: ColoredBox(
        color: NocheColors.ground,
        child: DefaultTextStyle.merge(
          style: NocheType.body.copyWith(color: NocheColors.text),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: pad.top,
              bottom: NocheSize.aboveTabBar + pad.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(context, lang, snap.openWords, courseLocale),
                        if (snap.reachedStops.isNotEmpty)
                          _placePills(
                            context,
                            snap,
                            selectedStop,
                            lang,
                            courseLocale,
                          ),
                        if (featured != null)
                          _nextCallCard(
                            context,
                            featured,
                            snap.previewWords,
                            lang,
                            courseLocale,
                            callsEntitled: snap.callsEntitled,
                          ),
                        if (others.isNotEmpty)
                          _otherCallsGrid(context, others, lang, courseLocale),
                        if (_note != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              16,
                              16,
                              0,
                            ),
                            child: NocheCard(
                              child: Text(
                                _note!,
                                style: NocheType.body.copyWith(
                                  color: NocheColors.label,
                                ),
                              ),
                            ),
                          ),
                        if (voiceTest != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              16,
                              16,
                              0,
                            ),
                            child: NocheCard(
                              onPressed: () => s.nav.go(const VoiceTestRoute()),
                              semanticLabel: voiceTest,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  voiceTest,
                                  style: NocheType.rowTitle.copyWith(
                                    color: NocheColors.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
