// El pedido's acts on StillHost: each story's steps walked in order with two sets of draw values, running both
// branches (wrong then right) of every decision. After every act:
// - every sprite thing's touch box holds its drawn pixels;
// - every visible thing in pedido.md's Needs list (23 things) answers a touch;
// - draw, hud, shadows, and talkAt run without error.
// Over the three stories, all 23 Needs things answer a touch and all 12 speakers have non-null talkAt.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/pedido/pedido.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Every thing pedido.md's Needs list says he can touch (23 things).
const List<String> needs = [
  'cuadro1',
  'cuadro2',
  'cuadro3',
  'cuadro4',
  'bebidas',
  'plato1',
  'plato2',
  'plato3',
  'bebida1',
  'bebida2',
  'bebida3',
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'mesera',
  'mesero',
  'cocinero',
  'coqui',
  'platanos',
  'platito',
  'vasito',
  'gato',
];

Map<String, dynamic> _story(String id) =>
    jsonDecode(File('test/support/fixtures/pedido/$id.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('pedido');
  });
  final answered = <String>{};
  final speakersSeen = <String>{};

  for (final id in const [
    'que-hay-de-comer',
    'tostones-y-mofongo',
    'las-bebidas',
  ]) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createPedido() as Pedido;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = <String, String>{};
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
            // Record every visible speaker's talkAt (and assert non-null while visible)
            final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
            for (final spk in PEDIDO_SPEAKERS) {
              if (spk == 'coqui') {
                if (jsTruthy((W['cq'] as Map?)?['vis'])) {
                  expect(
                    scene.talkAt(spk, W),
                    isNotNull,
                    reason: '$id $at: talkAt(coqui) returned null',
                  );
                  speakersSeen.add(spk);
                }
              } else {
                final p = gente[spk] as Map<String, dynamic>?;
                if (p != null && p['vis'] != 0) {
                  expect(
                    scene.talkAt(spk, W),
                    isNotNull,
                    reason: '$id $at: talkAt($spk) returned null while visible',
                  );
                  speakersSeen.add(spk);
                }
              }
            }
            // Verify every visible sprite thing's box holds its drawn pixels
            final its = scene.items(W, 0);
            for (final k in const [
              'plato1',
              'plato2',
              'plato3',
              'platito',
              'bebida1',
              'bebida2',
              'bebida3',
              'vasito',
              'platanos',
              'gato',
              'abuela',
              'abuelo',
              'luis',
              'carmen',
              'mesera',
              'mesero',
              'cocinero',
            ]) {
              final b = scene.box(k, W);
              final t = scene.cosas.firstWhere((t) => t.id == k);
              if ((t.si != null && !t.si!(W)) || b == null) continue;
              final tag =
                  const [
                    'abuela',
                    'abuelo',
                    'luis',
                    'carmen',
                    'mesera',
                    'mesero',
                    'cocinero',
                  ].contains(k)
                  ? 'persona:$k'
                  : 'cosa:$k';
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
              } else if (st['draw'] is String) {
                final name = st['draw'] as String;
                final ops = [for (final o in st['options'] as List) '$o'];
                final chosen = ops[pick % ops.length];
                v[name] = chosen;
                if (st['other'] is String) {
                  v[st['other'] as String] = ops.firstWhere((o) => o != chosen);
                }
              } else if (st['reparte'] is List) {
                final names = (st['reparte'] as List).cast<String>();
                final ops = [for (final o in st['options'] as List) '$o'];
                for (var i = 0; i < names.length; i++) {
                  v[names[i]] = ops[(i + pick) % ops.length];
                }
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
                await walk(st['wrong']);
                await walk(st['right']);
              } else if (st['calc'] is String) {
                final c = (st['cond'] as String).split('=');
                final lhs = v[c[0]] ?? c[0];
                final rhs = sub(c[1]) as String;
                v[st['calc'] as String] =
                    sub(lhs == rhs ? st['then'] : st['else']) as String;
              } else if (st['if'] is String) {
                final cond = st['if'] as String;
                if (cond.contains('=') && !cond.startsWith('lost=')) {
                  final c = cond.split('=');
                  final lhs = v[c[0]] ?? c[0];
                  final rhs = sub(c[1]) as String;
                  await walk(lhs == rhs ? st['then'] : st['else']);
                } else {
                  await walk(st['then']);
                  await walk(st['else']);
                }
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

  test('every thing in pedido.md Needs list (23) answered a touch', () {
    expect(answered, containsAll(needs));
    expect(needs.length, 23);
  });

  test('all 12 speakers had non-null talkAt while visible', () {
    expect(speakersSeen, containsAll(PEDIDO_SPEAKERS));
    expect(PEDIDO_SPEAKERS.length, 12);
  });

  ({Pedido scene, StillFrame frame, _ProbeHost host}) boot(String id) {
    final story = _story(id);
    final scene = createPedido() as Pedido;
    final frame = StillFrame(scene);
    final host = _ProbeHost(scene, frame);
    host.S = story;
    host.W = {
      ...host.W,
      'lost': 0,
      'resp': null,
      'twinkle': null,
      ...scene.fresh(story),
    };
    return (scene: scene, frame: frame, host: host);
  }

  test('cabeza and senala honor target direction, self-point, and sheet coordinates mid-gesture', () async {
    final (:scene, frame: _, :host) = boot('las-bebidas');
    await scene.acts['sale']!({'quien': 'carmen'});
    await scene.acts['llega']!({'quien': 'mesero', 'a': 'junto_mesa'});
    final abueloX = scene.places.screen('silla1')[0];
    final abuelaX = scene.places.screen('silla2')[0];
    final luisX = scene.places.screen('silla3')[0];

    Future<_GestureSnap> cap(String quien, Map<String, dynamic> act) async {
      host.arm(quien);
      await scene.acts['gesto']!(act);
      final c = host.captured!;
      final p = (host.W['gente'] as Map)[quien] as Map;
      expect(host.W['gestoCue'], isNull);
      expect([p['pose'], p['dx'], p['dy']], ['idle', 0, 0]);
      return c;
    }

    final cabAbuelo = await cap('luis', {
      'quien': 'luis',
      'que': 'cabeza',
      'a': 'abuelo',
    });
    final cabAbuela = await cap('abuelo', {
      'quien': 'abuelo',
      'que': 'cabeza',
      'a': 'abuela',
    });
    expect(
      [
        cabAbuelo.cue['a'],
        cabAbuelo.cue['dir'],
        cabAbuelo.cue['cueX'],
        cabAbuelo.dx,
        cabAbuelo.dy,
      ],
      ['abuelo', -1, abueloX, -2, 1],
    );
    expect(
      [
        cabAbuela.cue['a'],
        cabAbuela.cue['dir'],
        cabAbuela.cue['cueX'],
        cabAbuela.dx,
        cabAbuela.dy,
      ],
      ['abuela', 1, abuelaX, 2, 1],
    );
    expect(_pixelsEqual(cabAbuelo.pixels, cabAbuela.pixels), isFalse);

    final senAbuelo = await cap('luis', {
      'quien': 'luis',
      'que': 'senala',
      'a': 'abuelo',
    });
    final senAbuela = await cap('luis', {
      'quien': 'luis',
      'que': 'senala',
      'a': 'abuela',
    });
    final senLuis = await cap('luis', {
      'quien': 'luis',
      'que': 'senala',
      'a': 'luis',
    });
    expect(
      [
        senAbuelo.pose,
        senAbuelo.cue['a'],
        senAbuelo.cue['self'],
        senAbuelo.cue['dir'],
        senAbuelo.cue['cueX'],
      ],
      ['senala_izq', 'abuelo', false, -1, abueloX],
    );
    expect(
      [
        senAbuela.pose,
        senAbuela.cue['a'],
        senAbuela.cue['self'],
        senAbuela.cue['dir'],
        senAbuela.cue['cueX'],
      ],
      ['senala_izq', 'abuela', false, -1, abuelaX],
    );
    expect(
      [
        senLuis.pose,
        senLuis.cue['a'],
        senLuis.cue['self'],
        senLuis.cue['dir'],
        senLuis.cue['cueX'],
      ],
      ['yo', 'luis', true, 0, luisX],
    );
    expect(_pixelsEqual(senAbuelo.pixels, senAbuela.pixels), isFalse);
    expect(_pixelsEqual(senAbuelo.pixels, senLuis.pixels), isFalse);
    expect(_pixelsEqual(senAbuela.pixels, senLuis.pixels), isFalse);

    final senBoard = await cap('mesero', {
      'quien': 'mesero',
      'que': 'senala',
      'a': 'bebidas',
    });
    final bBox = scene.places.box('bebidas');
    expect(
      [
        senBoard.pose,
        senBoard.cue['a'],
        senBoard.cue['up'],
        senBoard.cue['cueX'],
      ],
      ['senala_der', 'bebidas', true, bBox[0] + bBox[2] ~/ 2],
    );
    expect(senBoard.cue['cueY'], greaterThanOrEqualTo(42));
  });

  test('da89(ok: 0) keeps selected wrong drink lifted and distinct through correction until sorbo89', () async {
    final (:scene, :frame, :host) = boot('las-bebidas');
    await scene.acts['sale']!({'quien': 'carmen'});
    await scene.acts['llega']!({'quien': 'mesero', 'a': 'junto_mesa'});
    await scene.acts['bandeja89']!({'orden': 'refresco,limonada,cafe'});
    Uint32List snap() {
      frame.draw(host.W, F: host.F, cam: host.cam);
      return Uint32List.fromList(frame.display);
    }

    await scene.acts['da89']!({'que': 'limonada', 'a': 'abuelo', 'ok': 0});
    expect(
      [host.W['alzaBebida'], host.W['da89Dx'], host.W['da89Dy']],
      ['limonada', 0, 0],
    );
    final wrongLim = snap();

    await scene.acts['da89']!({'que': 'cafe', 'a': 'abuelo', 'ok': 0});
    expect(
      [host.W['alzaBebida'], host.W['da89Dx'], host.W['da89Dy']],
      ['cafe', 0, 0],
    );
    final wrongCafe = snap();
    expect(_pixelsEqual(wrongLim, wrongCafe), isFalse);

    await scene.acts['sorbo89']!({});
    expect(host.W['alzaBebida'], isNull);
    expect(_pixelsEqual(wrongCafe, snap()), isFalse);
  });

  test('pide88(ok: 0) and platanos decrement cook a replacement plate from a plantain', () async {
    final (:scene, frame: _, :host) = boot('tostones-y-mofongo');
    await scene.acts['llega']!({'quien': 'joven', 'a': 'otra_mesa'});
    await scene.acts['tablero88']!({
      'orden': 'carne_tostones,carne_mofongo,pescado_tostones,pescado_mofongo',
    });

    host.resetTrace();
    await scene.acts['pide88']!({'cual': 'cuadro1', 'ok': 0});
    expect(host.props, containsAllInOrder(['platano', 'sarten']));
    expect(host.sawLlama, isTrue);
    expect(
      host.plates,
      containsAllInOrder(['carne_tostones', 'carne_mofongo']),
    );
    expect(
      [
        host.W['cocineroProp'],
        host.W['llamaFx'],
        host.W['campanaFx'],
        (host.W['repisa'] as List)[0],
      ],
      [null, 0, 0, null],
    );

    host.resetTrace();
    await scene.acts['platanos']!({'n': 2});
    expect(host.W['platanos'], 2);
    expect(host.props, containsAllInOrder(['platano', 'sarten']));
    expect(host.sawLlama, isTrue);
    expect(host.plates, isNotEmpty);
    expect(
      [
        host.W['cocineroProp'],
        host.W['llamaFx'],
        host.W['campanaFx'],
        (host.W['repisa'] as List)[0],
      ],
      [null, 0, 0, null],
    );
  });
}

