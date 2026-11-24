// El reloj's three stories (63 to 65) played with no screen on the REAL scene (order 59b), a part of every path
// through them (tool/reloj_paths_test.dart plays them all): for each story the four ways through its two decisions
// (rr, rw, wr, ww), each with the first value of every draw, and each other value of every draw once (with rr). Every
// play ends (`finished`), with no error, the decisions played as asked, the stake lost as the wrong ones say, and the
// sheet's rules hold at every act's end and at the end (test/support/reloj_rules.dart).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show BakedSet, Ctx, Scene, Sprite;
import 'package:coqui_scenes/coqui_scenes.dart' show SetBakes, SetScene;
import 'package:feature_story/src/play/virtual_parts.dart';
import 'package:feature_story/src/runner/renderer.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/runner/timers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/disk_course.dart';
import '../tool/tool_progress.dart';
import 'real_scene.dart';
import 'support/reloj_paths.dart';

class _VirtualClock implements Clock {
  _VirtualClock(this.timers);
  final StoryTimers timers;
  @override
  int nowMs() => timers.now;
}

class _MemoryStore implements KeyValueStore {
  final Map<String, String> _values = {};
  @override
  String? read(String key) => _values[key];
  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

class _NoSpeech implements SpeechListener {
  @override
  Future<bool> available() async => false;
  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) => throw StateError('no recogniser');
}

class _HandFrameCheckerRenderer extends HeadlessRenderer {
  _HandFrameCheckerRenderer({required this.scene, required this.baked})
    : _dyn = scene {
    final dynamic p = _dyn.places;
    _s = (p.e.S as num).toDouble();
    _bias = (p.bias as num).toDouble();
  }

  final SetScene scene;
  final dynamic _dyn;
  final BakedSet baked;
  late final double _s;
  late final double _bias;
  final double _t30 = math.tan(math.pi / 6);

  static const Set<String> _handSpots = {
    'mano_arriba',
    'mano_abajo',
    'mano_lado',
    'manecilla',
  };

  int checkedFrames = 0;
  int bounceOnHandFrames = 0;
  int totalOut = 0;
  int totalHid = 0;
  int totalCov = 0;
  int totalObscuredByTito = 0;
  final List<String> violations = [];

