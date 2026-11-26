/// All screen wording for `feature_words`.
///
/// Screens in `feature_words/lib/` and tests in `feature_words/test/` both read
/// from this file so changing a phrase is a single-line edit.
library;

/// Single source of truth for all user-visible and semantic wording in
/// `feature_words`.
abstract final class WordsWording {
  // Header & add-goal pill / sheet.
  static const String screenTitle = 'Words';
  static const String addPillLabel = '+ Add a word or goal';
  static const String addSheetTitle = 'Add a word or goal';
  static const String addExample =
      'For example: "talk to my 1-year-old around the house".';
  static const String addHint = 'A word or a goal';
  static const String addAction = 'Add';
  static const String addSavedNote = 'Saved. Material for it comes later.';
  static String addedItem(String item) => '· $item';

  // Due-today card & return bar chart.
  static const String dueTodaySingular = 'word comes\nback today';
  static const String dueTodayPlural = 'words come\nback today';
  static String dueTodayLabel(int count) =>
      count == 1 ? dueTodaySingular : dueTodayPlural;

  static String chartHeading(int totalWords) => totalWords == 1
      ? 'When your 1 word comes back'
      : 'When your $totalWords words come back';

  static const String bucketToday = 'Today';
  static const String bucketTomorrow = 'Tomorrow';
  static const String bucketThreeDays = '3 days';
  static const String bucketThisWeek = 'This week';
  static const String bucketLater = 'Later';

  static String chartSemanticLabel({
    required int today,
    required int tomorrow,
    required int threeDays,
    required int thisWeek,
    required int later,
  }) =>
      'Words coming back: $today today, $tomorrow tomorrow, '
      '$threeDays in 3 days, $thisWeek this week, $later later';

  // Skill segmented switch & empty states.
  static const String skillSwitchSemanticLabel = 'Skill';
  static const String listening = 'Listening';
  static const String speaking = 'Speaking';
  static const String reading = 'Reading';
  static String listeningTab(int goodCount) => '$listening · $goodCount';
  static String speakingTab(int goodCount) => '$speaking · $goodCount';
  static String readingTab(int goodCount) => '$reading · $goodCount';
  static const String readingLockedTab = '$reading · A2';
  static const String readingLockedMessage =
      'Reading opens for tracking at A2.';

  static const String emptyListening =
      'Play the first story on the map. Your words show up here.';
  static const String emptySpeaking =
      'Words you say in stories and calls show up here.';
  static const String emptyReading = 'Words you read show up here.';

  // Review action button.
  static const String startReview = 'Start review';
  static const String practice = 'Practice';

  // Word row due line & semantics.
  static const String good = 'good';
  static const String backToday = 'back today';
  static const String backTomorrow = 'back tomorrow';
  static String backInDays(int days) => 'back in $days days';
  static String backInWeeks(int weeks) => 'back in $weeks weeks';
  static String goodDue(String when) => '$good · $when';

  static String wordRowSemanticLabel({
    required String word,
    required String dueLine,
    required int stage,
    required int stageMax,
  }) => dueLine.isEmpty
      ? '$word, Stage $stage of $stageMax'
      : '$word, $dueLine, Stage $stage of $stageMax';

  // Word sheet.
  static const String ear = 'Ear';
  static const String mouth = 'Mouth';
  static const String heardIn = 'Heard in';
  static const String comesBackToday = 'Comes back today';
  static String comesBackInDays(int days) =>
      'Comes back in $days day${days > 1 ? 's' : ''}';
  static String playLineSemantic(String lineText) => 'Play: $lineText';
}
