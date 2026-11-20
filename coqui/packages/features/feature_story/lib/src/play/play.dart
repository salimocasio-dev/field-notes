// A story played with no screen: what `coqui/tool/ref/trazas/page-drive.js` does to the old page (it clicks the start
// disc and answers every question by rule), on the story runner, with no real time.
/// Plays a story by rule and returns its trace, in the shape of `coqui/ref/trazas/<story>/<plan>.json`.
///
/// The learner (see `coqui/tool/ref/trazas/README.md`): a choice is ready when the story waits for a touch, has asked,
/// has finished asking, is not naming a poked thing, no clip is playing and the mic is not listening. When one becomes
/// ready at virtual time t, the learner acts at t + [think] ms (700), after every timer due at or before that time has
/// run, if it is still the same situation then. Every choice point takes the next letter of the plan; a retry takes
/// none. Touches are made by thing id, never by position.
library;

import 'dart:async';
import 'dart:collection';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Scene, Thing, jsTruthy;
import 'package:feature_story/src/play/virtual_parts.dart';
import 'package:feature_story/src/runner/observer.dart';
import 'package:feature_story/src/runner/pending.dart';
import 'package:feature_story/src/runner/renderer.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/runner/timers.dart';

/// The three plans (README: "The learner").
const List<String> playPlans = ['right', 'wrong', 'alternate'];

/// The time the learner waits after a choice is ready, ms.
const int playThink = 700;

class _KeyValueMemory implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

// ---------- the watcher ----------

class _Choice {
  _Choice(this.kind, this.st, this.path);

  final String kind;
  final Map<String, dynamic> st;
  final String? path;
  int esperas = 0;
}

class _EsperaInfo {
  _EsperaInfo(this.n, this.role, this.choice);

  final int n;
  final String role;
  final _Choice? choice;
  String? letter;
  Map<String, dynamic>? rec;
  String? poked;
}

/// What the recording tool writes down while the story runs: steps, clips, the learner's choices and touches.
class _Watcher extends StoryObserver {
  _Watcher(this.timers, this.story, this.sounds) {
    _walk(story, '');
  }

  final StoryTimers timers;
  final Map<String, dynamic> story;
  final List<Object?> sounds;
  final Map<Object, String> paths = HashMap<Object, String>.identity();
  final List<Map<String, dynamic>> steps = [],
      clips = [],
      choices = [],
      touches = [];
  final List<_Choice> ch = [];
  final Expando<_EsperaInfo> info = Expando<_EsperaInfo>();
  String? nextPath;
  int esperas = 0;

  void _walk(Object? x, String p) {
    if (x is! Map && x is! List) return;
    if (paths.containsKey(x!)) return;
    paths[x] = p;
    if (x is List) {
      for (var i = 0; i < x.length; i++) {
        _walk(x[i], '$p.$i');
      }
    } else if (x is Map) {
      for (final e in x.entries) {
        _walk(e.value, p.isNotEmpty ? '$p.${e.key}' : e.key as String);
      }
    }
  }

  @override
  void pasosItem(List<Object?> list, int i) {
    final base = paths[list];
    nextPath = base == null ? null : '$base.$i';
  }

  @override
  Future<void> step(
    Object? st,
    String kind,
    String? id,
    String? act,
    Future<void> Function() run,
  ) {
    final own = st is Map || st is List ? paths[st!] : null;
    final path = own ?? nextPath;
    nextPath = null;
    final r = <String, dynamic>{
      'n': steps.length,
      't': timers.now,
      'path': path,
      'kind': kind,
    };
    if (kind == 'line' || kind == 'say') r['id'] = id;
    if (kind == 'act') r['act'] = act;
    steps.add(r);
    if (kind != 'ask' && kind != 'decide' && kind != 'elige') return run();
    final c = _Choice(kind, st as Map<String, dynamic>, path);
    ch.add(
      c,
    ); // before the call: ask, decide and elige reach espera() synchronously
    void pop() => ch.remove(c);
    Future<void> p;
    try {
      p = run();
    } catch (_) {
      pop();
      rethrow;
    }
    p.then((_) => pop(), onError: (Object _) => pop());
    return p;
  }

  @override
  Future<Pending> espera(
    Future<Pending> Function() start,
    Pending? Function() current,
    String? line,
  ) {
    final top = ch.isEmpty ? null : ch.last;
    final p = start();
    final me = current();
    if (me != null && info[me] == null) {
      var role = 'scene';
      if (top != null) {
        role = top.kind == 'decide' && me.kind != 'decide'
            ? 'retry'
            : top.esperas++ == 0
            ? 'first'
            : 'again';
      }
      info[me] = _EsperaInfo(esperas++, role, top);
    }
    return p;
  }

