// The whole picture: the Dart frame of La nevera against docs/proyecto/pixel/nevera-preview.html (the old sprite layer on
// the new set, through the sheet), rendered in headless Chrome by `tool/preview_shots.mjs --scene nevera`. The cases: the
// 24 review pictures of cual-nevera, the sheet's 19 level pictures (drawn through ScenePictures), and moments at rest of
// the recorded runs of La nevera's four stories (W from the run, moved to the new places by the preview's own rule for its
// story, drawn on the still host). Whoever is outside the window is drawn only on the set's pixels that show the outside
// (the sheet's clips.patio); the sorted list is drawn as it is drawn: each item owns the pixels it drew last, and the
// set's front parts are drawn again only where their owner stands behind them (the sheet's front); the shadows are those
// the sheet's shadows name; the bubbles go where the sheet's talk says.
//
// As El frente's (test/preview_test.dart): the browser's canvas smooths a sprite at a fractional position and the Dart
// canvas does not (decided, order 05), so a pixel counts as different only when a channel differs by more than 24.
// Over 2% of a picture is a finding to explain.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/nevera/nevera.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/channels.dart';
import 'support/fixtures/nevera_preview_fixture.dart';
import 'support/report.dart';
import 'support/nevera_preview_remap.dart';
import 'support/sheet_bundle.dart';

Future<Uint32List> decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint32List(data.offsetInBytes, data.lengthInBytes ~/ 4);
}

/// Pictures over 2%, each with why (none).
const Map<String, String> explained = {};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cases = (jsonDecode(neveraPreviewCases) as List)
      .cast<Map<String, dynamic>>();

  late ScenePictures pictures;
  late StillFrame frame;
  setUpAll(() async {
    pictures = ScenePictures(bundle: testBundle());
    frame = await pictures.frameOf('nevera');
  });

  final rows = <String>[];
  for (final c in cases) {
    test(
      '${c['id']}: no more than 2% of its pixels differ from the preview by more than 24',
      () async {
        final want = await decodePng(
          base64Decode(neveraPreviewPictures[c['picture'] as int].join()),
        );
        final Uint32List got;
        if (c['kind'] == 'pair') {
          got = await pictures.pixels(
            PictureRef(
              scene: 'nevera',
              set: (c['set'] as Map<String, dynamic>?) ?? const {},
              cam: (c['cam'] as List).cast<num>(),
            ),
            name: '${c['word']}.${c['side']}',
          );
        } else {
          final scene = frame.scene as Nevera;
          final W = neveraPreviewRemapW(
            neveraPreviewBaseW(
              scene.fresh(const {}),
              c['W'] as Map<String, dynamic>,
            ),
            scene.sheet,
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
  tearDownAll(() => report('nevera-preview', rows));
}
