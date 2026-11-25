/// Pure data model and calculations for the Noche Me screen
/// (`docs/proyecto/noche/Noche-Yo.dc.html`, story N4.7 / issue #107).
library;

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/js.dart';
import 'package:feature_profile/src/languages_data.dart';
import 'package:feature_profile/src/texts.dart';
import 'package:feature_profile/src/welcome.dart';

/// Fallback maximum word mastery stage until request 87
/// (`LanguageProgressStore.stageMax`) lands in `coqui_contracts`.
const int defaultStageMax = 4;

/// Default minutes-a-day goal when `ajustes.min` is missing or non-positive.
const int defaultGoalMinutes = 30;

/// Number of days plotted in the Me minutes bar chart.
const int meChartDays = 7;

const Set<String> _a2AndUp = {'A2', 'B1', 'B2', 'C1', 'C2'};

/// UTC calendar day key (`YYYY-MM-DD`), matching `coqui_progress`'s
/// `isoDayFromDate` and `palabras.js`'s `toISOString().slice(0, 10)`.
String utcIsoDay(DateTime day) {
  final d = DateTime.fromMillisecondsSinceEpoch(
    day.millisecondsSinceEpoch,
    isUtc: true,
  );
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

/// Fallback reader for daily minutes until request 87
/// (`LanguageProgressStore.minutesOn`) lands in `coqui_contracts`.
///
/// Reads `progress.raw['minutosDia'][YYYY-MM-DD]` (the same UTC day-key map
/// format used by `coqui_progress`) when present, returning `0` otherwise.
double readMinutesOn(ProgressStore progress, DateTime day) {
  final byDay = progress.raw['minutosDia'];
  if (byDay is! Map) return 0;
  final value = byDay[utcIsoDay(day)];
  if (value is num && value.isFinite && value > 0) {
    return value.toDouble();
  }
  return 0;
}

/// English single-letter weekday initial for [DateTime.weekday] (`1` = Mon .. `7` = Sun).
String weekdayInitial(int weekday) => switch (weekday) {
  DateTime.monday => 'M',
  DateTime.tuesday => 'T',
  DateTime.wednesday => 'W',
  DateTime.thursday => 'T',
  DateTime.friday => 'F',
  DateTime.saturday => 'S',
  DateTime.sunday => 'S',
  _ => '',
};

/// Resolves the learner's CEFR level label (`override`, `levelResult['cefr']`,
/// or [defaultLanguageLevel]).
String resolveLevel(ProgressStore progress, [String? override]) {
  if (override != null && override.isNotEmpty) return override;
  final cefr = progress.levelResult?['cefr'];
  if (cefr is String && cefr.isNotEmpty) return cefr;
  return defaultLanguageLevel;
}

/// Whether reading counts toward word mastery at [level] (A2 and above).
bool tracksReadingForLevel(String level) => _a2AndUp.contains(level);

/// Resolves the positive daily goal in minutes from `ajustes.min`.
int resolveGoalMinutes(Object? rawMin) {
  if (rawMin is num && rawMin.isFinite && rawMin > 0) {
    return math.max(1, jsRound(rawMin));
  }
  return defaultGoalMinutes;
}

/// Human-readable plan name matching `Noche-Yo.dc.html` and `Noche-Planes.dc.html`.
String planDisplayName(Plan plan) => switch (plan) {
  Plan.free => mePlanFree,
  Plan.course => mePlanCourse,
  Plan.courseAndCalls => mePlanCourseAndCalls,
};

/// One column in the 7-day minutes bar chart.
class MeDayBar {
  const MeDayBar({
    required this.dayUtc,
    required this.label,
    required this.minutes,
    required this.roundedMinutes,
    required this.isToday,
  });

  final DateTime dayUtc;
  final String label;
  final double minutes;
  final int roundedMinutes;
  final bool isToday;
}

/// Immutable snapshot rendered by `YoScreen` (N4.7 Me).
class MeViewData {
  const MeViewData({
    required this.totalMinutes,
    required this.streak,
    required this.streakFreezes,
    required this.goalMinutes,
    required this.selectedMinutePill,
    required this.weekBars,
    required this.weekChartSemanticLabel,
    required this.language,
    required this.level,
    required this.tracksReading,
    required this.currentPlace,
    required this.placeTotal,
    required this.placeDashes,
    required this.placeDashesSemanticLabel,
    required this.totalWords,
    required this.listeningGood,
    required this.speakingGood,
    required this.stageMax,
    required this.plan,
    required this.planName,
  });

  final int totalMinutes;
  final int streak;
  final int? streakFreezes;
  final int goalMinutes;

  /// The selected option in [minutePills], or `null` when the stored setting is
  /// not one of `[15, 30, 60, 120]`.
  final int? selectedMinutePill;
  final List<MeDayBar> weekBars;
  final String weekChartSemanticLabel;
  final Language language;
  final String level;
  final bool tracksReading;
  final Place? currentPlace;
  final int placeTotal;
  final List<NocheDashState> placeDashes;
  final String placeDashesSemanticLabel;
  final int totalWords;
  final int listeningGood;
  final int speakingGood;
  final int stageMax;
  final Plan plan;
  final String planName;

  double get listeningFraction =>
      totalWords <= 0 ? 0 : (listeningGood / totalWords).clamp(0.0, 1.0);

  double get speakingFraction =>
      totalWords <= 0 ? 0 : (speakingGood / totalWords).clamp(0.0, 1.0);

  String get streakLabel => '$streak ${plural(streak, 'day')}';

  String? get streakFreezesLabel {
    final freezes = streakFreezes;
    if (freezes == null) return null;
    return '$freezes ${plural(freezes, 'freeze')} saved';
  }
}

/// Computes [MeViewData] from [services] and optional overrides for contract
/// members still pending in `coqui/requests/`.
MeViewData buildMeViewData({
  required Services services,
  double Function(DateTime day)? minutesOn,
  int? streakFreezes,
  int? stageMax,
  Entitlements entitlements = const AllowAllEntitlements(),
  String? level,
}) {
  final progress = services.progress;
  final course = services.course;
  final resolvedStageMax = math.max(1, stageMax ?? defaultStageMax);
  final totalMinutes = math.max(0, jsRound(progress.minutes));
  final streak = math.max(0, progress.streak);

  final rawMin = progress.setting('min');
  final goalMinutes = resolveGoalMinutes(rawMin);
  final pillIndex = minutePillIndex(rawMin);
  final selectedMinutePill = pillIndex >= 0 ? minutePills[pillIndex] : null;

  final nowUtc = DateTime.fromMillisecondsSinceEpoch(
    services.clock.nowMs(),
    isUtc: true,
  );
  final todayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
  final readDay = minutesOn ?? (day) => readMinutesOn(progress, day);

  final weekBars = <MeDayBar>[];
  for (var offset = meChartDays - 1; offset >= 0; offset--) {
    final dayUtc = DateTime.utc(
      todayUtc.year,
      todayUtc.month,
      todayUtc.day - offset,
    );
    final rawValue = readDay(dayUtc);
    final safeMinutes = rawValue.isFinite && rawValue > 0 ? rawValue : 0.0;
    final isToday = offset == 0;
    weekBars.add(
      MeDayBar(
        dayUtc: dayUtc,
        label: isToday ? meTodayLabel : weekdayInitial(dayUtc.weekday),
        minutes: safeMinutes,
        roundedMinutes: jsRound(safeMinutes),
        isToday: isToday,
      ),
    );
  }

  final priorSix = [
    for (var i = 0; i < weekBars.length - 1; i++)
      '${weekBars[i].roundedMinutes}',
  ].join(', ');
  final todayRounded = weekBars.last.roundedMinutes;
  final weekChartSemanticLabel =
      'Minutes listened in the last 7 days: $priorSix, and $todayRounded so far today. Your goal is $goalMinutes a day.';

  final places = course.places;
  final firstUnfinished = places.indexWhere(
    (place) =>
        place.stories.isNotEmpty && !place.stories.every(progress.played),
  );
  final hereIndex = places.isEmpty ? -1 : currentPlaceIndex(progress, places);
  final currentPlace = hereIndex >= 0 ? places[hereIndex] : null;

  final placeDashes = <NocheDashState>[];
  var doneCount = 0;
  var toGoCount = 0;
  for (var i = 0; i < places.length; i++) {
    final place = places[i];
    final isDone =
        place.stories.isNotEmpty && place.stories.every(progress.played);
    final NocheDashState state;
    if (i == firstUnfinished) {
      state = NocheDashState.current;
    } else if (isDone) {
      state = NocheDashState.done;
      doneCount++;
    } else {
      state = NocheDashState.notYet;
      toGoCount++;
    }
    placeDashes.add(state);
  }

  final String placeDashesSemanticLabel;
  if (firstUnfinished >= 0) {
    placeDashesSemanticLabel =
        'Places: $doneCount done, on place ${places[firstUnfinished].n}, $toGoCount to go';
  } else {
    placeDashesSemanticLabel = 'Places: $doneCount done, $toGoCount to go';
  }

  final words = progress.words.toList(growable: false);
  final listeningGood = words
      .where((w) => w.ear.etapa >= resolvedStageMax)
      .length;
  final speakingGood = words
      .where((w) => w.mouth.etapa >= resolvedStageMax)
      .length;

  final resolvedLevel = resolveLevel(progress, level);
  final plan = entitlements.plan;

  return MeViewData(
    totalMinutes: totalMinutes,
    streak: streak,
    streakFreezes: streakFreezes,
    goalMinutes: goalMinutes,
    selectedMinutePill: selectedMinutePill,
    weekBars: weekBars,
    weekChartSemanticLabel: weekChartSemanticLabel,
    language: course.language,
    level: resolvedLevel,
    tracksReading: tracksReadingForLevel(resolvedLevel),
    currentPlace: currentPlace,
    placeTotal: places.length,
    placeDashes: placeDashes,
    placeDashesSemanticLabel: placeDashesSemanticLabel,
    totalWords: words.length,
    listeningGood: listeningGood,
    speakingGood: speakingGood,
    stageMax: resolvedStageMax,
    plan: plan,
    planName: planDisplayName(plan),
  );
}
