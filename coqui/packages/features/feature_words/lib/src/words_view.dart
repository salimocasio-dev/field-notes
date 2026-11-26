/// What the Noche Words tab shows, computed from `Services.progress`,
/// `Services.course`, and `Services.clock` (story N4.4, issue #104).
library;

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';

/// Fallback maximum word mastery stage until request 87
/// (`LanguageProgressStore.stageMax`) lands in `coqui_contracts`.
const int defaultStageMax = 4;

const double _dayMs = 864e5;

/// The three skill tabs on the Words screen.
enum WordsSkill { listening, speaking, reading }

/// The five review return-window columns in the Words bar chart.
enum DueBucket { today, tomorrow, threeDays, thisWeek, later }

/// Counts of words landing in each of the five return-window columns.
class DueBuckets {
  const DueBuckets({
    this.today = 0,
    this.tomorrow = 0,
    this.threeDays = 0,
    this.thisWeek = 0,
    this.later = 0,
  });

  final int today;
  final int tomorrow;
  final int threeDays;
  final int thisWeek;
  final int later;

  int get total => today + tomorrow + threeDays + thisWeek + later;
}

/// One row in the soonest-first word list for the selected skill.
class WordRowEntry {
  const WordRowEntry({
    required this.record,
    required this.skillRecord,
    required this.stage,
    required this.effectiveDue,
    required this.daysUntilDue,
    required this.bucket,
    required this.dueLine,
    required this.isDueToday,
    required this.isGood,
  });

  final WordRecord record;
  final SkillRecord skillRecord;
  final int stage;
  final num effectiveDue;
  final int? daysUntilDue;
  final DueBucket? bucket;
  final String dueLine;
  final bool isDueToday;
  final bool isGood;
}

/// All derived data for a single skill tab on the Words screen.
class SkillWordsView {
  const SkillWordsView({
    required this.dueToday,
    required this.totalWords,
    required this.goodCount,
    required this.buckets,
    required this.rows,
  });

  static const empty = SkillWordsView(
    dueToday: 0,
    totalWords: 0,
    goodCount: 0,
    buckets: DueBuckets(),
    rows: [],
  );

  final int dueToday;
  final int totalWords;
  final int goodCount;
  final DueBuckets buckets;
  final List<WordRowEntry> rows;
}

/// Complete view model for the Noche Words screen.
class WordsView {
  const WordsView({
    required this.listening,
    required this.speaking,
    required this.reading,
    required this.tracksReading,
    required this.stageMax,
    required this.hasReviewDue,
    required this.reviewEnabled,
    required this.added,
  });

  final SkillWordsView listening;
  final SkillWordsView speaking;
  final SkillWordsView reading;

  /// True once the learner reaches A2 or above (`progress.levelResult['cefr']`).
  final bool tracksReading;

  /// Highest stage (`etapa`) for a word's [NocheStageBar] and good counts.
  final int stageMax;

  /// True when Repaso has at least one due word it can serve.
  final bool hasReviewDue;

  /// True when either [hasReviewDue] is true or Repaso has askable words for
  /// practice.
  final bool reviewEnabled;

  /// Saved entries from "Add a word or goal" (`db.extra`).
  final List<String> added;

  SkillWordsView of(WordsSkill skill) => switch (skill) {
    WordsSkill.listening => listening,
    WordsSkill.speaking => speaking,
    WordsSkill.reading => reading,
  };

  /// Button label: "Start review" when words are due, "Practice" otherwise.
  String get reviewButtonLabel => hasReviewDue ? 'Start review' : 'Practice';

  /// Route parameter for [ReviewRoute].
  bool get reviewPractice => !hasReviewDue;
}

/// Whether reading progress tracking is open (A2 and above).
bool tracksReading(ProgressStore progress) {
  final band = progress.levelResult?['cefr'];
  return const ['A2', 'B1', 'B2', 'C1', 'C2'].contains(band);
}

/// Effective due timestamp for [skill] at [nowMs], honouring active parking
/// (`aparcada > nowMs`).
num effectiveDueMs(SkillRecord skill, int nowMs) {
  if (skill.aparcada > nowMs &&
      (skill.due == 0 || skill.due.isNaN || skill.aparcada > skill.due)) {
    return skill.aparcada;
  }
  return skill.due;
}

/// Whole days until [dueMs] from [nowMs], matching `comesBack`'s rounding:
/// `null` when unscheduled (`0` or `NaN`), `0` when due now or overdue,
/// `>= 1` otherwise.
int? daysUntilDue(num dueMs, int nowMs) {
  if (dueMs == 0 || dueMs.isNaN) return null;
  if (dueMs <= nowMs) return 0;
  return math.max(1, ((dueMs - nowMs) / _dayMs + 0.5).floor());
}

/// Maps [days] from [daysUntilDue] to one of the five Words chart columns.
DueBucket? dueBucketForDays(int? days) {
  if (days == null) return null;
  if (days <= 0) return DueBucket.today;
  if (days == 1) return DueBucket.tomorrow;
  if (days <= 3) return DueBucket.threeDays;
  if (days <= 7) return DueBucket.thisWeek;
  return DueBucket.later;
}

/// Convenience wrapper mapping [dueMs] directly to its [DueBucket] at [nowMs].
DueBucket? dueBucketFor(num dueMs, int nowMs) =>
    dueBucketForDays(daysUntilDue(dueMs, nowMs));

