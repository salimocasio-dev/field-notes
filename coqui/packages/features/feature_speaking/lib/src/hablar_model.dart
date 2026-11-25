/// What the Hablar tab shows, without a widget.
///
/// Replaces the old 10-row "Call Danny" list with:
/// - one picked [nextCall] hero (from open words + map progress),
/// - a 10-stop [stops] journey tied to the map places (done / ready / upcoming),
/// - main + 2–3 smaller titled calls per place, and
/// - a clean [CallEntitlement] hook for the live-calls subscription tier.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_speaking/src/call_catalog.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:feature_speaking/src/entitlements_hook.dart';

/// Availability state of a single call or place stop.
enum HablarCallState {
  /// Ready to start right now (place unlocked, call backed, build can call, entitled).
  ready,

  /// Already completed at least once (can be replayed any time).
  done,

  /// Place unlocked and call exists, but this build cannot place calls (`call.available == false`).
  later,

  /// Place unlocked and call exists, but locked by the subscription tier entitlement.
  tierLocked,

  /// Place unlocked, waiting for its live call definition in course data (or a smaller call `CallRoute` cannot
  /// name yet).
  soon,

  /// Locked until the learner finishes the place's stories on the map.
  upcoming,
}

/// One titled call entry displayed in the Hero card or a Place panel.
class HablarCallItem {
  const HablarCallItem({
    required this.spec,
    required this.place,
    required this.placeNumber,
    required this.state,
    required this.statusLine,
  });

  final HablarCallSpec spec;
  final Place place;
  final int placeNumber;
  final HablarCallState state;

  /// Short plain-English status line (e.g. "~5 min", "Opens when you finish La cocina").
  final String statusLine;

  bool get canStart =>
      state == HablarCallState.ready || state == HablarCallState.done;
}

/// One stop on the 10-place horizontal Map Journey strip.
class PlaceJourneyStop {
  const PlaceJourneyStop({
    required this.place,
    required this.placeNumber,
    required this.state,
    required this.calls,
    required this.statusLine,
  });

  final Place place;
  final int placeNumber;
  final HablarCallState state;
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
}

/// Complete, pure-Dart snapshot rendered by [HablarTab].
class HablarSnapshot {
  const HablarSnapshot({
    required this.nextCall,
    required this.stops,
    required this.openWords,
    required this.entitlement,
    required this.completedCount,
  });

  /// The single recommended call surfaced in the Up Next hero card.
  /// Always non-null when the course has at least one place.
  final HablarCallItem? nextCall;

  /// All 10 places in map order, with their state and titled calls.
  final List<PlaceJourneyStop> stops;

  /// Words open for speaking (`ear.etapa >= 3`).
  final List<String> openWords;

  /// Current subscription tier status for live calls.
  final CallEntitlement entitlement;

  /// Number of calls completed at least once (used to retire first-time hint).
  final int completedCount;

  /// Show the "Practice · no fail" reassurance line only before the first completed call.
  bool get showFirstTimeReassurance => completedCount == 0;
}

