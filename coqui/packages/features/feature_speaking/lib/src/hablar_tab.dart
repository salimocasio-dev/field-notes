/// The Hablar tab: one clear Next Call hero card + a 10-stop Map Journey.
///
/// Design rules enforced:
/// - Not a list of identical "Call Danny" rows.
/// - One obvious next call with a thumb-zone primary button.
/// - 10-stop horizontal place journey distinguishing Done / Ready / Upcoming
///   by both shape/icon and colour (never colour alone), opening a single
///   focused place panel when tapped.
/// - No screenshot pictures (no picture shown until original pixel art exists).
/// - No "I said it" self-report buttons.
/// - >= 48 px touch targets on every interactive control.
/// - Centralized calm Entitlements hook when locked by subscription tier.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:feature_speaking/src/entitlements_hook.dart';
import 'package:feature_speaking/src/hablar_model.dart';
import 'package:feature_speaking/src/speech_note.dart';
import 'package:material_ui/material_ui.dart';

class HablarTab extends StatefulWidget {
  const HablarTab({
    super.key,
    required this.services,
    this.callsLater,
    this.voiceTestLabel,
    this.showSpeechNote = false,
    this.entitlementCheck = defaultCallEntitlement,
    this.completedCallIds = const {},
  });

  final Services services;

  /// Line shown when this build cannot place calls (`call.available == false`).
  final String? callsLater;

  /// Optional entry label for `VoiceTestRoute`.
  final String? voiceTestLabel;

  /// Shows `notaHabla` on the Hablar tab when requested.
  final bool showSpeechNote;

  /// Subscription tier check hook for live calls.
  final CallEntitlementCheck entitlementCheck;

  /// Completed call IDs (temporary until `ProgressStore` tracks completed calls).
  final Set<String> completedCallIds;

  @override
  State<HablarTab> createState() => _HablarTabState();
}

class _HablarTabState extends State<HablarTab> {
  StreamSubscription<void>? _sub;
  String? _note;
  bool _callsFailed = false;

  /// Which place stop is expanded in the focused panel below (null = collapsed,
  /// avoiding duplicate "Up next" cards on initial load).
  String? _selectedPlaceId;

  @override
  void initState() {
    super.initState();
    _sub = widget.services.progress.changes.listen((_) {
      if (mounted) setState(() {});
    });
    _loadNote();
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
    super.dispose();
  }

  bool _callsAvailable() {
    if (_callsFailed) return false;
    final available = widget.services.call.available;
    if (!available) _callsFailed = true;
    return available;
  }

  void _startCall(HablarCallItem item) {
    if (!item.canStart) return;
    widget.services.haptics.tick();
    widget.services.nav.go(CallRoute(item.place.id));
  }

  void _togglePlace(String placeId) {
    widget.services.haptics.tick();
    setState(() {
      _selectedPlaceId = _selectedPlaceId == placeId ? null : placeId;
    });
  }

  PlaceJourneyStop? _findSelectedStop(List<PlaceJourneyStop> stops) {
    final id = _selectedPlaceId;
    if (id == null) return null;
    for (final stop in stops) {
      if (stop.place.id == id) return stop;
    }
    return null;
  }