  @override
  void frame({
    required Scene scene,
    required Map<String, dynamic> W,
    required int F,
    required List<num> cam,
    required void Function(Ctx c, int a) signs,
    List<num>? handPoint,
  }) {
    super.frame(
      scene: scene,
      W: W,
      F: F,
      cam: cam,
      signs: signs,
      handPoint: handPoint,
    );
    final q = W['cq'] as Map<String, dynamic>?;
    final spot = q?['spot'] as String?;
    if (q == null || spot == null || !_handSpots.contains(spot)) return;

    final a = F >> 1;
    final dy = (q['dy'] as num? ?? 0).toDouble();
    if (dy <= -4.0) bounceOnHandFrames++;
    checkedFrames++;

    final placed = _dyn.placed(W, a) as List;
    final coquiIdx = placed.indexWhere((dynamic it) => it.tag == 'coqui');
    if (coquiIdx < 0) {
      violations.add('F=$F spot=$spot: coqui missing from placed');
      return;
    }
    final dynamic coqui = placed[coquiIdx];
    final coquiSpr = coqui.s as Sprite;
    final coquiLeft = coqui.left as int;
    final coquiTop = coqui.top as int;
    final coquiSy = (coqui.sy as num).toDouble();
    final coquiD = (coqui.d as num).toDouble();

    final withTito = Uint32List.fromList(baked.pix);
    scene.draw(Ctx(withTito, 240, 216), W, a);

    final gente = W['gente'] as Map<String, dynamic>?;
    final tito = gente?['tito'] as Map<String, dynamic>?;
    final titoVis = tito?['vis'];
    final withoutTito = Uint32List.fromList(baked.pix);
    if (tito != null) tito['vis'] = 0;
    try {
      scene.draw(Ctx(withoutTito, 240, 216), W, a);
    } finally {
      if (tito != null) tito['vis'] = titoVis;
    }

    var total = 0;
    var out = 0;
    var hid = 0;
    var cov = 0;
    var obscuredByTito = 0;

    for (var y = 0; y < coquiSpr.h; y++) {
      final Y = coquiTop + y;
      final coquiPlane = coquiD + (coquiSy - (Y + 0.5)) * _t30 / _s;
      for (var x = 0; x < coquiSpr.w; x++) {
        if (coquiSpr.px[y * coquiSpr.w + x] >>> 24 == 0) continue;
        total++;
        final X = coquiLeft + x;
        if (X < 0 || X >= 240 || Y < 0 || Y >= 216) {
          out++;
          continue;
        }
        final idx = Y * 240 + X;
        if (baked.zb[idx] > coquiPlane + _bias) {
          hid++;
          continue;
        }
        var best = coquiPlane + 0.001;
        var covered = false;
        for (var j = 0; j < placed.length; j++) {
          if (j == coquiIdx) continue;
          final dynamic o = placed[j];
          final oLeft = o.left as int;
          final oTop = o.top as int;
          final oSpr = o.s as Sprite;
          if (X < oLeft ||
              X >= oLeft + oSpr.w ||
              Y < oTop ||
              Y >= oTop + oSpr.h) {
            continue;
          }
          final ox = X - oLeft, oy = Y - oTop;
          if (oSpr.px[oy * oSpr.w + ox] >>> 24 == 0) continue;
          final oSy = (o.sy as num).toDouble();
          final oD = (o.d as num).toDouble();
          final op = oD + (oSy - (Y + 0.5)) * _t30 / _s;
          if (baked.zb[idx] > op + _bias) continue;
          if (op > best) {
            best = op;
            covered = true;
          }
        }
        if (covered) cov++;
        if (withTito[idx] != withoutTito[idx]) obscuredByTito++;
      }
    }

    totalOut += out;
    totalHid += hid;
    totalCov += cov;
    totalObscuredByTito += obscuredByTito;
    if (total == 0 || out > 0 || hid > 0 || cov > 0 || obscuredByTito > 0) {
      final deg = (W['manoLarga'] as num?)?.toDouble();
      violations.add(
        'F=$F spot=$spot deg=$deg dy=$dy: total=$total out=$out hid=$hid cov=$cov obscuredByTito=$obscuredByTito',
      );
    }
  }
}

