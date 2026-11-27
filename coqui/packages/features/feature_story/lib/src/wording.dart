/// All English UI and semantic wording for `feature_story`.
///
/// Screens and `feature_story` tests both read from this file so copy lives in
/// one place.
library;

/// Single source of truth for user-visible and semantic English copy in
/// `feature_story`.
abstract final class StoryWording {
  // Header & controls.
  static const String txtToggle = 'TXT';
  static const String startStorySemantic = 'Start story';

  // Fallback screens.
  static const String notReadyLine = 'This story is not in the new app yet.';
  static const String needsUpdateLine = 'Update the app to play this story';
  static const String backToMap = 'Back to the map';

  // End of story.
  static const String playAgain = 'Play again';
  static const String map = 'Map';
  static const String nextStoryFallback = 'Next story';
  static const String todayHeading = 'TODAY';
  static const String minutesListenedSemantic = 'Minutes listened today';

  static String storyCounter(int current, int total) =>
      'STORY $current OF $total';

  static String newWordsHeading(int count) =>
      count == 1 ? '1 NEW WORD' : '$count NEW WORDS';

  static String minutesOfGoal(int done, int goal) => '$done of $goal min';

  static String nextReview(int minutes) => 'Next: review · $minutes min';

  static String nextStory(String title) => 'Next: $title';

  // Performance chip (?perf=1).
  static String sceneBake(double? ms) =>
      'scene bake ${ms == null ? '-' : ms.toStringAsFixed(0)} ms';
}