  @override
  void clip(String id, String via, String? who, String? talker, bool noVoice) {
    final e = <String, dynamic>{'t': timers.now, 'id': id, 'via': via};
    if (who != null && who.isNotEmpty) e['who'] = who;
    if (talker != null && talker.isNotEmpty) e['talker'] = talker;
    if (noVoice) e['voice'] = false;
    clips.add(e);
  }

  @override
  void tone(List<Object?> args) {
    final a = List<Object?>.of(args);
    while (a.isNotEmpty && a.last == null) {
      a.removeLast();
    }
    sounds.add(a);
  }
}

// ---------- the learner ----------

class _Want {
  _Want(this.key, this.act);

  final Object key;
  void Function() act;
}

class _Driver {
  _Driver({
    required this.runner,
    required this.scene,
    required this.watcher,
    required this.timers,
    required this.stub,
    required this.plan,
    this.thingOrder,
  });

  final StoryRunner runner;
  final Scene scene;
  final _Watcher watcher;
  final StoryTimers timers;
  final List<String> stub;
  final String plan;
  final List<String> Function(Map<String, dynamic> W, int now)? thingOrder;
  final List<Map<String, dynamic>> speechEvents = [];
  int letters = 0;
  final Expando<String> turnLetter = Expando<String>();
  final Expando<Map<String, Object>> keys = Expando<Map<String, Object>>();

  String letterFor() {
    final k = letters++;
    return plan == 'right'
        ? 'r'
        : plan == 'wrong'
        ? 'w'
        : (k % 2 == 0 ? 'r' : 'w');
  }

  // the rule: what is wrong
  List<String> sceneList() {
    final W = runner.W;
    final order = thingOrder;
    if (order != null) return order(W, timers.now);
    return [
      for (final Thing t in scene.cosas)
        if ((t.si == null || t.si!(W)) && _boxOf(t, W) != null) t.id,
    ];
  }

  Object? _boxOf(Thing t, Map<String, dynamic> W) {
    final b = t.box;
    return b is Function ? b(W) : b;
  }

  // as tap() maps a touch
  bool counts(Pending pn, String w) =>
      pn.live.contains(runner.touchedAs(pn, w));

  // an ask: the first thing in the scene's list that is not the asked one and that the touch would not count as it
  String? wrongPoke(Pending pn) {
    final resp = runner.W['resp'];
    for (final k in sceneList()) {
      if (k != 'coqui' &&
          !counts(pn, k) &&
          !(resp is List && resp.contains(k))) {
        return k;
      }
    }
    return null;
  }

  // a decide: the first live thing that is not the right one, not also right ("vale") and not free ("gratis")
  String? wrongOption(Pending pn, Map<String, dynamic> st) {
    final vale = [
      for (final v in (st['vale'] as List? ?? const []))
        runner.fill(v as String),
    ];
    final gratis = (st['gratis'] as Map? ?? const {}).keys
        .cast<String>()
        .toList();
    final al = pn.alias;
    for (final k in pn.live) {
      if (k != pn.pick &&
          !vale.contains(k) &&
          !gratis.contains(k) &&
          !(al != null && (al[k] == pn.pick || vale.contains(al[k])))) {
        return k;
      }
    }
    return null;
  }

  _EsperaInfo infoOf(Pending pn) =>
      watcher.info[pn] ??= _EsperaInfo(watcher.esperas++, 'scene', null);

