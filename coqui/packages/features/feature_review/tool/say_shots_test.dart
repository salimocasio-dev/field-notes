// Captures 3 speaking-card (Dilo) screenshots across the 3 built places (casa, parque, cocina) at 390 x 844, dpr 2
// (780 x 1688 PNGs), with real Roboto fonts loaded from coqui_ui.
//
//   flutter test tool/say_shots_test.dart --dart-define=OUT=test/screenshots
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test/support/repaso_course.dart';
import '../test/support/repaso_screen_rig.dart';

const String _out = String.fromEnvironment('OUT');

Future<void> _loadFonts() async {
  final dir = '${repoRoot.path}/coqui/packages/core/coqui_ui';
  Future<void> load(String family, Iterable<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File('$dir/$f').readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('packages/coqui_ui/$coquiFontFamily', coquiFontFiles.values);
  await load(coquiFontFamily, coquiFontFiles.values);
  for (final entry in nocheFontFiles.entries) {
    await load('packages/coqui_ui/${entry.key}', entry.value.values);
    await load(entry.key, entry.value.values);
  }
}

void main() {
  testWidgets('captures speaking cards across casa, parque, and cocina', (
    t,
  ) async {
    await t.runAsync(_loadFonts);
    Directory? dir;
    if (_out.isNotEmpty) {
      dir = Directory(_out)..createSync(recursive: true);
    }

    const cases = [
      ('say_01_casa_puerta.png', 'casa', 'puerta', '¡Abre la puerta, abuela!'),
      ('say_02_parque_pajaro.png', 'parque', 'pájaro', '¡El pájaro come!'),
      ('say_03_cocina_no_hay.png', 'cocina', 'no hay', '¡Papá, no hay leche!'),
    ];

    for (final (file, place, wordName, sentence) in cases) {
      final w = realRepaso.word(wordName);
      expect(w, isNotNull, reason: 'word $wordName exists');
      expect(w!.place, place, reason: '$wordName belongs to $place');
      final line = w.say.firstWhere((l) => l.text == sentence);

      final speech = HeldSpeech();
      final sc = Screen(t, json: everythingJson(realRepaso), listener: speech);
      await sc.open(w: 390, h: 844, dpr: 2, text: 1);
      sc.s.queue = [QueueEntry.play(SayItem(word: w.word, line: line))];
      await t.tap(find.byType(NochePlayDisc));
      await sc.settle();
      await sc.vt.runUntil(() => sc.s.mic == MicState.ready);
      await sc.settle();

      for (var i = 0; i < 2; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 15)),
        );
        await t.pump();
      }

      expect(t.takeException(), isNull, reason: file);
      expect(find.byType(ErrorWidget), findsNothing, reason: file);
      expect(sc.s.mic, MicState.ready, reason: file);
      expect(find.byKey(const ValueKey('say-prompt')), findsOneWidget);
      expect(
        find.textContaining(sentence, findRichText: true),
        findsOneWidget,
        reason: file,
      );

      if (dir != null) {
        final view = t.binding.renderViews.first;
        final layer = view.debugLayer! as OffsetLayer;
        final shot = await t.runAsync(() async {
          final image = await layer.toImage(view.paintBounds);
          final width = image.width;
          final height = image.height;
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          image.dispose();
          return (
            width: width,
            height: height,
            bytes: Uint8List.fromList(bytes),
          );
        });
        expect(shot!.width, 780, reason: file);
        expect(shot.height, 1688, reason: file);
        File('${dir.path}/$file').writeAsBytesSync(shot.bytes);
      }
    }
  });
}
