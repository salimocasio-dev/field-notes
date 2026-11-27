import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:feature_library/src/reader_page.dart';
import 'package:feature_library/src/reader_settings_sheet.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/text_reader.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart' show TestCourse, TimedClips, line, settle;

const List<Size> _shotViewports = [Size(390, 844), Size(412, 915)];

bool get _captureShots => Platform.environment['CAPTURE_READER_SHOTS'] == '1';

Future<void> _loadNocheFonts() async {
  for (final entry in nocheFontFiles.entries) {
    for (final prefix in ['', 'packages/coqui_ui/']) {
      final loader = FontLoader('$prefix${entry.key}');
      for (final relPath in entry.value.values) {
        final file = File('../../core/coqui_ui/$relPath');
        loader.addFont(
          Future.value(ByteData.sublistView(file.readAsBytesSync())),
        );
      }
      await loader.load();
    }
  }
}

Future<void> _saveScreenshot(WidgetTester tester, String filename) async {
  final boundary = tester.renderObject(
    find.byType(RepaintBoundary).first,
  ) as RenderRepaintBoundary;
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1.0));
  final byteData = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  final outFile = File('test/screenshots/$filename');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsBytesSync(byteData!.buffer.asUint8List());
}

WordRecord _earWord(String w, int stage) => WordRecord(
  w: w,
  primera: 0,
  ear: SkillRecord(etapa: stage),
);

/// Records canvas draw calls made by `ReaderPageView`'s text decorator painter
/// so tests can assert solid/dotted underlines and lit-sentence highlights.
class _RecordingCanvas implements Canvas {
  final List<({Offset p1, Offset p2, int argb})> lines = [];
  final List<({Rect rect, int argb})> rects = [];
  final List<({RRect rrect, int argb})> rrects = [];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    lines.add((p1: p1, p2: p2, argb: paint.color.toARGB32()));
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    rects.add((rect: rect, argb: paint.color.toARGB32()));
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    rrects.add((rrect: rrect, argb: paint.color.toARGB32()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

_RecordingCanvas _paintPageDecorations(WidgetTester tester) {
  final canvas = _RecordingCanvas();
  final customPaints = find.descendant(
    of: find.byType(ReaderPageView),
    matching: find.byType(CustomPaint),
  );
  for (final element in customPaints.evaluate()) {
    final widget = element.widget as CustomPaint;
    final painter = widget.painter;
    final box = element.renderObject as RenderBox?;
    if (painter != null && box != null && box.hasSize) {
      painter.paint(canvas, box.size);
    }
  }
  return canvas;
}

TextStyle _firstBodyTextStyle(WidgetTester tester) {
  final richTexts = find.descendant(
    of: find.byType(ReaderPageView),
    matching: find.byWidgetPredicate((w) => w is Text && w.textSpan != null),
  );
  expect(richTexts, findsWidgets);
  final text = tester.widget<Text>(richTexts.first);
  return text.textSpan!.style!;
}

Color _readerPageBackground(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .descendant(
          of: find.byType(TextReader),
          matching: find.byType(Material),
        )
        .first,
  );
  return material.color!;
}

Color _sizeDashColor(WidgetTester tester, int index) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byKey(ValueKey('reader-size-dash-$index')),
      matching: find.byType(Container),
    ),
  );
  return (container.decoration! as BoxDecoration).color!;
}

Future<void> _openSettingsSheet(WidgetTester tester) async {
  await tester.tap(
    find.bySemanticsLabel(NocheA11y.label(NocheA11y.textAndPage)),
  );
  await tester.pumpAndSettle();
  expect(find.byType(NocheSheet), findsOneWidget);
  expect(find.byType(ReaderSettingsSheet), findsOneWidget);
}

Future<ReadingText> _addSampleBook(ReadingStore store) {
  final paragraphs = [
    'Cuando llegamos a Cabo Rojo, ya era de noche. La casa de Abuela estaba al final de la calle, con la luz del balcón encendida.',
    '—¡Llegaron! —dijo Abuela desde la puerta—. Entren, que la comida está caliente.',
    'La cocina olía a sofrito y a café. En la estufa había una olla grande de arroz con gandules.',
    'Después de cenar nos sentamos en el balcón para escuchar las olas y hablar de los paseos del día siguiente.',
    'Por la mañana el sol subió temprano sobre el puerto y los botes pequeños salieron hacia las aguas claras.',
    'Caminamos por la orilla buscando caracoles blancos y piedras suaves entre la arena húmeda de la playa.',
    'Al mediodía compramos fruta fresca en el puesto de la esquina y volvimos caminando por la sombra de las palmas.',
    'Antes del atardecer subimos hasta el faro viejo para mirar el horizonte rojo y sentir el viento salado.',
    'Cuando cayó la tarde regresamos despacio a casa sabiendo que el verano apenas comenzaba.',
  ];
  return store.add(
    now: 100,
    title: 'Un verano en Cabo Rojo',
    body: paragraphs.join('\n\n'),
    generated: false,
    chapters: [
      ReadingChapter(
        label: 'Chapter 2',
        title: 'La cocina de Abuela',
        paragraphs: paragraphs,
      ),
    ],
  );
}