  _Want? learner() {
    if (runner.HAB.est == 'ready' && runner.HAB.cur != null) {
      // a speaking turn waits for the mic
      final reg = runner.HAB.log.last;
      final pn = runner.pending != null && !runner.pending!.done
          ? runner.pending
          : null;
      final key = runner.HAB.cur!;
      return _Want(key, () {
        final i = pn != null ? watcher.info[pn] : null;
        if (turnLetter[reg] == null) {
          turnLetter[reg] = i != null
              ? (i.letter ??= letterFor())
              : letterFor();
        }
        final letter = turnLetter[reg]!;
        var ans = 'none';
        if (letter == 'r' || reg['tipo'] == 'elige') {
          var id = reg['id'] as String;
          if (reg['tipo'] == 'elige') {
            final ids = id.split('|');
            id = ids[letter == 'r' ? 0 : (ids.length < 2 ? ids.length - 1 : 1)];
          }
          final targets = runner.habMarca(id);
          ans = targets != null
              ? targets.map((x) => x.formas[0]).join(' ')
              : 'none';
        }
        speechEvents.add({
          't': timers.now,
          'turn': reg['id'],
          'tipo': reg['tipo'],
          'letter': letter,
          'says': ans,
        });
        while (stub.length <= runner.HAB.si) {
          stub.add('none');
        }
        stub[runner.HAB.si] = ans;
        runner.tapMic();
      });
    }
    final pn = runner.pending;
    if (pn == null ||
        pn.done ||
        !pn.asked ||
        pn.tEnd == null ||
        pn.busy ||
        runner.speaking != 0 ||
        runner.HAB.est == 'listening' ||
        runner.HAB.est == 'processing') {
      return null;
    }
    final I = infoOf(pn);
    if (I.role == 'first' && I.letter == null) {
      I.letter = letterFor();
      final c = I.choice!;
      watcher.choices.add(
        I.rec = {
          'espera': I.n,
          't': timers.now,
          'kind': c.kind,
          'step': c.path,
          'letter': I.letter,
          'live': List<String>.of(pn.live),
          'pick': pn.pick,
          'touched': <String>[],
        },
      );
    }
    String k, why;
    if (I.role != 'first') {
      k =
          I.role == 'retry' &&
              pn.pick != null &&
              pn.pick!.isNotEmpty &&
              pn.live.contains(pn.pick)
          ? pn.pick!
          : pn.live[0];
      why = I.role;
    } else if (I.choice!.kind == 'ask') {
      if (I.letter == 'w' && I.poked == null) {
        // I.poked is set when the touch is made, so the plan stays the same until then
        final c = wrongPoke(pn);
        if (c != null) {
          k = c;
          why = 'wrong-poke';
        } else {
          I.rec!['noWrong'] = true;
          k = pn.live[0];
          why = 'right';
        }
      } else {
        k = pn.live[0];
        why = 'right';
      }
    } else if (I.choice!.kind == 'decide') {
      if (I.letter == 'w') {
        final c = wrongOption(pn, I.choice!.st);
        if (c != null) {
          k = c;
          why = 'wrong';
        } else {
          I.rec!['noWrong'] = true;
          k = pn.pick ?? '';
          why = 'right';
        }
      } else {
        k = pn.pick != null && pn.pick!.isNotEmpty ? pn.pick! : pn.live[0];
        why = 'right';
      }
    } else {
      k = I.letter == 'w' && pn.live.length > 1 ? pn.live[1] : pn.live[0];
      why = I.letter == 'w' ? 'second' : 'first';
    }
    final kk = keys[pn] ??= <String, Object>{};
    return _Want(kk['$k|$why'] ??= Object(), () {
      (I.rec?['touched'] as List?)?.add(k);
      if (why == 'wrong-poke') I.poked = k;
      touch(k, why, pn);
    });
  }

  // a touch on a named thing, at the point `Story.tapOn(k)` would use: the hand's point and 3 down, or the middle of
  // the box. The point only places the stars.
  void touch(String k, String why, Pending pn) {
    final rb = runner.respBox(k);
    final h = rb == null ? scene.handAt(k) : null;
    num x, y;
    if (h != null) {
      x = h[0];
      y = h[1] + 3;
    } else {
      final b = runner.bx(k);
      x = b[0] + b[2] / 2;
      y = b[1] + b[3] / 2;
    }
    final i = watcher.info[pn];
    watcher.touches.add({
      't': timers.now,
      'what': k,
      'why': why,
      'espera': i?.n,
      'x': x,
      'y': y,
    });
    runner.tapThing(k, x, y);
  }
}

// ---------- playing ----------

/// A real macrotask, so every microtask queued so far runs before the next timer (page-init.js: a `MessageChannel`
/// round trip). It is not a story delay: it is the one place the player yields to the event loop.
Future<void> _drain() {
  final c = Completer<void>();
  Timer.run(c.complete);
  return c.future;
}

