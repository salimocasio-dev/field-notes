/// What the Speak tab shows, without a widget.
///
/// Supplies:
/// - reached place stops and the single next locked place,
/// - structured calls from `course.callsFor(place.id)` when present (falling
///   back to the local catalog + `course.callFor(place.id)`),
/// - per-story unlock thresholds in unlock order (smaller calls first, then the
///   place's main call),
/// - a featured next call plus other calls per reached place, and
/// - live-call gating via `Entitlements.has(Feature.calls)`.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_speaking/src/call_catalog.dart';
import 'package:feature_speaking/src/call_controller.dart' show isCallBriefLive;
import 'package:feature_speaking/src/wording.dart';

/// Maximum number of open-word chips shown on the featured next-call card.
const int maxCallPreviewChips = 5;

/// Availability state of a single call or place stop.
enum HablarCallState {
  /// Ready to start now (threshold met, call backed, build can call, entitled).
  ready,

  /// Already completed at least once (can be replayed any time).
  done,

  /// Threshold met and call exists, but this build cannot place calls (`call.available == false`).
  later,

  /// Threshold met and call exists, but locked by the subscription tier entitlement.
  tierLocked,

  /// Threshold met, waiting for its live call definition in course data.
  soon,

  /// Locked until the learner finishes the required stories in the place.
  upcoming,
}

/// One titled call entry displayed in the featured card or other-calls grid.
class HablarCallItem {
  const HablarCallItem({
    required this.spec,
    required this.place,
    required this.placeNumber,
    required this.state,
    required this.statusLine,
    this.unlockAfterStory = 0,
    this.backedByCourse = false,
  }) : assert(unlockAfterStory >= 0);

  final HablarCallSpec spec;
  final Place place;
  final int placeNumber;
  final HablarCallState state;

  /// Short plain-English status line (e.g. "About 5 min", "Opens when you finish La casa").
  final String statusLine;

  /// Story count in [place] after which this call unlocks (0 when place has no stories).
  final int unlockAfterStory;

  /// Whether course data backs this call (`course.callsFor` or `course.callFor`).
  final bool backedByCourse;

  bool get canStart =>
      state == HablarCallState.ready || state == HablarCallState.done;

  /// Compact meta line shown on secondary call cards.
  String get cardMetaLine {
    if (state == HablarCallState.done) {
      return SpeakWording.cardMetaDone(spec.minutes);
    }
    if (canStart) return SpeakWording.cardMetaOpen(spec.minutes);
    if (state == HablarCallState.upcoming && unlockAfterStory > 0) {
      return SpeakWording.cardMetaAfterStory(spec.minutes, unlockAfterStory);
    }
    if (state == HablarCallState.soon) {
      return SpeakWording.cardMetaComingSoon(spec.minutes);
    }
    if (state == HablarCallState.later) {
      return SpeakWording.cardMetaLater(spec.minutes);
    }
    if (state == HablarCallState.tierLocked) {
      return SpeakWording.minutesOnly(spec.minutes);
    }
    return SpeakWording.minutesOnly(spec.minutes);
  }
}

/// One stop on the place journey (ordered by the course's map).
class PlaceJourneyStop {
  const PlaceJourneyStop({
    required this.place,
    required this.placeNumber,
    required this.reached,
    required this.state,
    required this.calls,
    required this.statusLine,
  });

  final Place place;
  final int placeNumber;
  final bool reached;
  final HablarCallState state;

  /// Calls in unlock order (smaller calls in catalog order first, then main call).
  final List<HablarCallItem> calls;
  final String statusLine;

  HablarCallItem? get mainCall {
    for (final c in calls) {
      if (c.spec.isMain) return c;
    }
    return calls.isEmpty ? null : calls.first;
  }

  List<HablarCallItem> get smallerCalls => [
    for (final c in calls)
      if (!c.spec.isMain) c,
  ];

  bool get hasOpenCall => calls.any((c) => c.canStart);

  bool get hasUnlockedCall => calls.any(
    (c) =>
        c.canStart ||
        c.state == HablarCallState.tierLocked ||
        c.state == HablarCallState.later,
  );

  /// The single call featured on this place's main card:
  /// 1. First `ready` call in unlock order.
  /// 2. Else if any `done` call exists: prefer `mainCall` if `done`, else the last `done` call.
  /// 3. Else first `tierLocked` or `later` call.
  /// 4. Else first `backedByCourse` call in unlock order.
  /// 5. Else first call in unlock order (or null if empty).
  HablarCallItem? get featuredCall {
    for (final c in calls) {
      if (c.state == HablarCallState.ready) return c;
    }
    final main = mainCall;
    if (main != null && main.state == HablarCallState.done) return main;
    for (final c in calls.reversed) {
      if (c.state == HablarCallState.done) return c;
    }
    for (final c in calls) {
      if (c.state == HablarCallState.tierLocked ||
          c.state == HablarCallState.later) {
        return c;
      }
    }
    for (final c in calls) {
      if (c.backedByCourse) return c;
    }
    return calls.isEmpty ? null : calls.first;
  }