  void _showWordsSheet(BuildContext context, List<String> openWords) {
    widget.services.haptics.tick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CoquiColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(HablarTexts.wordsTitle, style: CoquiText.h2),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: CoquiColors.ink),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (openWords.isEmpty)
                Text(HablarTexts.wordsNone, style: CoquiText.bodyMuted)
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final w in openWords)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: CoquiColors.bg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: CoquiColors.line,
                                width: CoquiLayout.border(ctx, 1),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                CallTexts.chip(w),
                                style: CoquiText.chip,
                              ),
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
    );
  }

  Widget _header(BuildContext context, List<String> openWords) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: ScreenTitle(CoquiLabels.speak)),
        Semantics(
          button: true,
          label:
              '${HablarTexts.wordsReadyPill(openWords.length)}. ${HablarTexts.wordsTitle}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showWordsSheet(context, openWords),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CoquiColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CoquiColors.line,
                      width: CoquiLayout.border(context, 1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      HablarTexts.wordsReadyPill(openWords.length),
                      style: CoquiText.smallMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Compact 10-stop horizontal Map Journey strip.
  /// Distinguishes Done / Ready / Upcoming by icon + border + fill (not colour alone).
  Widget _journeyStrip(BuildContext context, List<PlaceJourneyStop> stops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(HablarTexts.byPlace),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stops.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final stop = stops[idx];
              final selected = _selectedPlaceId == stop.place.id;
              final isDone = stop.state == HablarCallState.done;
              final isReady = stop.state == HablarCallState.ready;
              final isLocked =
                  stop.state == HablarCallState.upcoming ||
                  stop.state == HablarCallState.soon;

              final bg = selected
                  ? CoquiColors.ink
                  : isDone
                  ? CoquiColors.ok.withValues(alpha: 0.12)
                  : isReady
                  ? CoquiColors.card
                  : CoquiColors.bg;
              final border = selected
                  ? CoquiColors.ink
                  : isDone
                  ? CoquiColors.ok
                  : isReady
                  ? CoquiColors.info
                  : CoquiColors.line;
              final fg = selected
                  ? CoquiColors.white
                  : isDone
                  ? CoquiColors.ok
                  : isReady
                  ? CoquiColors.ink
                  : CoquiColors.mut;

              return Semantics(
                button: true,
                selected: selected,
                label: '${stop.placeNumber}. ${stop.place.name}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _togglePlace(stop.place.id),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 48,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: border,
                          width: CoquiLayout.border(ctx, selected ? 2 : 1.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isDone)
                              Icon(Icons.check, size: 16, color: fg)
                            else if (isLocked)
                              Icon(Icons.lock_outline, size: 15, color: fg)
                            else
                              Text(
                                '${stop.placeNumber}',
                                style: CoquiText.small.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            const SizedBox(width: 6),
                            Text(
                              stop.place.name,
                              style: CoquiText.small.copyWith(
                                color: fg,
                                fontWeight: isReady || selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Featured "Up next" hero card with thumb-zone Start call button.
  Widget _heroCard(BuildContext context, HablarSnapshot snap) {
    final next = snap.nextCall;
    if (next == null) return const SizedBox.shrink();

    final canStart = next.canStart;
    final ctaLabel = next.state == HablarCallState.done
        ? CallTexts.callAgain
        : CallTexts.startCall;

    return CoquiCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EyebrowLabel(
                '${HablarTexts.upNext} · ${next.placeNumber}. ${next.place.name}',
              ),
              const Spacer(),
              Text(
                CallTexts.durationLine(next.spec.minutes),
                style: CoquiText.smallMuted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(next.spec.titleEs, style: CoquiText.h1),
          const SizedBox(height: 6),
          Text(next.spec.jobEn, style: CoquiText.bodyMuted),
          if (snap.showFirstTimeReassurance && canStart) ...[
            const SizedBox(height: 10),
            Text(HablarTexts.practiceNoFail, style: CoquiText.smallMuted),
          ],
          const SizedBox(height: 20),
          if (canStart)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: CoquiButton(
                label: ctaLabel,
                icon: CoquiIcons.phone,
                kind: CoquiButtonKind.go,
                full: true,
                semanticLabel: '$ctaLabel: ${next.spec.titleEs}',
                onPressed: () => _startCall(next),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: CoquiColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CoquiColors.line,
                  width: CoquiLayout.border(context, 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Text(
                  next.statusLine,
                  style: CoquiText.smallMuted,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Focused single-place panel shown when the learner taps a stop on the map strip.
  Widget _placePanel(
    BuildContext context,
    PlaceJourneyStop stop,
    String? heroCallId,
  ) {
    final main = stop.mainCall;
    final smalls = stop.smallerCalls;
    return CoquiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${stop.placeNumber}. ${stop.place.name}',
                  style: CoquiText.h2,
                ),
              ),
              Text(stop.statusLine, style: CoquiText.smallMuted),
            ],
          ),
          if (main != null) ...[
            const SizedBox(height: 12),
            _callRow(
              context,
              main,
              isHeroDuplicate: main.spec.id == heroCallId,
            ),
          ],
          if (smalls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(HablarTexts.shortCallsLabel, style: CoquiText.eyebrow),
            const SizedBox(height: 6),
            for (var i = 0; i < smalls.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _callRow(
                context,
                smalls[i],
                isHeroDuplicate: smalls[i].spec.id == heroCallId,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _callRow(
    BuildContext context,
    HablarCallItem item, {
    required bool isHeroDuplicate,
  }) {
    final enabled = item.canStart && !isHeroDuplicate;
    final titleStyle = item.canStart
        ? CoquiText.rowTitle
        : CoquiText.rowTitle.copyWith(color: CoquiColors.mut);

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CoquiColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.spec.titleEs, style: titleStyle),
                    const SizedBox(height: 2),
                    Text(
                      '${item.spec.jobEn} · ${CallTexts.durationLine(item.spec.minutes)}',
                      style: CoquiText.smallMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isHeroDuplicate && item.canStart)
                Text(HablarTexts.upNextAbove, style: CoquiText.smallMuted)
              else if (item.state == HablarCallState.done)
                PlayButton(
                  icon: CoquiIcons.phone,
                  quiet: true,
                  semanticLabel: '${CallTexts.callAgain}: ${item.spec.titleEs}',
                  onPressed: () => _startCall(item),
                )
              else if (item.canStart)
                PlayButton(
                  icon: CoquiIcons.phone,
                  semanticLabel: '${CallTexts.startCall}: ${item.spec.titleEs}',
                  onPressed: () => _startCall(item),
                ),
            ],
          ),
        ),
      ),
    );

    return enabled
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _startCall(item),
            child: row,
          )
        : Semantics(enabled: item.canStart, child: row);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    final snap = buildHablarSnapshot(
      course: s.course,
      progress: s.progress,
      callsAvailable: _callsAvailable,
      entitlement: widget.entitlementCheck(),
      completedCallIds: widget.completedCallIds,
      callsLater: widget.callsLater ?? CallTexts.callsLater,
    );
    final selectedStop = _findSelectedStop(snap.stops);
    final voiceTest = widget.voiceTestLabel;

    return TabPage(
      children: [
        _header(context, snap.openWords),
        if (_note != null) KeyLine(_note!),
        const SizedBox(height: 8),
        _journeyStrip(context, snap.stops),
        const SizedBox(height: 16),
        if (selectedStop != null) ...[
          _placePanel(context, selectedStop, snap.nextCall?.spec.id),
          const SizedBox(height: 8),
        ],
        _heroCard(context, snap),
        if (voiceTest != null)
          Block(
            top: 12,
            child: CoquiCard(
              marginBottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => s.nav.go(const VoiceTestRoute()),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(voiceTest, style: CoquiText.rowTitle),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