typedef _GestureSnap = ({
  Uint32List pixels,
  Map<String, dynamic> cue,
  String pose,
  int dx,
  int dy,
});

bool _pixelsEqual(Uint32List a, Uint32List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _ProbeHost extends StillHost {
  _ProbeHost(super.scene, this.frame);

  final StillFrame frame;
  String? _watchWho;
  _GestureSnap? captured;
  final List<String> props = [];
  final List<String> plates = [];
  bool sawLlama = false;

  void arm(String who) {
    _watchWho = who;
    captured = null;
  }

  void resetTrace() {
    props.clear();
    plates.clear();
    sawLlama = false;
  }

  @override
  Future<void> wait(num ms) async {
    final prop = W['cocineroProp'] as String?;
    if (prop != null) props.add(prop);
    if ((W['llamaFx'] as num?)?.toInt() == 1) sawLlama = true;
    final rep = W['repisa'] as List?;
    if (rep != null && rep.isNotEmpty && rep[0] is String) {
      plates.add(rep[0] as String);
    }
    if (_watchWho != null && captured == null) {
      final p = (W['gente'] as Map)[_watchWho!] as Map;
      final cue = Map<String, dynamic>.from(
        (W['gestoCue'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      frame.draw(W, F: F, cam: cam);
      captured = (
        pixels: Uint32List.fromList(frame.display),
        cue: cue,
        pose: (p['pose'] as String?) ?? 'idle',
        dx: (p['dx'] as num?)?.toInt() ?? 0,
        dy: (p['dy'] as num?)?.toInt() ?? 0,
      );
      _watchWho = null;
    } else {
      frame.draw(W, F: F, cam: cam);
    }
  }
}
