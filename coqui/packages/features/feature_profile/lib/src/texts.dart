/// The English lines of the Yo tab and the welcome, copied from historia/app.html (v=39). Nothing here is
/// Spanish; every place name on screen comes from the catalog.
library;

// ---- yo (app.html:471-480) ----

/// The tab's title is `CoquiLabels.me`.
const String yoStreakLabel = 'day streak';
const String yoWhereYouAre = 'Where you are';
const String yoMinutesADay = 'Minutes a day';
const String yoPlanSized = "Today's plan is sized to this.";
const String yoOpenEveryPlace = 'Open every place';
const String yoOpenEveryPlaceHelp =
    'To look ahead. Places not built yet stay empty.';
const String yoSpeakInStories = 'Speak in stories';
const String yoSpeakInStoriesHelp =
    "Some of the coquí's lines become your turn: you say them and the app listens.";
const String yoSpeechNote =
    "Speaking in stories isn't available on this phone right now.";
const String yoLevelCheck = 'Level check';
const String yoLevelCheckHelp =
    'For people who already understand some Spanish. About 3 minutes, touch only.';
const String yoLevelCheckNotDone = 'Covers the stories built so far.';
const String yoStart = 'Start';
const String yoHowItWorks = 'How it works';

// ---- bienvenida (app.html:484-490) ----

const String welcomeTitle = 'Welcome to Coquí';
const String welcomeP1 =
    'You learn Spanish the way children do: by hearing it, with pictures, in short stories.';
const String welcomeP2 =
    'You answer by touching the picture. What you touch changes what happens.';
const String welcomeP3 = 'Words come back just before you would forget them.';
const String welcomeP4 =
    'English is only in the menus, to help you find your way.';
const String welcomeLevelCheck = 'Level check';

/// app.html:483 (`NIVELTXT`).
const String levelCheckText =
    'The words of the stories you already understand are yours to keep: each gets one cold check tomorrow, and they are open for speaking now.';
const String welcomeNext = 'Next';
const String welcomeTimeTitle = 'How much time a day?';
const String welcomeTimeHelp =
    "Today's plan is sized to it. You can change it in Yo.";
const String welcomeStartTitle = 'Where do you start?';
const String welcomeStartHelp =
    'The level check takes about 3 minutes. You hear a sentence and touch one of four pictures.';
const String welcomeNew = "I'm new to Spanish";
const String welcomeSome = 'I understand some Spanish';

// ---- new in order 25 ----

/// The About sheet's one line (the order's words).
const String aboutCredit =
    'Map and scene engine: Pixel Plays by Amir Mushich (MIT)';

/// The row at the foot of Yo that opens the About sheet.
const String aboutRow = 'About';

/// The one-time hint on an iPhone in the browser (the order's words).
const String installHint = 'To install: Share, then Add to Home Screen';

// ---- N4.7 Noche Me (docs/proyecto/noche/Noche-Yo.dc.html) ----

const String meTitle = 'Me';
const String meHowCoquiWorks = 'How Coquí works';
const String meMinutesListened = 'minutes listened';
const String meAllLanguages = 'all languages';
const String meTodayLabel = 'Today';
const List<String> meWeekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const String meListening = 'Listening';
const String meSpeaking = 'Speaking';
const String meReading = 'Reading';
const String meReadingNote = 'Open now. Counts from A2.';
const String meReadingOpenNote = 'Open now.';
const String meYourPlan = 'Your plan';
const String meManage = 'Manage ›';
const String mePlanFree = 'Free';
const String mePlanCourse = 'Course';
const String mePlanCourseAndCalls = 'Course + Calls';

String meStreakLabel(int streak, String dayWord) => '$streak $dayWord';

String meStreakFreezesLabel(int freezes, String freezeWord) =>
    '$freezes $freezeWord saved';

String meWeekChartLabel({
  required List<int> priorSix,
  required int today,
  required int goal,
}) =>
    'Minutes listened in the last 7 days: ${priorSix.join(', ')}, and $today so far today. Your goal is $goal a day.';

String mePlaceProgressLabel({
  required String level,
  required int placeNumber,
  required int placeTotal,
}) => '$level · place $placeNumber of $placeTotal';

String mePlaceDashesActiveLabel({
  required int done,
  required int currentNumber,
  required int toGo,
}) => 'Places: $done done, on place $currentNumber, $toGo to go';

String mePlaceDashesSummaryLabel({required int done, required int toGo}) =>
    'Places: $done done, $toGo to go';

String meSkillGoodLabel(int good, int total) => '$good of $total good';

String meSkillGoodSemanticLabel(int good, int total) =>
    '$good of $total words good';

String mePlanSemanticLabel(String planName) =>
    '$meYourPlan, $planName. $meManage';

String meLevelCheckDoneSuffix(String skippedText, String storyWord) =>
    'Done: $skippedText $storyWord skipped.';

String meBuildLabel(String build) => 'build $build';
