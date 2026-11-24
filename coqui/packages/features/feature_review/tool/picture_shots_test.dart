// Captures 4 issue #10 screenshots at 390 x 844, dpr 2 (780 x 1688 PNGs), with real Roboto fonts from coqui_ui.
//
//   flutter test tool/picture_shots_test.dart --dart-define=OUT=test/screenshots
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/word_picture.dart';
import 'package:feature_review/src/ui/book_image.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test/support/repaso_course.dart';
import '../test/support/repaso_screen_rig.dart';

const String _out = String.fromEnvironment('OUT');

class _ForbidPictures implements PictureSource {
  @override
  Widget of(
    PictureRef ref, {
    int width = 196,
    int height = 104,
    bool animated = false,
  }) => fail('ScenePictures.of($ref) must never be called under #10');

  @override
  Future<void> warm(Iterable<PictureRef> refs) async =>
      fail('ScenePictures.warm($refs) must never be called under #10');
}

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

  await load('packages/coqui_ui/Roboto', coquiFontFiles.values);
  await load('Roboto', coquiFontFiles.values);
}

Future<MemoryImage> _drawIconCard(WidgetTester t, {required bool door}) async {
  final bytes = await t.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Calm dark background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 196, 104),
      Paint()..color = const Color(0xFF1F242D),
    );
    if (door) {
      // Simple wooden door icon
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(76, 14, 44, 76),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFC58B53),
      );
      canvas.drawRect(
        const Rect.fromLTWH(82, 22, 32, 24),
        Paint()..color = const Color(0xFF9F6A38),
      );
      canvas.drawRect(
        const Rect.fromLTWH(82, 54, 32, 28),
        Paint()..color = const Color(0xFF9F6A38),
      );
      canvas.drawCircle(
        const Offset(112, 52),
        3.5,
        Paint()..color = const Color(0xFFF6D265),
      );
    } else {
      // Simple window icon
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(64, 18, 68, 68),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFE0E5EC),
      );
      canvas.drawRect(
        const Rect.fromLTWH(70, 24, 25, 25),
        Paint()..color = const Color(0xFF6BB6FF),
      );
      canvas.drawRect(
        const Rect.fromLTWH(101, 24, 25, 25),
        Paint()..color = const Color(0xFF6BB6FF),
      );
      canvas.drawRect(
        const Rect.fromLTWH(70, 55, 25, 25),
        Paint()..color = const Color(0xFF6BB6FF),
      );
      canvas.drawRect(
        const Rect.fromLTWH(101, 55, 25, 25),
        Paint()..color = const Color(0xFF6BB6FF),
      );
    }
    final image = await recorder.endRecording().toImage(196, 104);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return MemoryImage(bytes!);
}

Future<void> _saveShot(WidgetTester t, Directory? dir, String file) async {
  for (var i = 0; i < 2; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await t.pump();
  }
  expect(t.takeException(), isNull, reason: file);
  expect(find.byType(ErrorWidget), findsNothing, reason: file);
  if (dir == null) return;
  final view = t.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final shot = await t.runAsync(() async {
    final image = await layer.toImage(view.paintBounds);
    final width = image.width;
    final height = image.height;
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    image.dispose();
    return (width: width, height: height, bytes: Uint8List.fromList(bytes));
  });
  expect(shot!.width, 780, reason: file);
  expect(shot.height, 1688, reason: file);
  File('${dir.path}/$file').writeAsBytesSync(shot.bytes);
}

