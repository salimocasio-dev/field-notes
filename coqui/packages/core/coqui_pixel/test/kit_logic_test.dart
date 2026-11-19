// The kit's logic against the OLD code run in node (tool/make_kit_ref.mjs): `hit`, `box` and `handAt` of a made-up
// scene at 50 fixed points under four states of W, the shared acts and the bird's flights, the 18 names of `SFX`, the
// corners of a face of a world box, and how many frames `camGo` takes. The made-up scene is written twice, there and
// in test/support/kit_scene.dart.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/fixtures/ref_kit_logic.dart';
import 'support/json_close.dart';
import 'support/kit_scene.dart';
import 'support/rec_player.dart';

void main() {
  final ref = jsonDecode(kitLogicRef) as Map<String, dynamic>;
  final scene = ref['scene'] as Map<String, dynamic>;
  final points = [
    for (final p in scene['points'] as List<dynamic>)
      [(p as List<dynamic>)[0] as num, p[1] as num],
  ];
  final variants = (scene['variants'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  group('hit, box and handAt on a made-up scene', () {
    test('50 fixed points, 4 states of W', () {
      expect(points.length, 50);
      expect(variants.length, 4);
    });

    for (final v in variants) {
      final name = v['name'] as String;
      final W = v['W'] as Map<String, dynamic>;

      test('$name: hit returns the same id at every point', () {
        final s = Maqueta(own: true)..host = TestHost(W: copyJson(W));
        final expected = (v['hit'] as List<dynamic>).cast<String?>();
        final got = [for (final p in points) s.hit(p[0], p[1], s.host.W)];
        final bad = [
          for (var i = 0; i < points.length; i++)
            if (got[i] != expected[i])
              '${points[i]}: ${got[i]} against ${expected[i]}',
        ];
        expect(bad, isEmpty);
        // the state really tests something: some points hit, some do not
        expect(
          got.whereType<String>().length,
          expected.whereType<String>().length,
        );
        expect(got.contains(null), isTrue);
      });

      test('$name: box and handAt give the same values', () {
        final s = Maqueta(own: true)..host = TestHost(W: copyJson(W));
        final box = v['box'] as Map<String, dynamic>;
        final hand = v['handAt'] as Map<String, dynamic>;
        for (final id in scene['ids'] as List<dynamic>) {
          expect(s.box(id as String, s.host.W), box[id], reason: 'box $id');
          expect(s.handAt(id), hand[id], reason: 'handAt $id');
        }
      });

      test('$name: avePos', () {
        final s = Maqueta(own: true)..host = TestHost(W: copyJson(W));
        final ave = s.host.W['ave'] as Map<String, dynamic>?;
        final expected = v['avePos'] as List<dynamic>?;
        if (ave == null || ave['mode'] == 'none') {
          expect(expected, isNull);
        } else {
          expect(jsonDiff(s.avePos(ave), expected), '');
        }
      });
    }
  });

  group('the shared acts', () {
    final names = scene['actNames'] as Map<String, dynamic>;

    test(
      'a scene\'s own acts win, the shared ones are added to the same map',
      () {
        final own = Maqueta(own: true)..host = TestHost(W: {});
        final plain = Maqueta()..host = TestHost(W: {});
        expect(own.acts.keys.toList(), names['own']);
        expect(plain.acts.keys.toList(), names['plain']);
        expect(names['ownIrIsKept'], isTrue);
        expect(own.acts['ir'], own.ownIr);
        expect(plain.acts['ir'], isNotNull);
        expect(own.heartAt, (names['heartAt'] as List<dynamic>)[0]);
        expect(plain.heartAt, (names['heartAt'] as List<dynamic>)[1]);
      },
    );

    // the bird's calls, as the reference wrote them
    final birdCalls = <String, Future<void> Function(Escena s)>{
      'await KIT.aveVa(100, 80, 4, 1)': (s) => s.aveVa(100, 80, 4, 1),
      'await KIT.aveVa(20, 120)': (s) => s.aveVa(20, 120),
      'await KIT.aveVa(200, 40, 3, -1)': (s) => s.aveVa(200, 40, 3, -1),
      'await KIT.aveA(70, 50, 5)': (s) => s.aveA(70, 50, 5),
    };

    for (final run
        in (scene['acts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      test(run['title'] as String, () async {
        final host = TestHost(
          W: copyJson(run['W0'] as Map<String, dynamic>),
          cam: [for (final v in run['cam'] as List<dynamic>) v as num],
        );
        final s = Maqueta(own: run['scene'] == 'own')..host = host;
        final act = run['act'] as String;
        if (birdCalls.containsKey(act)) {
          await birdCalls[act]!(s);
        } else {
          await s.acts[act]!(
            Map<String, dynamic>.from(run['o'] as Map<String, dynamic>),
          );
        }
        expect(jsonDiff(host.log, run['log']), '', reason: 'the calls');
        expect(jsonDiff(host.W, run['W1']), '', reason: 'W after');
      });
    }
  });

  group('SFX', () {
    final sfx = ref['sfx'] as Map<String, dynamic>;

    List<List<Object?>> run(String name, List<dynamic> args) {
      final p = RecPlayer(), s = Sfx(p);
      switch (name) {
        case 'right':
          s.right();
        case 'toc':
          s.toc();
        case 'blip':
          s.blip();
        case 'creak':
          s.creak();
        case 'hop':
          s.hop();
        case 'coqui':
          s.coqui();
        case 'win':
          s.win();
        case 'luz':
          s.luz();
        case 'drop':
          s.drop();
        case 'trueno':
          args.isEmpty ? s.trueno() : s.trueno(args[0] as num);
        case 'lluvia':
          s.lluvia();
        case 'calla':
          s.calla();
        case 'suave':
          s.suave();
        case 'pio':
          s.pio();
        case 'slam':
          s.slam();
        case 'bonk':
          s.bonk();
        case 'munch':
          s.munch();
        case 'swoop':
          s.swoop();
        default:
          throw StateError('no SFX $name');
      }
      return p.calls;
    }

    test('juego.js defines 18 names', () {
      expect((sfx['names'] as List<dynamic>).length, 18);
    });

    for (final r
        in (sfx['list'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final name = r['name'] as String, args = r['args'] as List<dynamic>;
      test(
        '$name${args.isEmpty ? '' : '(${args.join(', ')})'}: the same calls with the same numbers',
        () {
          final got = run(name, args);
          final expected = (r['calls'] as List<dynamic>).cast<List<dynamic>>();
          // exact: the same literals, the same arithmetic
          expect(got.length, expected.length);
          for (var i = 0; i < got.length; i++) {
            expect(got[i], expected[i], reason: 'call $i');
          }
        },
      );
    }

    test('the thunder: the old graph starts at (v || 1) * .5, which is the player\'s to apply to `vol`', () {
      for (final r
          in (sfx['list'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        if (r['name'] != 'trueno') continue;
        final args = r['args'] as List<dynamic>;
        final v = args.isEmpty || args[0] == 0 ? 1 : args[0] as num;
        final raw = (r['raw'] as List<dynamic>).cast<List<dynamic>>();
        final gain = raw.firstWhere((x) => x[0] == 'gain.set')[1] as num;
        expect(gain, closeTo(v * .5, 1e-12));
        expect(
          (run('trueno', args).single[1] as num) * .5,
          closeTo(gain, 1e-12),
        );
      }
    });

    test(
      'the rain: the old code keeps it in a variable, Sfx does not (a finding)',
      () {
        // old: calla [], lluvia [loop on], lluvia [] (already on), calla [loop off], calla [] (nothing to stop)
        final old = (sfx['rainSequence'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        expect(
          [for (final s in old) (s['calls'] as List<dynamic>).length],
          [0, 1, 0, 1, 0],
        );
        // Sfx: every call reaches the player, which must treat loop('rain', true) twice and loop('rain', false) with no
        // rain as it treats them, as the old code did: nothing
        final p = RecPlayer(), s = Sfx(p);
        for (final x in old) {
          p.calls.clear();
          x['name'] == 'calla' ? s.calla() : s.lluvia();
          expect(p.calls, [
            ['loop', 'rain', x['name'] != 'calla'],
          ]);
        }
      },
    );
  });

  group('clipTo', () {
    final clip = ref['clip'] as Map<String, dynamic>;
    final s = clip['scene'] as Map<String, dynamic>;
    final engine = PpEngine(
      w: s['w'] as int,
      h: s['h'] as int,
      s: (s['s'] as num).toDouble(),
      originX: (s['originX'] as num).toDouble(),
      originY: (s['originY'] as num).toDouble(),
    );

    for (final b
        in (clip['boxes'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final world = [for (final v in b['world'] as List<dynamic>) v as num];
      final faces = b['faces'] as Map<String, dynamic>;
      for (final face in faces.keys) {
        test(
          'the $face face of the box $world is the projection of its four corners',
          () {
            final got = faceCorners(engine, world, face);
            final expected = (faces[face] as List<dynamic>)
                .cast<List<dynamic>>();
            expect(got.length, 4);
            for (var i = 0; i < 4; i++) {
              expect(got[i].sx, closeTo(expected[i][0] as num, 1e-9));
              expect(got[i].sy, closeTo(expected[i][1] as num, 1e-9));
            }
          },
        );
      }
    }

    test('an unknown face throws; a thing with no world box cannot clip', () {
      expect(
        () => faceCorners(engine, [0, 0, 0, 1, 1, 1], 'top'),
        throwsArgumentError,
      );
      final c = Ctx(Uint32List(240 * 216), 240, 216);
      expect(
        () => clipTo(c, engine, Thing(id: 'x', box: [0, 0, 1, 1]), 'y'),
        throwsArgumentError,
      );
    });

    test('the clip is the face: what is drawn inside it shows, what is outside does not', () {
      final px = Uint32List(240 * 216);
      final c = Ctx(px, 240, 216);
      final t = Thing(id: 'ventana', world: [-1.5, -2, 0, 3, 2.5, 3.2]);
      final poly = faceCorners(engine, t.world!, 'y');
      c.save();
      clipTo(c, engine, t, 'y');
      c.fillStyle = 0xFFFFFFFF;
      c.fillRect(0, 0, 240, 216);
      c.restore();
      // the painted pixels are the polygon's area, to within its edge
      var area = 0.0;
      for (var i = 0; i < 4; i++) {
        final a = poly[i], b = poly[(i + 1) % 4];
        area += a.sx * b.sy - b.sx * a.sy;
      }
      area = area.abs() / 2;
      final painted = px.where((v) => v != 0).length;
      expect(painted, closeTo(area, area * .03));
      final cx = (poly[0].sx + poly[2].sx) / 2,
          cy = (poly[0].sy + poly[2].sy) / 2;
      expect(px[cy.floor() * 240 + cx.floor()], 0xFFFFFFFF);
      expect(px[0], 0);
      // the clip is gone after restore
      c.fillStyle = 0xFFFFFFFF;
      c.fillRect(0, 0, 4, 4);
      expect(px[0], 0xFFFFFFFF);
    });
  });
}
