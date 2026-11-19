// Every act of El frente runs on the still host (waits at once, no sound) and leaves things where the sheet puts them.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/frente/frente.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Frente scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('frente');
    scene = frame.scene as Frente;
  });

  Map<String, dynamic> fresh() {
    frame.host
      ..fresh()
      ..S = {
        'stake': {'thing': 'nube', 'steps': 2},
      }
      ..F = 40;
    return frame.host.W;
  }

  Map<String, dynamic> cq() => frame.host.W['cq'] as Map<String, dynamic>;

  test(
    'the frog starts where the sheet puts him (juego.js:16 -> spot inicio)',
    () {
      fresh();
      final f = scene.sheet.frogAt('inicio', scene.projection);
      expect([cq()['x'], cq()['y'], cq()['s']], [f.x, f.y, f.scale]);
    },
  );

  test('ir and atras take the frog to the sheet\'s spots', () async {
    fresh();
    for (final k in scene.lugar.keys) {
      await scene.acts['ir']!({'a': k});
      expect([cq()['x'], cq()['y']], scene.lugar[k]!.sublist(0, 2), reason: k);
    }
    await scene.acts['atras']!({});
    expect([cq()['x'], cq()['y']], scene.lugar['patio']!.sublist(0, 2));
  });

  // one run of each act, from a world where it makes sense, drawn after it
  final runs =
      <String, (void Function(Map<String, dynamic> W), Map<String, dynamic>)>{
        'tocar': ((W) {}, {'en': 'puerta'}),
        'luz': ((W) {}, {}),
        'dentro': ((W) {}, {'en': 'ventana'}),
        'calla': ((W) {}, {}),
        'burbuja': ((W) {}, {'quien': 'cq', 'que': 'hola'}),
        'pose': (
          (W) => W['ab'] = <String, dynamic>{
            'en': 'puerta',
            'pose': 'idle',
            'bub': null,
            'al': 1,
          },
          {'que': 'wave'},
        ),
        'abre': ((W) {}, {'que': 'puerta'}),
        'abre.ventana': ((W) {}, {'que': 'ventana'}),
        'entra': (
          (W) => W['ab'] = <String, dynamic>{
            'en': 'puerta',
            'pose': 'idle',
            'bub': null,
            'al': 1,
          },
          {'por': 'puerta'},
        ),
        'entra.ventana': ((W) {}, {'por': 'ventana'}),
        'trueno': ((W) {}, {}),
        'llueve': ((W) => W['nube'] = <String, dynamic>{'x': 22, 'tx': 22}, {}),
        'gotas': ((W) {}, {}),
        'cuadro': ((W) {}, {}),
        'abrir': ((W) {}, {'que': 'ventana'}),
        'cerrar': ((W) {}, {'en': 'puerta'}),
        'abcierra': ((W) {}, {'que': 'ventana'}),
        'vete': ((W) {}, {}),
        'asoma': ((W) {}, {}),
        'baja': ((W) {}, {}),
        'pajaro': ((W) {}, {}),
        'bonk': (
          (W) => W['ave'] = <String, dynamic>{'mode': 'circle', 'st': 'n'},
          {'en': 'ventana'},
        ),
        'posa': (
          (W) => W['ave'] = <String, dynamic>{'mode': 'circle', 'st': 'n'},
          {'en': 'puerta'},
        ),
        'come': ((W) => W['plato'] = 3, {}),
        'regala': (
          (W) {
            W['plato'] = 3;
            W['ave'] = <String, dynamic>{'mode': 'circle', 'st': 'n'};
          },
          {},
        ),
        'fin2': (
          (W) => W['ave'] = <String, dynamic>{'mode': 'circle', 'st': 'n'},
          {},
        ),
        'tapa': ((W) {}, {}),
        'mueve': ((W) => W['escondite'] = 1, {'que': 'palma'}),
        'mira': ((W) => W['escondite'] = 1, {'en': 'palma_pequena'}),
        'sale': ((W) => W['escondite'] = 1, {'en': 'casa_pequena'}),
        'gana': ((W) {}, {}),
        'limpia': ((W) {}, {}),
        'tapate': ((W) {}, {}),
        'esconde': ((W) => W['escondite'] = 1, {'en': 'casa_grande'}),
        'esconde.casita': ((W) => W['escondite'] = 1, {'en': 'casa_pequena'}),
        'busca_ave': (
          (W) {
            W['escondite'] = 1;
            W['ave'] = <String, dynamic>{'mode': 'circle', 'st': 'n'};
          },
          {'en': 'casa_pequena'},
        ),
        'atardece': ((W) {}, {}),
        'devuelve': ((W) => W['lost'] = 1, {}),
        'avecasa': ((W) {}, {}),
        'abentra': (
          (W) => W['ab'] = <String, dynamic>{
            'en': 'paso',
            'pose': 'idle',
            'bub': null,
            'al': 1,
          },
          {},
        ),
        'marcador': ((W) {}, {}),
        'vetecq': ((W) {}, {}),
        'fin': ((W) {}, {}),
      };
  test('every act of frente.js has a run here', () {
    expect(
      runs.keys.map((k) => k.split('.').first).toSet(),
      scene.acts.keys.toSet().difference({'ir', 'atras'}),
    );
  });
  for (final r in runs.entries) {
    test('${r.key} runs and its world draws', () async {
      final W = fresh();
      r.value.$1(W);
      await scene.acts[r.key.split('.').first]!(r.value.$2);
      frame.draw(W, F: 41, cam: frame.host.cam);
    });
  }

  test('stake: the cloud comes closer, then it rains; the cake: the bird takes a slice', () async {
    final W = fresh();
    await scene.acts['trueno']!({});
    await scene.stake(1, 2, 'puerta');
    expect((W['nube'] as Map)['tx'], 76);
    await scene.stake(2, 2, 'puerta');
    expect(W['rain'], 1);
    final w2 = fresh();
    frame.host.S = {
      'stake': {'thing': 'bizcocho', 'steps': 3},
    };
    w2['plato'] = 3;
    w2['ave'] = <String, dynamic>{'mode': 'circle', 'st': 'n'};
    await scene.stake(1, 3, 'ventana');
    expect(w2['plato'], 2);
    frame.draw(w2, F: 41, cam: frame.host.cam);
  });

  test('remap: the positions of the files through the sheet', () {
    expect(scene.remap([146, 86]).sublist(0, 2), [
      scene.sheet.frogAt('hola', scene.projection).x,
      scene.sheet.frogAt('hola', scene.projection).y,
    ]);
    expect(scene.remap([0, 0]), [0, 0]);
    expect(
      scene.remap([30, 0, 196, 216]),
      scene.sheet.viewOf('wide@donde-esta-el-pajaro', scene.projection),
    );
    expect(scene.remap([52, 8, 180, 96]), [44, 0, 196, 104]);
    expect(scene.remap([143.36, 46, 45.28, 50]), [44, 49, 196, 104]);
    expect(scene.remap([166]), [145]);
    expect(() => scene.remap([1, 2]), throwsA(isA<SheetError>()));
  });
}