  /// All calls in unlock order except [featuredCall].
  List<HablarCallItem> get otherCalls {
    final featured = featuredCall;
    if (featured == null) return const [];
    return [
      for (final c in calls)
        if (!identical(c, featured)) c,
    ];
  }
}

/// Complete, pure-Dart snapshot rendered by [HablarTab].
class HablarSnapshot {
  const HablarSnapshot({
    required this.nextCall,
    required this.stops,
    required this.openWords,
    required this.callsEntitled,
    required this.completedCount,
  });

  /// The single recommended call across all places.
  /// Always non-null when the course has at least one place with calls.
  final HablarCallItem? nextCall;

  /// All places in map order, with their state and titled calls.
  final List<PlaceJourneyStop> stops;

  /// Words open for speaking (`ear.etapa >= 3`).
  final List<String> openWords;

  /// Whether live calls are included in the learner's current plan (`Entitlements.has(Feature.calls)`).
  final bool callsEntitled;

  /// Number of calls completed at least once.
  final int completedCount;

  /// Places the learner has reached.
  List<PlaceJourneyStop> get reachedStops => [
    for (final s in stops)
      if (s.reached) s,
  ];

  /// First place the learner has not reached yet, or null if all are reached.
  PlaceJourneyStop? get nextLockedStop {
    for (final s in stops) {
      if (!s.reached) return s;
    }
    return null;
  }

  /// Default selected place pill:
  /// 1. Latest reached stop with an open call.
  /// 2. Else latest reached stop with an unlocked call (`canStart`, `tierLocked`, or `later`).
  /// 3. Else the last reached stop (or null if none).
  PlaceJourneyStop? get defaultSelectedStop {
    final reached = reachedStops;
    for (final s in reached.reversed) {
      if (s.hasOpenCall) return s;
    }
    for (final s in reached.reversed) {
      if (s.hasUnlockedCall) return s;
    }
    return reached.isEmpty ? null : reached.last;
  }

  /// Returns the reached stop matching [id], or null.
  PlaceJourneyStop? stopById(String? id) {
    if (id == null) return null;
    for (final s in stops) {
      if (s.reached && s.place.id == id) return s;
    }
    return null;
  }

  /// Up to [maxCallPreviewChips] open words shown on the featured next-call card.
  List<String> get previewWords => openWords.take(maxCallPreviewChips).toList();
}

bool _isCallDone({
  required ProgressStore progress,
  required Set<String> completedCallIds,
  required HablarCallSpec spec,
  required String? briefId,
}) {
  if (completedCallIds.contains(spec.id) || progress.callDone(spec.id)) {
    return true;
  }
  if (briefId != null &&
      briefId != spec.id &&
      (completedCallIds.contains(briefId) || progress.callDone(briefId))) {
    return true;
  }
  if (spec.isMain &&
      spec.placeId != spec.id &&
      (completedCallIds.contains(spec.placeId) ||
          progress.callDone(spec.placeId))) {
    return true;
  }
  return false;
}

