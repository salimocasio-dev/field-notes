// The cake plate (frente.js:190). hud draws it on the DISPLAY picture, in the corner, whatever the view; hit turns the
// touch's picture point into display pixels with the view's zoom (pictureToDisplay) before it asks "sx < 66 and sy < 36".
// So the plate's touch area is the display rectangle 66 x 36, at zoom 1 (a 66 x 36 corner of the picture) and at zoom 2 (a
// 33 x 18 corner of the 98 x 108 region).
import 'dart:typed_data';

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

  // a world with the plate and nothing else that hit tests before it (no abuela, no hiding places, no bird; the frog is
  // not seen)
  Map<String, dynamic> plateW() {
    return ScenePictures.pictureW(scene, const {'plato': 2});
  }

  // every view of the sheet: its camera value, `[x, y, w, h]`
  Map<String, List<num>> cams() => {
    for (final v in scene.sheet.views.keys)
      v: scene.sheet.viewOf(v, scene.projection),
  };

  test('the sheet has views at both zooms', () {
    final zooms = {for (final c in cams().values) zoomOf(c)};
    expect(zooms, {1, 2});
  });

  test(
    'a touch on the display\'s corner 66 x 36 is the plate, at every view',
    () {
      final W = plateW();
      frame.host.W = W;
      for (final e in cams().entries) {
        final cam = e.value;
        frame.host.cam = cam;
        String? at(num dx, num dy) {
          final p = displayToPicture(cam, dx, dy);
          return scene.hit(p.x, p.y, W);
        }

        // inside: the display's pixels 0 to 65 across, 0 to 35 down (a touch is anywhere in a pixel)
        for (final (dx, dy) in [
          (0.0, 0.0),
          (10.5, 20.5),
          (32.0, 17.0),
          (65.0, 35.0),
          (65.9, 35.9),
        ]) {
          expect(
            at(dx, dy),
            'bizcocho',
            reason: '${e.key}: display ($dx, $dy)',
          );
        }
        // outside: the next display pixel
        for (final (dx, dy) in [
          (66.0, 0.0),
          (66.0, 35.0),
          (0.0, 36.0),
          (65.0, 36.0),
          (120.0, 100.0),
        ]) {
          expect(
            at(dx, dy),
            isNot('bizcocho'),
            reason: '${e.key}: display ($dx, $dy)',
          );
        }
      }
    },
  );

  test('it is the old arithmetic: (x - cam[0]) * DW / cam[2] < 66 and (y - cam[1]) * DH / cam[3] < 36', () {
    final W = plateW();
    frame.host.W = W;
    var plate = 0, other = 0;
    for (final e in cams().entries) {
      final cam = e.value;
      frame.host.cam = cam;
      for (var y = 0; y < pictureH; y += 3) {
        for (var x = 0; x < pictureW; x += 3) {
          final sx = (x - cam[0]) * 196 / cam[2],
              sy = (y - cam[1]) * 216 / cam[3];
          final old = sx < 66 && sy < 36;
          final got = scene.hit(x, y, W);
          if (old) {
            plate++;
          } else {
            other++;
          }
          expect(
            got == 'bizcocho',
            old,
            reason:
                '${e.key}: picture ($x, $y) is display ($sx, $sy), hit gives $got',
          );
        }
      }
    }
    expect(plate, greaterThan(100));
    expect(other, greaterThan(plate));
  });

  test('at zoom 2 the area is 33 x 18 of the region\'s picture pixels, not 66 x 36', () {
    final W = plateW();
    frame.host.W = W;
    final cam = scene.sheet.viewOf('puerta', scene.projection);
    expect(cam.sublist(2), [98, 108]);
    frame.host.cam = cam;
    String? hit(num dx, num dy) => scene.hit(cam[0] + dx, cam[1] + dy, W);
    expect(hit(32.9, 17.9), 'bizcocho');
    expect(hit(33, 5), isNot('bizcocho'));
    expect(hit(5, 18), isNot('bizcocho'));
    // the old code, without the zoom, would have taken (65, 35) picture pixels as the plate
    expect(hit(65, 35), isNot('bizcocho'));
  });

  test('hud draws the plate on the display in the same place at both zooms, inside the touch area', () {
    PlateRect? plateOn(List<num> cam) {
      Uint32List draw(Object? plato) {
        final W = plateW();
        W['plato'] = plato;
        frame.draw(W, F: 8, cam: cam);
        return Uint32List.fromList(frame.display);
      }

      final without = draw(null), withPlate = draw(3);
      var x0 = displayW, y0 = displayH, x1 = -1, y1 = -1;
      for (var i = 0; i < without.length; i++) {
        if (without[i] == withPlate[i]) continue;
        final x = i % displayW, y = i ~/ displayW;
        x0 = x < x0 ? x : x0;
        y0 = y < y0 ? y : y0;
        x1 = x > x1 ? x : x1;
        y1 = y > y1 ? y : y1;
      }
      return x1 < 0 ? null : PlateRect(x0, y0, x1 + 1, y1 + 1);
    }

    final byZoom = <int, PlateRect>{};
    for (final e in cams().entries) {
      final r = plateOn(e.value);
      expect(r, isNotNull, reason: '${e.key}: hud draws the plate');
      // the plate is inside the corner the touch area covers
      expect(r!.x1, lessThanOrEqualTo(66), reason: '${e.key}: $r');
      expect(r.y1, lessThanOrEqualTo(36), reason: '${e.key}: $r');
      // and fills most of it
      expect(r.x1 - r.x0, greaterThan(40), reason: '${e.key}: $r');
      expect(r.y1 - r.y0, greaterThan(20), reason: '${e.key}: $r');
      final z = zoomOf(e.value);
      expect(
        byZoom.putIfAbsent(z, () => r),
        r,
        reason: '${e.key}: the same place at zoom $z',
      );
    }
    expect(byZoom[1], byZoom[2], reason: 'the same place at zoom 1 and zoom 2');
  });
}

/// The pixels a plate fills on the display: `[x0, x1) x [y0, y1)`.
class PlateRect {
  PlateRect(this.x0, this.y0, this.x1, this.y1);
  final int x0, y0, x1, y1;

  @override
  bool operator ==(Object other) =>
      other is PlateRect &&
      other.x0 == x0 &&
      other.y0 == y0 &&
      other.x1 == x1 &&
      other.y1 == y1;

  @override
  int get hashCode => Object.hash(x0, y0, x1, y1);

  @override
  String toString() => 'PlateRect($x0, $y0, $x1, $y1)';
}
