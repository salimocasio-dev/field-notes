/// What cual.html and nivel.html take from juego.js: the voice (say, wait, bien, hush, playClip), the captions under
/// the pictures (muestra, borra, letras, letrasFin, callaLetras), the sound effects, and the three screens of a
/// lesson (start, play, end).
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:flutter/foundation.dart';

/// The host's `wait`: a future that completes after [d]. The widgets give it a timer they can cancel; the tests
/// give it a virtual clock. The logic never makes a timer of its own (page 12, section 6).
typedef Wait = Future<void> Function(Duration d);

/// juego.js: `throw "stop"`. The lesson was left (the X, or the screen went away): nothing runs on.
class SessionStopped implements Exception {
  const SessionStopped();
  @override
  String toString() => 'SessionStopped';
}

/// juego.js: TXT, "when the words show": while the line is spoken, right after it, or never. The old page reads
/// it from `?txt=`; "con" (during) is what a learner gets.
enum CaptionMode { during, after, never }

/// juego.js: estado(): the three states of a lesson screen.
enum LessonScreen { start, play, end }

/// The page's own words, kept as the old pages have them (English only: the Spanish comes from the catalog).
abstract final class ReviewStrings {
  // cual.js: cualArranca
  static const startHint = 'Listen, then touch the picture that fits.';
  // cual.js: cualFin
  static const doneTitle = 'Done';
  static const movingUp = 'moving up';
  static const comingBackSoon = 'coming back soon';
  static const right = 'right';
  static const missed = 'missed';
  static const movingUpHeading = 'Moving up';
  static const movingUpSub = "You'll see these less often";
  static const comingBackHeading = 'Coming back soon';
  static const comingBackSub = "You'll see these again soon";
  static const rightHeading = 'Right';
  static const missedHeading = 'Missed';
  // nivel.js
  static const levelTitle = 'Level check';
  static const levelDoneTitle = 'Level check done';
  static const levelStart = 'You start at the beginning.';
  static const toTheMap = 'To the map';
}

abstract class LessonBase extends ChangeNotifier {
  LessonBase({
    required this.clips,
    required this.course,
    required this.clock,
    required this.wait,
    this.captions = CaptionMode.during,
  });

  final ClipPlayer clips;
  final CourseCatalog course;

  /// Date.now() / performance.now(): the one clock.
  final Clock clock;

  /// The host's wait. See [Wait].
  final Wait wait;
  final CaptionMode captions;

  bool _disposed = false;

  /// juego.js: runId. Every lesson act checks it when it wakes; changing it stops them all.
  int _runId = 0;
  int get runId => _runId;

  /// juego.js: speaking: how many clips are sounding.
  int _speaking = 0;
  int get speaking => _speaking;

  /// juego.js: VOICE, CLIPS: which clips came ready. Before the load has finished none is.
  bool _voiceLoaded = false;
  Set<String> _notReady = {};
  Future<void> voiceReady = Future<void>.value();

  // ---- the screen
  LessonScreen screen = LessonScreen.start;

  /// pantalla(): the title and the lines under it of a start or end screen; no title hides them.
  String screenTitle = '';
  List<String> screenLines = const [];

  /// mkDots / step: how many segments the bar has, and how many are lit.
  int barSegments = 0;
  int barLit = 0;

  // ---- the caption under the picture
  String _captionText = '';
  bool _captionOn = false;
  int _capGen = 0;

  /// The line shown under the pictures ("" when none).
  String get caption => _captionOn ? _captionText : '';

  bool get disposed => _disposed;

  void changed() {
    if (!_disposed) notifyListeners();
  }

  // juego.js: step(n)
  void step(int n) {
    barLit = n;
    changed();
  }

  // juego.js: mkDots(n)
  void makeDots(int n) {
    barSegments = n;
    changed();
  }

  // juego.js: pantalla(h, ps)
  void showScreen(String title, [List<String> lines = const []]) {
    screenTitle = title;
    screenLines = lines;
    changed();
  }

  // juego.js: estado(s)
  void setScreen(LessonScreen s) {
    screen = s;
    changed();
  }

  // ---- loading the voice (juego.js: loadVoice)

  /// Makes the clips ready. [voiceReady] completes when they are (or could not be).
  void loadVoice(Iterable<String> clipIds) {
    voiceReady = () async {
      final failed = await clips.preload(clipIds);
      _notReady = failed.toSet();
      _voiceLoaded = true;
    }();
  }

  bool _clipReady(String id) => _voiceLoaded && !_notReady.contains(id);

  // ---- time

