// La nevera's touch boxes. (1) Every thing of the set lies inside its touch box: in all ten reached states, each pixel
// the fridge's parts drew (set-kit.js `part`: `nevera`, `nevera.dentro`, `nevera.puerta`) is inside the fridge's box for
// that state (moves line 15: NEVERA[W.nev.abierta]), and with the fridge open each pixel of its inside is inside the box of
// its inside (FRUTAS[W.nev.cajonver]); the kitchen's box is nevera.js's, its hint box inside it; each set thing's hand and
// hint box inside its box, in every state. (2) Every thing of the sprite layer the sheet moved lies inside its box: the
// things on the fridge's shelves (HUECO), the basket on its top, the cups, the net, the jug, the butter, the tray's roll and
// plate on the counter and the cups on the sill (each drawn alone, the pixels that change against the same picture with
// nothing on it: inside the box with its slack), but where the old file's own box leaves part of its sprite out (listed in
// [asOld]). (3) hit, in the kit's order, gives each thing's key at the middle of its box when it shows, but where the old
// order gives the point to a thing tested before it (listed in [shadowedBy]). The people's boxes (caja) are relative to
// them, as in the old file (code line 126; whoever is outside: the window's glass at their x, moves).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/nevera/nevera.dart';
import 'package:coqui_scenes/src/nevera/nevera_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// The middles hit gives to another thing, because the kit tests that thing first, each with why.
const Map<String, String> shadowedBy = {};