/// Builds the [HablarSnapshot] from [course], [progress], lazy [callsAvailable],
/// optional [entitlement], and optional [completedCallIds].
///
/// `callsAvailable` is read lazily and only when at least one unlocked place
/// has a live call (`course.callFor(place.id) != null`), preserving the lazy
/// voice-library preload behaviour tested in `hablar_test.dart`.
HablarSnapshot buildHablarSnapshot({
  required CourseCatalog course,
  required ProgressStore progress,
  required bool Function() callsAvailable,
  CallEntitlement entitlement = CallEntitlement.included,
  Set<String> completedCallIds = const {},
  String? callsLater,
}) {
  final partnerName = course.language.partnerName;
  final laterLine = callsLater ?? CallTexts.callsLaterFor(partnerName);

  var available = false;
  var asked = false;
  bool canCall() {
    if (!asked) {
      asked = true;
      available = callsAvailable();
    }
    return available;
  }

  final stops = <PlaceJourneyStop>[];
  for (var i = 0; i < course.places.length; i++) {
    final place = course.places[i];
    final placeNumber = i + 1;
    final storiesDone =
        place.stories.isNotEmpty && place.stories.every(progress.played);
    final brief = course.callFor(place.id);
    final specs = callsForPlace(place.id);

    HablarCallState placeState;
    String placeStatus;
    if (brief != null && storiesDone) {
      if (entitlement == CallEntitlement.upgradeRequired) {
        placeState = HablarCallState.tierLocked;
        placeStatus = HablarTexts.tierLockedLineFor(partnerName);
      } else if (!canCall()) {
        placeState = HablarCallState.later;
        placeStatus = laterLine;
      } else {
        final mainSpec = mainCallForPlace(place.id);
        final mainDone =
            mainSpec != null && completedCallIds.contains(mainSpec.id);
        placeState = mainDone ? HablarCallState.done : HablarCallState.ready;
        placeStatus = CallTexts.durationLine(brief.minutes);
      }
    } else if (storiesDone) {
      placeState = HablarCallState.soon;
      placeStatus = 'Coming soon · ${place.name}';
    } else {
      placeState = HablarCallState.upcoming;
      placeStatus = 'Opens when you finish ${place.name}';
    }

    final items = <HablarCallItem>[
      for (final spec in specs)
        () {
          final minutes = spec.isMain && brief != null
              ? brief.minutes
              : spec.minutes;
          final jobEn = spec.jobFor(partnerName);
          final effectiveSpec = minutes == spec.minutes && jobEn == spec.jobEn
              ? spec
              : HablarCallSpec(
                  id: spec.id,
                  placeId: spec.placeId,
                  titleEs: spec.titleEs,
                  jobEn: jobEn,
                  minutes: minutes,
                  isMain: spec.isMain,
                  pixelAsset: spec.pixelAsset,
                );
          HablarCallState itemState = placeState;
          final placeOpen =
              placeState == HablarCallState.ready ||
              placeState == HablarCallState.done;
          if (placeOpen && !spec.isMain) {
            // `CallRoute` carries only a place (request 25), so a smaller call would start the place's main call:
            // it is listed, not started, until the route can name it.
            itemState = HablarCallState.soon;
          } else if (placeOpen && completedCallIds.contains(spec.id)) {
            itemState = HablarCallState.done;
          } else if (placeState == HablarCallState.done &&
              !completedCallIds.contains(spec.id)) {
            itemState = HablarCallState.ready;
          }
          final itemStatus =
              itemState == HablarCallState.ready ||
                  itemState == HablarCallState.done
              ? CallTexts.durationLine(effectiveSpec.minutes)
              : placeOpen
              ? HablarTexts.smallerCallSoon
              : placeStatus;
          return HablarCallItem(
            spec: effectiveSpec,
            place: place,
            placeNumber: placeNumber,
            state: itemState,
            statusLine: itemStatus,
          );
        }(),
    ];

    stops.add(
      PlaceJourneyStop(
        place: place,
        placeNumber: placeNumber,
        state: placeState,
        calls: items,
        statusLine: placeStatus,
      ),
    );
  }

  final next = _pickNextCall(stops);
  return HablarSnapshot(
    nextCall: next,
    stops: stops,
    openWords: wordsOpenForSpeaking(progress),
    entitlement: entitlement,
    completedCount: completedCallIds.length,
  );
}

/// Picks the single best "Up next" call for the Hero card:
/// 1. First uncompleted ready main call (in map order).
/// 2. Else first uncompleted ready smaller call.
/// 3. Else most recent completed ready call (for replay).
/// 4. Else first tier-locked or later call.
/// 5. Else the first place's main call (showing what unlocks next).
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
  for (final stop in stops) {
    final main = stop.mainCall;
    if (main != null &&
        (main.state == HablarCallState.tierLocked ||
            main.state == HablarCallState.later)) {
      return main;
    }
  }
  for (final stop in stops) {
    final main = stop.mainCall;
    if (main != null) return main;
  }
  return null;
}

/// The words open for speaking: ear stage 3 or higher.
List<String> wordsOpenForSpeaking(ProgressStore progress) => [
  for (final r in progress.words)
    if (r.ear.etapa >= 3) r.w,
];

/// Static English UI labels for the Hablar tab (menus in English).
abstract final class HablarTexts {
  static const upNext = 'UP NEXT';
  static const byPlace = 'By place';
  static String practiceNoFailFor(String partnerName) =>
      'Practice with $partnerName · no fail, help any time';
  static String get practiceNoFail =>
      practiceNoFailFor(Language.spanish.partnerName);
  static const upNextAbove = 'Up next above';
  static const doneBadge = 'Done';
  static const mainCallLabel = 'Main call';
  static const shortCallsLabel = 'Shorter practice';

  /// A smaller call of an open place, until `CallRoute` can name it (request 25).
  static const smallerCallSoon = 'Coming soon';
  static const wordsTitle = 'Words open for speaking';
  static const wordsNone =
      'None yet. A word opens once your ear has held it for a few days.';
  static String tierLockedLineFor(String partnerName) =>
      'Live calls with $partnerName are included in the top plan.';
  static String get tierLockedLine =>
      tierLockedLineFor(Language.spanish.partnerName);
  static const tierLockedAction = 'Live calls plan';
  static String wordsReadyPill(int count) =>
      count == 1 ? '1 word ready' : '$count words ready';
}