  /// juego.js: sleep(ms): no check of runId.
  Future<void> sleep(int ms) => wait(Duration(milliseconds: ms));

  /// juego.js: wait(ms): throws [SessionStopped] when the lesson was left meanwhile.
  Future<void> waitMs(int ms) async {
    final my = _runId;
    await sleep(ms);
    if (my != _runId) throw const SessionStopped();
  }

  // ---- the voice

  // juego.js: words
  int _words(String id) {
    final t = course.clip(id)?.text;
    final s = (t == null || t.isEmpty) ? 'x x' : t;
    return s.split(RegExp(r'\s+')).length;
  }

  /// juego.js: playClip: the clip plays through the clip player; false when it is not ready, or was cut off.
  Future<bool> playClip(String id) async {
    if (!_clipReady(id)) return false;
    _speaking++;
    _letras(id);
    var v = false;
    try {
      v = await clips.play(id);
    } finally {
      _speaking = _speaking > 0 ? _speaking - 1 : 0;
    }
    _letrasFin(id, v);
    return v;
  }

  /// juego.js: hush: every sound stops.
  void hush() {
    unawaited(clips.stop());
  }

  /// juego.js: say(id, gap): the line, then a pause of [gap] ms (after a recording that played to its end). A
  /// line with no recording ready runs for the time its words take, 360 ms a word and 300.
  Future<void> say(String id, int gap) async {
    final my = _runId;
    if (_clipReady(id)) {
      final ok = await playClip(id);
      if (ok) await sleep(gap);
    } else {
      _letras(id);
      await sleep(360 * _words(id) + 300);
      _letrasFin(id, true);
      await sleep(gap);
    }
    if (my != _runId) throw const SessionStopped();
  }

  /// juego.js: bien(id): after 300 ms, the praise line, then 350 ms.
  Future<void> bien(String clipId) async {
    await waitMs(300);
    await say(clipId, 350);
  }

  // ---- sound effects (juego.js: SFX)

  // SFX.right
  void sfxRight() {
    clips.tone(784, at: 0, dur: .1, wave: 'triangle', vol: .14);
    clips.tone(1047, at: .09, dur: .1, wave: 'triangle', vol: .14);
    clips.tone(1319, at: .18, dur: .26, wave: 'triangle', vol: .14);
  }

  // SFX.bonk
  void sfxBonk() {
    clips.tone(600, at: 0, dur: .06, wave: 'square', vol: .05, toHz: 200);
    clips.tone(300, at: .06, dur: .2, wave: 'triangle', vol: .08, toHz: 120);
  }

  // SFX.blip
  void sfxBlip() {
    clips.tone(520, at: 0, dur: .06, wave: 'sine', vol: .07, toHz: 640);
  }

  // ---- the caption (juego.js: muestra, borra, letras, letrasFin, callaLetras)
  //
  // In a lesson page the speaker is never on screen (donde() gives null for the frog and for everyone: the page's
  // own world has nobody in it), so juego.js's muestra puts the whole line in the caption, whoever says it.

  // juego.js: muestra
  void _muestra(String id) {
    _capGen++; // clearTimeout(capT)
    _captionText = course.clip(id)?.text ?? '';
    _captionOn = _captionText.isNotEmpty;
    changed();
  }

  // juego.js: borra
  void _borra(int ms) {
    _capGen++;
    final gen = _capGen;
    unawaited(
      sleep(ms).then((_) {
        if (gen == _capGen) {
          _captionOn = false;
          changed();
        }
      }),
    );
  }

  // juego.js: letras
  void _letras(String id) {
    if (captions == CaptionMode.during) _muestra(id);
  }

  // juego.js: letrasFin
  void _letrasFin(String id, bool done) {
    if (captions == CaptionMode.never) return;
    if (captions == CaptionMode.after) {
      if (!done) return;
      _muestra(id);
      final len = (course.clip(id)?.text ?? '').length;
      _borra(len * 70 > 1800 ? len * 70 : 1800);
      return;
    }
    _borra(1700);
  }

  // juego.js: callaLetras
  void hideCaption() {
    _capGen++;
    _captionOn = false;
    changed();
  }

  /// The start of a run: runId++; hush(); callaLetras().
  void beginRun() {
    _runId++;
    hush();
    hideCaption();
  }

  /// juego.js: salir(): everything stops. The lesson is left by whoever calls this, then navigates.
  void leave() {
    _runId++;
    hush();
    hideCaption();
  }

  @override
  void dispose() {
    if (!_disposed) {
      _runId++;
      hush();
      _capGen++;
    }
    _disposed = true;
    super.dispose();
  }
}
