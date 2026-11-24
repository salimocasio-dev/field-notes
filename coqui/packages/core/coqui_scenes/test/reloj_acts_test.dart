// El reloj's acts on a host whose waits return at once (StillHost): each story's steps walked in order, every act the
// stories call run with the values they give it (each story walked twice with different draw values), both branches of
// each decision (wrong then right). After every act:
// - every touch box contains its thing (a sprite thing's box is its drawn pixels' box; a set thing's is the sheet's);
// - every thing the Needs list says he can touch that is shown answers a touch: some point of its box hits it;
// - the frame draws (the sprite layer and the signs) and the shadows are cast without an error.
// And: each thing the Needs list names answered a touch at least once over the three stories, and the time cards'
// boxes are those of the sheet (things.carta_a, _b) when the frog is at pie2.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/reloj/reloj.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// What the Needs list says he can touch (reloj.md, "Needs": things he can touch).
const List<String> needs = [
  'reloj',
  'arriba',
  'abajo',
  'carta_a',
  'carta_b',
  'n40',
  'n60',
  'n80',
  'n90',
  'n100',
  'tito',
  'vendedor',
  'luis',
  'carmen',
  'abuela',
  'senor',
  'senora',
  'coqui',
  'pastelillos',
  'puertita',
];

Map<String, dynamic> _story(String id) =>
    jsonDecode(File('test/support/fixtures/reloj/$id.json').readAsStringSync())
        as Map<String, dynamic>;

class _RecordingHost extends StillHost {
  _RecordingHost(super.scene);

  void Function(num ms)? onWait;