/// Builds the [HablarSnapshot] from [course], [progress], lazy [callsAvailable],
/// optional [entitlements], optional [completedCallIds], and [shortCallsEnabled].
///
/// `callsAvailable` is read lazily and only when at least one startable call
/// meets its story threshold, is backed by course data, and is entitled —
/// preserving the lazy voice-library preload behaviour.
///
/// [shortCallsEnabled] defaults to `false` until `coqui/app/lib/src/addresses.dart`
/// preserves `CallRoute.callId` (see `106-feature-speaking-needs-app-call-id-address.md`),
/// keeping smaller calls in [HablarCallState.soon] so tapping one can never
/// accidentally start the place's main call.
HablarSnapshot buildHablarSnapshot({
  required CourseCatalog course,
  required ProgressStore progress,
  required bool Function() callsAvailable,
  Entitlements entitlements = const AllowAllEntitlements(),
  Set<String> completedCallIds = const {},
  String? callsLater,
  bool shortCallsEnabled = false,
}) {
  final callsEntitled = entitlements.has(Feature.calls);
  final partnerName = course.language.partnerName;
  final laterLine = callsLater ?? SpeakWording.callsLaterFor(partnerName);

  var available = false;
  var asked = false;
  bool canCall() {
    if (!asked) {
      asked = true;
      available = callsAvailable();
    }
    return available;
  }

  final places = course.places;
  var maxReached = 0;
  for (var i = 1; i < places.length; i++) {
    final prev = places[i - 1];
    final prevDone =
        prev.stories.isNotEmpty && prev.stories.every(progress.played);
    final hasPlayedInPlace = places[i].stories.any(progress.played);
    if (hasPlayedInPlace || (places[i].stories.isNotEmpty && prevDone)) {
      maxReached = i;
    }
  }

  final isSpanish = course.language.code == Language.spanish.code;
  var completedCount = 0;
  final countedIds = <String>{};
  final stops = <PlaceJourneyStop>[];
  for (var i = 0; i < places.length; i++) {
    final place = places[i];
    final placeNumber = i + 1;
    final reached = i <= maxReached;
    final totalStories = place.stories.length;
    final playedCount = place.stories.where(progress.played).length;

    final courseCalls = course.callsFor(place.id);
    final localCatalog = callsForPlace(place.id);
    final localById = {for (final s in localCatalog) s.id: s};
    final localMain = mainCallForPlace(place.id);

    final resolved = <(HablarCallSpec, String?, bool)>[];
    if (courseCalls.isNotEmpty) {
      final seenIds = <String>{};
      var hasCourseSmall = false;
      for (final c in courseCalls) {
        final fallback = localById[c.id] ?? (c.isMain ? localMain : null);
        final title = c.title.trim().isNotEmpty
            ? c.title
            : (isSpanish ? (fallback?.titleEs ?? place.name) : place.name);
        final rawJob = c.jobEn.trim().isNotEmpty
            ? c.jobEn
            : (fallback?.jobEn ?? c.job);
        final spec = HablarCallSpec(
          id: c.id == place.id && fallback != null ? fallback.id : c.id,
          placeId: c.placeId,
          titleEs: title,
          jobEn: rawJob.replaceAll('{partner}', partnerName),
          minutes: c.minutes,
          isMain: c.isMain,
          pixelAsset: c.photo,
        );
        if (!spec.isMain) hasCourseSmall = true;
        seenIds.add(spec.id);
        resolved.add((spec, c.id, isCallBriefLive(c)));
      }
      // Legacy single-call catalog: list local smaller calls as unbacked (`soon`).
      if (!hasCourseSmall && isSpanish) {
        for (final local in localCatalog) {
          if (local.isMain || seenIds.contains(local.id)) continue;
          resolved.add((
            HablarCallSpec(
              id: local.id,
              placeId: local.placeId,
              titleEs: local.titleEs,
              jobEn: local.jobFor(partnerName),
              minutes: local.minutes,
              isMain: false,
              pixelAsset: local.pixelAsset,
            ),
            null,
            false,
          ));
        }
      }
    } else if (isSpanish) {
      for (final spec in localCatalog) {
        resolved.add((
          HablarCallSpec(
            id: spec.id,
            placeId: spec.placeId,
            titleEs: spec.titleEs,
            jobEn: spec.jobFor(partnerName),
            minutes: spec.minutes,
            isMain: spec.isMain,
            pixelAsset: spec.pixelAsset,
          ),
          null,
          false,
        ));
      }
    }

    final smalls = [
      for (final entry in resolved)
        if (!entry.$1.isMain) entry,
    ];
    final mains = [
      for (final entry in resolved)
        if (entry.$1.isMain) entry,
    ];
    final ordered = [...smalls, ...mains];
    final smallCount = smalls.length;

    final items = <HablarCallItem>[];
    var smallIndex = 0;
    for (final (spec, briefId, backedByCourse) in ordered) {
      final int unlockAfter;
      if (!spec.isMain) {
        unlockAfter = totalStories == 0
            ? 0
            : (((smallIndex + 1) * totalStories) / (smallCount + 1))
                  .ceil()
                  .clamp(1, totalStories);
        smallIndex++;
      } else {
        unlockAfter = totalStories;
      }

      final done = _isCallDone(
        progress: progress,
        completedCallIds: completedCallIds,
        spec: spec,
        briefId: briefId,
      );
      if (done) {
        completedCount++;
        countedIds.add(spec.id);
        if (briefId != null) countedIds.add(briefId);
        if (spec.isMain) countedIds.add(place.id);
      }

      final thresholdMet = totalStories > 0 && playedCount >= unlockAfter;
      final canStartKind = spec.isMain || shortCallsEnabled;

      final HablarCallState itemState;
      final String itemStatus;
      if (!thresholdMet) {
        itemState = HablarCallState.upcoming;
        itemStatus = unlockAfter > 0 && unlockAfter < totalStories
            ? SpeakWording.opensAfterStory(unlockAfter)
            : SpeakWording.opensWhenYouFinish(place.name);
      } else if (!backedByCourse || !canStartKind) {
        itemState = HablarCallState.soon;
        itemStatus = SpeakWording.comingSoonPlace(place.name);
      } else if (!callsEntitled) {
        itemState = HablarCallState.tierLocked;
        itemStatus = SpeakWording.planCardBody(partnerName);
      } else if (!canCall()) {
        itemState = HablarCallState.later;
        itemStatus = laterLine;
      } else {
        itemState = done ? HablarCallState.done : HablarCallState.ready;
        itemStatus = SpeakWording.durationLine(spec.minutes);
      }

      items.add(
        HablarCallItem(
          spec: spec,
          place: place,
          placeNumber: placeNumber,
          state: itemState,
          statusLine: itemStatus,
          unlockAfterStory: unlockAfter,
          backedByCourse: backedByCourse && canStartKind,
        ),
      );
    }

    final (placeState, placeStatus) = _derivePlaceState(
      items,
      place: place,
      storiesDone: totalStories > 0 && playedCount >= totalStories,
    );

    stops.add(
      PlaceJourneyStop(
        place: place,
        placeNumber: placeNumber,
        reached: reached,
        state: placeState,
        calls: items,
        statusLine: placeStatus,
      ),
    );
  }

  for (final id in completedCallIds) {
    if (!countedIds.contains(id)) completedCount++;
  }

  final next = _pickNextCall(stops);
  return HablarSnapshot(
    nextCall: next,
    stops: stops,
    openWords: wordsOpenForSpeaking(progress),
    callsEntitled: callsEntitled,
    completedCount: completedCount,
  );
}

