/// The stand-ins a story needs to be played with no screen and no real time, as the old recording tool played the old
/// page (`coqui/tool/ref/trazas/page-init.js`): a clip that plays in no time, the sounds written down, a counted random
/// source, and a progress store that writes down what the page told it.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Sfx;
import 'package:feature_story/src/runner/timers.dart';

/// A clip player whose `play` ends by a timer of 0 ms on the story's timers (page-init.js: a source's `start()` sets a
/// 0 ms timer that reports its end, unless `stop()` came first). A clip is ready when the catalog has it. A `limit` is a
/// second timer: the clip is cut then. Tones, noise and loops do nothing.
class VirtualClipPlayer implements ClipPlayer {
  VirtualClipPlayer(this.timers, this.course);

  final StoryTimers timers;
  final CourseCatalog course;
  final List<Completer<bool>> _playing = [];

  /// Every clip [play] was asked for, in order, and the time limit each was given.
  final List<String> played = [];
  final List<Duration?> limits = [];

  @override
  bool muted = false;

  @override
  Future<void> unlock() async {}

  @override
  Future<List<String>> preload(Iterable<String> clipIds) async => [
    for (final id in {...clipIds})
      if (course.clip(id) == null) id,
  ];

  @override
  Future<bool> play(String clipId, {Duration? limit}) {
    played.add(clipId);
    limits.add(limit);
    final c = Completer<bool>();
    _playing.add(c);
    int? lim;
    final end = timers.setTimeout(() {
      if (c.isCompleted) return;
      timers.clear(lim);
      _playing.remove(c);
      c.complete(true);
    }, 0);
    if (limit != null) {
      lim = timers.setTimeout(() {
        if (c.isCompleted) return;
        timers.clear(end);
        _playing.remove(c);
        c.complete(false);
      }, limit.inMilliseconds);
    }
    return c.future;
  }

  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) {}

  @override
  void noiseBurst({double vol = 1}) {}

  @override
  void loop(String name, bool on) {}

  @override
  Future<void> stop() async {
    for (final c in List.of(_playing)) {
      if (!c.isCompleted) c.complete(false);
    }
    _playing.clear();
  }
}

/// The sound effects, each written down (page-drive.js wraps every `SFX` method). `trueno(v)` is written with its
/// argument when it was given one.
class RecordingSfx extends Sfx {
  RecordingSfx(super.player, this.sounds);

  /// A name, or a list: name and arguments. A scene's own `tone` is written by the runner's observer.
  final List<Object?> sounds;

  void _r(String name) => sounds.add(name);

  @override
  void right() {
    _r('right');
    super.right();
  }

  @override
  void toc() {
    _r('toc');
    super.toc();
  }

  @override
  void blip() {
    _r('blip');
    super.blip();
  }

  @override
  void creak() {
    _r('creak');
    super.creak();
  }

  @override
  void hop() {
    _r('hop');
    super.hop();
  }

  @override
  void coqui() {
    _r('coqui');
    super.coqui();
  }

  @override
  void win() {
    _r('win');
    super.win();
  }

  @override
  void luz() {
    _r('luz');
    super.luz();
  }

  @override
  void drop() {
    _r('drop');
    super.drop();
  }

  @override
  void trueno([num? v]) {
    sounds.add(v == null ? 'trueno' : ['trueno', v]);
    super.trueno(v);
  }

  @override
  void lluvia() {
    _r('lluvia');
    super.lluvia();
  }

  @override
  void calla() {
    _r('calla');
    super.calla();
  }

  @override
  void suave() {
    _r('suave');
    super.suave();
  }

  @override
  void pio() {
    _r('pio');
    super.pio();
  }

  @override
  void slam() {
    _r('slam');
    super.slam();
  }

  @override
  void bonk() {
    _r('bonk');
    super.bonk();
  }

  @override
  void munch() {
    _r('munch');
    super.munch();
  }

  @override
  void swoop() {
    _r('swoop');
    super.swoop();
  }
}

/// The one random source, counted (page-init.js: `Math.random` is Mulberry32 and every draw is counted).
class CountingRng implements Rng {
  CountingRng(this._inner);

  final Rng _inner;

  /// How many values were drawn.
  int draws = 0;

  @override
  double next() {
    draws++;
    return _inner.next();
  }
}

/// The progress store the story talks to, with what the page told it written down (page-drive.js wraps `PAL.cuento`,
/// `PAL.oido`, `PAL.minutos` and `PAL.responde`). Everything else goes straight to [inner].
class RecordingProgress implements ProgressStore {
  RecordingProgress(this.inner, this.timers);

  final ProgressStore inner;
  final StoryTimers timers;

  /// What `storyFinished` was given, as `{id, focusWords, backAgain, lost, log}`; null if it was not called.
  Map<String, dynamic>? result;

  /// The id `listened` was given; null if it was not called.
  String? listenedId;

  /// What `addMinutes` was given; null if it was not called.
  double? minutesGiven;

  /// Every `answer`: `{t, w, sk, ok, ms, intro}`.
  final List<Map<String, dynamic>> answers = [];

  @override
  void storyFinished(StoryResult r) {
    result = {
      'id': r.id,
      'focusWords': List<String>.of(r.focusWords),
      'backAgain': List<String>.of(r.backAgain),
      'lost': r.lost,
      'log': [for (final d in r.log) d.toJson()],
    };
    inner.storyFinished(r);
  }

  @override
  void listened(String id) {
    listenedId = id;
    inner.listened(id);
  }

  @override
  void addMinutes(double m) {
    minutesGiven = m;
    inner.addMinutes(m);
  }

  @override
  SkillRecord answer(
    String w,
    Skill skill, {
    required bool ok,
    int? ms,
    bool intro = false,
  }) {
    answers.add({
      't': timers.now,
      'w': w,
      'sk': skill.name,
      'ok': ok,
      'ms': ms,
      'intro': intro,
    });
    return inner.answer(w, skill, ok: ok, ms: ms, intro: intro);
  }

  @override
  Stream<void> get changes => inner.changes;
  @override
  Map<String, dynamic> get raw => inner.raw;
  @override
  Iterable<WordRecord> get words => inner.words;
  @override
  WordRecord? word(String w) => inner.word(w);
  @override
  StoryRecord? story(String id) => inner.story(id);
  @override
  bool played(String id) => inner.played(id);
  @override
  List<String> due(Skill skill, {int? at}) => inner.due(skill, at: at);
  @override
  WordRecord heard(String w) => inner.heard(w);
  @override
  void presume(List<String> words, List<String> stories, List<Object?> log) =>
      inner.presume(words, stories, log);
  @override
  bool hasRead(String id) => inner.hasRead(id);
  @override
  void markRead(String id) => inner.markRead(id);
  @override
  double get minutes => inner.minutes;
  @override
  int get streak => inner.streak;
  @override
  bool openForSpeaking(String w) => inner.openForSpeaking(w);
  @override
  Object? setting(String key) => inner.setting(key);
  @override
  void setSetting(String key, Object value) => inner.setSetting(key, value);
  @override
  List<String> get added => inner.added;
  @override
  void add(String wordOrGoal) => inner.add(wordOrGoal);
  @override
  Map<String, dynamic>? get levelResult => inner.levelResult;
  @override
  String export() => inner.export();
  @override
  void import(String json) => inner.import(json);
  @override
  void reset() => inner.reset();
}
