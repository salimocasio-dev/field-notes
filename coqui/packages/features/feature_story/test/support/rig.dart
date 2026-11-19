// What a test of the story runner needs: a course with the lines it names, a progress store that writes down what the story
// tells it, a clip player that plays in no time, the story's own timers, and a way to play on by answering the questions.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_story/src/play/virtual_parts.dart';
import 'package:feature_story/src/runner/pending.dart';
import 'package:feature_story/src/runner/speech_session.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/runner/timers.dart';

import '../../tool/stand_in_scene.dart';

/// A course that has the clips a test names. The fixed lines are the ones datos/fijos.json names.
class TestCourse implements CourseCatalog {
  TestCourse({Set<String>? missing, this.lengths = const {}})
    : missing = missing ?? {};

  /// Clips that have no recording.
  final Set<String> missing;

  /// A clip's length in ms (1000 when not given).
  final Map<String, int> lengths;

  @override
  Future<void> load() async {}

  @override
  List<Place> get places => const [];

  @override
  ClipInfo? clip(String id) => missing.contains(id)
      ? null
      : ClipInfo(
          id: id,
          who: 'narr',
          text: id == 'ahora_tu' ? 'Ahora tú.' : '',
          startMs: 0,
          endMs: lengths[id] ?? 1000,
          url: 'audio/$id.mp3',
        );

  @override
  String fixedClip(String role) => const {
    'story_your_turn': 'ahora_tu',
    'story_praise': 'muy_bien',
    'story_routine_no_prefix': 'hz_no_',
  }[role]!;

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName}');
}

class MemStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// A progress store for a test: it remembers the words he has said, and writes down what the story tells it.
class TestProgress implements ProgressStore {
  TestProgress({this.habla = 1, Set<String>? open}) : open = open ?? {};

  final Object habla;

  /// The words open for speaking.
  final Set<String> open;
  final Map<String, int> mouth = {};
  final List<StoryResult> finished = [];
  final List<String> listenedIds = [];
  final List<double> minutesAdded = [];
  final List<({String w, bool ok, int? ms})> answers = [];

  @override
  void storyFinished(StoryResult r) => finished.add(r);

  @override
  void listened(String id) => listenedIds.add(id);

  @override
  void addMinutes(double m) => minutesAdded.add(m);

  @override
  SkillRecord answer(
    String w,
    Skill skill, {
    required bool ok,
    int? ms,
    bool intro = false,
  }) {
    if (skill == Skill.mouth) {
      mouth[w] = (mouth[w] ?? 0) + 1;
      answers.add((w: w, ok: ok, ms: ms));
    }
    return SkillRecord();
  }

  @override
  WordRecord? word(String w) => mouth.containsKey(w)
      ? WordRecord(w: w, primera: 0, mouth: SkillRecord()..n = mouth[w]!)
      : null;

  @override
  bool openForSpeaking(String w) => open.contains(w) || (mouth[w] ?? 0) > 0;

  @override
  Object? setting(String key) => key == 'habla' ? habla : null;

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName}');
}

/// A recogniser that is not there.
class NoSpeech implements SpeechListener {
  @override
  Future<bool> available() async => false;

  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) => throw StateError('no recogniser');
}

class _Clock implements Clock {
  _Clock(this.t);

  final StoryTimers t;

  @override
  int nowMs() => t.now;
}

/// One play of a story on the test's own pieces.
class Rig {
  Rig._(
    this.runner,
    this.timers,
    this.player,
    this.progress,
    this.scene,
    this.memory,
    this.sounds,
    this.course,
    this.stub,
  );

  final StoryRunner runner;
  final StoryTimers timers;
  final VirtualClipPlayer player;
  final TestProgress progress;
  final StandInScene scene;
  final MemStore memory;
  final List<Object?> sounds;
  final TestCourse course;

  /// The recogniser stub's results (`?mic=stub:`), which a test may add to at any time.
  final List<String> stub;

  /// Every clip the story asked the player for, in order.
  List<String> get clips => player.played;

  /// Makes a rig for [story]. [stub] switches the stub recogniser on; [open] are the words open for speaking.
  static Future<Rig> make(
    Map<String, dynamic> story, {
    StandInScene? scene,
    TestCourse? course,
    TestProgress? progress,
    MemStore? memory,
    Rng? rng,
    bool listen = false,
    TxtMode txt = TxtMode.con,
    List<String>? stub,
    bool micOff = false,
    bool allOpen = false,
    Map<String, String> forced = const {},
    Map<String, String> mem = const {},
    SpeechSession? session,
    VirtualClipPlayer Function(StoryTimers, CourseCatalog)? playerFor,
  }) async {
    final timers = StoryTimers();
    final c = course ?? TestCourse();
    final p = progress ?? TestProgress();
    final m = memory ?? MemStore();
    final sc = scene ?? StandInScene();
    final player = playerFor != null
        ? playerFor(timers, c)
        : VirtualClipPlayer(timers, c);
    final sounds = <Object?>[];
    final st = stub;
    final runner = StoryRunner(
      storyId: story['id'] as String,
      story: story,
      E: sc,
      course: c,
      clips: player,
      speech: NoSpeech(),
      progress: p,
      rng: rng ?? Mulberry32(1),
      clock: _Clock(timers),
      memory: m,
      options: StoryOptions(
        listen: listen,
        txt: txt,
        micStub: st,
        micOff: micOff,
        allOpen: allOpen,
        forced: forced,
        mem: mem,
      ),
      timers: timers,
      sfx: RecordingSfx(player, sounds),
      session: session,
    );
    await runner.init();
    return Rig._(runner, timers, player, p, sc, m, sounds, c, st ?? <String>[]);
  }