void main() {
  testWidgets('captures 4 issue #10 picture policy screenshots', (t) async {
    await t.runAsync(_loadFonts);
    Directory? dir;
    if (_out.isNotEmpty) {
      dir = Directory(_out)..createSync(recursive: true);
    }

    // 1. ¿Qué oyes? prompt card for unpicturable word "sí" (word tiles only, zero pictures)
    {
      final sc = Screen(
        t,
        json: everythingJson(realRepaso),
        pictures: _ForbidPictures(),
      );
      await sc.open(w: 390, h: 844, dpr: 2, text: 1);
      final wSi = realRepaso.word('sí')!;
      final sSi = sc.s.planner.hearSentences(wSi).first;
      final item = sc.s.planner.hearItem(wSi, sSi);
      sc.s.queue = [QueueEntry.scored(item)];
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      await sc.vt.runUntil(() => sc.s.yourTurn);
      await sc.settle();
      expect(find.byType(WordTile), findsNWidgets(3));
      expect(find.byType(PictureChoice), findsNothing);
      expect(find.byType(BookImage), findsNothing);
      await _saveShot(t, dir, 'pictures_01_hear_unpicturable_si.png');
    }

    // Sentence with non-null sentence.picture in repaso.json, usable for both Hear and Build
    final picSentence = realRepaso.sentences.firstWhere(
      (s) => s.picture != null && s.forHearing && s.forBuilding,
    );
    final targetWord = realRepaso.words.firstWhere(
      (x) => picSentence.tokens.contains(x.word) && x.sentences.isNotEmpty,
    );

    // 2. ¿Qué oyes? answered reveal (text only, zero BookImage story screenshot)
    {
      final sc = Screen(
        t,
        json: everythingJson(realRepaso),
        pictures: _ForbidPictures(),
      );
      await sc.open(w: 390, h: 844, dpr: 2, text: 1);
      final hear = sc.s.planner.hearItem(targetWord, picSentence);
      sc.s.queue = [QueueEntry.scored(hear)];
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      await sc.vt.runUntil(() => sc.s.yourTurn);
      await t.tap(find.byType(WordTile).at(hear.answer));
      await sc.vt.runUntil(() => sc.s.canNext);
      await sc.settle();
      expect(find.byType(BookImage), findsNothing);
      await _saveShot(t, dir, 'pictures_02_hear_reveal_no_screenshot.png');
    }

    // 3. Arma la frase answered reveal (text only, zero BookImage story screenshot)
    {
      final sc = Screen(
        t,
        json: everythingJson(realRepaso),
        pictures: _ForbidPictures(),
      );
      await sc.open(w: 390, h: 844, dpr: 2, text: 1);
      final wrong = sc.s.planner.wrongTiles(
        targetWord,
        picSentence,
        singleWords: true,
      )!;
      final extra = [for (final e in wrong) RepasoPlanner.tileForm(e.word)];
      final build = BuildItem(
        word: targetWord.word,
        sentence: picSentence,
        order: picSentence.tokens,
        pool: [...picSentence.tokens.reversed, ...extra],
      );
      sc.s.queue = [QueueEntry.play(build)];
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      await sc.vt.runUntil(() => sc.s.yourTurn);
      await sc.settle();
      for (final w in build.order) {
        final k = sc.s.choices.indexWhere((c) => !c.done && c.label == w);
        final tile = find
            .descendant(
              of: find.byType(TileTray).last,
              matching: find.byType(WordTile),
            )
            .at(k);
        await t.ensureVisible(tile);
        await t.tap(tile);
        await sc.settle();
      }
      await sc.vt.runUntil(() => sc.s.canNext);
      await sc.settle();
      expect(find.byType(BookImage), findsNothing);
      await _saveShot(t, dir, 'pictures_03_build_reveal_no_screenshot.png');
    }

    // 4. ¿Cuál? prompt card for puerta with dedicated word_assets/puerta.png vs word_assets/ventana.png
    {
      final doorImg = await _drawIconCard(t, door: true);
      final windowImg = await _drawIconCard(t, door: false);
      final db = jsonDecode(seedJson('curso')) as Map<String, dynamic>;
      ((db['palabras'] as Map)['puerta'] as Map)['ear']['n'] = 0;

      const asset = WordPictureAsset(
        word: 'puerta',
        yesAsset: 'word_assets/puerta.png',
        noAsset: 'word_assets/ventana.png',
      );
      final sc = Screen(
        t,
        json: jsonEncode(db),
        pictures: _ForbidPictures(),
        wordAssets: {'puerta': asset},
      );
      await sc.open(
        w: 390,
        h: 844,
        dpr: 2,
        text: 1,
        imageProvider: (url) =>
            url.contains('puerta.png') ? doorImg : windowImg,
      );
      final wPuerta = realRepaso.word('puerta')!;
      final item = sc.s.planner.scoredItem(wPuerta);
      expect(item, isA<CualItem>());
      sc.s.queue = [QueueEntry.scored(item)];
      await t.tap(find.byType(LessonStartButton));
      await sc.settle();
      await sc.vt.runUntil(() => sc.s.yourTurn);
      await sc.settle();
      expect(find.byType(PictureChoice), findsNWidgets(2));
      await _saveShot(t, dir, 'pictures_04_cual_dedicated_asset.png');
    }
  });
}
