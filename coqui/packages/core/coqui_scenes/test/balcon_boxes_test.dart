// El balcón's touch boxes. (1) Every thing of the set lies inside its touch box: in each of the 4 states, each pixel the
// set's part for that thing drew (set-kit.js `part`) is inside the box its touch hits (Sheet.hitBoxOf of its hit world
// box). (2) Every glass and jug lies inside its box (balcon.js `cajaDe`, relative to where it stands: the sheet keeps
// it), at every place of the table and on the small chair. (3) hit, in the kit's order, returns each thing's key at the
// middle of its box wherever it shows (the 4 states, the review pictures, the kept moments of the recorded runs), but
// where the old order gives the point to a thing tested before it; those are listed in [shadowedBy] (the numbers go to
// the report).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/balcon/balcon.dart';
import 'package:coqui_scenes/src/balcon/balcon_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/balcon_preview_remap.dart';
import 'support/fixtures/balcon_preview_fixture.dart';
import 'support/fixtures/balcon_set_refs.dart';
import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// The set's parts that draw each thing of the set (balcon-set.html: `part(name, ...)`).
const Map<String, List<String>> partsOf = {
  'mesa': ['mesa'],
  'silla_pequena': ['silla_pequena'],
  'silla_grande': ['silla_grande'],
  'puerta': ['puerta'],
  // the window with its frame, its shutters (open, flat on the wall) and the flower box (sheet: things.ventana.what)
  'ventana': ['ventana', 'jardinera', 'flores'],
  'balcon': ['balcon'],
};

/// The things whose drawn pixels go outside their box, and why.
const Map<String, String> outside = {
  'balcon': 'the porch floor\'s box is its open front strip only, from abuela\'s chair to the door (sheet: things.balcon.what: with this camera the porch is a slanting band and a box cannot follow it)',
  'silla_grande': 'in every state 10 of its 1620 pixels, 1 px outside: the arms are .07 wide on each side of a line .05 in from the chair\'s half-width, so they reach .02 past the box of its 8 corners (sheet: things.silla_grande.turned); its touch slack (m 2) covers them',
  'ventana': 'with the shutters open (win open: no story reaches it), 20 of 1325 pixels, 1 px outside: each open leaf lies flat .54 beside the opening, the box reaches .45 (sheet: things.ventana.world); its touch slack (m 1) covers them',
};

/// Whether thing [k] shows in [W] (and so can be touched).
bool shows(Balcon scene, String k, Map<String, dynamic> W) {
  if (Balcon.IDS.contains(k)) {
    final v = scene.enMesa(k);
    return v != null && !jsTruthy(v['mano']);
  }
  switch (k) {
    case 'abuela':
      final ab = W['ab'] as Map<String, dynamic>?;
      return ab != null && ab['al'] is num && (ab['al'] as num) > .5;
    case 'pajaro':
      return W['ave'] != null && (W['ave'] as Map)['mode'] != 'none';
    case 'coqui':
      return jsTruthy((W['cq'] as Map)['vis']);
  }
  return true;
}