/// Formats a word row's due line:
/// - due today or overdue: `"back today"` (or `"good · back today"` at top stage)
/// - tomorrow: `"back tomorrow"`
/// - 2..13 days: `"back in <N> days"`
/// - 14+ days: `"back in <N> weeks"` (rounded to nearest week, >= 2)
/// - top stage (`isGood`): prefixed with `"good · "` (or `"good"` if unscheduled)
String formatWordDueLine({required int? days, required bool isGood}) {
  if (days == null) return isGood ? 'good' : '';
  final String when;
  if (days <= 0) {
    when = 'back today';
  } else if (days == 1) {
    when = 'back tomorrow';
  } else if (days < 14) {
    when = 'back in $days days';
  } else {
    final weeks = (days / 7 + 0.5).floor();
    when = 'back in $weeks weeks';
  }
  return isGood ? 'good · $when' : when;
}

// app.html: pares().m (CU.items by `w`, the last one of a word wins, as Map.set does)
/// The review pair of each word that has one, on the exact word.
Map<String, ReviewPair> pairsByWord(CourseCatalog course) => {
  for (final p in course.pairs) p.word: p,
};

// app.html: jug (the stories he has played, in the course's order)
/// The ids of the stories he has played, in the course's order.
List<String> playedStories(Services s) => [
  for (final l in s.course.places)
    for (final c in l.stories)
      if (s.progress.played(c)) c,
];

SkillWordsView _buildSkillView({
  required List<WordRecord> allWords,
  required Skill skill,
  required int nowMs,
  required int stageMax,
}) {
  final indexed = <({int index, WordRowEntry entry})>[];
  var today = 0;
  var tomorrow = 0;
  var threeDays = 0;
  var thisWeek = 0;
  var later = 0;
  var good = 0;

  for (var i = 0; i < allWords.length; i++) {
    final record = allWords[i];
    final sr = record.of(skill);
    final tracked = skill == Skill.ear
        ? sr.etapa > 0
        : (sr.etapa > 0 || sr.n > 0);
    if (!tracked) continue;

    final effDue = effectiveDueMs(sr, nowMs);
    final days = daysUntilDue(effDue, nowMs);
    final bucket = dueBucketForDays(days);
    switch (bucket) {
      case DueBucket.today:
        today++;
      case DueBucket.tomorrow:
        tomorrow++;
      case DueBucket.threeDays:
        threeDays++;
      case DueBucket.thisWeek:
        thisWeek++;
      case DueBucket.later:
        later++;
      case null:
        break;
    }

    final isGood = sr.etapa >= stageMax;
    if (isGood) good++;

    indexed.add((
      index: i,
      entry: WordRowEntry(
        record: record,
        skillRecord: sr,
        stage: sr.etapa,
        effectiveDue: effDue,
        daysUntilDue: days,
        bucket: bucket,
        dueLine: formatWordDueLine(days: days, isGood: isGood),
        isDueToday: days == 0,
        isGood: isGood,
      ),
    ));
  }

  // Soonest first; unscheduled words (due == 0) go after scheduled words;
  // ties keep the store's original order.
  indexed.sort((a, b) {
    final aHas = a.entry.daysUntilDue != null;
    final bHas = b.entry.daysUntilDue != null;
    if (aHas != bHas) return aHas ? -1 : 1;
    if (aHas && bHas) {
      final d = a.entry.effectiveDue.compareTo(b.entry.effectiveDue);
      if (d != 0) return d;
    }
    return a.index.compareTo(b.index);
  });

  return SkillWordsView(
    dueToday: today,
    totalWords: indexed.length,
    goodCount: good,
    buckets: DueBuckets(
      today: today,
      tomorrow: tomorrow,
      threeDays: threeDays,
      thisWeek: thisWeek,
      later: later,
    ),
    rows: [for (final item in indexed) item.entry],
  );
}

/// Synchronously builds a [WordsView] from already-loaded [Services].
WordsView buildWordsViewSync(Services s, {int? stageMax}) {
  final progress = s.progress;
  final course = s.course;
  final nowMs = s.clock.nowMs();
  final resolvedStageMax = math.max(1, stageMax ?? defaultStageMax);
  final allWords = progress.words.toList(growable: false);

  final listening = _buildSkillView(
    allWords: allWords,
    skill: Skill.ear,
    nowMs: nowMs,
    stageMax: resolvedStageMax,
  );
  final speaking = _buildSkillView(
    allWords: allWords,
    skill: Skill.mouth,
    nowMs: nowMs,
    stageMax: resolvedStageMax,
  );

  // Repaso asks the words it can serve (page 15: a word with a picture pair, or
  // one a sentence he has heard can score; the one rule lives in coqui_contracts,
  // where the session asks it too).
  final pairs = pairsByWord(course);
  final serving = repasoServing(course, progress);
  bool serves(String w) =>
      serving != null ? serving.canServe(w) : pairs.containsKey(w);

  final repasoDue = [
    for (final w in progress.due(Skill.ear))
      if (serves(w)) w,
  ];
  final askable = [
    for (final r in allWords)
      if (r.ear.etapa > 0 && serves(r.w)) r,
  ];

  return WordsView(
    listening: listening,
    speaking: speaking,
    reading: SkillWordsView.empty,
    tracksReading: tracksReading(progress),
    stageMax: resolvedStageMax,
    hasReviewDue: repasoDue.isNotEmpty,
    reviewEnabled: repasoDue.isNotEmpty || askable.isNotEmpty,
    added: progress.added,
  );
}

/// Loads the course catalog and computes the current [WordsView].
Future<WordsView> buildWordsView(Services s, {int? stageMax}) async {
  try {
    await s.course.load();
  } on Object {
    // Still render the learner's stored words even if course metadata fails to load.
  }
  return buildWordsViewSync(s, stageMax: stageMax);
}