/// Plays [story] by [plan] (`right`, `wrong` or `alternate`) with every random draw from `Mulberry32(seed)`, and returns
/// its trace: the same fields as `coqui/ref/trazas/<story>/<plan>.json`.
///
/// - [draws]: draws and decides fixed from outside (the old page's `?a=puerta`: name to value). Usually empty.
/// - [sceneFor]: makes the scene, given the one random source (counted: `draws.total`). A scene that draws a random
///   number must draw it from this.
/// - [view]: the screen's state, if the caller wants to read it when the story is over (the buttons of the end screen:
///   `view.foot`). The trace does not hold it, as the old page's recorded runs do not.
/// - [course]: the catalog. A clip exists when `course.clip(id)` has it.
/// - [progress]: what the story's end is written into. Words are open for speaking, as in the recorded runs
///   (`?abiertas=todas`); no recogniser is there (`?mic=stub:none`).
/// - [storySha256], [list], [place], [page]: the trace's own fields, as the recording tool writes them. [list] and
///   [place] are found in the catalog's places when not given.
/// - [thingOrder]: the scene's things in the order the wrong-touch rule reads them (given the world and the story's time),
///   when the scene's `cosas` is not it (El frente has no list: its order is that of its `hit()`).
/// - [micStub]: the stub's results, if a story with speaking turns is played (the learner writes into it).
/// - [startFrog], [frogShadow]: where the frog starts and whether he keeps the old shadow, for a converted scene (what its
///   sheet says); the old numbers and the old shadow when not given.
Future<Map<String, dynamic>> play({
  required Map<String, dynamic> story,
  required String plan,
  Map<String, String> draws = const {},
  required int seed,
  required Scene Function(Rng rng) sceneFor,
  required CourseCatalog course,
  required ProgressStore progress,
  KeyValueStore? memory,
  String? storySha256,
  String? list,
  String? place,
  String? page,
  int think = playThink,
  int limitMs = 4 * 3600 * 1000,
  List<String> Function(Map<String, dynamic> W, int now)? thingOrder,
  bool allOpen = true,
  List<String>? micStub,
  StoryView? view,
  ({int x, int y, num scale}) Function(Scene scene)? startFrog,
  bool Function(Scene scene)? frogShadow,
}) async {
  if (!playPlans.contains(plan)) {
    throw ArgumentError.value(plan, 'plan', 'right, wrong or alternate');
  }
  final id = story['id'] as String;
  final timers = StoryTimers();
  final rng = CountingRng(Mulberry32(seed));
  final scene = sceneFor(rng);
  final sounds = <Object?>[];
  final watcher = _Watcher(timers, story, sounds);
  final clock = _VirtualClock(timers);
  final player = VirtualClipPlayer(timers, course);
  final rec = RecordingProgress(progress, timers);
  final stub = micStub ?? <String>['none'];
  final mem = memory ?? _KeyValueMemory();
  final runner = StoryRunner(
    storyId: id,
    story: story,
    E: scene,
    course: course,
    clips: player,
    speech: _NoSpeech(),
    progress: rec,
    rng: rng,
    clock: clock,
    memory: mem,
    options: StoryOptions(
      micStub: stub,
      allOpen: allOpen,
      recordsProgress: true,
      forced: draws,
    ),
    timers: timers,
    renderer: HeadlessRenderer(),
    view: view,
    observer: watcher,
    sfx: RecordingSfx(player, sounds),
    startFrog: startFrog == null ? null : () => startFrog(scene),
    frogShadow: frogShadow?.call(scene) ?? true,
  );
  final errors = <String>[];
  final done = Completer<Map<String, dynamic>?>();
  runZonedGuarded(
    () async {
      await runner.init();
      final drawsAtGo = rng.draws;
      final driver = _Driver(
        runner: runner,
        scene: scene,
        watcher: watcher,
        timers: timers,
        stub: stub,
        plan: plan,
        thingOrder: thingOrder,
      );
      unawaited(
        runner.start().then(
          (_) {},
          onError: (Object e, StackTrace s) =>
              errors.add('unhandledrejection: $e\n$s'),
        ),
      );
      var started = false;
      String? end;
      _Want? want0;
      int? planAt;
      var iters = 0;
      for (;;) {
        await _drain();
        if (errors.isNotEmpty) {
          end = 'page error';
          break;
        }
        if (runner.running) {
          started = true;
        } else if (started) {
          end = 'finished';
          break;
        }
        final want = driver.learner();
        if (want != null) {
          if (want0 == null || !identical(want0.key, want.key)) {
            want0 = want;
            planAt = timers.now + think;
          } else {
            want0.act = want.act;
          }
        } else {
          want0 = null;
        }
        final t = timers.next();
        if (want0 != null && (t == null || t.at > planAt!)) {
          timers.now = planAt!;
          final a = want0.act;
          want0 = null;
          a();
          continue;
        }
        if (t == null) {
          end = 'stuck: nothing scheduled and nothing to touch';
          break;
        }
        if (t.at > limitMs) {
          end = 'stuck: still running at the time limit';
          break;
        }
        try {
          timers.fire(t);
        } catch (e, s) {
          errors.add('timer: $e\n$s');
        }
        if (++iters > 5000000) {
          end = 'stuck: too many timers';
          break;
        }
      }
      await _drain();
      done.complete(
        _finish(
          end: end,
          runner: runner,
          scene: scene,
          story: story,
          watcher: watcher,
          driver: driver,
          rec: rec,
          timers: timers,
          sounds: sounds,
          rng: rng,
          drawsAtGo: drawsAtGo,
          mem: runner.MEM,
          errors: errors,
        ),
      );
    },
    (Object e, StackTrace s) {
      errors.add('error: $e\n$s');
      if (!done.isCompleted) done.complete(null);
    },
  );
  final r = await done.future;
  if (r == null) return _failed(story, plan, seed, errors, timers);
  final placeInfo = _where(course, id);
  return <String, dynamic>{
    'story': id,
    'plan': plan,
    'seed': seed,
    'list': list ?? placeInfo.$1,
    'place': place ?? placeInfo.$2,
    'scene': story['scene'],
    'tipo': jsTruthy(story['tipo']) ? story['tipo'] : null,
    'storySha256': storySha256,
    'page':
        page ??
        'historia/index.html?cuento=$id&fast=1&rec=1&mic=stub:none&abiertas=todas',
    'think': think,
    ...r,
  };
}