/// What the old file's own box leaves out of its sprite (the box and the sprite are placed relative to each other as in
/// nevera.js; only their row moved), each a test of the pixels outside it and why.
final Map<String, (bool Function(int x, int y, List<num> b), String)> asOld = {
  'jarra': (
    (x, y, b) => true,
    'the jug: its sprite is 23 x 29, drawn round x by its foot, the box of a thing with no name 18 x 23 from x - 9, y - 19 '
        '(nevera.js:83, :130, :131)',
  ),
  't_fruta': (
    (x, y, b) => x == b[0] - 1 || x == b[0] + b[2],
    'the plate of fruit: its sprite is 22 wide round x, from x - 11 to x + 10, the box 18 wide from x - 9, its slack 1 '
        '(nevera.js:63, :130)',
  ),
  'mant': (
    (x, y, b) => x == b[0] - 1 || x == b[0] + b[2],
    'the butter\'s dish: its sprite is 20 wide round x, from x - 10 to x + 9, the box 18 wide from x - 9, with no slack '
        '(nevera.js:46, :130, :131)',
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Nevera scene;
  late StillFrame frame;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('nevera');
    scene = frame.scene as Nevera;
  });
  final rows = <String>[];

  bool inside(List<num> b, num x, num y) =>
      x >= b[0] && x < b[0] + b[2] && y >= b[1] && y < b[1] + b[3];

  Map<String, dynamic> wOf(NeveraState st) => {
    'nev': {
      'abierta': st.nev,
      'cajon': st.cajon == 1 ? 1 : 0,
      'cajonver': st.cajon == 2 ? 1 : 0,
    },
    'pila': st.pila == '0' ? null : st.pila,
    'banco': st.banco ? 1 : 0,
  };

  test('the ten reached states: every pixel of the fridge inside its box, its inside in its own; hands and hint boxes', () {
    final keys = [for (final b in scene.sheet.setKey.baked) b.key!];
    expect(keys, hasLength(10));
    for (final key in keys) {
      final st = NeveraState.fromKey(key), w = wOf(st);
      expect(scene.setKey(w), key);
      final e = neveraEngine(), s = NeveraSet(e, PpBuild(e), st);
      s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
      s.buildSet();
      final tags = s.k.PART_TAGS!, box = scene.box('nevera', w)!;
      var n = 0, out = 0, nIn = 0, outIn = 0;
      final fb = st.nev == 1 ? scene.box('frutas', w)! : null;
      for (var i = 0; i < tags.length; i++) {
        final t = tags[i];
        if (t == null || !t.startsWith('nevera')) continue;
        final x = i % e.W, y = i ~/ e.W;
        n++;
        if (!inside(box, x, y)) out++;
        if (fb != null && t == 'nevera.dentro') {
          nIn++;
          if (!inside(fb, x, y)) outIn++;
        }
      }
      rows.add(
        '$key nevera: $n px, $out outside $box${fb == null ? '' : '; its inside: $nIn px, $outIn outside $fb'}',
      );
      expect(n, greaterThan(0));
      expect(out, 0, reason: key);
      expect(outIn, 0, reason: key);
      // the hands and the hint boxes the state shows (nevera-preview.html hb: by the set's key)
      scene.host.W.clear();
      scene.host.W.addAll({...scene.fresh(const {}), ...w});
      for (final k in ['nevera', 'cocina', if (st.nev == 1) 'frutas']) {
        final b = scene.box(k, w)!, h = scene.handAt(k)!;
        final hb = scene.cosa(k)!.hintBox ?? b;
        expect(
          inside(b, h[0], h[1]),
          isTrue,
          reason: '$key $k: its hand $h in $b',
        );
        expect(
          hb[0] >= b[0] &&
              hb[1] >= b[1] &&
              hb[0] + hb[2] <= b[0] + b[2] &&
              hb[1] + hb[3] <= b[1] + b[3],
          isTrue,
          reason: '$key $k: its hint box $hb in $b',
        );
      }
    }
    expect(scene.box('cocina', const {}), [22, 16, 196, 198]);
  });

  // a W with nothing anywhere, the fridge as [nev] says, the stool there, nobody, the frog away
  Map<String, dynamic> empty([Map<String, dynamic> nev = const {}]) {
    final w = <String, dynamic>{
      'spot': null,
      'twinkle': null,
      'fx': <Map<String, dynamic>>[],
      'heart': 0,
      'lost': 0,
      'resp': null,
      ...scene.fresh(const {}),
      'nev': {'abierta': 0, 'h': <dynamic>[], ...nev},
    };
    (w['cq'] as Map)['vis'] = 0;
    return w;
  }

  List<int> drawn(Map<String, dynamic> w, Map<String, dynamic> nev) {
    final cam = scene.CAM['wide']!;
    frame.draw(empty(nev), F: 0, cam: cam, tick: 0, allSigns: false);
    final before = [...frame.picture];
    frame.draw(w, F: 0, cam: cam, tick: 0, allSigns: false);
    return [
      for (var i = 0; i < before.length; i++)
        if (frame.picture[i] != before[i]) i,
    ];
  }

  // each thing alone, where the stories put it: (the fridge as it is, how W holds the thing)
  final open = <String, dynamic>{'abierta': 1};
  final things =
      <String, (Map<String, dynamic>, void Function(Map<String, dynamic> w))>{
        for (final k in const ['leche', 'queso', 'mantequilla'])
          for (final at in const [0, 1, 2, 3])
            '$k@$at': (
              open,
              (w) {
                final h = <dynamic>[null, null, null, null];
                h[at] = {'k': k, 'v': 3};
                (w['nev'] as Map)['h'] = h;
              },
            ),
        'cesta': (const {}, (w) => w['cesta'] = {'n': 3}),
        for (final (id, x) in const [
          ('v_rojo', 170),
          ('v_azul', 180),
          ('v_verde', 191),
          ('v_amarillo', 201),
        ])
          id: (
            const {},
            (w) => w['cosas'] = [
              {
                'id': id,
                'k': 'vaso',
                'v': id.substring(2),
                'x': x,
                'y': scene.CT(x),
                'z': 100,
                'n': 1,
              },
            ],
          ),
        for (final (id, x) in const [('v_rojo', 187), ('v_azul', 199)])
          '$id@sill': (
            const {},
            (w) => w['cosas'] = [
              {
                'id': id,
                'k': 'vaso',
                'v': id.substring(2),
                'x': x,
                'y': scene.SL(x),
                'z': 100,
                'n': 1,
              },
            ],
          ),
        'red': (
          const {},
          (w) => w['cosas'] = [
            {
              'id': 'red',
              'k': 'red',
              'v': 4,
              'x': 142,
              'y': scene.CT(142),
              'z': 100,
            },
          ],
        ),
        'jarra': (
          const {},
          (w) => w['cosas'] = [
            {
              'id': 'jarra',
              'k': 'jarra',
              'v': 3,
              'x': 156,
              'y': scene.CT(156),
              'z': 100,
            },
          ],
        ),
        'mant': (
          const {},
          (w) => w['cosas'] = [
            {
              'id': 'mant',
              'k': 'mantequilla',
              'v': 3,
              'x': 178,
              'y': scene.SL(178),
              'z': 90,
            },
          ],
        ),
        for (final x in const [187, 205]) ...{
          't_pan@$x': (
            const {},
            (w) => w['cosas'] = [
              {
                'id': 't_pan',
                'k': 'panecillo',
                'x': x,
                'y': scene.CT(x) - 1,
                'z': 120,
              },
            ],
          ),
          't_fruta@$x': (
            const {},
            (w) => w['cosas'] = [
              {
                'id': 't_fruta',
                'k': 'platofruta',
                'x': x,
                'y': scene.CT(x),
                'z': 120,
              },
            ],
          ),
        },
      };
  for (final en in things.entries) {
    test('${en.key}: every pixel it draws is inside its box (with its slack)', () {
      final k = en.key.split('@')[0];
      final w = empty(en.value.$1);
      en.value.$2(w);
      final px = drawn(w, en.value.$1),
          b = scene.box(k, w)!,
          t = scene.cosa(k)!;
      final m = t.m ?? 3, bm = [b[0] - m, b[1] - m, b[2] + 2 * m, b[3] + 2 * m];
      final outside = px.where((i) => !inside(bm, i % 240, i ~/ 240)).toList();
      final old = asOld[k];
      final out = outside
          .where((i) => old == null || !old.$1(i % 240, i ~/ 240, bm))
          .toList();
      rows.add(
        '${en.key}: ${px.length} px, ${outside.length} outside $b (slack $m)${old == null ? '' : ', as the old: ${old.$2}'}',
      );
      expect(px, isNotEmpty);
      expect(
        out,
        isEmpty,
        reason:
            '${en.key}: ${[
              for (final i in out.take(12)) [i % 240, i ~/ 240],
            ]} outside $bm',
      );
      expect(t.si!(w), isTrue);
    });
  }

  test('hit gives each thing at the middle of its box', () {
    for (final en in {
      ...things,
      'nevera': (const <String, dynamic>{}, (Map<String, dynamic> w) {}),
      'frutas': (open, (Map<String, dynamic> w) {}),
      'cocina': (const <String, dynamic>{}, (Map<String, dynamic> w) {}),
    }.entries) {
      final k = en.key.split('@')[0];
      final w = empty(en.value.$1);
      en.value.$2(w);
      final b = scene.box(k, w)!;
      final got = scene.hit(b[0] + b[2] / 2, b[1] + b[3] / 2, w);
      rows.add('hit ${en.key} at its middle: $got');
      if (got != k) {
        expect(
          shadowedBy.containsKey('$k -> $got'),
          isTrue,
          reason: '${en.key}: $got',
        );
      }
    }
  });
  tearDownAll(() => report('nevera-boxes', rows));
}
