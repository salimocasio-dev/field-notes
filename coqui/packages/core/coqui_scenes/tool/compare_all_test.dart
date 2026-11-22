// Every picture tool/preview_shots.mjs wrote (every moment at rest of every recorded run, the review and level
// pictures) against the Dart frame, on the vm, as test/preview_test.dart (test/balcon_preview_test.dart) does for the
// fixture's few:
//
//   COQUI_PREVIEW_DIR=<--out of preview_shots.mjs> COQUI_REPORT_DIR=<dir> [COQUI_SCENE=balcon|sala|patio|camino|campo|lago|banco|mesa|estufa|nevera|comer] flutter test tool/compare_all_test.dart
//
// COQUI_SCENE is the scene the pictures are of (frente when not set); the report is preview-all.vm.txt for El frente,
// preview-all-<scene>.vm.txt for another.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/balcon/balcon.dart';
import 'package:coqui_scenes/src/banco/banco.dart';
import 'package:coqui_scenes/src/camino/camino.dart';
import 'package:coqui_scenes/src/campo/campo.dart';
import 'package:coqui_scenes/src/estufa/estufa.dart';
import 'package:coqui_scenes/src/frente/frente.dart';
import 'package:coqui_scenes/src/lago/lago.dart';
import 'package:coqui_scenes/src/nevera/nevera.dart';
import 'package:coqui_scenes/src/comer/comer.dart';
import 'package:coqui_scenes/src/mesa/mesa.dart';
import 'package:coqui_scenes/src/patio/patio.dart';
import 'package:coqui_scenes/src/sala/sala.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/balcon_preview_remap.dart';
import '../test/support/banco_preview_remap.dart';
import '../test/support/camino_preview_remap.dart';
import '../test/support/campo_preview_remap.dart';
import '../test/support/channels.dart';
import '../test/support/estufa_preview_remap.dart';
import '../test/support/lago_preview_remap.dart';
import '../test/support/nevera_preview_remap.dart';
import '../test/support/comer_preview_remap.dart';
import '../test/support/mesa_preview_remap.dart';
import '../test/support/patio_preview_remap.dart';
import '../test/support/preview_remap.dart';
import '../test/support/report.dart';
import '../test/support/sala_preview_remap.dart';

Future<Uint32List> decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint32List(data.offsetInBytes, data.lengthInBytes ~/ 4);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Platform.environment['COQUI_PREVIEW_DIR'];
  final id = Platform.environment['COQUI_SCENE'] ?? 'frente';
  test('every picture of the preview against the Dart frame', () async {
    if (dir == null) {
      markTestSkipped('set COQUI_PREVIEW_DIR');
      return;
    }
    final pictures = ScenePictures();
    final frame = await pictures.frameOf(id);
    final scene = frame.scene;
    // the preview's own rule for moving a recorded W to the new places (a dev tool's, per scene)
    Map<String, dynamic> moved(
      Map<String, dynamic> w,
      List<String>? acts,
      String? story,
    ) => switch (scene) {
      Frente f => previewRemapW(previewBaseW(f.fresh(const {}), w), f.sheet),
      Balcon b => balconPreviewRemapW(
        balconPreviewBaseW(b.fresh(const {}), w),
        b.sheet,
      ),
      Sala s => salaPreviewRemapW(
        salaPreviewBaseW(s.fresh(const {}), w),
        s.sheet,
        acts: acts,
      ),
      Patio p => patioPreviewRemapW(
        patioPreviewBaseW(p.fresh(const {}), w),
        p.sheet,
        story: story,
        acts: acts,
      ),
      Camino k => caminoPreviewRemapW(
        caminoPreviewBaseW(k.fresh(const {}), w),
        k.sheet,
        story: story,
        acts: acts,
      ),
      Campo k => campoPreviewRemapW(
        campoPreviewBaseW(k.fresh(const {}), w),
        k.sheet,
        story: story,
        acts: acts,
      ),
      Lago k => lagoPreviewRemapW(
        lagoPreviewBaseW(k.fresh(const {}), w),
        k.sheet,
        story: story,
        acts: acts,
      ),
      Banco k => bancoPreviewRemapW(
        bancoPreviewBaseW(k.fresh(const {}), w),
        k,
        story: story,
      ),
      Mesa k => mesaPreviewRemapW(
        mesaPreviewBaseW(k.fresh(const {}), w),
        k,
        story: story,
      ),
      Estufa k => estufaPreviewRemapW(
        estufaPreviewBaseW(k.fresh(const {}), w),
        k.sheet,
        story: story,
      ),
      Nevera k => neveraPreviewRemapW(
        neveraPreviewBaseW(k.fresh(const {}), w),
        k.sheet,
        story: story,
      ),
      Comer k => comerPreviewRemapW(
        comerPreviewBaseW(k.fresh(const {}), w),
        k,
        story: story,
      ),
      _ => throw StateError('no preview rule for $id'),
    };
    final rows = <String>[];
    var over = 0, max = 0.0, exact = 0;
    final cases = (jsonDecode(
      File('$dir/cases.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    for (final c in cases) {
      final want = await decodePng(File('$dir/${c['file']}').readAsBytesSync());
      final Uint32List got;
      if (c['kind'] == 'pair') {
        got = await pictures.pixels(
          PictureRef(
            scene: id,
            set: (c['set'] as Map<String, dynamic>?) ?? const {},
            cam: (c['cam'] as List).cast<num>(),
          ),
          name: '${c['word']}.${c['side']}',
        );
      } else {
        final W = moved(
          c['W'] as Map<String, dynamic>,
          (c['acts'] as List?)?.cast<String>(),
          c['story'] as String?,
        );
        final cam = scene.sheet.viewOf(c['view'] as String, scene.projection);
        frame.draw(W, F: c['F'] as int, cam: cam, tick: 0, allSigns: false);
        got = cropZoom(frame.picture, 240, cam, 196 ~/ cam[2]);
      }
      final d = channelDiff(got, want, width: 196),
          any = channelDiff(got, want, width: 196, limit: 0);
      if (any.count == 0) exact++;
      if (d.percent > 2) over++;
      if (d.percent > max) max = d.percent;
      rows.add(
        '${c['id']}: ${d.count} of ${d.total} (${d.percent.toStringAsFixed(2)}%) differ by more than 24; ${any.count} differ at all',
      );
    }
    rows.add(
      '${cases.length} pictures: $exact identical, $over over 2%, the most ${max.toStringAsFixed(2)}%',
    );
    report(id == 'frente' ? 'preview-all' : 'preview-all-$id', rows);
    expect(over, 0, reason: rows.last);
  }, timeout: const Timeout(Duration(minutes: 20)));
}