(String?, String?) _where(CourseCatalog course, String id) {
  for (final p in course.places) {
    if (p.stories.contains(id)) return ('cuentos', p.id);
    if (p.pictureStories.contains(id)) return ('dibujos', p.id);
    if (p.routines.contains(id)) return ('haz', p.id);
  }
  return (null, null);
}

Map<String, dynamic> _failed(
  Map<String, dynamic> story,
  String plan,
  int seed,
  List<String> errors,
  StoryTimers timers,
) => {
  'story': story['id'],
  'plan': plan,
  'seed': seed,
  'end': 'page error',
  'finished': false,
  'virtualMs': timers.now,
  'errors': errors,
};

Map<String, dynamic> _finish({
  required String end,
  required StoryRunner runner,
  required Scene scene,
  required Map<String, dynamic> story,
  required _Watcher watcher,
  required _Driver driver,
  required RecordingProgress rec,
  required StoryTimers timers,
  required List<Object?> sounds,
  required CountingRng rng,
  required int drawsAtGo,
  required Map<String, dynamic> mem,
  required List<String> errors,
}) {
  final W = runner.W;
  final stake = story['stake'];
  final steps = watcher.steps;
  final estado = scene.estado(W);
  return {
    'end': end,
    'finished': end == 'finished',
    'virtualMs': timers.now,
    'voice': runner.VOICE,
    'draws': {'atLoad': drawsAtGo, 'total': rng.draws},
    'marks': W.containsKey('marcas') ? W['marcas'] : null,
    'lost': W['lost'],
    'ending': {
      'lost': W['lost'],
      'stakeSteps': stake is Map && stake['steps'] != null
          ? stake['steps']
          : null,
      'heart': jsTruthy(W['heart']) ? W['heart'] : 0,
      'final': [
        for (final s in steps)
          if (s['path'] != null &&
              RegExp(r'^final\b').hasMatch(s['path'] as String))
            s['path'],
      ],
      'screen': runner.view.screen.name,
    },
    'estado': estado.isEmpty ? null : estado,
    'result': rec.result,
    'listened': rec.listenedId,
    'minutes': rec.minutesGiven,
    'speech': {
      'turns': [for (final r in runner.HAB.log) Map<String, dynamic>.of(r)],
      'events': [...driver.speechEvents, ...rec.answers],
    },
    'memory': Map<String, dynamic>.of(mem),
    'errors': errors,
    'clips': watcher.clips,
    'sounds': sounds,
    'steps': steps,
    'touches': watcher.touches,
    'choices': watcher.choices,
    'decisions': [for (final d in runner.LOG) d.toJson()],
  };
}

/// The story's clock for the live host's `pump()`: it says the story's time (it is not used by a player, which moves
/// the timers itself).
class _VirtualClock implements Clock {
  _VirtualClock(this.timers);

  final StoryTimers timers;

  @override
  int nowMs() => timers.now;
}

/// A recogniser that is not there (`?mic=stub:` answers instead).
class _NoSpeech implements SpeechListener {
  @override
  Future<bool> available() async => false;

  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) => throw StateError('no recogniser: the stub answers');
}
