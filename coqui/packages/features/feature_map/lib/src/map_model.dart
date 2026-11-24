// What the map screen reads from the learner's progress and the course: which places are open and done, where
// the frog stands (app.html: `hecho`, `abierto`, `aqui`, `jugados`), and today's plan (app.html: `plan`).
// Pure Dart.
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_map/src/map_picture.dart';

// app.html: AJ().todo is 0 or 1 ("Open every place"); JavaScript treats 0 as false
bool _truthy(Object? v) => v is num ? v != 0 : v == true;

/// app.html: abierto. A place is open when it has stories, or when "Open every place" is on.
bool placeOpen(ProgressStore progress, Place l) =>
    _truthy(progress.setting('todo')) || l.stories.isNotEmpty;

/// app.html: `l.cuentos && l.cuentos.every(hecho)`. A place with no stories is never done.
bool placeDone(ProgressStore progress, Place l) =>
    l.stories.isNotEmpty && l.stories.every(progress.played);

/// app.html: jugados. The stories of a place he has played.
int storiesPlayed(ProgressStore progress, Place l) =>
    l.stories.where(progress.played).length;

/// app.html: aqui. The first place with stories he has not played all of, or the first place when there is none
/// (the old page does the same: with every story played the frog sits on place 1).
int currentPlace(ProgressStore progress, List<Place> places) => math.max(
  0,
  places.indexWhere(
    (l) => l.stories.isNotEmpty && !l.stories.every(progress.played),
  ),
);

/// The map's state from the real progress: mapa.html's `hecho`, `abierto` and `aqui`, by app.html's rules. A
/// place the course does not list is not open and not done.
MapState mapStateOf(ProgressStore progress, CourseCatalog course) {
  final places = course.places;
  return MapState(
    hecho: [for (final l in places) placeDone(progress, l)],
    abierto: [for (final l in places) placeOpen(progress, l)],
    aqui: currentPlace(progress, places),
  );
}

/// Typed kind of a [TodayEntry], so Noche labels do not match on English copy.
enum TodayEntryKind { review, newStory, secondPlay, listenAgain, call }

/// One entry of today's plan (app.html: an entry of `plan()`): what to play, how it is described, how long it
/// takes, and where it goes. The review entry ([review]) has no title here: its title is Spanish text that comes
/// from nowhere in the catalog (the screen shows it only when it is given one).
class TodayEntry {
  const TodayEntry({
    this.title,
    required this.line,
    required this.minutes,
    required this.route,
    required this.kind,
    this.review = false,
  });

  /// The story's title, from the catalog; null for the review entry.
  final String? title;

  /// app.html: `d`. "New story · play it twice", "3 words coming back", ...
  final String line;

  /// app.html: `m`
  final int minutes;

  /// app.html: `href` (the review) or `c` (a story): where the green button goes.
  final AppRoute route;

  /// The ¿Cuál? entry: due words, or all of them when nothing else is left.
  final bool review;

  /// Typed kind of this entry.
  final TodayEntryKind kind;

  /// app.html, `hud`: `p[0].d + " · " + p[0].m + " min"`
  String get subtitle => '$line · $minutes min';
}