(HablarCallState, String) _derivePlaceState(
  List<HablarCallItem> items, {
  required Place place,
  required bool storiesDone,
}) {
  for (final c in items) {
    if (c.state == HablarCallState.ready) return (c.state, c.statusLine);
  }
  HablarCallItem? main;
  for (final c in items) {
    if (c.spec.isMain) {
      main = c;
      break;
    }
  }
  if (main != null && main.state == HablarCallState.done) {
    return (main.state, main.statusLine);
  }
  for (final c in items.reversed) {
    if (c.state == HablarCallState.done) return (c.state, c.statusLine);
  }
  for (final c in items) {
    if (c.state == HablarCallState.tierLocked) return (c.state, c.statusLine);
  }
  for (final c in items) {
    if (c.state == HablarCallState.later) return (c.state, c.statusLine);
  }
  if (main != null) {
    return (main.state, main.statusLine);
  }
  if (items.isNotEmpty) {
    return (items.first.state, items.first.statusLine);
  }
  if (storiesDone) {
    return (HablarCallState.soon, SpeakWording.comingSoonPlace(place.name));
  }
  return (
    HablarCallState.upcoming,
    SpeakWording.opensWhenYouFinish(place.name),
  );
}

/// Picks the single best "Up next" call across all places:
/// 1. First uncompleted ready main call (in map order).
/// 2. Else first uncompleted ready smaller call.
/// 3. Else most recent completed call (preferring main, for replay).
/// 4. Else first tier-locked or later call.
/// 5. Else the first place's featured call.
HablarCallItem? _pickNextCall(List<PlaceJourneyStop> stops) {
  for (final stop in stops) {
    final main = stop.mainCall;
    if (main != null && main.state == HablarCallState.ready) return main;
  }
  for (final stop in stops) {
    for (final c in stop.smallerCalls) {
      if (c.state == HablarCallState.ready) return c;
    }
  }
  for (final stop in stops.reversed) {
    final main = stop.mainCall;
    if (main != null && main.state == HablarCallState.done) return main;
  }
  for (final stop in stops.reversed) {
    for (final c in stop.calls.reversed) {
      if (c.state == HablarCallState.done) return c;
    }
  }
  for (final stop in stops) {
    for (final c in stop.calls) {
      if (c.state == HablarCallState.tierLocked ||
          c.state == HablarCallState.later) {
        return c;
      }
    }
  }
  for (final stop in stops) {
    final featured = stop.featuredCall;
    if (featured != null) return featured;
  }
  return null;
}

/// The words open for speaking: ear stage 3 or higher.
List<String> wordsOpenForSpeaking(ProgressStore progress) => [
  for (final r in progress.words)
    if (r.ear.etapa >= 3) r.w,
];
