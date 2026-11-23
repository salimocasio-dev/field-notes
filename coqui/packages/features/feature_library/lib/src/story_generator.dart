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

  StoryDraft? generate({
    required ReadingVocabulary vocabulary,
    required List<String> focus,
    required Iterable<String> due,
    required Set<String> previous,
    required Rng rng,
  }) {
    final targets = focus
        .map(readingKey)
        .where((word) => word.isNotEmpty)
        .toSet();
    final review = due.map(readingKey).where((word) => word.isNotEmpty).toSet();
    final best = <StoryDraft>[];
    ({int review, int newWords})? bestScore;
    for (final draft in _drafts()) {
      if (previous.contains(draft.body)) continue;
      final coverage = readingCoverage(draft.body, vocabulary);
      final unknown = coverage.unknown;
      if (!meetsReadingCoverage(coverage) ||
          unknown.length > 3 ||
          unknown.values.any((count) => count < 2)) {
        continue;
      }

      final searchable = readingLines(draft.body)
          .map((line) => ' ${readingKey(line)} ')
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
