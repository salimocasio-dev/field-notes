// Every act of El balcón runs on the still host (waits at once, no sound), leaves things where the sheet puts them, and
// its world draws; its shadows are cast as balcon-preview.html casts them; remap gives the sheet's places; the furniture
// in front is drawn again over abuela only where it is nearer than she is.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/balcon/balcon.dart';
import 'package:coqui_scenes/src/balcon/balcon_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Balcon scene;
  final rng = Mulberry32(1);
  setUpAll(() async {
    final sheet = (await ScenePictures(bundle: testBundle()).frameOf('balcon'))
        .scene
        .sheet;
    frame = StillFrame(Balcon(sheet, rng: rng));
    scene = frame.scene as Balcon;
  });

  Map<String, dynamic> fresh({String thing = 'rondas'}) {
    frame.host
      ..fresh()
      ..S = {
        'stake': {'thing': thing, 'steps': 3},
      }
      ..F = 40;
    return frame.host.W;
  }

  Map<String, dynamic> cq() => frame.host.W['cq'] as Map<String, dynamic>;

  test('the frog starts at the sheet\'s jardin, abuela in the doorway', () {
    final W = fresh();
    final j = scene.sheet.frogAt('jardin', scene.projection);
    expect([cq()['x'], cq()['y']], [j.x, j.y]);
    final ab = W['ab'] as Map<String, dynamic>;
    expect([ab['x'], ab['y']], scene.sheet.spots['abuela.puerta']!.ab);
    expect(scene.setKey(W), 'shut-shut');
    W['door'] = 1;
    expect(scene.setKey(W), 'open-shut');
  });

  test('ir takes the frog to the sheet\'s spots; sube to the foot of the steps, then onto the porch', () async {
    fresh();
    for (final k in scene.lugar.keys) {
      await scene.acts['ir']!({'a': k});
      expect([cq()['x'], cq()['y']], scene.lugar[k]!.sublist(0, 2), reason: k);
    }
    fresh();
    await scene.acts['sube']!({});
    expect([cq()['x'], cq()['y']], scene.lugar['balcon']!.sublist(0, 2));
  });

  test('abuela walks to her spots: abentra, absale (to the table), absienta (to her chair)', () async {
    final W = fresh();
    await scene.acts['abentra']!({});
    final ab = W['ab'] as Map<String, dynamic>;
    expect(
      [ab['x'], ab['y'], ab['en'], ab['al']],
      [...scene.AB['puerta']!, 'puerta', 0],
    );
    await scene.acts['absale']!({});
    expect([ab['x'], ab['y'], ab['trae']], [...scene.AB['mesa']!, 1]);
    await scene.acts['pone2']!({});
    expect(
      [for (final v in W['vasos'] as List) (v as Map)['x']]..sort(),
      scene.X2,
    );
    await scene.acts['absienta']!({});
    expect([ab['x'], ab['y'], ab['en']], [...scene.AB['lado']!, 'silla']);
    frame.draw(W, F: 41, cam: scene.CAM['wide']!);
  });

  // one run of each act, from a world where it makes sense, drawn after it
  final runs =
      <String, (void Function(Map<String, dynamic> W), Map<String, dynamic>)>{
        'sube': ((W) {}, {}),
        'absienta': ((W) {}, {}),
        'abentra': ((W) {}, {}),
        'absale': ((W) {}, {}),
        'pone2': ((W) {}, {}),
        'sirve': ((W) {}, {'que': 'sm'}),
        'sirve.gp': ((W) {}, {'que': 'gp'}),
        'coge': ((W) => scene.acts['pone2']!({}), {'en': 'agua'}),
        'suelta': ((W) {}, {}),
        'bebecq': ((W) {}, {}),
        'abcoge': ((W) {}, {'en': 'jugo'}),
        'abbebe': ((W) {}, {}),
        'aveventana': (
          (W) => W['ave'] = <String, dynamic>{
            'mode': 'sit',
            'x': 10,
            'y': 10,
            'st': 'n',
          },
          {},
        ),
        'aveva': ((W) {}, {'en': 'agua'}),
        'avebebe': ((W) {}, {'en': 'agua'}),
        'avesilla': ((W) {}, {}),
        'gana': ((W) {}, {}),
        'marcador': ((W) => W['mios'] = 3, {}),
        'marcador.pierde': ((W) => W['lost'] = 3, {}),
        'lleva': ((W) => scene.acts['pone']!({}), {'en': 'agua'}),
        'bebe': ((W) {}, {}),
        'aparta': (
          (W) => W['abvaso'] = <String, dynamic>{'k': 'jugo', 'lv': 1},
          {},
        ),
        'muestra': ((W) {}, {'en': 'jugo'}),
        'deja': ((W) {}, {}),
        'recoge': ((W) {}, {}),
        'dafan': ((W) {}, {}),
        'fanmesa': ((W) {}, {}),
        'rompe': ((W) {}, {}),
        'ofrece': ((W) {}, {'en': 'agua'}),
        'recibe': ((W) {}, {}),
        'pone': ((W) {}, {}),
        'cqbebe': ((W) {}, {}),
        'cqhielo': (
          (W) => (W['vasos'] as List).add(<String, dynamic>{
            'id': 'mio',
            'k': 'agua',
            't': 'n',
            'lv': 1,
            'x': 140,
            'mano': 1,
          }),
          {},
        ),
        'final': ((W) => W['lost'] = 3, {}),
        'final.fresco': ((W) => W['fresco'] = 2, {}),
        'fin': ((W) {}, {}),
        'burbuja': ((W) {}, {'quien': 'cq', 'que': 'calor'}),
        'calla': ((W) {}, {}),
        'pose': ((W) {}, {'que': 'wave'}),
      };
  test('every act of balcon.js has a run here', () {
    expect(
      runs.keys.map((k) => k.split('.').first).toSet(),
      scene.acts.keys.toSet().difference({'ir'}),
    );
  });
  // the acts in their order, on one world, as a story strings them (abuela in her chair from absienta on)
  test('each act runs and its world draws', () async {
    final W = fresh(thing: 'calor');
    W['door'] = 1;
    for (final r in runs.entries) {
      r.value.$1(W);
      await scene.acts[r.key.split('.').first]!(r.value.$2);
      W['termo'] = 1;
      W['rondas'] = 1;
      frame.draw(W, F: 41, cam: scene.CAM['wide']!);
    }
  });

  test('stake: the bird gets a glass; the heat climbs', () async {
    final W = fresh();
    await scene.stake(1, 3, 'jugo');
    expect(W['vsuyos'], ['agua']);
    final w2 = fresh(thing: 'calor');
    w2['lost'] = 1;
    await scene.stake(1, 3, 'jugo');
    expect([w2['rojo'], w2['sudor']], [40, 3]);
  });

  test('remap: the positions of the files through the sheet', () {
    final e = scene.projection;
    expect(scene.remap([84, 129]), scene.lugar['abuela']);
    expect(scene.remap([94, 147]), scene.sheet.spots['abuela.lado']!.ab);
    expect(scene.remap([106, 148]), scene.sheet.spots['abuela.camina']!.ab);
    expect(scene.remap([120, 86]), scene.PERCH);
    expect(scene.remap([120]), [scene.sheet.remapX(120)]);
    expect(scene.remap([80]), [80]);
    expect(
      scene.remap([86, 98, 68, 36.1]),
      scene.sheet.pictures['vaso.si']!.crop,
    );
    expect(scene.sheet.viewOf('wide', e), scene.CAM['wide']);
    expect(() => scene.remap([1, 2]), throwsA(isA<SheetError>()));
  });

  group('shadows, as balcon-preview.html casts them', () {
    Map<String, dynamic> world({Object? frogAl = 1, Map<String, dynamic>? ab}) {
      final W = ScenePictures.pictureW(scene, const {});
      W['cq'] = <String, dynamic>{
        ...(W['cq'] as Map<String, dynamic>),
        'x': scene.lugar['balcon']![0],
        'y': scene.lugar['balcon']![1],
        'vis': 1,
        'al': frogAl,
      };
      W['ab'] = ab;
      return W;
    }

    test('the frog: one while seen and more than half in, none on the small chair\'s seat', () {
      expect(scene.shadows(world()), hasLength(1));
      expect(scene.shadows(world()).single.r, .45);
      for (final al in [.5, 0, null]) {
        expect(scene.shadows(world(frogAl: al)), isEmpty, reason: 'al $al');
      }
      final W = world();
      final L = scene.lugar['silla_pequena']!;
      (W['cq'] as Map<String, dynamic>)
        ..['x'] = L[0]
        ..['y'] = L[1];
      expect(scene.shadows(W), isEmpty);
    });

    test('abuela: five while standing (no al or more than half), none in her chair', () {
      Map<String, dynamic> ab(String en, [Object? al]) => {
        'en': en,
        'x': scene.AB['mesa']![0],
        'y': scene.AB['mesa']![1],
        'al': al,
      };
      expect(scene.shadows(world(ab: ab('camina'))), hasLength(6));
      expect(scene.shadows(world(ab: ab('puerta', 1))), hasLength(6));
      expect(scene.shadows(world(ab: ab('puerta', .4))), hasLength(1));
      expect(scene.shadows(world(ab: ab('silla', 1))), hasLength(1));
      expect(
        [for (final s in scene.shadows(world(ab: ab('camina')))) s.z].skip(1),
        [.3, .65, 1, 1.35, 1.7],
      );
    });
  });

  test('the furniture in front: the table drawn again over abuela where it is nearer than she is, and only there', () {
    // abuela walking behind the table (her feet above the sheet's `behind`: drawn before the furniture, balcon.js:126)
    final W = fresh();
    final ab = W['ab'] as Map<String, dynamic>
      ..['en'] = 'camina'
      ..['x'] = 128
      ..['y'] = scene.BEHIND - 6;
    frame.draw(W, F: 8, cam: scene.CAM['wide']!);
    final withAb = Uint32List.fromList(frame.picture);
    W['ab'] = null;
    frame.draw(W, F: 8, cam: scene.CAM['wide']!);
    final none = Uint32List.fromList(frame.picture);
    W['ab'] = ab;
    // the table's own pixels (balcon-set.html part "mesa") and the depth test of the sheet's front
    final e = balconEngine(), b = PpBuild(e);
    final s = BalconSet(e, b, const BalconState());
    s.k.PART_TAGS = List<String?>.filled(240 * 216, null);
    s.buildSet();
    final tags = s.k.PART_TAGS!, Z = e.bakedZ;
    final COS = math.sqrt(3) / 2, T30 = math.tan(math.pi / 6);
    final u = (128 - e.OX) / e.S,
        v = (scene.BEHIND - 6 - 1 - e.OY + .3 * COS * e.S) / (e.S * .5);
    final vAb = ((u + v) / math.sqrt2 + (v - u) / math.sqrt2) / math.sqrt2;
    var nearer = 0, hers = 0;
    for (var y = scene.BEHIND - 6 - 50; y < scene.BEHIND - 6; y++) {
      for (var x = 128 - 30; x < 128 + 30; x++) {
        final i = y * 240 + x;
        if (tags[i] == 'mesa' &&
            Z[i] > vAb / COS - (y + .5 - e.OY) * T30 / e.S) {
          nearer++;
          // the table's pixel, not hers
          expect(withAb[i], none[i], reason: 'pixel $x, $y');
        } else if (withAb[i] != none[i]) {
          hers++;
        }
      }
    }
    expect(nearer, greaterThan(0));
    expect(hers, greaterThan(0));
  });
}
