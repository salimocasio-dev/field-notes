// The whole picture: the Dart frame of La mesa against docs/proyecto/pixel/mesa-preview.html (the old sprite layer on
// the new set, through the sheet), rendered in headless Chrome by `tool/preview_shots.mjs --scene mesa`. The cases: the
// 24 review pictures of cual-mesa (cocina.no on El colmado's stall, the stored still), the sheet's 16 level pictures
// (drawn through ScenePictures), and moments at rest of the recorded runs of La mesa's four files (W from the run, moved
// to the new places by the preview's own rule for its story, drawn on the still host). The sorted list is drawn as it
// is drawn: each item owns the pixels it drew last, and the table, its legs, the chairs, their legs, the counters, the
// stove, the left wall, the door's frame, threshold and reveal are drawn again only where their owner stands behind them
// (the sheet's front; a chair never over whoever sits); the shadows on the clear floor only (the sheet's shadows); the
// bubbles go where the sheet's talk says.
//
// As El frente's (test/preview_test.dart): the browser's canvas smooths a sprite at a fractional position and the Dart
// canvas does not (decided, order 05), so a pixel counts as different only when a channel differs by more than 24.
// Over 2% of a picture is a finding to explain.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/mesa/mesa.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/channels.dart';
import 'support/fixtures/mesa_preview_fixture.dart';
import 'support/report.dart';
import 'support/mesa_preview_remap.dart';
import 'support/sheet_bundle.dart';

Future<Uint32List> decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint32List(data.offsetInBytes, data.lengthInBytes ~/ 4);
}

/// Pictures over 2%, each with why (none of the kept ones: the moments of the rolling cart over 2% are not kept).
const Map<String, String> explained = {};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cases = (jsonDecode(mesaPreviewCases) as List)
      .cast<Map<String, dynamic>>();

  late ScenePictures pictures;
  late StillFrame frame;
  setUpAll(() async {
    pictures = ScenePictures(bundle: testBundle());
    frame = await pictures.frameOf('mesa');
  });

  final rows = <String>[];
  for (final c in cases) {
    test(
      '${c['id']}: no more than 2% of its pixels differ from the preview by more than 24',
      () async {
        final want = await decodePng(
          base64Decode(mesaPreviewPictures[c['picture'] as int].join()),
        );
        final Uint32List got;
        if (c['kind'] == 'pair') {
          got = await pictures.pixels(
            PictureRef(
              scene: 'mesa',
              set: (c['set'] as Map<String, dynamic>?) ?? const {},
              cam: (c['cam'] as List).cast<num>(),
            ),
            name: '${c['word']}.${c['side']}',
          );
        } else {
          final scene = frame.scene as Mesa;
          final W = mesaPreviewRemapW(
            mesaPreviewBaseW(
              scene.fresh(const {}),
              c['W'] as Map<String, dynamic>,
            ),
            scene,
            story: c['story'] as String?,
          );
          final cam = scene.sheet.viewOf(c['view'] as String, scene.projection);
          frame.draw(W, F: c['F'] as int, cam: cam, tick: 0, allSigns: false);
          got = cropZoom(frame.picture, 240, cam, 196 ~/ cam[2]);
        }
        final d = channelDiff(got, want, width: 196);
        rows.add(
          '${c['id']}: ${d.count} of ${d.total} (${d.percent.toStringAsFixed(2)}%)',
        );
        if (d.percent > 2 && !explained.containsKey(c['id'])) {
          fail(
            '${d.count} of ${d.total} (${d.percent.toStringAsFixed(2)}%) differ; first: ${d.first}',
          );
        }
      },
    );
  }
  tearDownAll(() => report('mesa-preview', rows));
}