/// The middles hit gives to another thing, because the kit tests that thing first (the old order is kept: things with
/// `z` first, then the bird, then the frog, then the rest in the list's order: the drinks, abuela, the table, the
/// chairs, the door, the window, the porch).
const Map<String, String> shadowedBy = {
  'balcon -> coqui': 'the frog on the porch stands over the middle of the porch\'s strip; the kit tests the frog first',
  'mesa -> agua': 'a glass or jug of water on the table: the drinks come first in the list (balcon.js IDS)',
  'mesa -> jugo': 'the same, for the juice',
  'mesa -> vaso_mesa': 'the same, for the glass on the table',
  'mesa -> pajaro':
      'the bird on the table (pair toma), tested before the things',
  'puerta -> abuela': 'abuela in the doorway is tested before the door (she is earlier in the list)',
  'silla_grande -> abuela': 'abuela in her chair is tested before the chair',
  'silla_pequena -> coqui':
      'the frog on the small chair\'s seat, tested before the things',
  'silla_pequena -> pajaro':
      'the bird on the small chair\'s seat, tested before the things',
  'silla_pequena -> vaso_silla':
      'the glass on the small chair comes first in the list',
  'ventana -> pajaro':
      'the bird on the window\'s flower box, tested before the things',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Balcon scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('balcon');
    scene = frame.scene as Balcon;
  });
  final refs = (jsonDecode(balconSetRefs) as List).cast<Map<String, dynamic>>();
  final rows = <String>[];

  test('every thing of the set lies inside its touch box, in every state', () {
    final e = balconEngine(), b = PpBuild(e);
    final over = <String>{};
    for (final r in refs) {
      final st = BalconState.fromQuery(r['query'] as String);
      final s = BalconSet(e, b, st);
      s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
      s.buildSet();
      final tags = s.k.PART_TAGS!;
      for (final t in partsOf.entries) {
        final box = scene.sheet.hitBoxOf(t.key, e)!;
        var drawn = 0, out = 0, far = 0;
        for (var i = 0; i < tags.length; i++) {
          if (!t.value.contains(tags[i])) continue;
          drawn++;
          final x = i % e.W, y = i ~/ e.W;
          if (x < box[0] ||
              x >= box[0] + box[2] ||
              y < box[1] ||
              y >= box[1] + box[3]) {
            out++;
            final d = [
              box[0] - x,
              x - (box[0] + box[2] - 1),
              box[1] - y,
              y - (box[1] + box[3] - 1),
            ].reduce((a, b) => a > b ? a : b);
            if (d > far) far = d;
          }
        }
        rows.add(
          '${r['id']} ${t.key} (parts ${t.value.join(', ')}): $out of $drawn drawn pixels outside $box'
          '${out > 0 ? ', at most $far px out' : ''}',
        );
        expect(drawn, greaterThan(0), reason: '${t.key} in ${r['id']}');
        if (out > 0) over.add(t.key);
      }
    }
    expect(over, outside.keys.toSet(), reason: 'outside its box: $over');
  });

  test('every glass and jug lies inside its box (cajaDe), on the table and on the small chair', () {
    var checked = 0;
    final out = <String>[];
    void check(String what, Map<String, dynamic> v, void Function(Ctx c) draw) {
      final pix = Uint32List(240 * 216), c = Ctx(pix, 240, 216);
      draw(c);
      final box = scene.cajaDe(v);
      var n = 0, o = 0;
      for (var i = 0; i < pix.length; i++) {
        if (pix[i] >> 24 == 0) continue;
        n++;
        final x = i % 240, y = i ~/ 240;
        if (x < box[0] ||
            x >= box[0] + box[2] ||
            y < box[1] ||
            y >= box[1] + box[3]) {
          o++;
        }
      }
      checked++;
      rows.add('$what: $o of $n pixels outside $box');
      expect(n, greaterThan(0));
      if (o > 0) out.add(what);
    }

    for (final name in const [
      'mesa.izq',
      'mesa.der',
      'mesa.centro',
      'mesa.toma',
    ]) {
      final x = (scene.sheet.points[name]!.screen[0] + .5).floor();
      for (final t in const ['n', 'g', 'p']) {
        for (final k in const ['jugo', 'agua']) {
          final v = <String, dynamic>{'t': t, 'k': k, 'x': x, 'lv': 1};
          check(
            '$name glass $t $k',
            v,
            (c) => vaso(c, x, scene.MESA_Y, t, k, 1),
          );
        }
      }
      for (final k in const ['jugo', 'agua']) {
        check('$name jug $k', {
          'k': k,
          'x': x,
        }, (c) => jarra(c, x, scene.MESA_Y, k));
      }
    }
    final a = scene.ASIENTO;
    check('ASIENTO glass n agua', {
      't': 'n',
      'k': 'agua',
      'x': a[0],
      'y': a[1] - 1,
      'lv': 1,
    }, (c) => vaso(c, a[0], a[1] - 1, 'n', 'agua', 1));
    rows.add('glasses and jugs: $checked checked, outside their box: $out');
    expect(out, isEmpty);
  });

  // hit at the middle of each box, in the 4 states, the review pictures and the moments of the stories
  test('hit gives each thing its key at the middle of its box, wherever it shows', () {
    final worlds = <(String, Map<String, dynamic>, int)>[];
    for (final r in refs) {
      final st = BalconState.fromQuery(r['query'] as String);
      final W = <String, dynamic>{
        'fx': <Map<String, dynamic>>[],
        'heart': 0,
        'lost': 0,
        'resp': null,
        ...scene.fresh(const {}),
        'door': st.door == 'open' ? 1 : 0,
        'win': st.win == 'open' ? 1 : 0,
      };
      expect(scene.setKey(W), st.key);
      worlds.add(('state ${r['id']}', W, 8));
    }
    for (final c in (jsonDecode(
      balconPreviewCases,
    ) as List).cast<Map<String, dynamic>>()) {
      if (c['kind'] == 'pair') {
        worlds.add((
          c['id'] as String,
          ScenePictures.pictureW(
            scene,
            (c['set'] as Map<String, dynamic>?) ?? const {},
          ),
          pictureF,
        ));
      } else {
        worlds.add((
          c['id'] as String,
          balconPreviewRemapW(
            balconPreviewBaseW(
              scene.fresh(const {}),
              c['W'] as Map<String, dynamic>,
            ),
            scene.sheet,
          ),
          c['F'] as int,
        ));
      }
    }
    final misses = <String>{};
    var checked = 0;
    for (final (name, W, F) in worlds) {
      frame.host
        ..W = W
        ..F = F
        ..cam = scene.CAM['wide']!;
      final keys = [for (final t in scene.cosas) t.id, 'pajaro', 'coqui'];
      for (final k in keys) {
        if (!shows(scene, k, W)) continue;
        List<num> mid;
        if (k == 'coqui') {
          final b = frogBox(W['cq'] as Map<String, dynamic>);
          mid = [b.x + b.w / 2, b.y + b.h / 2];
        } else if (k == 'pajaro') {
          final p = scene.avePos(W['ave'] as Map<String, dynamic>);
          mid = [p[0], p[1] - 10];
        } else {
          final b = scene.box(k, W)!;
          mid = [b[0] + b[2] / 2, b[1] + b[3] / 2];
        }
        final got = scene.hit(mid[0], mid[1], W);
        checked++;
        if (got != k) {
          misses.add('$k -> $got');
          rows.add(
            'hit $name: the middle of $k (${mid[0]}, ${mid[1]}) gives $got',
          );
        }
      }
    }
    rows.add(
      'hit: $checked middles checked in ${worlds.length} worlds; misses by kind: ${misses.toList()..sort()}',
    );
    expect(misses, shadowedBy.keys.toSet(), reason: rows.last);
  });

  tearDownAll(() => report('balcon-boxes', rows));
}
