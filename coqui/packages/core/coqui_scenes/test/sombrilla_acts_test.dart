// La sombrilla's acts on StillHost: each story's steps walked in order with two sets of draw values, running both
// branches (wrong then right) of every decision. After every act:
// - every sprite thing's touch box holds its drawn pixels;
// - every visible thing in sombrilla.md's Needs list answers a touch;
// - draw, hud, and shadows run without error.
// Over the three stories, every single one of the 21 things in the Needs list answers a touch at least once.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/sombrilla/sombrilla.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Every thing sombrilla.md's Needs list says he can touch (21 things).
const List<String> needs = [
  'ojo_izq',
  'ojo_der',
  'nariz',
  'boca',
  'cara',
  'cabeza',
  'brazo_izq',
  'brazo_der',
  'mano_izq',
  'mano_der',
  'pies',
  'sombreros',
  'gafas',
  'chancletas',
  'abuela',
  'luis',
  'carmen',
  'coqui',
  'perro',
  'caracoles',
  'bola',
];

Map<String, dynamic> _story(String id) => jsonDecode(
  File('test/support/fixtures/sombrilla/$id.json').readAsStringSync(),
) as Map<String, dynamic>;

Map<String, String> sombrillaVars(String id, int pick) => switch (id) {
  'la-cara' =>
    pick == 0
        ? {
            'pa': 'ojo',
            'ka': 'ojo_izq',
            'ea': 'ojo_izq',
            'pb': 'nariz',
            'kb': 'nariz',
            'eb': 'nariz',
            'x': 'boca',
          }
        : {
            'pa': 'boca',
            'ka': 'boca',
            'ea': 'boca',
            'pb': 'ojo',
            'kb': 'ojo_izq',
            'eb': 'ojo_der',
            'x': 'nariz',
          },
  'la-cabeza-y-los-brazos' =>
    pick == 0
        ? {
            'pa': 'brazo',
            'ka': 'brazo_izq',
            'ea': 'brazo_izq',
            'pb': 'cabeza',
            'kb': 'cabeza',
            'eb': 'cabeza',
            'x': 'mano_izq',
          }
        : {
            'pa': 'mano',
            'ka': 'mano_izq',
            'ea': 'mano_der',
            'pb': 'brazo',
            'kb': 'brazo_izq',
            'eb': 'brazo_der',
            'x': 'cabeza',
          },
  _ =>
    pick == 0
        ? {
            'qa': 'abuela',
            'qb': 'carmen',
            'pa': 'pie',
            'ta': 'chancletas',
            'pb': 'cabeza',
            'tb': 'sombreros',
            'x': 'gafas',
          }
        : {
            'qa': 'carmen',
            'qb': 'abuela',
            'pa': 'ojo',
            'ta': 'gafas',
            'pb': 'pie',
            'tb': 'chancletas',
            'x': 'sombreros',
          },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('sombrilla');
  });
  final answered = <String>{};

  for (final id in const ['la-cara', 'la-cabeza-y-los-brazos', 'me-duele']) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createSombrilla() as Sombrilla;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = sombrillaVars(id, pick);
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
            // Every sprite thing's box holds its drawn pixels.
            for (final it in scene.items(W, 0)) {
              final tag = it.tag;
              if (tag == null) continue;
              final k = tag.startsWith('persona:')
                  ? tag.substring(8)
                  : tag.startsWith('cosa:')
                  ? tag.substring(5)
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
                if (!jsTruthy(o['suelto'])) await check('${st['act']} #$acts');
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

          await check('start');
          await walk(story['beats']);
          await walk(story['final']);
          expect(acts, greaterThan(10));
        },
      );
    }
  }

  test('adjacent body parts and face boxes resolve exact boundary pixels', () {
    // Story 76: arms and hands share x = 108 and x = 186; exact boxes must win.
    final s76 = _story('la-cabeza-y-los-brazos');
    final scene76 = createSombrilla() as Sombrilla;
    final host76 = StillHost(scene76);
    host76.S = s76;
    host76.W = {...host76.W, ...scene76.fresh(s76)};
    final w76 = host76.W;
    expect(scene76.hit(106, 123, w76), 'mano_izq');
    expect(scene76.hit(107, 123, w76), 'mano_izq');
    expect(scene76.hit(108, 123, w76), 'brazo_izq');
    expect(scene76.hit(146, 123, w76), 'brazo_izq');
    expect(scene76.hit(147, 123, w76), 'brazo_der');
    expect(scene76.hit(185, 123, w76), 'brazo_der');
    expect(scene76.hit(186, 123, w76), 'mano_der');
    expect(scene76.hit(187, 123, w76), 'mano_der');
    expect(scene76.hit(147, 115, w76), 'cabeza');

    // Story 75: nariz and boca share y = 130 inside cara.
    final s75 = _story('la-cara');
    final scene75 = createSombrilla() as Sombrilla;
    final host75 = StillHost(scene75);
    host75.S = s75;
    host75.W = {...host75.W, ...scene75.fresh(s75)};
    final w75 = host75.W;
    expect(scene75.hit(147, 129, w75), 'nariz');
    expect(scene75.hit(147, 130, w75), 'boca');
    expect(scene75.hit(131, 117, w75), 'ojo_izq');
    expect(scene75.hit(163, 117, w75), 'ojo_der');
    expect(scene75.hit(110, 110, w75), 'cara');
    // Frog at coqui.cara sits 1 px from the face boxes: all 4 frogBox corners must hit coqui.
    final fb75 = host75.frogBox(w75['cq'] as Map<String, dynamic>);
    expect(scene75.hit(fb75.x, fb75.y, w75), 'coqui');
    expect(scene75.hit(fb75.x + fb75.w - 1, fb75.y, w75), 'coqui');
    expect(scene75.hit(fb75.x, fb75.y + fb75.h - 1, w75), 'coqui');
    expect(scene75.hit(fb75.x + fb75.w - 1, fb75.y + fb75.h - 1, w75), 'coqui');

    // Story 77: pies hits both individual foot boxes and never the gap between them.
    final s77 = _story('me-duele');
    final scene77 = createSombrilla() as Sombrilla;
    final host77 = StillHost(scene77);
    host77.S = s77;
    host77.W = {...host77.W, ...scene77.fresh(s77)};
    final w77 = host77.W;
    expect(scene77.hit(126, 163, w77), 'pies');
    expect(scene77.hit(167, 163, w77), 'pies');
    expect(scene77.hit(147, 163, w77), isNot('pies'));
    ((w77['gente'] as Map)['luis'] as Map)['vis'] = 0;
    expect(scene77.hit(147, 163, w77), isNull);
  });

  tearDownAll(() {
    expect(answered, containsAll(needs), reason: 'answered: $answered');
  });
}
