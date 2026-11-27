/// English UI and semantic wording for the Speak tab.
library;

/// Static English UI labels and semantic strings for the Speak tab.
abstract final class SpeakWording {
  static const screenTitle = 'Speak';
  static const wordsYouCanUse = 'Words you can use';
  static const placeTabListLabel = 'Place';

  static String wordsReadyToSay(int count) =>
      count == 1 ? '1 word ready to say' : '$count words ready to say';

  static String wordsButtonSemantic(int count) =>
      '${wordsReadyToSay(count)}. $wordsTitle';

  static const wordsTitle = 'Words open for speaking';
  static const wordsNone =
      'None yet. A word opens once your ear has held it for a few days.';

  static String lockedPlaceLabel(String placeName) =>
      '$placeName, not reached yet';

  static const afterPrefix = 'After ';

  static String afterPlace(String placeName) => '$afterPrefix$placeName';

  static String nextCallEyebrow(String partnerName, int minutes) =>
      'Next call with $partnerName · $minutes min';

  static String doneCallEyebrow(String partnerName, int minutes) =>
      'Call with $partnerName · $minutes min · done';

  static const planTag = 'Course + Calls';
  static const planCardTitle = 'Live calls are in Course + Calls';

  static String planCardBody(String partnerName) =>
      '$partnerName talks with you using the words you know. '
      'On your plan you still say lines back inside every story.';

  static const seePlans = 'See plans';

  static String callPartner(String partnerName) => 'Call $partnerName';

  static String callingPartner(String partnerName) => 'Calling $partnerName';

  static String callDiscSemantic(String partnerName, String callTitle) =>
      '${callPartner(partnerName)}: $callTitle';

  static String otherCallSemantic(String callTitle, String metaLine) =>
      '$callTitle, $metaLine';

  static String lockedOtherCallSemantic(String callTitle, String metaLine) =>
      '$callTitle, locked: $metaLine';

  static String minutesOnly(int minutes) => '$minutes min';

  static String cardMetaDone(int minutes) => '$minutes min · done';

  static String cardMetaOpen(int minutes) => '$minutes min · open';

  static String cardMetaAfterStory(int minutes, int storyNumber) =>
      '$minutes min · after story $storyNumber';

  static String cardMetaComingSoon(int minutes) => '$minutes min · coming soon';

  static String cardMetaLater(int minutes) => '$minutes min · later';

  static String opensAfterStory(int storyNumber) =>
      'Opens after story $storyNumber';

  static String opensWhenYouFinish(String placeName) =>
      'Opens when you finish $placeName';

  static String comingSoonPlace(String placeName) => 'Coming soon · $placeName';

  static String callsLaterFor(String partnerName) =>
      'Calls with $partnerName open later.';

  static String durationLine(int minutes) => 'About $minutes min';

  static String backToSpeak(String speakTabName) => 'Back to $speakTabName';

  static String voiceTestInstruction(String languageName) =>
      'Tap the mic and say each $languageName line.';

  static String voiceTestResult(int right, int total) =>
      'Heard right: $right of $total';

  static const emptyHeard = '—';
}
