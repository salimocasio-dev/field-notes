// La noche's acts on StillHost: each story's steps walked in order with two sets of draw values, running both
// branches (wrong then right) of every decision. After every act:
// - every sprite thing's touch box holds its drawn pixels;
// - every visible thing in noche-sheet.json's things / noche.md's Needs list answers a touch;
// - draw, hud, shadows, and talkAt run without error.
// Over the three stories, every single one of the 25 Needs things answers a touch.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/noche/noche.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Every thing noche-sheet.json / noche.md's Needs list says he can touch (25 things).
const List<String> needs = [
  'television',
  'luz1',
  'luz2',
  'luz3',
  'bufanda',
  'lana',
  'mesa',
  'aparador',
  'bandeja',
  'jugo',
  'flan',
  'queso',
  'frutas',
  'vela',
  'cama',
  'sofa',
  'libro',
  'reloj',
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'perro',
  'coqui',
  'manos_luis',
];

Map<String, dynamic> _story(String id) =>
    jsonDecode(File('test/support/fixtures/noche/$id.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, String> nocheVars(String id, int pick) => switch (id) {
  'prende-y-apaga' =>
    pick == 0
        ? {'qa': 'luis', 'qb': 'carmen', 'wa': 'apaga', 'wb': 'prende'}
        : {'qa': 'carmen', 'qb': 'luis', 'wa': 'prende', 'wb': 'apaga'},
  'antes-y-despues' =>
    pick == 0
        ? {'wa': 'antes', 'wb': 'despues'}
        : {'wa': 'despues', 'wb': 'antes'},
  _ =>
    pick == 0
        ? {'qa': 'luis', 'qb': 'carmen', 'wa': 'acuesta', 'wb': 'descansa'}
        : {'qa': 'carmen', 'qb': 'luis', 'wa': 'descansa', 'wb': 'acuesta'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('noche');
  });
  final answered = <String>{};

  for (final id in const ['prende-y-apaga', 'antes-y-despues', 'se-acuesta']) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createNoche() as Noche;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = {...nocheVars(id, pick)};
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
            expect(
              scene.talkAt('coqui', W),
              isNotNull,
              reason: '$id $at: talkAt(coqui) returned null',
            );
            final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
            for (final en in gente.entries) {
              final p = en.value as Map<String, dynamic>;
              if (p['vis'] == 0) continue;
              expect(
                scene.talkAt(en.key, W),
                isNotNull,
                reason: '$id $at: talkAt(${en.key}) returned null',
              );
            }
            // Verify every visible sprite thing's box holds its drawn pixels
            final its = scene.placed(W, 0);
            for (final k in const [
              'bufanda',
              'lana',
              'libro',
              'jugo',
              'flan',
              'queso',
              'frutas',
              'vela',
              ...NOCHE_PERSONAS,
            ]) {
              final b = scene.box(k, W);
              final t = scene.cosas.firstWhere((t) => t.id == k);
              if ((t.si != null && !t.si!(W)) || b == null) continue;
              final tag = NOCHE_PERSONAS.contains(k) ? 'persona:$k' : 'cosa:$k';
              for (final it in its) {
                if (it.tag != tag) continue;
                for (var py = 0; py < it.s.h; py++) {
                  for (var px = 0; px < it.s.w; px++) {
                    if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
                    final X = it.left + px, Y = it.top + py;
                    if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
                    expect(
                      X >= b[0] &&
                          X < b[0] + b[2] &&
                          Y >= b[1] &&
                          Y < b[1] + b[3],
                      isTrue,
                      reason: '$id $at: $k pixel ($X,$Y) outside box $b',
                    );
                  }
                }
              }
            }
            // Verify every visible thing in Needs answers a touch
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
              expect(
                frogHits,
                isTrue,
                reason: '$id $at: coqui answers no touch',
              );
              answered.add('coqui');
            }
          }

          Future<void> walk(Object? steps) async {
            if (steps is! List) return;
            for (final st in steps) {
              if (st is! Map<String, dynamic>) continue;
              if (st['set'] is Map) {
                host.W.addAll((st['set'] as Map).cast<String, dynamic>());
              } else if (st['act'] is String) {
                final name = st['act'] as String;
                expect(
                  scene.acts.containsKey(name),
                  isTrue,
                  reason: '$id: unknown act $name',
                );
                final o = {for (final e in st.entries) e.key: sub(e.value)};
                await scene.acts[name]!(o);
                host.F += 3;
                acts++;
                if (!jsTruthy(o['suelto'])) await check('after $name (#$acts)');
              } else if (st['ask'] is String) {
                await walk(st['lead']);
                final k = sub(st['ask']) as String;
                final b = scene.box(k, host.W);
                expect(b, isNotNull, reason: '$id: asked thing $k has no box');
                await walk(st['after']);
                await walk(st['then']);
              } else if (st['calc'] is String) {
                final cond = st['cond'] as String;
                final bool okCond;
                if (cond == 'ok') {
                  okCond = v['_ok'] == '1';
                } else {
                  final c = cond.split('=');
                  final lhs = sub('\$${c[0]}') as String;
                  final rhs = sub(c[1]) as String;
                  okCond = lhs == rhs;
                }
                v[st['calc'] as String] =
                    sub(okCond ? st['then'] : st['else']) as String;
              } else if (st['draw'] is String) {
                final dn = st['draw'] as String;
                final ops = st['options'] as List;
                if (ops.length == 1 || !v.containsKey(dn)) {
                  v[dn] = ops.first as String;
                }
              } else if (st['decide'] is String) {
                await walk(st['lead']);
                final pk = sub(st['pick']) as String;
                final ops = [
                  for (final o in st['options'] as List) sub(o) as String,
                ];
                for (final op in ops) {
                  expect(
                    scene.box(op, host.W),
                    isNotNull,
                    reason: '$id: decide option $op has no box',
                  );
                }
                v['x'] = ops.firstWhere((o) => o != pk);
                v['_ok'] = '0';
                await walk(st['wrong']);
                await walk(st['right']);
              } else if (st['if'] is String) {
                final cond = st['if'] as String;
                if (cond == 'ok') {
                  await walk(st['else']);
                  await walk(st['then']);
                } else if (cond.startsWith('lost=')) {
                  await walk(st['then']);
                } else {
                  final parts = cond.split('=');
                  final lhs = sub('\$${parts[0]}') as String;
                  final rhs = sub(parts[1]) as String;
                  await walk(lhs == rhs ? st['then'] : st['else']);
                }
              }
            }
          }

          await check('at start');
          await walk(story['beats']);
          await walk(story['final']);
        },
      );
    }
  }

  test('every one of the 25 Needs things answered a touch', () {
    expect(answered, containsAll(needs));
  });

  test('clock hands in se-acuesta render visibly in front of the wall', () {
    final scene = createNoche() as Noche;
    final engine = scene.places.e;
    final baked = SetBakes(scene).bakeKey('0-1-0-0-0-0');
    final w = <String, dynamic>{
      'story': 107,
      'luz1': 0,
      'luz2': 1,
      'luz3': 0,
      'tele': 0,
      'abierto': 0,
      'oscuro': 0,
      'relojHora': 8,
      'gente': <String, dynamic>{},
    };
    scene.setFramed(engine, baked, w);
    final frame = Uint32List.fromList(baked.pix);
    scene.draw(Ctx(frame, 240, 216), w, 0);
    final rb = scene.places.box('reloj');
    var changed = 0;
    for (var y = rb[1]; y < rb[1] + rb[3]; y++) {
      for (var x = rb[0]; x < rb[0] + rb[2]; x++) {
        final i = y * 240 + x;
        if (frame[i] != baked.pix[i]) changed++;
      }
    }
    expect(changed, greaterThan(4));
  });

  test('perro106 sets Canelo into the paws-on-table pose', () async {
    final story = _story('antes-y-despues');
    final scene = createNoche() as Noche;
    final host = StillHost(scene);
    host.S = story;
    host.W = {...host.W, 'lost': 0, ...scene.fresh(story)};
    await scene.acts['perro106']!({});
    final perro = (host.W['gente'] as Map)['perro'] as Map;
    expect(perro['pose'], 'mesa');
    final placedPerro = scene
        .placed(host.W, 0)
        .firstWhere((it) => it.tag == 'persona:perro');
    expect(placedPerro.s.h, 26);
  });

  test(
    'descansa107 renders feet-up pose distinct from ordinary sitting',
    () async {
      final story = _story('se-acuesta');
      final scene = createNoche() as Noche;
      final host = StillHost(scene);
      host.S = story;
      host.W = {...host.W, 'lost': 0, ...scene.fresh(story)};
      final sitting = scene
          .placed(host.W, 0)
          .firstWhere((it) => it.tag == 'persona:abuelo')
          .s;
      await scene.acts['descansa107']!({'quien': 'abuelo', 'ok': 1});
      await scene.acts['descansa107']!({
        'quien': 'luis',
        'a': 'sofa_pies',
        'ok': 1,
      });
      final abuelo = (host.W['gente'] as Map)['abuelo'] as Map;
      final luis = (host.W['gente'] as Map)['luis'] as Map;
      expect(abuelo['pose'], 'pies');
      expect(luis['pose'], 'pies');
      final feetUp = scene
          .placed(host.W, 0)
          .firstWhere((it) => it.tag == 'persona:abuelo')
          .s;
      expect(feetUp.px, isNot(equals(sitting.px)));
    },
  );

  test('prende-y-apaga draws wool at lap anchor and tracks rolling lanaFx', () {
    final story = _story('prende-y-apaga');
    final scene = createNoche() as Noche;
    final host = StillHost(scene);
    host.S = story;
    host.W = {...host.W, 'lost': 0, ...scene.fresh(story)};
    final items = scene.placed(host.W, 0);
    expect(items.any((it) => it.tag == 'cosa:lana'), isTrue);
    final staticBox = scene.box('lana', host.W);
    expect(staticBox, isNotNull);
    host.W['lanaFx'] = {'x': 120, 'y': 160};
    final movedBox = scene.box('lana', host.W);
    expect(movedBox, [116, 152, 8, 8]);
  });
}