  @override
  Future<void> wait(num ms) async {
    onWait?.call(ms);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('reloj');
  });
  final answered = <String>{};

  Map<String, String> vars(String id, int pick) => switch (id) {
    'que-hora-es' =>
      pick == 0
          ? {
              'ha': '5',
              'da': 'l',
              'oa': '8',
              'ka': 'carta_a',
              'ja': 'carta_b',
              'ua': '5',
              'va': '8',
              'hb': '9',
              'db': 'e',
              'ob': '4',
              'kb': 'carta_b',
              'jb': 'carta_a',
              'ub': '4',
              'vb': '9',
            }
          : {
              'ha': '4',
              'da': 'e',
              'oa': '1',
              'ka': 'carta_b',
              'ja': 'carta_a',
              'ua': '1',
              'va': '4',
              'hb': '12',
              'db': 'e',
              'ob': '7',
              'kb': 'carta_a',
              'jb': 'carta_b',
              'ub': '12',
              'vb': '7',
            },
    'y-media' =>
      pick == 0
          ? {
              'ha': '5',
              'da': 'media',
              'oa': 'punto',
              'pa': 'abajo',
              'ma': '1',
              'hb': '8',
              'db': 'punto',
              'ob': 'media',
              'pb': 'arriba',
              'mb': '0',
            }
          : {
              'ha': '4',
              'da': 'punto',
              'oa': 'media',
              'pa': 'arriba',
              'ma': '0',
              'hb': '11',
              'db': 'media',
              'ob': 'punto',
              'pb': 'abajo',
              'mb': '1',
            },
    _ =>
      pick == 0
          ? {'na': '100', 'nb': '60', 'nc': '80', 'xn': '60'}
          : {'na': '80', 'nb': '100', 'nc': '60', 'xn': '100'},
  };

  for (final id in const ['que-hora-es', 'y-media', 'bingo']) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createReloj() as Reloj;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = vars(id, pick);
          Object? sub(Object? s) => s is String
              ? s.replaceAllMapped(
                  RegExp(r'\$([a-z]+)'),
                  (m) => v[m[1]!] ?? m[0]!,
                )
              : s;
          final pix = Uint32List(240 * 216), disp = Uint32List(196 * 216);
          var acts = 0;

          Future<void> check(String at) async {
            final W = host.W;
            scene.draw(Ctx(pix, 240, 216), W, host.F);
            scene.hud(Ctx(disp, 196, 216), W, host.F);
            scene.shadows(W);
            for (final k in needs) {
              if (k == 'coqui') continue;
              final b = scene.box(k, W);
              final t = scene.cosas.firstWhere(
                (t) => t.id == k,
                orElse: () => Thing(id: ''),
              );
              if (t.id.isEmpty || (t.si != null && !t.si!(W)) || b == null) {
                continue;
              }
              var hits = false;
              for (var y = b[1].toInt(); y < b[1] + b[3] && !hits; y++) {
                for (var x = b[0].toInt(); x < b[0] + b[2] && !hits; x++) {
                  if (scene.hit(x, y, W) == k) hits = true;
                }
              }
              expect(
                hits,
                isTrue,
                reason: '$id $at: $k shown, its box $b answers no touch',
              );
              answered.add(k);
            }
            final q = W['cq'] as Map<String, dynamic>;
            if (jsTruthy(q['vis'])) {
              final fb = host.frogBox(q);
              var frogHits = false;
              for (var y = fb.y.toInt(); y < fb.y + fb.h && !frogHits; y++) {
                for (var x = fb.x.toInt(); x < fb.x + fb.w && !frogHits; x++) {
                  if (scene.hit(x, y, W) == 'coqui') frogHits = true;
                }
              }
              if (frogHits) answered.add('coqui');
            }
            // every sprite thing's box holds its drawn pixels
            for (final it in scene.items(W, 0)) {
              final tag = it.tag;
              if (tag == null) continue;
              final k = tag == 'cosa:plato'
                  ? 'pastelillos'
                  : tag.startsWith('persona:')
                  ? tag.substring(8)
                  : tag;
              if (!needs.contains(k)) continue;
              final b = scene.box(k, W)!;
              for (var y = 0; y < it.s.h; y++) {
                for (var x = 0; x < it.s.w; x++) {
                  if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
                  final X = it.left + x, Y = it.top + y;
                  expect(
                    X >= b[0] &&
                        X < b[0] + b[2] &&
                        Y >= b[1] &&
                        Y < b[1] + b[3],
                    isTrue,
                    reason: '$id $at: $k\'s pixel ($X, $Y) out of its box $b',
                  );
                }
              }
            }
          }

          Future<void> walk(Object? steps) async {
            if (steps is! List) return;
            for (final st in steps) {
              if (st is! Map<String, dynamic>) continue;
              if (st['set'] is Map) {
                host.W.addAll((st['set'] as Map).cast<String, dynamic>());
              } else if (st['act'] is String) {
                final o = {for (final e in st.entries) e.key: sub(e.value)};
                await scene.acts[st['act']]!(o);
                acts++;
                host.F += 3;
                await check('${st['act']} #$acts');
              } else if (st['ask'] is String) {
                await walk(st['after']);
                await walk(st['then']);
              } else if (st['decide'] is String) {
                await walk(st['lead']);
                await walk(st['wrong']);
                await walk(st['right']);
              } else if (st['if'] is String) {
                await walk(st['then']);
                await walk(st['else']);
              }
            }
          }

          await walk(story['beats']);
          await walk(story['final']);
          expect(acts, greaterThan(15));
          // time cards' boxes match the sheet's for the frog at pie2
          host.W['cartas'] = {'a': 5, 'b': 8};
          final L = scene.lugar['pie2']!,
              q = host.W['cq'] as Map<String, dynamic>;
          q
            ..['x'] = L[0]
            ..['y'] = L[1]
            ..['vis'] = 1;
          expect(scene.box('carta_a', host.W), scene.places.box('carta_a'));
          expect(scene.box('carta_b', host.W), scene.places.box('carta_b'));
        },
      );
    }
  }

  test('campana rings all n times for hours above four', () async {
    final story = _story('que-hora-es');
    final scene = createReloj() as Reloj;
    final host = _RecordingHost(scene);
    host.S = story;
    host.W = {...host.W, ...scene.fresh(story)};

    Future<int> countPulses(int n) async {
      var pulses = 0;
      host.onWait = (_) {
        expect(
          host.W['campanaHasta'],
          greaterThan(host.F),
          reason: 'bell wave should be active on pulse ${pulses + 1} of $n',
        );
        pulses++;
        host.F += 6;
      };
      await scene.acts['campana']!({'n': n});
      return pulses;
    }

    expect(await countPulses(12), 12);
    expect(await countPulses(5), 5);
    expect(await countPulses(1), 1);
  });

  test('larga carries the frog on every intermediate frame during hand rotation', () async {
    final story = _story('y-media');
    final scene = createReloj() as Reloj;
    final host = _RecordingHost(scene);
    host.S = story;
    host.W = {...host.W, ...scene.fresh(story)};

    final bakes = SetBakes(scene);
    final baked = bakes.bakeKey(scene.setKey(host.W));
    scene.setFramed(bakes.engine, baked, host.W);
    final tito =
        (host.W['gente'] as Map<String, dynamic>)['tito']
            as Map<String, dynamic>;
    expect(tito['vis'], 1);

    await scene.acts['ir']!({'a': 'manecilla'});
    final q = host.W['cq'] as Map<String, dynamic>;
    expect(q['spot'], 'mano_abajo');
    expect(host.W['manoLarga'], 180.0);
    final startPos = (q['x'] as num, q['y'] as num);

    double distToSeg(
      double px,
      double py,
      double x0,
      double y0,
      double x1,
      double y1,
    ) {
      final dx = x1 - x0, dy = y1 - y0;
      final l2 = dx * dx + dy * dy;
      final t = l2 == 0
          ? 0.0
          : (((px - x0) * dx + (py - y0) * dy) / l2).clamp(0.0, 1.0);
      final cx = x0 + t * dx, cy = y0 + t * dy;
      return math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
    }

    final t30 = math.tan(math.pi / 6);
    final s = scene.places.e.S;
    final bias = scene.places.bias;

    void checkFrogVisible(
      String label,
      double deg,
      List<RelojItem> placed,
      Uint32List withTito,
      Uint32List withoutTito,
    ) {
      expect(
        placed.any((it) => it.tag == 'persona:tito'),
        isTrue,
        reason: '$label deg=$deg: persona:tito must be placed in frame',
      );
      final coquiIdx = placed.indexWhere((it) => it.tag == 'coqui');
      expect(coquiIdx, greaterThanOrEqualTo(0));
      final coqui = placed[coquiIdx];
      var total = 0;
      var out = 0;
      var hid = 0;
      var cov = 0;
      var obscuredByTito = 0;
      final covBy = <String, int>{};

      for (var y = 0; y < coqui.s.h; y++) {
        final Y = coqui.top + y;
        final coquiPlane = coqui.d + (coqui.sy - (Y + 0.5)) * t30 / s;
        for (var x = 0; x < coqui.s.w; x++) {
          if (coqui.s.px[y * coqui.s.w + x] >>> 24 == 0) continue;
          total++;
          final X = coqui.left + x;
          if (X < 0 || X >= 240 || Y < 0 || Y >= 216) {
            out++;
            continue;
          }
          final idx = Y * 240 + X;
          if (baked.zb[idx] > coquiPlane + bias) {
            hid++;
            continue;
          }
          var best = coquiPlane + 0.001;
          String? winner;
          for (var j = 0; j < placed.length; j++) {
            if (j == coquiIdx) continue;
            final o = placed[j];
            if (X < o.left ||
                X >= o.left + o.s.w ||
                Y < o.top ||
                Y >= o.top + o.s.h) {
              continue;
            }
            final ox = X - o.left, oy = Y - o.top;
            if (o.s.px[oy * o.s.w + ox] >>> 24 == 0) continue;
            final op = o.d + (o.sy - (Y + 0.5)) * t30 / s;
            if (baked.zb[idx] > op + bias) continue;
            if (op > best) {
              best = op;
              winner = o.tag ?? 'sprite';
            }
          }
          if (winner != null) {
            cov++;
            covBy[winner] = (covBy[winner] ?? 0) + 1;
          }
          if (withTito[idx] != withoutTito[idx]) {
            obscuredByTito++;
          }
        }
      }

      expect(total, greaterThan(0), reason: '$label deg=$deg: frog has ink');
      expect(out, 0, reason: '$label deg=$deg: $out/$total frog pixels out');
      expect(
        hid,
        0,
        reason: '$label deg=$deg: $hid/$total frog pixels hidden by set',
      );
      expect(
        cov,
        0,
        reason: '$label deg=$deg: $cov/$total frog pixels covered by $covBy',
      );
      expect(
        obscuredByTito,
        0,
        reason:
            '$label deg=$deg: $obscuredByTito/$total frog pixels obscured by tito',
      );
    }

    Future<
      List<
        ({
          double deg,
          num qx,
          num qy,
          String? spot,
          RelojItem coqui,
          RelojItem hand,
          List<RelojItem> placed,
          Uint32List withTito,
          Uint32List withoutTito,
        })
      >
    >
    recordLarga(String a, String label) async {
      final frames =
          <
            ({
              double deg,
              num qx,
              num qy,
              String? spot,
              RelojItem coqui,
              RelojItem hand,
              List<RelojItem> placed,
              Uint32List withTito,
              Uint32List withoutTito,
            })
          >[];
      host.onWait = (_) {
        final placed = scene.placed(host.W, host.F);
        final withTito = Uint32List.fromList(baked.pix);
        scene.draw(Ctx(withTito, 240, 216), host.W, host.F);
        final withoutTito = Uint32List.fromList(baked.pix);
        tito['vis'] = 0;
        try {
          scene.draw(Ctx(withoutTito, 240, 216), host.W, host.F);
        } finally {
          tito['vis'] = 1;
        }
        final coqui = placed.firstWhere((it) => it.tag == 'coqui');
        final hand = placed.firstWhere((it) => it.tag == 'mano_larga');
        final deg = (host.W['manoLarga'] as num).toDouble();
        checkFrogVisible(label, deg, placed, withTito, withoutTito);
        frames.add((
          deg: deg,
          qx: q['x'] as num,
          qy: q['y'] as num,
          spot: q['spot'] as String?,
          coqui: coqui,
          hand: hand,
          placed: placed,
          withTito: withTito,
          withoutTito: withoutTito,
        ));
      };
      await scene.acts['larga']!({'a': a});
      host.onWait = null;
      return frames;
    }

    // Sweep 1: media -> punto (180° -> 0° via 3 o'clock)
    final upFrames = (await recordLarga(
      'punto',
      'media->punto',
    )).take(4).toList();
    expect([for (final f in upFrames) f.deg], [135.0, 90.0, 45.0, 0.0]);
    final positions = <(num, num)>{};
    for (final f in upFrames) {
      expect((f.qx, f.qy), isNot(startPos));
      positions.add((f.qx, f.qy));
    }
    expect(positions.length, 4);

    final arribaL = scene.lugar['mano_arriba']!;
    expect((upFrames[3].qx, upFrames[3].qy), (arribaL[0], arribaL[1]));
    expect(upFrames[3].spot, 'mano_arriba');

    final pv = scene.places.handPivot;
    final len = scene.places.longHand;
    for (final f in upFrames) {
      final rad = f.deg * math.pi / 180;
      final tipX = pv.sx + len * math.sin(rad);
      final tipY = pv.sy - len * math.cos(rad);
      final dist = distToSeg(
        (f.qx + 16).toDouble(),
        (f.qy + 25).toDouble(),
        pv.sx,
        pv.sy,
        tipX,
        tipY,
      );
      expect(
        dist,
        lessThanOrEqualTo(2.0),
        reason: 'deg=${f.deg} feet (${f.qx + 16}, ${f.qy + 25}) dist=$dist',
      );

      final box = Reloj.inkBox(f.coqui)!;
      expect(box[0], greaterThanOrEqualTo(0));
      expect(box[1], greaterThanOrEqualTo(0));
      expect(box[0] + box[2], lessThanOrEqualTo(240));
      expect(box[1] + box[3], lessThanOrEqualTo(216));

      final yMid = f.coqui.sy - 0.5;
      final coquiPlane = f.coqui.d + (f.coqui.sy - yMid) * t30 / s;
      final handPlane = f.hand.d + (f.hand.sy - yMid) * t30 / s;
      expect(
        coquiPlane,
        greaterThan(handPlane + 0.001),
        reason: 'deg=${f.deg}: coqui must sit in front of mano_larga',
      );
    }

    // Sweep 2: punto -> media (0° -> 180° via 3 o'clock)
    final toMediaFrames = (await recordLarga(
      'media',
      'punto->media',
    )).take(4).toList();
    expect([for (final f in toMediaFrames) f.deg], [45.0, 90.0, 135.0, 180.0]);
    expect(toMediaFrames[3].spot, 'mano_abajo');

    // Sweep 3: media -> lado (180° -> 90°)
    final mediaToSideFrames = (await recordLarga(
      'lado',
      'media->lado',
    )).take(4).toList();
    expect(
      [for (final f in mediaToSideFrames) f.deg],
      [157.5, 135.0, 112.5, 90.0],
    );
    expect(mediaToSideFrames[3].spot, 'mano_lado');

    // Sweep 4: lado -> punto (90° -> 0°)
    final sideToPuntoFrames = (await recordLarga(
      'punto',
      'lado->punto',
    )).take(4).toList();
    expect([for (final f in sideToPuntoFrames) f.deg], [67.5, 45.0, 22.5, 0.0]);
    expect(sideToPuntoFrames[3].spot, 'mano_arriba');

    // Sweep 5: punto -> lado (0° -> 90°)
    final sideStart = (q['x'] as num, q['y'] as num);
    final sideFrames = (await recordLarga(
      'lado',
      'punto->lado',
    )).take(4).toList();
    expect({for (final f in sideFrames) (f.qx, f.qy)}.length, 4);
    expect((sideFrames[0].qx, sideFrames[0].qy), isNot(sideStart));
    expect(sideFrames[3].spot, 'mano_lado');

    // Sweep 6: lado -> media (90° -> 180°)
    final downStart = (q['x'] as num, q['y'] as num);
    final downFrames = (await recordLarga(
      'media',
      'lado->media',
    )).take(4).toList();
    expect({for (final f in downFrames) (f.qx, f.qy)}.length, 4);
    expect((downFrames[0].qx, downFrames[0].qy), isNot(downStart));
    expect(downFrames[3].spot, 'mano_abajo');

    // Story 63: poke('reloj') still advances manoLarga by +12° (180 -> 192 -> 204)
    final s63Story = _story('que-hora-es');
    final s63Scene = createReloj() as Reloj;
    final s63Host = StillHost(s63Scene);
    s63Host.S = s63Story;
    s63Host.W = {...s63Host.W, ...s63Scene.fresh(s63Story)};
    expect(s63Host.W['manoLarga'], 180.0);
    s63Scene.poke('reloj');
    expect(s63Host.W['manoLarga'], 192.0);
    s63Scene.poke('reloj');
    expect(s63Host.W['manoLarga'], 204.0);

    // Story 64: free clock taps while riding mano_abajo keep manoLarga at 180°
    // and sweep through the open 3-o'clock half [135, 90, 45, 0].
    expect(q['spot'], 'mano_abajo');
    expect(host.W['manoLarga'], 180.0);
    for (var i = 0; i < 3; i++) {
      scene.poke('reloj');
      expect(host.W['manoLarga'], 180.0);
    }
    final afterPokeFrames = (await recordLarga(
      'punto',
      'after-poke->punto',
    )).take(4).toList();
    expect([for (final f in afterPokeFrames) f.deg], [135.0, 90.0, 45.0, 0.0]);
    expect(afterPokeFrames[3].spot, 'mano_arriba');

    // Defense-in-depth: even if manoLarga drifted past 180° while riding
    // mano_abajo, larga('punto') still sweeps [135, 90, 45, 0] clear of Tito.
    await recordLarga('media', 'reset->media-1');
    expect(q['spot'], 'mano_abajo');
    host.W['manoLarga'] = 204.0;
    final defenseFrames = (await recordLarga(
      'punto',
      'defense-204->punto',
    )).take(4).toList();
    expect([for (final f in defenseFrames) f.deg], [135.0, 90.0, 45.0, 0.0]);
    expect(defenseFrames[3].spot, 'mano_arriba');

    // Celebratory bounce (q['dy'] = -8.0) during larga('punto') at 45° and 0° /
    // mano_arriba stays inside the picture (out == 0) and unobscured.
    await recordLarga('media', 'reset->media-2');
    expect(q['spot'], 'mano_abajo');
    q['dy'] = -8.0;
    try {
      final bounceFrames = (await recordLarga(
        'punto',
        'bounce->punto',
      )).take(4).toList();
      expect([for (final f in bounceFrames) f.deg], [135.0, 90.0, 45.0, 0.0]);
      expect(bounceFrames[2].deg, 45.0);
      expect(bounceFrames[3].deg, 0.0);
      expect(bounceFrames[3].spot, 'mano_arriba');
    } finally {
      q['dy'] = 0.0;
    }
  });

  test(
    'bingo renders rival small cards and frijol updates their pixels',
    () async {
      final story = _story('bingo');
      final scene = createReloj() as Reloj;
      final host = _RecordingHost(scene);
      host.S = story;
      host.W = {...host.W, ...scene.fresh(story)};

      final bakes = SetBakes(scene);
      final baked = bakes.bakeKey(scene.setKey(host.W));
      scene.setFramed(bakes.engine, baked, host.W);

      final initItems = scene.items(host.W, 0);
      final tags = {for (final it in initItems) it.tag};
      expect(
        tags,
        containsAll([
          'cosa:carton_luis',
          'cosa:carton_senor',
          'cosa:carton_tito',
        ]),
      );

      int diffInBox(Uint32List a, Uint32List b, List<num> box) {
        var changed = 0;
        final x0 = math.max(0, box[0].toInt());
        final y0 = math.max(0, box[1].toInt());
        final x1 = math.min(240, (box[0] + box[2]).toInt());
        final y1 = math.min(216, (box[1] + box[3]).toInt());
        for (var y = y0; y < y1; y++) {
          for (var x = x0; x < x1; x++) {
            final i = y * 240 + x;
            if (a[i] != b[i]) changed++;
          }
        }
        return changed;
      }

      List<num> itemBox(String tag) {
        final it = scene.items(host.W, 0).firstWhere((e) => e.tag == tag);
        return Reloj.inkBox(it)!;
      }

      final before = Uint32List(240 * 216);
      scene.draw(Ctx(before, 240, 216), host.W, host.F);

      await scene.acts['frijol']!({'carton': 'luis', 'n': 50});
      expect((host.W['cartones'] as Map)['luis'], 1);

      final after = Uint32List(240 * 216);
      scene.draw(Ctx(after, 240, 216), host.W, host.F);

      final luisBox = itemBox('cosa:carton_luis');
      expect(diffInBox(before, after, luisBox), greaterThan(0));
      var totalChanged = 0;
      for (var i = 0; i < before.length; i++) {
        if (before[i] != after[i]) totalChanged++;
      }
      expect(totalChanged, greaterThan(0));

      final senorBefore = Uint32List.fromList(after);
      await scene.acts['frijol']!({'carton': 'senor'});
      expect((host.W['cartones'] as Map)['senor'], 4);
      final senorAfter4 = Uint32List(240 * 216);
      scene.draw(Ctx(senorAfter4, 240, 216), host.W, host.F);
      final senorBox = itemBox('cosa:carton_senor');
      expect(diffInBox(senorBefore, senorAfter4, senorBox), greaterThan(0));

      await scene.acts['rival65']!({'quien': 'senor'});
      expect((host.W['cartones'] as Map)['senor'], 5);
      final senorAfter5 = Uint32List(240 * 216);
      scene.draw(Ctx(senorAfter5, 240, 216), host.W, host.F);
      expect(diffInBox(senorAfter4, senorAfter5, senorBox), greaterThan(0));
    },
  );

  tearDownAll(() {
    expect(answered, containsAll(needs), reason: 'answered: $answered');
  });
}
