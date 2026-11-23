/// The matching helpers of the call (llamada.js: norm, dice, adios) and the lines it shows.
library;

import 'package:coqui_contracts/coqui_contracts.dart';

// llamada.js: dice
/// Does the normalised [text] hold [word] (or phrase) on word boundaries? [text] is already `normalize`d
/// (one space each side); the word is normalised here and an empty one never matches.
bool dice(String text, String word) {
  final w = normalize(word);
  return w.trim() != '' && text.contains(w);
}

// llamada.js: adios
/// A goodbye, from either side: [text] holds one of [goodbyeWords] (`course.goodbyeWords`).
bool isGoodbye(String text, Iterable<String> goodbyeWords) {
  final n = normalize(text);
  return goodbyeWords.any((g) => dice(n, g));
}

// llamada.js: mmss
/// Call seconds as `mm:ss`.
String mmss(double seconds) {
  final s = seconds.floor();
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

/// What the call shows and sends. Menus and prompts are in English; the two
/// messages to Danny are the page's protocol with the agent, not learner text.
abstract final class CallTexts {
  static const startCall = 'Start call';
  static const callAgain = 'Call again';
  static const calling = 'Calling...';
  static const danny = 'Danny';
  static const yourTurn = 'Your turn';
  static const oneMoment = 'One moment';
  static const help = 'Help';
  static const helpNote = 'Danny will say it again, slowly.';
  static const done = 'Call done';
  static const comingBackNext = 'Coming back next call';
  static const micOff =
      'The microphone is off. Allow it in your browser to call.';
  static const notStarted =
      'The call did not start. Check your connection and try again.';
  static const libraryFailed =
      'The voice part did not load. Check your connection and try again.';

  /// Shown when this build cannot place a call (`call.available` is false).
  static const callsLater = 'Calls with Danny open later.';

  /// Kept only for `CallScreen`'s existing dialog semantics label; never used on Hablar cards.
  static const callDanny = 'Call Danny';

  /// Protocol message sent to Danny when the learner taps Help.
  static const sendHelp = '(ayuda)';

  /// Protocol message sent to Danny to end the call.
  static const sendEnd = '(fin)';

  /// `About N min` for pre-call and card duration hints.
  static String durationLine(int minutes) => 'About $minutes min';

  /// `${place} · about ${minutes} min`, kept for pre-call metadata.
  static String aboutLine(String place, int minutes) =>
      '$place · about $minutes min';

  /// `N min · M words said`.
  static String summary(int minutes, int words) =>
      '$minutes min · $words word${words == 1 ? '' : 's'} said';

  /// Strips `<`, `>`, and `&` before rendering a word chip.
  static String chip(String word) => word.replaceAll(RegExp('[<&>]'), '');
}