/// app.html: plan. Today's plan: returns first, then new stories (up to three a day, each twice), then replays,
/// sized to his minutes. Never empty.
List<TodayEntry> todayPlan({
  required ProgressStore progress,
  required CourseCatalog course,
  required Clock clock,
}) {
  final out = <TodayEntry>[];
  // the words Repaso can serve (one rule, page 15, asked in coqui_contracts); with no games' data, today's: a word that
  // has a picture pair
  final serving = repasoServing(course, progress);
  final due = progress
      .due(Skill.ear)
      .where(
        (w) => serving != null
            ? serving.canServe(w)
            : course.pairs.any((p) => p.word == w),
      )
      .toList();
  final minSetting = progress.setting('min');
  final min = minSetting is num ? minSetting : 30;
  num used = 0;
  if (due.isNotEmpty) {
    final nd = math.min(due.length, 10);
    out.add(
      TodayEntry(
        line: '$nd word${nd > 1 ? 's' : ''} coming back',
        minutes: math.min(6, 2 + (nd / 3).ceil()),
        route: const ReviewRoute(),
        review: true,
        kind: TodayEntryKind.review,
      ),
    );
  }
  final cs = [for (final l in course.places) ...l.stories];
  int veces(String id) => progress.story(id)?.n ?? 0;
  final now = DateTime.fromMillisecondsSinceEpoch(clock.nowMs());
  bool today(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  final nuevosHoy = cs.where((c) {
    final r = progress.story(c);
    return r != null && today(r.primera);
  }).length;
  final nuevos = cs
      .where((c) => veces(c) < 2)
      .take(math.max(0, 3 - nuevosHoy + cs.where((c) => veces(c) == 1).length))
      .toList();
  for (final c in nuevos) {
    if (used >= min && out.isNotEmpty) break;
    final x = course.meta(c);
    if (x == null) continue;
    final secondPlay = veces(c) != 0;
    final m = x.minutes * (secondPlay ? 1 : 2);
    out.add(
      TodayEntry(
        title: x.title,
        line: secondPlay ? 'Second play' : 'New story · play it twice',
        minutes: m,
        route: StoryRoute(c),
        kind: secondPlay ? TodayEntryKind.secondPlay : TodayEntryKind.newStory,
      ),
    );
    used += m;
  }
  final otros = cs.where((c) => veces(c) >= 2).toList();
  var k = 0;
  while (used < min && otros.isNotEmpty && k < 6) {
    final c = otros[k % otros.length];
    final x = course.meta(c);
    if (x == null) {
      k++;
      continue;
    }
    out.add(
      TodayEntry(
        title: x.title,
        line: 'Listen again',
        minutes: x.minutes,
        route: StoryRoute(c),
        kind: TodayEntryKind.listenAgain,
      ),
    );
    used += x.minutes;
    k++;
  }
  if (out.isEmpty) {
    out.add(
      const TodayEntry(
        line: 'All your words',
        minutes: 3,
        route: ReviewRoute(),
        review: true,
        kind: TodayEntryKind.review,
      ),
    );
  }
  return out;
}

/// Short kind label shown in the Noche Up next card (`"<kind> · <N> min"`).
String upNextKind(TodayEntry entry) => switch (entry.kind) {
  TodayEntryKind.newStory => 'New story',
  TodayEntryKind.secondPlay => 'Second play',
  TodayEntryKind.listenAgain => 'Listen again',
  TodayEntryKind.review || TodayEntryKind.call => entry.line,
};

/// Step label used in the `"Then <step1>, then <step2>"` line of the Noche Up next card.
String? planStepLabel(TodayEntry entry) => switch (entry.kind) {
  TodayEntryKind.review => 'review',
  TodayEntryKind.call => 'a call',
  TodayEntryKind.newStory => 'a new story',
  TodayEntryKind.secondPlay || TodayEntryKind.listenAgain => 'listening',
};

/// Formats `"Then <step1>, then <step2>"` from the entries of [plan] after the first.
/// Returns `null` when there are no steps.
String? upNextThenLine(List<TodayEntry> plan) {
  if (plan.length <= 1) return null;
  final steps = <String>[];
  for (final entry in plan.skip(1)) {
    final step = planStepLabel(entry);
    if (step != null) {
      steps.add(step);
      if (steps.length == 2) break;
    }
  }
  if (steps.isEmpty) return null;
  if (steps.length == 1) return 'Then ${steps[0]}';
  return 'Then ${steps[0]}, then ${steps[1]}';
}

/// Index in [places] of the place whose `stories` contains [storyId], or `null`.
int? placeIndexForStory(List<Place> places, String storyId) {
  for (var i = 0; i < places.length; i++) {
    if (places[i].stories.contains(storyId)) return i;
  }
  return null;
}