Future<void> _drain() {
  final c = Completer<void>();
  Timer.run(c.complete);
  return c.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in relojStories) {
    test(
      '$id: the four ways through its decisions, every draw\'s values',
      () async {
        final story = jsonDecode(
          File('test/fixtures/reloj/$id.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final make = await realSceneFor('reloj');
        final at = await relojDecisionLetters(course, make, story);
        expect(at, hasLength(2));
        final all = relojDrawsOf(story);
        final picks = <Map<String, String>>[all.first];
        for (final k in all.first.keys) {
          for (final v in {for (final d in all) d[k]!}) {
            if (v == all.first[k]) continue;
            final pick = all.firstWhere((d) => d[k] == v);
            if (!picks.contains(pick)) picks.add(pick);
          }
        }
        final summaries = await playRelojSummaries(story, at, [
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            for (final d in pat == 'rr' ? picks : [picks.first])
              (d: d, pat: pat),
        ]);
        for (final s in summaries) {
          final pat = s['pattern'] as String;
          final what = jsonEncode(s);
          expect(s['end'], 'finished', reason: what);
          expect(s['errors'], isEmpty, reason: what);
          expect(s['decisionsPlayed'], pat, reason: what);
          expect(s['lost'], 'w'.allMatches(pat).length, reason: what);
          expect(s['breaches'], isEmpty, reason: what);
          expect(s['checks'], greaterThan(10), reason: what);
        }
      },
      timeout: const Timeout(Duration(minutes: 20)),
    );
  }

  test('y-media: real answer bounce and free clock taps keep the frog whole on every frame', () async {
    final story = jsonDecode(
      File('test/fixtures/reloj/y-media.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final make = await realSceneFor('reloj');
    final rng = Mulberry32(1);
    final scene = make(rng);
    final bakes = SetBakes(scene);
    final baked = bakes.bakeKey('tarde-0');

    final timers = StoryTimers();
    final player = VirtualClipPlayer(timers, course);
    final renderer = _HandFrameCheckerRenderer(scene: scene, baked: baked);
    final stub = <String>['none'];
    final runner = StoryRunner(
      storyId: 'y-media',
      story: story,
      E: scene,
      course: course,
      clips: player,
      speech: _NoSpeech(),
      progress: RecordingProgress(ToolProgress(), timers),
      rng: rng,
      clock: _VirtualClock(timers),
      memory: _MemoryStore(),
      options: StoryOptions(micStub: stub, allOpen: false),
      timers: timers,
      renderer: renderer,
      sfx: RecordingSfx(player, <Object?>[]),
      startFrog: () => startFrogOf(scene),
      frogShadow: frogShadowOf(scene),
    );

    var largaCalls = 0;
    var freeClockTaps = 0;
    final origLarga = scene.acts['larga']!;
    scene.acts['larga'] = (o) async {
      largaCalls++;
      if (largaCalls == 3) {
        for (var i = 0; i < 3; i++) {
          expect(scene.hit(98, 38, runner.W), 'reloj');
          runner.tap(98, 38);
          freeClockTaps++;
          expect(
            (runner.W['manoLarga'] as num).toDouble(),
            lessThanOrEqualTo(180.0),
            reason:
                'free clock tap #$freeClockTaps must keep manoLarga <= 180°',
          );
        }
      }
      await origLarga(o);
    };

    await runner.init();
    (scene as dynamic).setFramed(bakes.engine, baked, runner.W);

    final errors = <String>[];
    unawaited(
      runner.start().then(
        (_) {},
        onError: (Object e, StackTrace s) => errors.add('$e\n$s'),
      ),
    );

    var started = false;
    Object? pendingKey;
    int? actAt;
    for (var iters = 0; iters < 500000; iters++) {
      await _drain();
      if (errors.isNotEmpty) break;
      if (runner.running) {
        started = true;
      } else if (started) {
        break;
      }

      Object? wantKey;
      void Function()? wantAct;
      if (runner.HAB.est == 'ready' && runner.HAB.cur != null) {
        wantKey = runner.HAB.cur!;
        wantAct = () {
          final reg = runner.HAB.log.last;
          final targets = runner.habMarca(reg['id'] as String);
          final ans = targets != null
              ? targets.map((x) => x.formas[0]).join(' ')
              : 'none';
          while (stub.length <= runner.HAB.si) {
            stub.add('none');
          }
          stub[runner.HAB.si] = ans;
          runner.tapMic();
        };
      } else {
        final pn = runner.pending;
        if (pn != null &&
            !pn.done &&
            pn.asked &&
            pn.tEnd != null &&
            !pn.busy &&
            runner.speaking == 0) {
          final target = pn.pick != null && pn.pick!.isNotEmpty
              ? pn.pick!
              : pn.live.first;
          wantKey = pn;
          wantAct = () {
            final b = runner.bx(target);
            runner.tap(b[0] + b[2] / 2, b[1] + b[3] / 2);
          };
        }
      }

      if (wantKey != null) {
        if (!identical(pendingKey, wantKey)) {
          pendingKey = wantKey;
          actAt = timers.now + 700;
        }
      } else {
        pendingKey = null;
        actAt = null;
      }

      final next = timers.next();
      if (pendingKey != null && (next == null || next.at > actAt!)) {
        timers.now = actAt!;
        final act = wantAct!;
        pendingKey = null;
        actAt = null;
        act();
        continue;
      }
      if (next == null || next.at > 600000) break;
      timers.fire(next);
    }
    await _drain();

    expect(errors, isEmpty);
    expect(started, isTrue);
    expect(runner.running, isFalse);
    expect(freeClockTaps, 3);
    expect(largaCalls, greaterThanOrEqualTo(3));
    expect(renderer.checkedFrames, greaterThan(0));
    expect(
      renderer.bounceOnHandFrames,
      greaterThan(0),
      reason: 'expected real bounce(8) frames (dy <= -4) while on the hand',
    );
    expect(renderer.totalOut, 0, reason: renderer.violations.join('\n'));
    expect(renderer.totalHid, 0, reason: renderer.violations.join('\n'));
    expect(renderer.totalCov, 0, reason: renderer.violations.join('\n'));
    expect(
      renderer.totalObscuredByTito,
      0,
      reason: renderer.violations.join('\n'),
    );
    expect(renderer.violations, isEmpty);
  });
}