  /// A real macrotask, so every queued microtask runs.
  Future<void> drain() {
    final c = Completer<void>();
    Timer.run(c.complete);
    return c.future;
  }

  /// What stopped the story, if something did (an error a step threw).
  Object? failure;

  /// Starts the story (the start disc).
  Future<void> start() async {
    unawaited(
      runner.start().then((_) {}, onError: (Object e) => failure ??= e),
    );
    await drain();
  }

  /// Fires the next timer, if any is due by [limit]. False when there is none.
  Future<bool> tick({int? limit}) async {
    await drain();
    final t = timers.next();
    if (t == null || (limit != null && t.at > limit)) return false;
    timers.fire(t);
    await drain();
    return true;
  }

  /// Lets [ms] of the story's time go by.
  Future<void> advance(int ms) async {
    final until = timers.now + ms;
    while (await tick(limit: until)) {}
    timers.now = until;
    await drain();
  }

  /// Goes on until [ok] is true. Throws when [limitMs] of story time pass first.
  Future<void> until(
    bool Function() ok, {
    int limitMs = 600000,
    String what = 'the condition',
  }) async {
    final end = timers.now + limitMs;
    await drain();
    while (!ok()) {
      if (!await tick(limit: end)) {
        throw StateError('$what never came (at ${timers.now} ms)');
      }
    }
  }

  /// Goes on until the touch is waited for and the question has been asked.
  Future<Pending> untilAsked() async {
    await until(
      () =>
          runner.pendingNow != null &&
          runner.pendingNow!.asked &&
          runner.pendingNow!.tEnd != null,
      what: 'the question',
    );
    return runner.pendingNow!;
  }

  /// A touch on a named thing.
  void touch(String what) => runner.tapThing(what, 100, 100);

  /// Plays the story through. At each question [choose] is given the thing waited for and says what to touch (null: leave
  /// it). He answers [think] ms after the question is ready.
  Future<void> finish(
    String? Function(Pending pn) choose, {
    int think = 700,
    int limitMs = 3600000,
  }) async {
    unawaited(
      runner.start().then((_) {}, onError: (Object e) => failure ??= e),
    );
    final end = timers.now + limitMs;
    var started = false;
    Pending? waiting;
    int? at;
    for (;;) {
      await drain();
      if (failure != null) throw failure!;
      if (runner.running) {
        started = true;
      } else if (started) {
        return;
      }
      final pn = runner.pendingNow;
      final ready =
          pn != null &&
          pn.asked &&
          pn.tEnd != null &&
          !pn.busy &&
          runner.speaking == 0 &&
          runner.HAB.est != 'listening' &&
          runner.HAB.est != 'processing';
      if (ready) {
        if (!identical(waiting, pn)) {
          waiting = pn;
          at = timers.now + think;
        }
      } else {
        waiting = null;
      }
      final t = timers.next();
      if (waiting != null && (t == null || t.at > at!)) {
        timers.now = at!;
        final what = choose(waiting);
        waiting = null;
        if (what != null) touch(what);
        continue;
      }
      if (t == null) {
        throw StateError(
          'stuck at ${timers.now} ms: nothing scheduled and nothing to touch',
        );
      }
      if (t.at > end) throw StateError('still running at the time limit');
      timers.fire(t);
    }
  }

  /// Plays the story through as `habla_motor_check.py` does: the mic is tapped when it is ready (`tapMic`), the question is
  /// answered by [choose] when it is asked and no turn is going on (an elige also while the mic is up when [touchElige]).
  Future<void> finishTurns(
    String? Function(Pending pn) choose, {
    bool tapMic = true,
    bool touchElige = false,
    int think = 700,
    int limitMs = 3600000,
  }) async {
    unawaited(
      runner.start().then((_) {}, onError: (Object e) => failure ??= e),
    );
    final end = timers.now + limitMs;
    var started = false;
    Object? key;
    int? at;
    void Function()? act;
    for (;;) {
      await drain();
      if (failure != null) throw failure!;
      if (runner.running) {
        started = true;
      } else if (started) {
        return;
      }
      Object? k;
      void Function()? a;
      final pn = runner.pendingNow;
      if (tapMic && runner.HAB.est == 'ready' && runner.HAB.cur != null) {
        k = runner.HAB.cur;
        a = runner.tapMic;
      } else if (pn != null &&
          pn.asked &&
          pn.tEnd != null &&
          !pn.busy &&
          runner.speaking == 0 &&
          (runner.HAB.est == '' ||
              (touchElige &&
                  pn.kind == 'elige' &&
                  runner.HAB.est != 'listening' &&
                  runner.HAB.est != 'processing'))) {
        k = pn;
        a = () {
          final what = choose(pn);
          if (what != null) touch(what);
        };
      }
      if (k == null) {
        key = null;
      } else if (!identical(key, k)) {
        key = k;
        at = timers.now + think;
        act = a;
      } else {
        act = a;
      }
      final t = timers.next();
      if (key != null && (t == null || t.at > at!)) {
        timers.now = at!;
        final f = act!;
        key = null;
        f();
        continue;
      }
      if (t == null) throw StateError('stuck at ${timers.now} ms');
      if (t.at > end) throw StateError('still running at the time limit');
      timers.fire(t);
    }
  }
}
