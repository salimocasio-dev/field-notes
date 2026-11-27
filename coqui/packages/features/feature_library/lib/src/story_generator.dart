import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/reading_assets.dart';

class StoryDraft {
  const StoryDraft(this.title, this.body);
  final String title;
  final String body;
}

/// Alternatives within a beat lead into the same next beat. Compose a
/// combination locally and check it against the learner's current records.
class StoryGenerator {
  StoryGenerator(this.plots);

  factory StoryGenerator.fromJson(Map<String, dynamic> json) => StoryGenerator([
    for (final plot in json['plots'] as List)
      (
        title: plot['title'] as String,
        beats: [
          for (final beat in plot['beats'] as List)
            List<String>.from(beat as List),
        ],
      ),
  ]);

  static Future<StoryGenerator> load() async => StoryGenerator.fromJson(
    jsonDecode(await loadReadingAsset('story_plots.json'))
        as Map<String, dynamic>,
  );

  final List<({String title, List<List<String>> beats})> plots;

  Iterable<StoryDraft> _drafts() sync* {
    for (final plot in plots) {
      for (final lines in _combine(plot.beats, 0)) {
        yield StoryDraft(plot.title, lines.join('\n'));
      }
    }
  }

  Iterable<List<String>> _combine(List<List<String>> beats, int index) sync* {
    if (index == beats.length) {
      yield [];
      return;
    }
    for (final option in beats[index]) {
      for (final tail in _combine(beats, index + 1)) {
        yield [option, ...tail];
      }
    }
  }

  Map<String, int>? _eligibleUnknown(
    StoryDraft draft,
    ReadingVocabulary vocabulary,
    Set<String> previous,
  ) {
    if (previous.contains(draft.body)) return null;
    final coverage = readingCoverage(draft.body, vocabulary);
    final unknown = coverage.unknown;
    if (!meetsReadingCoverage(coverage) ||
        unknown.length > 3 ||
        unknown.values.any((count) => count < 2)) {
      return null;
    }
    return unknown;
  }

  /// True when [generate] with no practice words would return a story for
  /// [vocabulary], [due], and [previous].
  bool canWrite({
    required ReadingVocabulary vocabulary,
    required Iterable<String> due,
    required Set<String> previous,
  }) => _drafts().any(
    (draft) => _eligibleUnknown(draft, vocabulary, previous) != null,
  );

  StoryDraft? generate({
    required ReadingVocabulary vocabulary,
    required List<String> focus,
    required Iterable<String> due,
    required Set<String> previous,
    required Rng rng,
  }) {
    final language = vocabulary.language;
    final targets = focus
        .map((word) => readingKey(word, language: language))
        .where((word) => word.isNotEmpty)
        .toSet();
    final review = due
        .map((word) => readingKey(word, language: language))
        .where((word) => word.isNotEmpty)
        .toSet();
    final best = <StoryDraft>[];
    ({int review, int newWords})? bestScore;
    for (final draft in _drafts()) {
      final unknown = _eligibleUnknown(draft, vocabulary, previous);
      if (unknown == null) continue;

      final searchable = readingLines(draft.body)
          .map((line) => ' ${readingKey(line, language: language)} ')
          .toList();
      bool includes(String word) =>
          searchable.any((line) => line.contains(' $word '));
      if (!targets.every(includes)) continue;
      final score = (
        review: review.where(includes).length,
        newWords: unknown.length,
      );
      final old = bestScore;
      final higher =
          old == null ||
          score.review > old.review ||
          (score.review == old.review && score.newWords > old.newWords);
      if (higher) {
        best.clear();
        bestScore = score;
      }
      if (higher ||
          (score.review == old.review && score.newWords == old.newWords)) {
        best.add(draft);
      }
    }
    return best.isEmpty ? null : best[(rng.next() * best.length).floor()];
  }
}
