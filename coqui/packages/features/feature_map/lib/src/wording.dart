/// All English UI and semantic wording for `feature_map`.
///
/// Screens, models, and tests in `feature_map` read from this file so changing
/// copy is a single-file edit.
library;

/// Single source of truth for user-visible and semantic English copy in
/// `feature_map`.
abstract final class MapWording {
  // Common & module.
  static const String reviewTitle = 'Review';

  // Map model / today plan.
  static String wordsComingBack(int count) =>
      '$count word${count > 1 ? 's' : ''} coming back';
  static const String secondPlay = 'Second play';
  static const String newStoryPlayTwice = 'New story · play it twice';
  static const String listenAgain = 'Listen again';
  static const String allYourWords = 'All your words';
  static const String newStory = 'New story';
  static const String stepReview = 'review';
  static const String stepCall = 'a call';
  static const String stepNewStory = 'a new story';
  static const String stepListening = 'listening';

  static String minutesLabel(int minutes) => '$minutes min';
  static String lineWithMinutes(String line, int minutes) =>
      '$line · ${minutesLabel(minutes)}';
  static String thenOne(String first) => 'Then $first';
  static String thenTwo(String first, String second) =>
      'Then $first, then $second';

  // Map screen.
  static const String courseMapSemantic = 'Course map';
  static String changeLanguageSemantic(String languageName) =>
      '$languageName. Change language.';
  static String streakDays(int streak) =>
      streak == 1 ? '1 day' : '$streak days';
  static const String youAreHere = 'You are here';
  static const String newPlace = 'New place';
  static String newPlaceCounter(int current, int total) =>
      'New place · $current of $total';
  static String playFirstStory(int number) => 'Play first · Story $number';
  static const String afterPlacePrefix = 'After ';
  static String afterPlace(String placeName) => '$afterPlacePrefix$placeName';
  static const String upNext = 'UP NEXT';
  static const String upNextWithPlacePrefix = 'UP NEXT · ';
  static const String startReviewSemantic = 'Start review';
  static String playStorySemantic(String title) => 'Play the story $title';
  static String openPlaceSemantic(String placeName) => 'Open $placeName';
  static const String cardActionOpen = 'Open';
  static const String cardActionShowUpNext = 'Show what is next';

  // Place screen.
  static const String read = 'Read';
  static String callPartner(String partnerName) => 'Call $partnerName';
  static String placeCounter(int current, int total) =>
      'Place $current of $total';
  static String storiesHeard(int heard, int total) =>
      '$heard of $total stories heard';
  static String allStories(int count) => 'All $count stories';
  static const String planCourse = 'Course';
  static const String notBuiltYet = 'Not built yet.';
  static const String lockedUntilPreviousDone =
      'Locked until the places before it are done.';
  static String scenesList(List<String> scenes) =>
      'Scenes: ${scenes.join(' · ')}';
  static const String storyTileStatusInCourse = ', in Course';
  static const String storyTileStatusHeard = ', heard';
  static const String storyTileStatusUpNext = ', up next';
  static String storyTileSemantic({
    required int number,
    required String title,
    required String statusSuffix,
  }) => 'Story $number: $title$statusSuffix';
  static String storyTileLabel(int number, String title) => '$number · $title';
  static const String placeInCourseTitle = 'This place is in Course';
  static const String placeInCourseBody =
      'Every place and every story are in Course.';
  static const String seePlans = 'See plans';
  static String playNextStory(int number) => 'Play next · Story $number';
  static const String allStoriesHeard = 'All stories heard';
  static const String backToMapSemantic = 'Back to the map';
}
