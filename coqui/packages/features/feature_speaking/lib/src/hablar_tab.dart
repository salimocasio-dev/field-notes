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
import 'package:feature_speaking/src/motion.dart';
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

class _HablarTabState extends State<HablarTab> with TickerProviderStateMixin {
  StreamSubscription<void>? _sub;
  StreamSubscription<void>? _entitlementSub;
  String? _note;
  bool _callsFailed = false;
  bool _openingWords = false;
  String? _selectedPlaceId;

  late final AnimationController _lockHintController = AnimationController(
    vsync: this,
  )..addStatusListener(_handleLockHintStatus);
  Place? _lockHintPlace;
  NocheMotionData _lockHintMotion = NocheMotion.normal;
  NocheFollowSide _placeFollowSide = NocheFollowSide.end;
  int _followEpoch = 0;

  void _handleLockHintStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _lockHintPlace != null &&
        mounted) {
      setState(() {
        _lockHintPlace = null;
      });
    }
  }

  void _clearLockHint() {
    if (_lockHintPlace == null && !_lockHintController.isAnimating) return;
    _lockHintController.stop();
    _lockHintController.value = 0.0;
    _lockHintPlace = null;
  }

  @override
  void initState() {
    super.initState();
    _sub = widget.services.progress.changes.listen((_) {
      _clearLockHint();
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
        _clearLockHint();
        if (mounted) setState(() {});
      });
      _clearLockHint();
      _selectedPlaceId = null;
      _followEpoch++;
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
    _lockHintController
      ..removeStatusListener(_handleLockHintStatus)
      ..dispose();
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

  void _selectPlace(
    String placeId,
    List<PlaceJourneyStop> reached,
    String currentPlaceId,
  ) {
    final fromIndex = reached.indexWhere((s) => s.place.id == currentPlaceId);
    final toIndex = reached.indexWhere((s) => s.place.id == placeId);
    widget.services.haptics.tick();
    setState(() {
      _clearLockHint();
      if (fromIndex >= 0 && toIndex >= 0 && fromIndex != toIndex) {
        _placeFollowSide = SpeakingMotion.placeFollowSide(
          fromIndex: fromIndex,
          toIndex: toIndex,
        );
      }
      _selectedPlaceId = placeId;
    });
  }

  void _showLockedPlaceHint(Place precedingPlace) {
    final motion = SpeakingMotion.resolve(
      context,
      serviceReduceMotion: widget.services.reduceMotion,
    );
    setState(() {
      _lockHintPlace = precedingPlace;
      _lockHintMotion = motion;
    });
    _lockHintController.duration = motion.press + motion.lockHold + motion.move;
    _lockHintController.forward(from: 0.0);
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

  Widget _fadeWithRoute({
    required Animation<double>? secondaryAnimation,
    required NocheMotionData motion,
    required Widget child,
    Key? opacityKey,
  }) {
    if (secondaryAnimation == null) {
      return opacityKey == null
          ? child
          : Opacity(key: opacityKey, opacity: 1.0, child: child);
    }
    return AnimatedBuilder(
      animation: secondaryAnimation,
      builder: (context, inner) {
        final isReturning =
            secondaryAnimation.status == AnimationStatus.reverse;
        final opacity = isReturning
            ? SpeakingMotion.backReturnOpacity(
                reverseProgress: 1.0 - secondaryAnimation.value,
                motion: motion,
              )
            : SpeakingMotion.outgoingFadeOpacity(
                routeValue: secondaryAnimation.value,
                motion: motion,
                totalDuration: motion.pageIn,
              );
        return Opacity(key: opacityKey, opacity: opacity, child: inner);
      },
      child: child,
    );
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
                    child: NocheLtr(
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
    final selectedId = selectedStop?.place.id ?? reached.first.place.id;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: NochePillGroup<String>(
        role: NocheSegmentedRole.tabList,
        semanticLabel: SpeakWording.placeTabListLabel,
        selected: selectedId,
        onChanged: (id) => _selectPlace(id, reached, selectedId),
        options: [
          for (final stop in reached)
            NochePillOption<String>(
              value: stop.place.id,
              label: stop.place.name,
              foregroundColor: NocheColors.label,
              script: lang.script,
              locale: courseLocale,
              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 16, 0),
              leading: MetaData(
                key: Key('speak-place-${stop.place.id}'),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox(width: 8, height: NocheSize.touch),
              ),
            ),
        ],
        trailing: nextLocked != null
            ? Semantics(
                container: true,
                role: ui.SemanticsRole.tab,
                selected: false,
                child: NocheQuietLock(
                  key: const Key('speak-locked-place-pill'),
                  borderRadius: NocheSize.pillRadius,
                  padding: EdgeInsetsDirectional.zero,
                  semanticLabel: SpeakWording.lockedPlaceLabel(
                    nextLocked.place.name,
                  ),
                  onTap: () => _showLockedPlaceHint(reached.last.place),
                  builder: (context, reasonColor) => SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: NocheIcon(
                        NocheIcons.lock,
                        size: 20,
                        color: reasonColor,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _lockedPlaceHint(Place place, Language lang, Locale courseLocale) {
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        excludeSemantics: true,
        label: SpeakWording.afterPlace(place.name),
        child: AnimatedBuilder(
          animation: _lockHintController,
          builder: (context, child) {
            final motion = _lockHintMotion;
            final total = motion.press + motion.lockHold + motion.move;
            final totalUs = total.inMicroseconds.toDouble();
            final elapsedUs = _lockHintController.value * totalUs;
            final pressUs = motion.press.inMicroseconds.toDouble();
            final holdEnd = motion.press + motion.lockHold;
            final holdEndUs = holdEnd.inMicroseconds.toDouble();
            final rise = motion.reduced ? 0.0 : SpeakingMotion.lockHintRise;

            final double opacity;
            final double dy;
            if (elapsedUs < pressUs) {
              final p = SpeakingMotion.segmentProgressUs(
                elapsedUs: elapsedUs,
                start: Duration.zero,
                duration: motion.press,
                curve: motion.enter,
              );
              opacity = p;
              dy = -rise * (1.0 - p);
            } else if (elapsedUs <= holdEndUs) {
              opacity = 1.0;
              dy = 0.0;
            } else {
              final pOut = SpeakingMotion.segmentProgressUs(
                elapsedUs: elapsedUs,
                start: holdEnd,
                duration: motion.move,
                curve: motion.exit,
              );
              opacity = (1.0 - pOut).clamp(0.0, 1.0);
              dy = -rise * pOut;
            }

            return Transform.translate(
              key: const ValueKey('speak-locked-place-hint-motion'),
              offset: Offset(0, dy),
              child: Opacity(opacity: opacity, child: child),
            );
          },
          child: Container(
            key: const Key('speak-locked-place-hint'),
            height: 40,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: NocheColors.panel,
              border: Border.all(color: NocheColors.line, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                NocheIcon(NocheIcons.lock, size: 18, color: NocheColors.text),
                const SizedBox(width: 8),
                NocheLtr(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: SpeakWording.afterPrefix,
                          style: NocheType.buttonStrong.copyWith(
                            color: NocheColors.text,
                          ),
                        ),
                        TextSpan(
                          text: place.name,
                          locale: courseLocale,
                          style: NocheType.forScript(
                            NocheType.buttonStrong,
                            lang.script,
                          ).copyWith(color: NocheColors.text),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final isRtl = lang.direction == LanguageDirection.rtl;
    final englishAlign = isRtl ? TextAlign.end : TextAlign.start;

    if (item.state == HablarCallState.upcoming) {
      return NocheQuietLock(
        key: Key('speak-other-call-${item.spec.id}'),
        borderRadius: NocheSize.cardRadius,
        padding: const EdgeInsetsDirectional.all(15),
        semanticLabel: SpeakWording.lockedOtherCallSemantic(
          item.spec.titleEs,
          item.cardMetaLine,
        ),
        builder: (context, reasonColor) => ConstrainedBox(
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
                style: NocheType.forScript(
                  NocheType.rowTitle,
                  lang.script,
                ).copyWith(color: reasonColor),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  NocheIcon(NocheIcons.lock, size: 18, color: reasonColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: NocheLtr(
                      child: Text(
                        item.cardMetaLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: englishAlign,
                        style: NocheType.body.copyWith(
                          height: 1,
                          color: reasonColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

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
          NocheLtr(
            child: Text(
              item.cardMetaLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: englishAlign,
              textDirection: TextDirection.ltr,
              style: metaStyle,
            ),
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

  Widget _statusCard({
    required Key key,
    required HablarCallState state,
    required String statusLine,
    required Animation<double>? secondaryAnimation,
    required NocheMotionData motion,
  }) {
    final Widget card = state == HablarCallState.upcoming
        ? NocheQuietLock(
            key: key,
            borderRadius: NocheSize.cardRadius,
            padding: const EdgeInsetsDirectional.all(15),
            semanticLabel: statusLine,
            builder: (context, reasonColor) => Center(
              child: Text(
                statusLine,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: NocheType.body.copyWith(color: reasonColor),
              ),
            ),
          )
        : NocheCard(
            key: key,
            variant: NocheCardVariant.dashed,
            child: Text(
              statusLine,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: NocheType.body.copyWith(color: NocheColors.label),
            ),
          );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
      child: _fadeWithRoute(
        secondaryAnimation: secondaryAnimation,
        motion: motion,
        child: card,
      ),
    );
  }

  Widget? _footerControl(
    BuildContext context,
    HablarCallItem? featured,
    PlaceJourneyStop? selectedStop,
    Language lang, {
    required bool callsEntitled,
    required NocheMotionData motion,
    required Animation<double>? secondaryAnimation,
  }) {
    if (!callsEntitled) {
      final isRtl = lang.direction == LanguageDirection.rtl;
      final englishAlign = isRtl ? TextAlign.end : TextAlign.start;
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
        child: _fadeWithRoute(
          secondaryAnimation: secondaryAnimation,
          motion: motion,
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
        ),
      );
    }
    if (featured == null) {
      if (selectedStop != null && selectedStop.statusLine.isNotEmpty) {
        return _statusCard(
          key: selectedStop.state == HablarCallState.soon
              ? const Key('speak-coming-soon')
              : const Key('speak-locked-status'),
          state: selectedStop.state,
          statusLine: selectedStop.statusLine,
          secondaryAnimation: secondaryAnimation,
          motion: motion,
        );
      }
      return null;
    }
    if (featured.canStart) {
      final label = SpeakWording.callPartner(lang.partnerName);
      final canHero = !motion.reduced && TickerMode.valuesOf(context).enabled;
      Widget disc = NochePlayDisc(
        key: const Key('speak-call-disc'),
        size: NocheSize.mic,
        icon: NocheIcons.mic,
        halo: true,
        semanticLabel: SpeakWording.callDiscSemantic(
          lang.partnerName,
          featured.spec.titleEs,
        ),
        onPressed: () => _startCall(featured),
      );
      if (canHero) {
        disc = Hero(
          tag: SpeakingMotion.callMicHeroTag,
          curve: motion.travel,
          createRectTween: (begin, end) => RectTween(begin: begin, end: end),
          child: disc,
        );
      }
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
        child: NocheArrive(
          delay: NocheMotion.rowsAfter,
          crossAxisAlignment: CrossAxisAlignment.center,
          next: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _fadeWithRoute(
                secondaryAnimation: secondaryAnimation,
                motion: motion,
                child: Text(
                  label,
                  textDirection: TextDirection.ltr,
                  style: NocheType.rowTitle.copyWith(
                    height: 1,
                    color: NocheColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              disc,
            ],
          ),
          children: const [],
        ),
      );
    }
    if (featured.statusLine.isNotEmpty) {
      return _statusCard(
        key: featured.state == HablarCallState.soon
            ? const Key('speak-coming-soon')
            : const Key('speak-locked-status'),
        state: featured.state,
        statusLine: featured.statusLine,
        secondaryAnimation: secondaryAnimation,
        motion: motion,
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
    final mq = MediaQuery.of(context);
    final pad = mq.padding;
    final reduce = s.reduceMotion || mq.disableAnimations;
    final motion = SpeakingMotion.resolve(
      context,
      serviceReduceMotion: s.reduceMotion,
    );
    final secondaryAnimation = ModalRoute.of(context)?.secondaryAnimation;

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
      context,
      featured,
      selectedStop,
      lang,
      callsEntitled: snap.callsEntitled,
      motion: motion,
      secondaryAnimation: secondaryAnimation,
    );
    final showLockHint =
        snap.reachedStops.isNotEmpty &&
        snap.nextLockedStop != null &&
        _lockHintPlace != null;

    final body = MediaQuery(
      data: mq.copyWith(disableAnimations: reduce),
      child: Directionality(
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
                    child: _fadeWithRoute(
                      secondaryAnimation: secondaryAnimation,
                      motion: motion,
                      opacityKey: const ValueKey('speak-outgoing-opacity'),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _header(
                              context,
                              lang,
                              snap.openWords,
                              courseLocale,
                            ),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (snap.reachedStops.isNotEmpty)
                                      _placePills(
                                        context,
                                        snap,
                                        selectedStop,
                                        lang,
                                        courseLocale,
                                      ),
                                    KeyedSubtree(
                                      key: ValueKey(_followEpoch),
                                      child: NocheFollow(
                                        key: const Key('speak-place-follow'),
                                        contentKey:
                                            selectedStop?.place.id ?? '',
                                        side: _placeFollowSide,
                                        distance: NocheMotion.tab,
                                        child: ListView(
                                          shrinkWrap: true,
                                          primary: false,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsetsDirectional.zero,
                                          children: [
                                            if (featured != null)
                                              _nextCallCard(
                                                context,
                                                featured,
                                                snap.previewWords,
                                                lang,
                                                courseLocale,
                                                callsEntitled:
                                                    snap.callsEntitled,
                                              ),
                                            if (others.isNotEmpty)
                                              _otherCallsGrid(
                                                context,
                                                others,
                                                lang,
                                                courseLocale,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_note != null)
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.fromSTEB(
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
                                        padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                              16,
                                              16,
                                              16,
                                              0,
                                            ),
                                        child: NocheCard(
                                          onPressed: () =>
                                              s.nav.go(const VoiceTestRoute()),
                                          semanticLabel: voiceTest,
                                          child: Align(
                                            alignment: AlignmentDirectional
                                                .centerStart,
                                            child: Text(
                                              voiceTest,
                                              style: NocheType.rowTitle
                                                  .copyWith(
                                                    color: NocheColors.text,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                                if (showLockHint)
                                  PositionedDirectional(
                                    end: 16,
                                    top: NocheSize.touch + NocheSize.grid,
                                    child: _lockedPlaceHint(
                                      _lockHintPlace!,
                                      lang,
                                      courseLocale,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ?footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return body;
  }
}