void main() {
  setUpAll(() async {
    await _loadNocheFonts();
  });

  group('ReaderSettings model & storage', () {
    test('defines exact 7 text size steps and 3 line spacing multipliers', () {
      const expectedSteps = [
        (15.0, 25.0),
        (16.0, 26.0),
        (17.0, 28.0),
        (19.0, 31.0),
        (21.0, 34.0),
        (23.0, 38.0),
        (26.0, 42.0),
      ];
      expect(const ReaderSettings().step, 4);
      expect(const ReaderSettings().page, ReaderPageTheme.night);
      expect(const ReaderSettings().font, ReaderFont.literata);
      expect(const ReaderSettings().spacing, ReaderLineSpacing.normal);
      expect(const ReaderSettings().underlineWords, isTrue);
      expect(const ReaderSettings().lightUpSentence, isTrue);

      for (var i = 0; i < expectedSteps.length; i++) {
        final s = ReaderSettings(step: i + 1);
        expect(s.bodyFontSize, expectedSteps[i].$1);
        expect(s.bodyLineHeight, expectedSteps[i].$2);
        expect(
          s.copyWith(spacing: ReaderLineSpacing.tight).bodyLineHeight,
          closeTo(expectedSteps[i].$2 * 0.88, 1e-9),
        );
        expect(
          s.copyWith(spacing: ReaderLineSpacing.loose).bodyLineHeight,
          closeTo(expectedSteps[i].$2 * 1.15, 1e-9),
        );
      }
    });

    test(
      'roundtrips through KeyValueStore and handles invalid or legacy data',
      () async {
        final kv = FakeKeyValueStore();
        const custom = ReaderSettings(
          step: 6,
          page: ReaderPageTheme.sepia,
          font: ReaderFont.lexend,
          spacing: ReaderLineSpacing.loose,
          underlineWords: false,
          lightUpSentence: false,
          speed: 0.75,
        );
        await custom.saveTo(kv);
        expect(ReaderSettings.loadFrom(kv), custom);

        // Numeric double step (e.g. decoded on web), clamping, and non-finite guards.
        expect(ReaderSettings.fromJson({'step': 5.0}).step, 5);
        expect(ReaderSettings.fromJson({'step': 0}).step, 1);
        expect(ReaderSettings.fromJson({'step': 99}).step, 7);
        expect(ReaderSettings.fromJson({'step': double.nan}).step, 4);
        expect(ReaderSettings.fromJson({'step': double.infinity}).step, 4);

        // Corrupt JSON falls back to defaults.
        await kv.write('settings', '{bad json');
        expect(ReaderSettings.loadFrom(kv), const ReaderSettings());

        // Legacy tam=24 maps to step 6 when settings key is absent.
        final legacyKv = FakeKeyValueStore()..values['tam'] = '24';
        expect(ReaderSettings.loadFrom(legacyKv).step, 6);
      },
    );
  });

  group('Text and page settings sheet (N5.2)', () {
    testWidgets(
      'text size steps 1..7 update page typography, dashes, label, and survive restart',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final services = fakeServices();
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await _addSampleBook(store);

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('run1'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);

        expect(_firstBodyTextStyle(tester).fontSize, 19);
        expect(_firstBodyTextStyle(tester).height! * 19, closeTo(31, 0.01));
        final pagesAtDefault = store.place(book.id).totalPages!;

        await _openSettingsSheet(tester);

        expect(find.text('TEXT SIZE'), findsOneWidget);
        expect(find.text('Step 4 of 7'), findsOneWidget);
        expect(
          [for (var i = 0; i < 7; i++) _sizeDashColor(tester, i)],
          [
            NocheColors.text,
            NocheColors.text,
            NocheColors.text,
            NocheColors.text,
            NocheColors.line,
            NocheColors.line,
            NocheColors.line,
          ],
        );

        // Tap Larger A three times: 4 -> 5 -> 6 -> 7, then extra tap clamps at 7.
        final larger = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.largerText),
        );
        final smaller = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.smallerText),
        );

        await tester.tap(larger);
        await settle(tester);
        expect(find.text('Step 5 of 7'), findsOneWidget);
        expect(_firstBodyTextStyle(tester).fontSize, 21);

        await tester.tap(larger);
        await settle(tester);
        expect(find.text('Step 6 of 7'), findsOneWidget);
        expect(_firstBodyTextStyle(tester).fontSize, 23);

        await tester.tap(larger);
        await settle(tester);
        expect(find.text('Step 7 of 7'), findsOneWidget);
        expect(_firstBodyTextStyle(tester).fontSize, 26);
        expect(_firstBodyTextStyle(tester).height! * 26, closeTo(42, 0.01));
        expect(store.place(book.id).totalPages!, greaterThan(pagesAtDefault));

        await tester.tap(larger);
        await settle(tester);
        expect(find.text('Step 7 of 7'), findsOneWidget);

        // Tap Smaller A down to step 1 and verify clamping at 1.
        for (var i = 0; i < 7; i++) {
          await tester.tap(smaller);
          await settle(tester);
        }
        expect(find.text('Step 1 of 7'), findsOneWidget);
        expect(_firstBodyTextStyle(tester).fontSize, 15);
        expect(_firstBodyTextStyle(tester).height! * 15, closeTo(25, 0.01));

        // Close sheet, restart TextReader on same fake storage, confirm persistence.
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.closeTextAndPage)),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('run2'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);

        expect(_firstBodyTextStyle(tester).fontSize, 15);
        await _openSettingsSheet(tester);
        expect(find.text('Step 1 of 7'), findsOneWidget);
      },
    );

    testWidgets(
      'font tiles (80 high), exact help line, immediate page font update, and persistence',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final services = fakeServices();
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await _addSampleBook(store);

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('font1'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);

        expect(
          _firstBodyTextStyle(tester).fontFamily,
          NocheType.bookBody.fontFamily,
        );

        await _openSettingsSheet(tester);

        expect(find.text('FONT'), findsOneWidget);
        expect(
          find.text(
            'No font is fastest for everyone. Keep the one you read most easily.',
          ),
          findsOneWidget,
        );
        expect(find.text('Ag'), findsNWidgets(3));
        for (final name in ['Literata', 'Atkinson', 'Lexend']) {
          final tileFinder = find.bySemanticsLabel(name);
          expect(tileFinder, findsOneWidget);
          expect(tester.getSize(tileFinder).height, 80);
        }

        // Switch to Atkinson -> body style changes fontFamily from Literata to Atkinson
        // while preserving NocheType.body's own weight.
        final literataFamily = _firstBodyTextStyle(tester).fontFamily;
        expect(_firstBodyTextStyle(tester).fontWeight, FontWeight.w400);
        await tester.tap(find.bySemanticsLabel('Atkinson'));
        await settle(tester);
        final atkinsonStyle = _firstBodyTextStyle(tester);
        expect(atkinsonStyle.fontFamily, NocheType.body.fontFamily);
        expect(atkinsonStyle.fontFamily, isNot(literataFamily));
        expect(atkinsonStyle.fontWeight, NocheType.body.fontWeight);
        expect(
          ReaderSettings.loadFrom(services.storage('leer')).font,
          ReaderFont.atkinson,
        );

        // Lexend tile stays disabled until coqui_ui exposes NocheType.bookBodyLexend
        // so learners are never shown Atkinson mislabelled as Lexend.
        final lexendSemantics = tester.getSemantics(
          find.bySemanticsLabel('Lexend'),
        );
        if (ReaderSettings.lexendAvailable) {
          await tester.tap(find.bySemanticsLabel('Lexend'));
          await settle(tester);
          final lexendStyle = _firstBodyTextStyle(tester);
          expect(lexendStyle.fontFamily, endsWith(nocheFontLexend));
          expect(lexendStyle.fontFamily, isNot(atkinsonStyle.fontFamily));
        } else {
          expect(
            lexendSemantics.flagsCollection.isEnabled,
            ui.Tristate.isFalse,
          );
          expect(lexendSemantics.hint, isNotEmpty);
          await tester.tap(find.bySemanticsLabel('Lexend'));
          await settle(tester);
          expect(
            ReaderSettings.loadFrom(services.storage('leer')).font,
            ReaderFont.atkinson,
          );
        }

        // Restart TextReader on same storage -> Atkinson survives restart.
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('app-font2'),
            home: TextReader(
              key: const ValueKey('font2'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);
        expect(
          _firstBodyTextStyle(tester).fontFamily,
          NocheType.body.fontFamily,
        );
        await _openSettingsSheet(tester);
        final atkinsonSemantics = tester.getSemantics(
          find.bySemanticsLabel('Atkinson'),
        );
        expect(
          atkinsonSemantics.flagsCollection.isChecked,
          ui.CheckedState.isTrue,
        );
      },
    );

    testWidgets(
      'line spacing Tight/Normal/Loose updates line height immediately and survives restart',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final services = fakeServices();
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await _addSampleBook(store);

        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('app-spacing1'),
            home: TextReader(
              key: const ValueKey('spacing1'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);

        double renderedLineHeight() {
          final style = _firstBodyTextStyle(tester);
          return style.fontSize! * style.height!;
        }

        expect(renderedLineHeight(), closeTo(31.0, 0.01));
        await _openSettingsSheet(tester);

        expect(find.text('LINE SPACING'), findsOneWidget);
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.lineSpacingTight)),
        );
        await settle(tester);
        expect(renderedLineHeight(), closeTo(31.0 * 0.88, 0.01));

        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.lineSpacingLoose)),
        );
        await settle(tester);
        expect(renderedLineHeight(), closeTo(31.0 * 1.15, 0.01));

        // Restart TextReader -> Loose spacing survives restart.
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('app-spacing2'),
            home: TextReader(
              key: const ValueKey('spacing2'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);
        expect(renderedLineHeight(), closeTo(31.0 * 1.15, 0.01));
      },
    );

    testWidgets(
      'page colour Night/Sepia/Day updates page behind scrim immediately and survives restart',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final services = fakeServices();
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await _addSampleBook(store);

        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('app-page1'),
            home: TextReader(
              key: const ValueKey('page1'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);

        expect(_readerPageBackground(tester), NocheColors.lessonGround);
        expect(_firstBodyTextStyle(tester).color, NocheColors.nightText);

        await _openSettingsSheet(tester);
        expect(find.text('PAGE'), findsOneWidget);

        for (final role in [
          NocheA11y.pageNight,
          NocheA11y.pageSepia,
          NocheA11y.pageDay,
        ]) {
          final pill = find.bySemanticsLabel(NocheA11y.label(role));
          expect(pill, findsOneWidget);
          expect(tester.getSize(pill).height, 48);
        }

        // Switch to Sepia -> page behind sheet transitions to Sepia in move.
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.pageSepia)),
        );
        await tester.pumpAndSettle();
        expect(_readerPageBackground(tester), NocheColors.sepiaPage);
        expect(_firstBodyTextStyle(tester).color, NocheColors.sepiaText);

        // Switch to Day -> page behind sheet transitions to Day in move.
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.pageDay)),
        );
        await tester.pumpAndSettle();
        expect(_readerPageBackground(tester), NocheColors.dayPage);
        expect(_firstBodyTextStyle(tester).color, NocheColors.dayText);

        // Restart TextReader -> Day theme survives restart.
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('app-page2'),
            home: TextReader(
              key: const ValueKey('page2'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);
        expect(_readerPageBackground(tester), NocheColors.dayPage);
        expect(_firstBodyTextStyle(tester).color, NocheColors.dayText);
      },
    );

    testWidgets(
      'underline switch hides both solid and dotted underlines in quick and survives restart',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final progress = FakeProgressStore();
        progress.import(
          jsonEncode({
            ...progress.raw,
            'palabras': {
              'casa': _earWord('casa', 4).toJson(), // known -> none
              'encendida': _earWord(
                'encendida',
                2,
              ).toJson(), // learning -> dotted
              // 'sofrito' omitted -> stage 0 -> solid listening underline
            },
          }),
        );
        final services = fakeServices(progress: progress);
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await store.add(
          now: 1,
          title: 'Prueba',
          body: 'Casa encendida sofrito.',
          generated: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('app-underline1'),
            home: TextReader(
              key: const ValueKey('underline1'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);

        // Both underline kinds painted when ON.
        final before = _paintPageDecorations(tester);
        expect(
          before.lines.any((l) => l.argb == NocheColors.listening.toARGB32()),
          isTrue,
        );
        expect(
          before.rects.any((r) => r.argb == NocheColors.lessonLabel.toARGB32()),
          isTrue,
        );

        await _openSettingsSheet(tester);
        await tester.tap(find.text("Underline words I'm still learning"));
        await tester.pumpAndSettle();

        // Both underline kinds fade away cleanly.
        final after = _paintPageDecorations(tester);
        expect(after.lines, isEmpty);
        expect(after.rects, isEmpty);

        // Restart TextReader -> underlines stay off.
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('app-underline2'),
            home: TextReader(
              key: const ValueKey('underline2'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);
        final restarted = _paintPageDecorations(tester);
        expect(restarted.lines, isEmpty);
        expect(restarted.rects, isEmpty);
      },
    );

    testWidgets(
      'light up sentence switch toggles active sentence highlight immediately and survives restart',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final course = TestCourse();
        final clips = TimedClips(length: const Duration(seconds: 5));
        final services = fakeServices(course: course, clips: clips);

        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('app-lit1'),
            home: TextReader(
              key: const ValueKey('lit1'),
              services: services,
              id: 'uno',
            ),
          ),
        );
        await settle(tester);

        // Start playback so sentence u1 is active and lit.
        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        await tester.pump(NocheMotion.quick);

        final litBefore = _paintPageDecorations(tester);
        expect(
          litBefore.rrects.any(
            (r) => r.argb == NocheColors.litSentence.toARGB32(),
          ),
          isTrue,
        );

        // Open settings while active sentence is playing, turn light-up OFF.
        await _openSettingsSheet(tester);
        await tester.tap(find.text('Light up the sentence being read'));
        await tester.pump();
        await tester.pump(NocheMotion.quick);

        final litAfterOff = _paintPageDecorations(tester);
        expect(
          litAfterOff.rrects.any(
            (r) => r.argb == NocheColors.litSentence.toARGB32(),
          ),
          isFalse,
        );

        // Restart TextReader on same storage and play again -> stays unlit.
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('app-lit2'),
            home: TextReader(
              key: const ValueKey('lit2'),
              services: services,
              id: 'uno',
            ),
          ),
        );
        await settle(tester);

        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final litRestarted = _paintPageDecorations(tester);
        expect(
          litRestarted.rrects.any(
            (r) => r.argb == NocheColors.litSentence.toARGB32(),
          ),
          isFalse,
        );

        // Stop playback before test ends so no pending timers remain.
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.pause)),
        );
        await settle(tester);
      },
    );

    testWidgets('meets 48x48 touch targets and renders cleanly in RTL Arabic', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final course = FakeCourseCatalog.arabic();
      await course.load();
      final services = fakeServices(course: course);
      final store = ReadingStore(services.storage(ReadingStore.space));
      final book = await store.add(
        now: 1,
        title: 'بيت جدة',
        body: 'هذا بيت جدة الكبير في المدينة القديمة.',
        generated: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TextReader(services: services, id: book.id),
        ),
      );
      await settle(tester);

      await _openSettingsSheet(tester);
      expect(tester.takeException(), isNull);
      // Arabic reader page behind the scrim stays RTL while English sheet chrome
      // follows ambient app directionality.
      expect(
        Directionality.of(tester.element(find.byType(ReaderPageView))),
        TextDirection.rtl,
      );
      expect(
        Directionality.of(tester.element(find.byType(ReaderSettingsSheet))),
        TextDirection.ltr,
      );

      for (final label in [
        NocheA11y.label(NocheA11y.smallerText),
        NocheA11y.label(NocheA11y.largerText),
        'Literata',
        'Atkinson',
        'Lexend',
        NocheA11y.label(NocheA11y.lineSpacingTight),
        NocheA11y.label(NocheA11y.lineSpacingNormal),
        NocheA11y.label(NocheA11y.lineSpacingLoose),
        NocheA11y.label(NocheA11y.pageNight),
        NocheA11y.label(NocheA11y.pageSepia),
        NocheA11y.label(NocheA11y.pageDay),
      ]) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets(
      'changing text size during narration refreshes sentence page mapping without out-of-range page index',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final filler = List.filled(
          18,
          'Caminamos despacio por la orilla del mar escuchando las olas.',
        ).join(' ');
        final course = TestCourse(
          books: {
            'narr-reflow': Book(
              id: 'narr-reflow',
              title: 'Reflow',
              readable: true,
              pages: [
                BookPage(image: 'img/1.png', clips: ['n1']),
                BookPage(image: 'img/2.png', clips: ['n2']),
                BookPage(image: 'img/3.png', clips: ['n3']),
              ],
            ),
          },
          stories: {
            'narr-reflow': {
              'title': 'Reflow',
              'clips': {
                'n1': line('narr', 'Primera frase corta.'),
                'n2': line('narr', filler),
                'n3': line('narr', 'Última frase del libro.'),
              },
            },
          },
          recorded: {'n1', 'n2', 'n3'},
        );
        final clips = TimedClips(length: const Duration(milliseconds: 600));
        final services = fakeServices(course: course, clips: clips);

        // Start at largest text size (step 7) so the book spans multiple pages.
        await const ReaderSettings(step: 7).saveTo(services.storage('leer'));

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: 'narr-reflow'),
          ),
        );
        await settle(tester);

        // Start playback on n1, then shrink text size all the way down to step 1
        // while playback is still running so total page count shrinks sharply.
        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        expect(clips.played, ['n1']);

        await _openSettingsSheet(tester);
        final smaller = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.smallerText),
        );
        for (var i = 0; i < 6; i++) {
          await tester.tap(smaller);
          await tester.pump();
        }
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.closeTextAndPage)),
        );
        await tester.pump();

        // Advance into n2, then into n3; narration uses refreshed page indices
        // and lights n3 cleanly without out-of-range page exceptions.
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(NocheMotion.followAfter + NocheMotion.move);
        expect(tester.takeException(), isNull);
        expect(clips.played, containsAllInOrder(['n1', 'n2', 'n3']));
        final lit = _paintPageDecorations(tester);
        expect(
          lit.rrects.any((r) => r.argb == NocheColors.litSentence.toARGB32()),
          isTrue,
        );

        // Let final clip finish cleanly.
        await tester.pump(const Duration(milliseconds: 700));
        await settle(tester);
      },
    );

    testWidgets(
      'paused narration does not override current page anchor when changing text size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final filler = List.filled(
          18,
          'Caminamos despacio por la orilla del mar escuchando las olas.',
        ).join(' ');
        final course = TestCourse(
          books: {
            'narr-pause': Book(
              id: 'narr-pause',
              title: 'Pausa',
              readable: true,
              pages: [
                BookPage(image: 'img/1.png', clips: ['p1']),
                BookPage(image: 'img/2.png', clips: ['p2']),
              ],
            ),
          },
          stories: {
            'narr-pause': {
              'title': 'Pausa',
              'clips': {
                'p1': line('narr', 'Primera frase corta.'),
                'p2': line('narr', filler),
              },
            },
          },
          recorded: {'p1', 'p2'},
        );
        final clips = TimedClips(length: const Duration(seconds: 5));
        final services = fakeServices(course: course, clips: clips);
        await const ReaderSettings(step: 6).saveTo(services.storage('leer'));

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: 'narr-pause'),
          ),
        );
        await settle(tester);
        expect(find.textContaining('1 / '), findsOneWidget);

        // Start playback on page 1, pause, turn to page 2, then increase text size:
        // repagination keeps page 2's reading anchor instead of jumping back to page 1.
        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.pause)),
        );
        await settle(tester);

        await tester.fling(
          find.byType(ReaderPageView),
          const Offset(-300, 0),
          800,
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('2 / '), findsOneWidget);

        await _openSettingsSheet(tester);
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.largerText)),
        );
        await settle(tester);
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.closeTextAndPage)),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('1 / '), findsNothing);
      },
    );
  });

  group('Text and page motion (N8.14)', () {
    Color aaSurfaceColor(WidgetTester tester) {
      final box = tester.widget<Container>(
        find.byKey(const Key('reader-aa-button-surface')),
      );
      return (box.decoration! as BoxDecoration).color!;
    }

    Color aaLabelColor(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const Key('reader-aa-button-label')))
        .style!
        .color!;

    Color textColorByKey(WidgetTester tester, Key key) =>
        tester.widget<Text>(find.byKey(key)).style!.color!;

    Color containerColorByKey(WidgetTester tester, Key key) =>
        tester.widget<Container>(find.byKey(key)).color!;

    double argbAlpha(int argb) => ((argb >> 24) & 0xff) / 255.0;

    void expectIntermediateColor(Color actual, Color start, Color end) {
      expect(actual, isNot(start));
      expect(actual, isNot(end));
    }

    Future<void> pumpSampleReader(
      WidgetTester tester, {
      Services? services,
      bool disableAnimations = false,
      TextDirection? appDirection,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final svc = services ?? fakeServices();
      final store = ReadingStore(svc.storage(ReadingStore.space));
      final book = await _addSampleBook(store);

      Widget app = MaterialApp(
        builder: appDirection == null
            ? null
            : (context, child) =>
                  Directionality(textDirection: appDirection, child: child!),
        home: TextReader(services: svc, id: book.id),
      );
      if (disableAnimations) {
        app = MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: app,
        );
      }

      await tester.pumpWidget(app);
      await settle(tester);
    }

    testWidgets(
      'scrimless sheet slides in pageIn/pageOut, closes on tap above, and Aa button fills/unfills in quick',
      (tester) async {
        await pumpSampleReader(tester);

        // Closed state: Aa button is transparent with nightText label.
        expect(aaSurfaceColor(tester).a, closeTo(0.0, 1e-6));
        expect(aaLabelColor(tester), NocheColors.nightText);

        // Tap Aa to open.
        await tester.tap(find.byKey(const Key('reader-aa-button')));
        await tester.pump();

        // No scrim barrier or NocheColors.scrim overlay anywhere in the tree.
        expect(find.byKey(const ValueKey('noche_sheet_scrim')), findsNothing);
        expect(
          find.byWidgetPredicate(
            (w) =>
                (w is ModalBarrier && w.color == NocheColors.scrim) ||
                (w is ColoredBox && w.color == NocheColors.scrim),
          ),
          findsNothing,
        );

        // Frame 0: sheet starts off bottom (dy == 1.0), Aa starts at 0.
        final surfaceFinder = find.byKey(
          const ValueKey('reader_settings_sheet_surface'),
        );
        expect(surfaceFinder, findsOneWidget);
        expect(
          tester.widget<FractionalTranslation>(surfaceFinder).translation.dy,
          closeTo(1.0, 1e-6),
        );
        expect(aaSurfaceColor(tester).a, closeTo(0.0, 1e-6));

        // Midpoint of quick: Aa surface and label are mid-transition.
        await tester.pump(NocheMotion.quick ~/ 2);
        expect(aaSurfaceColor(tester).a, greaterThan(0.0));
        expect(aaSurfaceColor(tester).a, lessThan(1.0));
        expectIntermediateColor(
          aaLabelColor(tester),
          NocheColors.nightText,
          NocheColors.lessonGround,
        );

        // End of quick: Aa fill is complete while sheet is still rising.
        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));
        expect(aaSurfaceColor(tester), NocheColors.nightText);
        expect(aaLabelColor(tester), NocheColors.lessonGround);

        // Midpoint of pageIn: sheet is strictly partway up following enter curve.
        final toPageInMid = (NocheMotion.pageIn ~/ 2) - NocheMotion.quick;
        if (toPageInMid > Duration.zero) {
          await tester.pump(toPageInMid);
        }
        final midInDy = tester
            .widget<FractionalTranslation>(surfaceFinder)
            .translation
            .dy;
        expect(midInDy, greaterThan(0.0));
        expect(midInDy, lessThan(1.0));
        expect(midInDy, closeTo(1.0 - NocheMotion.enter.transform(0.5), 0.08));

        // End of pageIn: sheet rests at dy == 0.0.
        await tester.pump(
          NocheMotion.pageIn -
              (toPageInMid > Duration.zero
                  ? NocheMotion.pageIn ~/ 2
                  : NocheMotion.quick),
        );
        expect(
          tester.widget<FractionalTranslation>(surfaceFinder).translation.dy,
          closeTo(0.0, 1e-6),
        );

        // Tap above the sheet to dismiss.
        await tester.tap(find.byKey(const Key('reader-settings-closer')));
        await tester.pump();

        // Midpoint of quick during close: Aa unfills partway; sheet begins exiting.
        await tester.pump(NocheMotion.quick ~/ 2);
        expect(aaSurfaceColor(tester).a, greaterThan(0.0));
        expect(aaSurfaceColor(tester).a, lessThan(1.0));
        expectIntermediateColor(
          aaLabelColor(tester),
          NocheColors.lessonGround,
          NocheColors.nightText,
        );

        // Midpoint of pageOut: sheet slides down along exit curve.
        final toPageOutMid =
            (NocheMotion.pageOut ~/ 2) - (NocheMotion.quick ~/ 2);
        await tester.pump(toPageOutMid);
        final midOutDy = tester
            .widget<FractionalTranslation>(surfaceFinder)
            .translation
            .dy;
        expect(midOutDy, greaterThan(0.0));
        expect(midOutDy, lessThan(1.0));
        expect(midOutDy, closeTo(NocheMotion.exit.transform(0.5), 0.08));

        // End of quick: Aa is back to unfilled.
        final toQuickEnd = NocheMotion.quick - (NocheMotion.pageOut ~/ 2);
        if (toQuickEnd > Duration.zero) {
          await tester.pump(toQuickEnd);
        }
        expect(aaSurfaceColor(tester).a, closeTo(0.0, 1e-6));
        expect(aaLabelColor(tester), NocheColors.nightText);

        // End of pageOut: sheet is dismissed.
        await tester.pump(NocheMotion.pageOut);
        await tester.pump();
        expect(find.byType(ReaderSettingsSheet), findsNothing);
      },
    );

    testWidgets(
      'text size dashes fill and empty in quick while page body fontSize updates immediately',
      (tester) async {
        await pumpSampleReader(tester);
        await _openSettingsSheet(tester);

        final larger = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.largerText),
        );
        final smaller = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.smallerText),
        );

        expect(_firstBodyTextStyle(tester).fontSize, 19);
        expect(_sizeDashColor(tester, 4), NocheColors.line);

        // Step up 4 -> 5: body fontSize changes on frame 0; dash 4 fills in quick.
        await tester.tap(larger);
        await tester.pump();
        expect(_firstBodyTextStyle(tester).fontSize, 21);
        expect(_sizeDashColor(tester, 4), NocheColors.line);

        await tester.pump(NocheMotion.quick ~/ 2);
        expectIntermediateColor(
          _sizeDashColor(tester, 4),
          NocheColors.line,
          NocheColors.text,
        );

        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));
        expect(_sizeDashColor(tester, 4), NocheColors.text);

        // Step down 5 -> 4: body fontSize changes on frame 0; dash 4 empties in quick.
        await tester.tap(smaller);
        await tester.pump();
        expect(_firstBodyTextStyle(tester).fontSize, 19);
        expect(_sizeDashColor(tester, 4), NocheColors.text);

        await tester.pump(NocheMotion.quick ~/ 2);
        expectIntermediateColor(
          _sizeDashColor(tester, 4),
          NocheColors.text,
          NocheColors.line,
        );

        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));
        expect(_sizeDashColor(tester, 4), NocheColors.line);
      },
    );

    testWidgets(
      'font outline mark slides horizontally in move on travel while page body fontFamily updates immediately',
      (tester) async {
        await pumpSampleReader(tester);
        await _openSettingsSheet(tester);

        final markFinder = find.byKey(
          const ValueKey('noche_outline_group_mark'),
        );
        final literataFinder = find.bySemanticsLabel('Literata');
        final atkinsonFinder = find.bySemanticsLabel('Atkinson');

        final startX = tester.getTopLeft(markFinder).dx;
        final targetX = tester.getTopLeft(atkinsonFinder).dx;
        expect(startX, closeTo(tester.getTopLeft(literataFinder).dx, 0.5));
        expect(targetX, greaterThan(startX));

        await tester.tap(atkinsonFinder);
        await tester.pump();

        // Body fontFamily updates on frame 0; outline mark begins at startX.
        expect(
          _firstBodyTextStyle(tester).fontFamily,
          NocheType.body.fontFamily,
        );
        expect(tester.getTopLeft(markFinder).dx, closeTo(startX, 0.5));

        // Midpoint of move: mark travels along NocheMotion.travel.
        await tester.pump(NocheMotion.move ~/ 2);
        final midX = tester.getTopLeft(markFinder).dx;
        expect(midX, greaterThan(startX));
        expect(midX, lessThan(targetX));
        expect(
          midX,
          closeTo(
            ui.lerpDouble(startX, targetX, NocheMotion.travel.transform(0.5))!,
            2.0,
          ),
        );

        // End of move: mark lands on Atkinson tile.
        await tester.pump(NocheMotion.move - (NocheMotion.move ~/ 2));
        expect(tester.getTopLeft(markFinder).dx, closeTo(targetX, 0.5));
      },
    );

    testWidgets(
      'line spacing thumb slides in move on travel while page line height updates immediately',
      (tester) async {
        await pumpSampleReader(tester);
        await _openSettingsSheet(tester);

        double renderedLineHeight() {
          final style = _firstBodyTextStyle(tester);
          return style.fontSize! * style.height!;
        }

        final thumbFinder = find.byKey(
          const ValueKey('reader-line-spacing-thumb'),
        );
        final normalFinder = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.lineSpacingNormal),
        );
        final looseFinder = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.lineSpacingLoose),
        );

        final startX = tester.getTopLeft(thumbFinder).dx;
        final targetX = tester.getTopLeft(looseFinder).dx;
        expect(startX, closeTo(tester.getTopLeft(normalFinder).dx, 0.5));
        expect(targetX, greaterThan(startX));

        await tester.tap(looseFinder);
        await tester.pump();

        // Line height updates immediately on frame 0; thumb starts at startX.
        expect(renderedLineHeight(), closeTo(31.0 * 1.15, 0.01));
        expect(tester.getTopLeft(thumbFinder).dx, closeTo(startX, 0.5));

        // Midpoint of move: thumb travels along NocheMotion.travel.
        await tester.pump(NocheMotion.move ~/ 2);
        final midX = tester.getTopLeft(thumbFinder).dx;
        expect(midX, greaterThan(startX));
        expect(midX, lessThan(targetX));
        expect(
          midX,
          closeTo(
            ui.lerpDouble(startX, targetX, NocheMotion.travel.transform(0.5))!,
            2.0,
          ),
        );

        // End of move: thumb lands on Loose option.
        await tester.pump(NocheMotion.move - (NocheMotion.move ~/ 2));
        expect(tester.getTopLeft(thumbFinder).dx, closeTo(targetX, 0.5));
      },
    );

    testWidgets(
      'page colour ring slides and page ground, text, labels, and rule all transition together in move on travel',
      (tester) async {
        await pumpSampleReader(tester);
        await _openSettingsSheet(tester);

        final ringFinder = find.byKey(const ValueKey('reader-page-color-ring'));
        final nightFinder = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.pageNight),
        );
        final sepiaFinder = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.pageSepia),
        );

        final startX = tester.getTopLeft(ringFinder).dx;
        final targetX = tester.getTopLeft(sepiaFinder).dx;
        expect(startX, closeTo(tester.getTopLeft(nightFinder).dx, 0.5));
        expect(targetX, greaterThan(startX));

        // Initial Night colors.
        expect(_readerPageBackground(tester), NocheColors.lessonGround);
        expect(_firstBodyTextStyle(tester).color, NocheColors.nightText);
        expect(
          textColorByKey(tester, const Key('reader-book-title')),
          NocheColors.lessonLabel,
        );
        expect(
          textColorByKey(tester, const Key('reader-chapter-label')),
          NocheColors.lessonLabel,
        );
        expect(
          textColorByKey(tester, const Key('reader-chapter-title')),
          NocheColors.text,
        );
        expect(
          containerColorByKey(tester, const Key('reader-chapter-rule')),
          NocheColors.lessonBorder,
        );

        // Tap Sepia.
        await tester.tap(sepiaFinder);
        await tester.pump();

        // Frame 0: ring and colors start at Night.
        expect(tester.getTopLeft(ringFinder).dx, closeTo(startX, 0.5));
        expect(_readerPageBackground(tester), NocheColors.lessonGround);

        // Midpoint of move: ring AND all page colors are strictly intermediate.
        await tester.pump(NocheMotion.move ~/ 2);
        final midX = tester.getTopLeft(ringFinder).dx;
        expect(midX, greaterThan(startX));
        expect(midX, lessThan(targetX));
        expect(
          midX,
          closeTo(
            ui.lerpDouble(startX, targetX, NocheMotion.travel.transform(0.5))!,
            2.0,
          ),
        );

        expectIntermediateColor(
          _readerPageBackground(tester),
          NocheColors.lessonGround,
          NocheColors.sepiaPage,
        );
        expectIntermediateColor(
          _firstBodyTextStyle(tester).color!,
          NocheColors.nightText,
          NocheColors.sepiaText,
        );
        expectIntermediateColor(
          textColorByKey(tester, const Key('reader-book-title')),
          NocheColors.lessonLabel,
          NocheColors.sepiaLabel,
        );
        expectIntermediateColor(
          textColorByKey(tester, const Key('reader-chapter-label')),
          NocheColors.lessonLabel,
          NocheColors.sepiaLabel,
        );
        expectIntermediateColor(
          textColorByKey(tester, const Key('reader-chapter-title')),
          NocheColors.text,
          NocheColors.sepiaText,
        );
        expectIntermediateColor(
          containerColorByKey(tester, const Key('reader-chapter-rule')),
          NocheColors.lessonBorder,
          NocheColors.sepiaRule,
        );

        // End of move: ring lands on Sepia and all colors reach exact Sepia palette.
        await tester.pump(NocheMotion.move - (NocheMotion.move ~/ 2));
        expect(tester.getTopLeft(ringFinder).dx, closeTo(targetX, 0.5));
        expect(_readerPageBackground(tester), NocheColors.sepiaPage);
        expect(_firstBodyTextStyle(tester).color, NocheColors.sepiaText);
        expect(
          textColorByKey(tester, const Key('reader-book-title')),
          NocheColors.sepiaLabel,
        );
        expect(
          textColorByKey(tester, const Key('reader-chapter-label')),
          NocheColors.sepiaLabel,
        );
        expect(
          textColorByKey(tester, const Key('reader-chapter-title')),
          NocheColors.sepiaText,
        );
        expect(
          containerColorByKey(tester, const Key('reader-chapter-rule')),
          NocheColors.sepiaRule,
        );
      },
    );

    testWidgets(
      'underline switch knob travels in move while solid and dotted underlines fade out/in in quick',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final progress = FakeProgressStore();
        progress.import(
          jsonEncode({
            ...progress.raw,
            'palabras': {
              'casa': _earWord('casa', 4).toJson(),
              'encendida': _earWord('encendida', 2).toJson(),
            },
          }),
        );
        final services = fakeServices(progress: progress);
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await store.add(
          now: 1,
          title: 'Prueba',
          body: 'Casa encendida sofrito.',
          generated: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: book.id),
          ),
        );
        await settle(tester);
        await _openSettingsSheet(tester);

        final switchFinder = find.byKey(const Key('reader-switch-underline'));
        final knobFinder = find.descendant(
          of: switchFinder,
          matching: find.byKey(const ValueKey('noche_switch_knob')),
        );
        final onKnobX = tester.getTopLeft(knobFinder).dx;

        // Toggle OFF.
        await tester.tap(switchFinder);
        await tester.pump();

        // Midpoint of quick: both underline kinds fade partway and knob is moving.
        await tester.pump(NocheMotion.quick ~/ 2);
        final midOff = _paintPageDecorations(tester);
        expect(midOff.lines, isNotEmpty);
        expect(midOff.rects, isNotEmpty);
        expect(argbAlpha(midOff.lines.first.argb), greaterThan(0.0));
        expect(argbAlpha(midOff.lines.first.argb), lessThan(1.0));
        expect(argbAlpha(midOff.rects.first.argb), greaterThan(0.0));
        expect(argbAlpha(midOff.rects.first.argb), lessThan(1.0));
        final midOffKnobX = tester.getTopLeft(knobFinder).dx;
        expect(midOffKnobX, lessThan(onKnobX));

        // End of quick: underlines are completely faded out.
        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));
        final endOff = _paintPageDecorations(tester);
        expect(endOff.lines, isEmpty);
        expect(endOff.rects, isEmpty);

        // End of move: knob finishes traveling to start.
        await tester.pump(NocheMotion.move - NocheMotion.quick);
        final offKnobX = tester.getTopLeft(knobFinder).dx;
        expect(offKnobX, lessThan(midOffKnobX));

        // Toggle ON.
        await tester.tap(switchFinder);
        await tester.pump();

        // Midpoint of quick: both underline kinds fade back in partway.
        await tester.pump(NocheMotion.quick ~/ 2);
        final midOn = _paintPageDecorations(tester);
        expect(midOn.lines, isNotEmpty);
        expect(midOn.rects, isNotEmpty);
        expect(argbAlpha(midOn.lines.first.argb), greaterThan(0.0));
        expect(argbAlpha(midOn.lines.first.argb), lessThan(1.0));
        expect(argbAlpha(midOn.rects.first.argb), greaterThan(0.0));
        expect(argbAlpha(midOn.rects.first.argb), lessThan(1.0));
        final midOnKnobX = tester.getTopLeft(knobFinder).dx;
        expect(midOnKnobX, greaterThan(offKnobX));
        expect(midOnKnobX, lessThan(onKnobX));

        // End of quick: underlines are back to full color.
        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));
        final endOn = _paintPageDecorations(tester);
        expect(
          endOn.lines.any((l) => l.argb == NocheColors.listening.toARGB32()),
          isTrue,
        );
        expect(
          endOn.rects.any((r) => r.argb == NocheColors.lessonLabel.toARGB32()),
          isTrue,
        );

        // End of move: knob returns to ON position.
        await tester.pump(NocheMotion.move - NocheMotion.quick);
        expect(tester.getTopLeft(knobFinder).dx, closeTo(onKnobX, 0.5));
      },
    );

    testWidgets(
      'light-up-sentence switch knob travels in move while active sentence highlight fades out/in in quick',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final course = TestCourse();
        final clips = TimedClips(length: const Duration(seconds: 10));
        final services = fakeServices(course: course, clips: clips);

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: 'uno'),
          ),
        );
        await settle(tester);

        // Start playback so first sentence is active and lit.
        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        await tester.pump(NocheMotion.quick);

        await _openSettingsSheet(tester);

        final switchFinder = find.byKey(const Key('reader-switch-lit'));
        final knobFinder = find.descendant(
          of: switchFinder,
          matching: find.byKey(const ValueKey('noche_switch_knob')),
        );
        final onKnobX = tester.getTopLeft(knobFinder).dx;
        final fullLitAlpha = NocheColors.litSentence.a;

        // Toggle OFF.
        await tester.tap(switchFinder);
        await tester.pump();

        // Midpoint of quick: sentence highlight alpha is strictly intermediate.
        await tester.pump(NocheMotion.quick ~/ 2);
        final midOff = _paintPageDecorations(tester);
        expect(midOff.rrects, isNotEmpty);
        expect(argbAlpha(midOff.rrects.first.argb), greaterThan(0.0));
        expect(argbAlpha(midOff.rrects.first.argb), lessThan(fullLitAlpha));
        final midOffKnobX = tester.getTopLeft(knobFinder).dx;
        expect(midOffKnobX, lessThan(onKnobX));

        // End of quick: highlight faded out completely.
        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));
        expect(_paintPageDecorations(tester).rrects, isEmpty);

        // End of move: knob lands at OFF position.
        await tester.pump(NocheMotion.move - NocheMotion.quick);
        final offKnobX = tester.getTopLeft(knobFinder).dx;
        expect(offKnobX, lessThan(midOffKnobX));

        // Toggle ON.
        await tester.tap(switchFinder);
        await tester.pump();

        // Midpoint of quick: sentence highlight fades back in partway.
        await tester.pump(NocheMotion.quick ~/ 2);
        final midOn = _paintPageDecorations(tester);
        expect(midOn.rrects, isNotEmpty);
        expect(argbAlpha(midOn.rrects.first.argb), greaterThan(0.0));
        expect(argbAlpha(midOn.rrects.first.argb), lessThan(fullLitAlpha));
        final midOnKnobX = tester.getTopLeft(knobFinder).dx;
        expect(midOnKnobX, greaterThan(offKnobX));
        expect(midOnKnobX, lessThan(onKnobX));

        // End of quick: highlight reaches full litSentence color.
        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));
        expect(
          _paintPageDecorations(tester).rrects
              .any((r) => r.argb == NocheColors.litSentence.toARGB32()),
          isTrue,
        );

        // End of move: knob returns to ON position.
        await tester.pump(NocheMotion.move - NocheMotion.quick);
        expect(tester.getTopLeft(knobFinder).dx, closeTo(onKnobX, 0.5));

        // Close sheet and stop narration cleanly.
        await tester.tap(find.byKey(const Key('reader-settings-closer')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.pause)),
        );
        await settle(tester);
      },
    );

    testWidgets(
      'reduced motion fades sheet in place, snaps sliding marks with quick fade, and finishes page colors in quick',
      (tester) async {
        await pumpSampleReader(tester, disableAnimations: true);

        // Open sheet: uses Opacity (no FractionalTranslation) and fades in quick.
        await tester.tap(find.byKey(const Key('reader-aa-button')));
        await tester.pump();
        final surfaceFinder = find.byKey(
          const ValueKey('reader_settings_sheet_surface'),
        );
        expect(surfaceFinder, findsOneWidget);
        expect(tester.widget(surfaceFinder), isA<Opacity>());
        expect(
          find.ancestor(
            of: find.byType(NocheSheet),
            matching: find.byType(FractionalTranslation),
          ),
          findsNothing,
        );

        await tester.pump(NocheMotion.quick ~/ 2);
        final midSheetOpacity = tester.widget<Opacity>(surfaceFinder).opacity;
        expect(midSheetOpacity, greaterThan(0.0));
        expect(midSheetOpacity, lessThan(1.0));

        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));
        expect(
          tester.widget<Opacity>(surfaceFinder).opacity,
          closeTo(1.0, 1e-6),
        );

        // Font outline snaps to Atkinson on frame 0 and fades in quick.
        final atkinsonFinder = find.bySemanticsLabel('Atkinson');
        final fontMarkFinder = find.byKey(
          const ValueKey('noche_outline_group_mark'),
        );
        final atkinsonX = tester.getTopLeft(atkinsonFinder).dx;
        await tester.tap(atkinsonFinder);
        await tester.pump();
        expect(tester.getTopLeft(fontMarkFinder).dx, closeTo(atkinsonX, 0.5));
        final fontMarkOpacityWidget = tester.widget<Opacity>(
          find
              .ancestor(of: fontMarkFinder, matching: find.byType(Opacity))
              .first,
        );
        expect(fontMarkOpacityWidget.opacity, closeTo(0.0, 1e-6));
        await tester.pump(NocheMotion.quick ~/ 2);
        final fontMarkMidOpacity = tester
            .widget<Opacity>(
              find
                  .ancestor(of: fontMarkFinder, matching: find.byType(Opacity))
                  .first,
            )
            .opacity;
        expect(fontMarkMidOpacity, greaterThan(0.0));
        expect(fontMarkMidOpacity, lessThan(1.0));
        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));

        // Line spacing thumb snaps to Loose on frame 0 and fades in quick.
        final looseFinder = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.lineSpacingLoose),
        );
        final spacingThumbFinder = find.byKey(
          const ValueKey('reader-line-spacing-thumb'),
        );
        final looseX = tester.getTopLeft(looseFinder).dx;
        await tester.tap(looseFinder);
        await tester.pump();
        expect(tester.getTopLeft(spacingThumbFinder).dx, closeTo(looseX, 0.5));
        await tester.pump(NocheMotion.quick ~/ 2);
        final spacingMidOpacity = tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: spacingThumbFinder,
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity;
        expect(spacingMidOpacity, greaterThan(0.0));
        expect(spacingMidOpacity, lessThan(1.0));
        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));

        // Page colour ring snaps to Sepia on frame 0 and page colors finish in quick.
        final sepiaFinder = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.pageSepia),
        );
        final pageRingFinder = find.byKey(
          const ValueKey('reader-page-color-ring'),
        );
        final sepiaX = tester.getTopLeft(sepiaFinder).dx;
        await tester.tap(sepiaFinder);
        await tester.pump();
        expect(tester.getTopLeft(pageRingFinder).dx, closeTo(sepiaX, 0.5));
        await tester.pump(NocheMotion.quick ~/ 2);
        final ringMidOpacity = tester
            .widget<Opacity>(
              find
                  .ancestor(of: pageRingFinder, matching: find.byType(Opacity))
                  .first,
            )
            .opacity;
        expect(ringMidOpacity, greaterThan(0.0));
        expect(ringMidOpacity, lessThan(1.0));
        expectIntermediateColor(
          _readerPageBackground(tester),
          NocheColors.lessonGround,
          NocheColors.sepiaPage,
        );
        await tester.pump(NocheMotion.quick - (NocheMotion.quick ~/ 2));
        expect(_readerPageBackground(tester), NocheColors.sepiaPage);
        expect(_firstBodyTextStyle(tester).color, NocheColors.sepiaText);
      },
    );

    testWidgets(
      'RTL Arabic renders and animates scrimless sheet and sliding controls cleanly',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final course = FakeCourseCatalog.arabic();
        await course.load();
        final services = fakeServices(course: course);
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await store.add(
          now: 1,
          title: 'بيت جدة',
          body: 'هذا بيت جدة الكبير في المدينة القديمة.',
          generated: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: TextReader(services: services, id: book.id),
          ),
        );
        await settle(tester);

        await _openSettingsSheet(tester);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('noche_sheet_scrim')), findsNothing);

        // In RTL, options lay out right-to-left: Atkinson is to the left of Literata,
        // Loose is to the left of Normal, and Sepia is to the left of Night.
        final fontMark = find.byKey(const ValueKey('noche_outline_group_mark'));
        final atkinson = find.bySemanticsLabel('Atkinson');
        final fontStartX = tester.getTopLeft(fontMark).dx;
        final fontTargetX = tester.getTopLeft(atkinson).dx;
        expect(fontTargetX, lessThan(fontStartX));
        await tester.tap(atkinson);
        await tester.pump();
        await tester.pump(NocheMotion.move ~/ 2);
        final fontMidX = tester.getTopLeft(fontMark).dx;
        expect(fontMidX, lessThan(fontStartX));
        expect(fontMidX, greaterThan(fontTargetX));
        await tester.pump(NocheMotion.move - (NocheMotion.move ~/ 2));
        expect(tester.getTopLeft(fontMark).dx, closeTo(fontTargetX, 0.5));

        final spacingThumb = find.byKey(
          const ValueKey('reader-line-spacing-thumb'),
        );
        final loose = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.lineSpacingLoose),
        );
        final spacingStartX = tester.getTopLeft(spacingThumb).dx;
        final spacingTargetX = tester.getTopLeft(loose).dx;
        expect(spacingTargetX, lessThan(spacingStartX));
        await tester.tap(loose);
        await tester.pump();
        await tester.pump(NocheMotion.move ~/ 2);
        final spacingMidX = tester.getTopLeft(spacingThumb).dx;
        expect(spacingMidX, lessThan(spacingStartX));
        expect(spacingMidX, greaterThan(spacingTargetX));
        await tester.pump(NocheMotion.move - (NocheMotion.move ~/ 2));
        expect(
          tester.getTopLeft(spacingThumb).dx,
          closeTo(spacingTargetX, 0.5),
        );

        final pageRing = find.byKey(const ValueKey('reader-page-color-ring'));
        final sepia = find.bySemanticsLabel(
          NocheA11y.label(NocheA11y.pageSepia),
        );
        final ringStartX = tester.getTopLeft(pageRing).dx;
        final ringTargetX = tester.getTopLeft(sepia).dx;
        expect(ringTargetX, lessThan(ringStartX));
        await tester.tap(sepia);
        await tester.pump();
        await tester.pump(NocheMotion.move ~/ 2);
        final ringMidX = tester.getTopLeft(pageRing).dx;
        expect(ringMidX, lessThan(ringStartX));
        expect(ringMidX, greaterThan(ringTargetX));
        await tester.pump(NocheMotion.move - (NocheMotion.move ~/ 2));
        expect(tester.getTopLeft(pageRing).dx, closeTo(ringTargetX, 0.5));
        expect(_readerPageBackground(tester), NocheColors.sepiaPage);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Reader settings screenshots', () {
    for (final size in _shotViewports) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('capture Noche-Lector-Aa sheet at $tag', (tester) async {
        if (!_captureShots) return;

        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = size;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final progress = FakeProgressStore();
        progress.import(
          jsonEncode({
            ...progress.raw,
            'palabras': {
              for (final w in [
                'cuando',
                'llegamos',
                'a',
                'cabo',
                'rojo',
                'ya',
                'era',
                'de',
                'noche',
                'la',
                'casa',
                'abuela',
                'estaba',
                'al',
                'final',
                'calle',
                'con',
                'luz',
                'del',
                'balcón',
                'llegaron',
                'dijo',
                'desde',
                'puerta',
                'entren',
                'que',
                'comida',
                'está',
                'caliente',
              ])
                w: _earWord(w, 4).toJson(),
              'encendida': _earWord('encendida', 2).toJson(),
            },
          }),
        );

        final services = fakeServices(progress: progress);
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await _addSampleBook(store);
        await const ReaderSettings(page: ReaderPageTheme.sepia)
            .saveTo(services.storage('leer'));

        await tester.pumpWidget(
          RepaintBoundary(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: TextReader(services: services, id: book.id),
            ),
          ),
        );
        await settle(tester);

        await _openSettingsSheet(tester);
        await _saveScreenshot(tester, 'reader_settings_sepia_$tag.png');
      });
    }
  });
}
