// The touch boxes. (1) Every thing of the set lies inside its touch box: in each of the 25 states, each pixel the
// set's part for that thing drew (set-kit.js `part`, the swaying fronds included at time 0) is inside the box its touch
// hits (Sheet.hitBoxOf of its hit world box). Its box (Sheet.boxOf of its world box: what the hint frame goes round, as
// frente.js's box) may be tighter: the house's and the window's are. (2) hit, in the old order, returns each thing's key at the centre of its box in
// every state where the thing shows, but where the old order gives the point to a thing tested before it; those are
// listed in [shadowedBy] (the numbers go to the report).
import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/frente/frente.dart';
import 'package:coqui_scenes/src/frente/frente_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/preview_fixture.dart';
import 'support/fixtures/set_refs.dart';
import 'support/preview_remap.dart';
import 'support/report.dart';
import 'support/sheet_bundle.dart';
import 'support/state_w.dart';

/// The set's part that draws each thing of the set (frente-set.html: `part(name, ...)`).
const Map<String, String> partOf = {
  'casa': 'casa',
  'casa_grande': 'casa',
  'puerta': 'puerta',
  'ventana': 'ventana',
  'palma': 'palma',
  'palma_grande': 'palma',
  'palma_pequena': 'palma_pequena',
  'casa_pequena': 'casa_pequena',
};

