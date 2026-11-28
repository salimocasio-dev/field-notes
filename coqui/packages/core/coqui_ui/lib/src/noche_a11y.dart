/// Lesson and reader accessibility labels (page 22, Part 1.7).
///
/// Keyed by role (`close`, `hearAgain`, `mic`, `captions`, `back`,
/// `textAndPage`, `chapters`, `sentenceAgain`, `listen`, `speed`, ...), in
/// English by default. Flip [NocheA11y.lessonLabelsInCourseLanguage] to `true`
/// and pass `course.language.a11yWords` to switch to the course's language
/// without rewriting any screen.
library;

/// Table of lesson and reader accessibility labels.
abstract final class NocheA11y {
  /// When `false` (default), [label] returns English labels.
  /// When `true`, [label] uses the course's `a11yWords` entry for the role
  /// when present and non-empty, falling back to English otherwise.
  static bool lessonLabelsInCourseLanguage = false;

  static const String close = 'close';
  static const String hearAgain = 'hearAgain';
  static const String mic = 'mic';
  static const String micReady = 'micReady';
  static const String micListening = 'micListening';
  static const String micThinking = 'micThinking';
  static const String micTheySpeak = 'micTheySpeak';
  static const String micRight = 'micRight';
  static const String micNotYet = 'micNotYet';
  static const String captions = 'captions';
  static const String back = 'back';
  static const String textAndPage = 'textAndPage';
  static const String closeTextAndPage = 'closeTextAndPage';
  static const String chapters = 'chapters';
  static const String sentenceAgain = 'sentenceAgain';
  static const String listen = 'listen';
  static const String pause = 'pause';
  static const String speed = 'speed';
  static const String partProgress = 'partProgress';
  static const String pageProgress = 'pageProgress';
  static const String minutesRemaining = 'minutesRemaining';
  static const String smallerText = 'smallerText';
  static const String largerText = 'largerText';
  static const String font = 'font';
  static const String lineSpacing = 'lineSpacing';
  static const String pageColour = 'pageColour';
  static const String lineSpacingTight = 'lineSpacingTight';
  static const String lineSpacingNormal = 'lineSpacingNormal';
  static const String lineSpacingLoose = 'lineSpacingLoose';
  static const String pageNight = 'pageNight';
  static const String pageSepia = 'pageSepia';
  static const String pageDay = 'pageDay';
  static const String closeSheet = 'closeSheet';
  static const String tabs = 'tabs';

  /// Default English labels for every role.
  static const Map<String, String> english = {
    close: 'Close story',
    hearAgain: 'Hear again',
    mic: 'Microphone',
    micReady: 'Microphone, ready',
    micListening: 'Microphone, listening',
    micThinking: 'Microphone, thinking',
    micTheySpeak: 'Microphone, they speak',
    micRight: 'Microphone, heard right',
    micNotYet: 'Microphone, not yet',
    captions: 'Text on screen',
    back: 'Back to library',
    textAndPage: 'Text and page',
    closeTextAndPage: 'Close text and page',
    chapters: 'Chapters',
    sentenceAgain: 'Repeat sentence',
    listen: 'Listen',
    pause: 'Pause',
    speed: 'Speed',
    partProgress: 'Part {current} of {total}',
    pageProgress: 'Page {current} of {total}',
    minutesRemaining: '{minutes} min remaining in chapter',
    smallerText: 'Smaller text',
    largerText: 'Larger text',
    font: 'Font',
    lineSpacing: 'Line spacing',
    pageColour: 'Page colour',
    lineSpacingTight: 'Tight',
    lineSpacingNormal: 'Normal',
    lineSpacingLoose: 'Loose',
    pageNight: 'Night',
    pageSepia: 'Sepia',
    pageDay: 'Day',
    closeSheet: 'Close',
    tabs: 'Tabs',
  };

  /// Returns the accessibility label for [role].
  ///
  /// Uses [courseWords]`[role]` when [lessonLabelsInCourseLanguage] is `true`
  /// and [courseWords] holds a non-empty string for [role]; otherwise uses
  /// [english]`[role]` (or [role] itself if unknown). Any `{key}` placeholders
  /// in the template are replaced with values from [args].
  static String label(
    String role, {
    Map<String, String>? courseWords,
    Map<String, String>? args,
  }) {
    String? value;
    if (lessonLabelsInCourseLanguage && courseWords != null) {
      final candidate = courseWords[role];
      if (candidate != null && candidate.isNotEmpty) {
        value = candidate;
      }
    }
    var out = value ?? english[role] ?? role;
    if (args != null) {
      for (final entry in args.entries) {
        out = out.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return out;
  }
}
