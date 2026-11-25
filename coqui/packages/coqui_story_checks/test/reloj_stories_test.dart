// El reloj's three stories (63 to 65) played with no screen on the REAL scene (order 59b), a part of every path
// through them (tool/reloj_paths_test.dart plays them all): for each story the four ways through its two decisions
// (rr, rw, wr, ww), each with the first value of every draw, and each other value of every draw once (with rr). Every
// play ends (`finished`), with no error, the decisions played as asked, the stake lost as the wrong ones say, and the
// sheet's rules hold at every act's end and at the end (test/support/reloj_rules.dart).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart' show BakedSet, Ctx, Scene, Sprite;
import 'package:coqui_scenes/coqui_scenes.dart' show SetBakes, SetScene;
import 'package:coqui_story_checks/coqui_story_checks.dart';
import 'package:feature_story/feature_story.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/reloj_paths.dart';

class _HandFrameChecker {
  _HandFrameChecker({required this.scene, required this.baked}) : _dyn = scene {
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

  void checkFrame(Scene scene, Map<String, dynamic> W, int F) {
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
    late SetScene scene;
    late SetBakes bakes;
    late BakedSet baked;
    late _HandFrameChecker checker;
    late Map<String, dynamic> world;
    late void Function(num x, num y) tapAt;

    var largaCalls = 0;
    var freeClockTaps = 0;

    final trace = await play(
      story: story,
      plan: 'right',
      seed: 1,
      allOpen: false,
      sceneFor: (rng) {
        scene = make(rng);
        bakes = SetBakes(scene);
        baked = bakes.bakeKey('tarde-0');
        checker = _HandFrameChecker(scene: scene, baked: baked);
        final origLarga = scene.acts['larga']!;
        scene.acts['larga'] = (o) async {
          largaCalls++;
          if (largaCalls == 3) {
            for (var i = 0; i < 3; i++) {
              expect(scene.hit(98, 38, world), 'reloj');
              tapAt(98, 38);
              freeClockTaps++;
              expect(
                (world['manoLarga'] as num).toDouble(),
                lessThanOrEqualTo(180.0),
                reason:
                    'free clock tap #$freeClockTaps must keep manoLarga <= 180°',
              );
            }
          }
          await origLarga(o);
        };
        return scene;
      },
      course: course,
      progress: ToolProgress(),
      startFrog: startFrogOf,
      frogShadow: frogShadowOf,
      onInit: (W, tap) {
        world = W;
        tapAt = tap;
        (scene as dynamic).setFramed(bakes.engine, baked, W);
      },
      onFrame: (s, W, F) => checker.checkFrame(s, W, F),
    );

    expect(trace['errors'], isEmpty);
    expect(trace['end'], 'finished');
    expect(freeClockTaps, 3);
    expect(largaCalls, greaterThanOrEqualTo(3));
    expect(checker.checkedFrames, greaterThan(0));
    expect(
      checker.bounceOnHandFrames,
      greaterThan(0),
      reason: 'expected real bounce(8) frames (dy <= -4) while on the hand',
    );
    expect(checker.totalOut, 0, reason: checker.violations.join('\n'));
    expect(checker.totalHid, 0, reason: checker.violations.join('\n'));
    expect(checker.totalCov, 0, reason: checker.violations.join('\n'));
    expect(
      checker.totalObscuredByTito,
      0,
      reason: checker.violations.join('\n'),
    );
    expect(checker.violations, isEmpty);
  });
}