/// Whether thing [k] shows in [W] (and so can be touched).
bool shows(String k, Map<String, dynamic> W, String sky) {
  switch (k) {
    case 'palma_grande' || 'casa_grande' || 'palma_pequena' || 'casa_pequena':
      return jsTruthy(W['escondite']);
    case 'sol':
      return sky != 'rain';
    case 'abuela':
      return jsTruthy(W['ab']);
    case 'pajaro':
      return W['ave'] != null && (W['ave'] as Map)['mode'] != 'none';
    case 'coqui':
      return jsTruthy((W['cq'] as Map)['vis']);
    case 'nube':
      return W['nube'] != null;
    case 'bizcocho':
      return W['plato'] != null;
  }
  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Frente scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('frente');
    scene = frame.scene as Frente;
  });
  final refs = (jsonDecode(setRefs) as List).cast<Map<String, dynamic>>();
  final rows = <String>[];

  test('every thing of the set lies inside its touch box, in every state', () {
    final e = frenteEngine(), b = PpBuild(e);
    final over = <String>{};
    for (final r in refs) {
      final st = FrenteState.fromQuery(r['query'] as String);
      final fs = FrenteSet(e, b, st);
      fs.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
      fs.buildSet();
      e.pix.setAll(0, e.bakedPix);
      e.zb.setAll(0, e.bakedZ);
      e.drawLeaves(0);
      e.drawTufts(0);
      fs.k.tagLeaves(e.zb);
      final tags = fs.k.PART_TAGS!;
      for (final t in partOf.entries) {
        if (!st.hide &&
            (t.key == 'palma_pequena' ||
                t.key == 'casa_pequena' ||
                t.key.endsWith('_grande'))) {
          continue;
        }
        final box = scene.sheet.hitBoxOf(t.key, e)!;
        var drawn = 0, out = 0;
        for (var i = 0; i < tags.length; i++) {
          if (tags[i] != t.value) continue;
          drawn++;
          final x = i % e.W, y = i ~/ e.W;
          if (x < box[0] ||
              x >= box[0] + box[2] ||
              y < box[1] ||
              y >= box[1] + box[3]) {
            out++;
          }
        }
        rows.add(
          '${r['id']} ${t.key} (part ${t.value}): $out of $drawn drawn pixels outside $box',
        );
        expect(
          drawn,
          greaterThan(0),
          reason: '${t.key} draws nothing in ${r['id']}',
        );
        if (out > 0) over.add('${r['id']} ${t.key}');
      }
      // the sun: the sky's disc (screen space) inside its box
      if (st.sky != 'rain') {
        final box = scene.sheet.boxOf('sol', e);
        var drawn = 0, out = 0;
        for (var iy = 0; iy < e.H; iy++) {
          for (var ix = 0; ix < e.W; ix++) {
            if (e.zb[iy * e.W + ix] > -1e8) continue;
            if (fs.k.skyDisc(
                  SUN[0],
                  SUN[1],
                  SUN[2],
                  SKIES[st.sky]!.sun!,
                  ix,
                  iy,
                ) ==
                0) {
              continue;
            }
            drawn++;
            if (ix < box[0] ||
                ix >= box[0] + box[2] ||
                iy < box[1] ||
                iy >= box[1] + box[3]) {
              out++;
            }
          }
        }
        rows.add('${r['id']} sol: $out of $drawn drawn pixels outside $box');
        if (out > 0) over.add('${r['id']} sol');
      }
    }
    expect(over, outside.keys.toSet(), reason: 'outside its box: $over');
  });

  // hit at the middle of each box, in the 25 states, the review pictures and the moments of the stories
  test('hit gives each thing its key at the middle of its box, wherever it shows', () {
    final worlds = <(String, Map<String, dynamic>, int, String)>[];
    for (final r in refs) {
      final st = FrenteState.fromQuery(r['query'] as String),
          w = wOfState(scene, st);
      frame.host.F = w.F;
      expect(
        scene.setKey(w.W),
        st.key,
        reason: 'setKey of the W made for ${r['id']}',
      );
      worlds.add(('state ${r['id']}', w.W, w.F, st.sky));
    }
    for (final c
        in (jsonDecode(previewCases) as List).cast<Map<String, dynamic>>()) {
      final Map<String, dynamic> W;
      final int F;
      if (c['kind'] == 'pair') {
        W = ScenePictures.pictureW(
          scene,
          (c['set'] as Map<String, dynamic>?) ?? const {},
        );
        F = pictureF;
      } else {
        W = previewRemapW(
          previewBaseW(scene.fresh(const {}), c['W'] as Map<String, dynamic>),
          scene.sheet,
        );
        F = c['F'] as int;
      }
      frame.host.F = F;
      final sky = FrenteState.fromKey(scene.setKey(W)).sky;
      worlds.add((c['id'] as String, W, F, sky));
    }
    final misses = <String>{};
    var checked = 0;
    for (final (name, W, F, sky) in worlds) {
      frame.host
        ..W = W
        ..F = F
        ..cam = scene.CAM['wide']!;
      for (final k in scene.sheet.things.keys) {
        if (!shows(k, W, sky)) continue;
        List<num> mid;
        if (k == 'coqui') {
          final b = frogBox(W['cq'] as Map<String, dynamic>);
          mid = [b.x + b.w / 2, b.y + b.h / 2];
        } else if (k == 'pajaro') {
          final p = scene.avePos(W['ave'] as Map<String, dynamic>);
          mid = [
            p[0],
            p[1] - 10,
          ]; // its hit: |x - p[0]| < 16, p[1] - 24 < y < p[1] + 5
        } else if (k == 'bizcocho') {
          mid = [
            frame.host.cam[0] + 30,
            frame.host.cam[1] + 17,
          ]; // the plate in the corner of the display
        } else {
          // frente.js's box() has no palma and no sol: their box is the sheet's
          final b = scene.box(k, W) ?? scene.sheet.boxOf(k, scene.projection);
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

  tearDownAll(() => report('boxes', rows));
}

/// The things that draw outside their box, in a state, and why.
const Map<String, String> outside = {
  'door-shut-win-shut-lights-0-sky-dusk-hide-rustle-palma-side-1 palma_pequena': 'the rustling palm sits one pixel to the side (set: rustle, side); its box is the still palm\'s: 3 pixels of a frond',
  'door-shut-win-shut-lights-0-sky-dusk-hide-rustle-todo-side-1 palma_pequena':
      'the same one-pixel rustle of the small palm',
};

/// The middles hit gives to another thing, because frente.js's hit tests that thing first (the old order is kept).
const Map<String, String> shadowedBy = {
  'casa -> puerta': 'the door stands in the middle of the house\'s box; hit tests puerta before casa',
  'casa -> casa_grande': 'story 3: hit tests the hiding places first, and casa_grande is the same box as casa',
  'puerta -> casa_grande':
      'story 3: the hiding places first (frente.js:187-188)',
  'ventana -> casa_grande': 'story 3: the hiding places first',
  'palma -> palma_grande':
      'story 3: palma_grande is the same box as palma, tested first',
  'puerta -> abuela': 'abuela in the doorway is tested first (frente.js:186)',
  'ventana -> abuela': 'abuela in the window is tested first',
  'coqui -> abuela':
      'the frog before the door with abuela in it: abuela is tested first',
  'coqui -> casa_grande': 'story 3: the frog on the porch is inside casa_grande\'s box, tested before the frog (frente.js:187-191)',
  'pajaro -> casa_grande': 'story 3: the bird at the door is inside casa_grande\'s box, tested first',
  'pajaro -> casa_pequena':
      'story 3: the bird at the birdhouse, tested after the hiding places',
  'pajaro -> palma_pequena':
      'story 3: the bird in the small palm, tested after the hiding places',
  'casa -> abuela': 'story 3: abuela on the porch stands over the middle of the house\'s box (up to the eaves); she is tested first',
  'casa_grande -> abuela': 'story 3: the same, for the house as a hiding place',
  'sol -> pajaro': 'the bird circling over the sun; it is tested before sol',
  'sol -> null': 'in a storm the pale sun shows but hit skips the sun (frente.js:197, !W.storm)',
};
