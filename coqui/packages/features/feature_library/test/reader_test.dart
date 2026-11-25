import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:feature_library/src/reader_page.dart';
import 'package:feature_library/src/reader_pagination.dart';
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

class _CourseWithWords extends TestCourse implements LanguageCatalog {
  _CourseWithWords({
    super.books,
    super.stories,
    super.recorded,
    Language? language,
  }) : _language = language ?? Language.spanish;

  final Language _language;

  @override
  Language get language => _language;

  @override
  ClipInfo? clip(String id) {
    if (id == 'solo-parcha') {
      return ClipInfo(
        id: id,
        who: 'narr',
        text: 'parcha',
        startMs: 0,
        endMs: 400,
        url: 'audio/$id.mp3',
      );
    }
    if (id == 'solo-casa') {
      return ClipInfo(
        id: id,
        who: 'narr',
        text: 'casa',
        startMs: 0,
        endMs: 400,
        url: 'audio/$id.mp3',
      );
    }
    return super.clip(id);
  }
}

class _CourseWithRepaso extends _CourseWithWords implements RepasoCatalog {
  _CourseWithRepaso({super.books, super.stories, super.recorded, this.repaso});

  @override
  final RepasoData? repaso;
}

Language _arabicLanguage() => Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-SA',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  partnerName: 'Karim',
  callAgentId: 'agent_test_ar',
  micWords: const {
    'ready': 'تحدث',
    'listening': 'أستمع',
    'thinking': 'لحظة',
    'theySpeak': 'استمع',
    'right': 'ممتاز',
    'notYet': 'مرة أخرى',
  },
  tabNames: const {
    'library': 'المكتبة',
    'words': 'الكلمات',
    'map': 'الخريطة',
    'speak': 'تحدث',
    'me': 'أنا',
  },
);

Future<ReadingText> _addLongMultiChapterBook(ReadingStore store) {
  final ch1Paragraphs = [
    'Cuando llegamos a Cabo Rojo, ya era de noche y la brisa del mar entraba por cada ventana abierta de la casa.',
    '—¡Llegaron! —dijo Abuela desde la puerta de madera—. Pasen a la sala que la comida todavía está caliente.',
    'En la cocina había una olla grande de arroz, platos hondos sobre la mesa y una jarra fría de jugo fresco.',
    'Tito dejó su mochila junto al sillón azul y miró el patio donde cantaban los coquíes bajo la lluvia suave.',
    'Después de cenar nos sentamos en el balcón para escuchar las olas y hablar de los paseos del día siguiente.',
    'La luna iluminaba los árboles de mango mientras los vecinos cerraban sus portones y apagaban las luces del frente.',
  ];
  final ch2Paragraphs = [
    'Por la mañana el sol subió temprano sobre el puerto y los botes pequeños salieron hacia las aguas claras.',
    'Caminamos por la orilla buscando caracoles blancos y piedras suaves entre la arena húmeda de la playa.',
    'Al mediodía compramos fruta fresca en el puesto de la esquina y volvimos caminando por la sombra de las palmas.',
    'Abuela preparó café en la cocina y nos contó historias antiguas de cuando ella viajaba en tren por la isla.',
    'Antes del atardecer subimos hasta el faro viejo para mirar el horizonte rojo y sentir el viento salado.',
    'Cuando cayó la tarde regresamos despacio a casa sabiendo que el verano apenas comenzaba.',
  ];
  final chapters = [
    ReadingChapter(
      label: 'Part I',
      title: 'La llegada a la costa',
      paragraphs: ch1Paragraphs,
    ),
    ReadingChapter(
      label: 'Part II',
      title: 'El paseo por el faro',
      paragraphs: ch2Paragraphs,
    ),
  ];
  return store.add(
    now: 500,
    title: 'Un verano en Cabo Rojo',
    body: [...ch1Paragraphs, ...ch2Paragraphs].join('\n\n'),
    generated: false,
    chapters: chapters,
  );
}

void main() {
  setUpAll(() async {
    await _loadNocheFonts();
  });

  group('ReaderEarIndex word marks and custom stageMax', () {
    test('maps ear stages 0..4 and respects custom stageMax', () {
      final indexDefault = ReaderEarIndex([
        _earWord('cero', 0),
        _earWord('uno', 1),
        _earWord('dos', 2),
        _earWord('tres', 3),
        _earWord('cuatro', 4),
        _earWord('Casa', 2),
      ], Language.spanish);

      expect(indexDefault.stageMax, defaultStageMax);
      expect(indexDefault.markFor('desconocida'), WordMarkKind.neverHeard);
      expect(indexDefault.markFor('cero'), WordMarkKind.neverHeard);
      expect(indexDefault.markFor('uno'), WordMarkKind.learning);
      expect(indexDefault.markFor('dos'), WordMarkKind.learning);
      expect(indexDefault.markFor('tres'), WordMarkKind.learning);
      expect(indexDefault.markFor('cuatro'), WordMarkKind.known);
      expect(indexDefault.markFor('casa'), WordMarkKind.learning);
      expect(indexDefault.markFor('123'), WordMarkKind.none);

      // Custom stageMax = 6 ensures stage 4 is still learning (not hardcoded 4/5).
      final indexCustom = ReaderEarIndex(
        [_earWord('cuatro', 4), _earWord('seis', 6)],
        Language.spanish,
        stageMax: 6,
      );
      expect(indexCustom.markFor('cuatro'), WordMarkKind.learning);
      expect(indexCustom.markFor('seis'), WordMarkKind.known);
    });
  });

  group('Pagination and chapter boundaries', () {
    test('multi-chapter book starts each chapter on a new page without inventing labels', () async {
      final services = fakeServices();
      final store = ReadingStore(services.storage(ReadingStore.space));
      final book = await _addLongMultiChapterBook(store);
      final doc = ReaderDocument.fromPersonal(book);

      final smallPages = paginateDocument(
        doc: doc,
        contentWidth: 334,
        contentHeight: 540,
        settings: const ReaderSettings(step: 1),
        language: Language.spanish,
        textScaler: TextScaler.noScaling,
      );
      final largePages = paginateDocument(
        doc: doc,
        contentWidth: 334,
        contentHeight: 540,
        settings: const ReaderSettings(step: 7),
        language: Language.spanish,
        textScaler: TextScaler.noScaling,
      );

      expect(largePages.length, greaterThan(smallPages.length));
      final ch2Start = smallPages.firstWhere((p) => p.chapterIndex == 1);
      expect(ch2Start.isChapterStart, isTrue);
      expect(ch2Start.slices.every((s) => s.chapterIndex == 1), isTrue);

      // Course books keep label null (never invent "CAPÍTULO 1").
      final course = TestCourse();
      final courseBook = (await course.book('uno'))!;
      final courseStory = await course.story('uno');
      final courseDoc = ReaderDocument.fromCourseBook(
        courseBook,
        courseStory,
        course,
      );
      expect(courseDoc.chapters.single.label, isNull);
    });
  });

  group('TextReader widget behavior', () {
    testWidgets(
      'word tap bubble shows speaker + dots with clip, no speaker without clip, and dismisses',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final course = _CourseWithRepaso(
          repaso: RepasoData(
            sentences: [],
            words: [
              RepasoWord(
                word: 'casa',
                place: 'casa',
                scoring: RepasoScoring.cual,
                solo: 'solo-casa',
              ),
            ],
          ),
        );
        final progress = FakeProgressStore();
        progress.import(
          jsonEncode({
            ...progress.raw,
            'palabras': {
              'casa': _earWord('casa', 2).toJson(),
              'azul': _earWord('azul', 1).toJson(),
            },
          }),
        );
        final clips = TimedClips(length: const Duration(milliseconds: 50));
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
        );
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await store.add(
          now: 1,
          title: 'Prueba',
          body: 'La Casa azul 123.',
          generated: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: book.id, stageMax: 5),
          ),
        );
        await settle(tester);

        // Unrecorded learner book hides audio footer controls.
        expect(find.byType(NochePlayDisc), findsNothing);
        expect(find.text('0.9×'), findsNothing);

        // Tap recorded word "Casa": opens bubble with speaker + 5 stage dots, plays solo clip.
        Offset centerOfWord(String word) {
          final para = tester.renderObject(
            find.textContaining(word, findRichText: true),
          ) as RenderParagraph;
          final plain = para.text.toPlainText();
          final idx = plain.indexOf(word);
          final boxes = para.getBoxesForSelection(
            TextSelection(baseOffset: idx, extentOffset: idx + word.length),
          );
          return para.localToGlobal(boxes.first.toRect().center);
        }

        final rect = tester.getRect(
          find.textContaining('Casa', findRichText: true),
        );
        await tester.tapAt(centerOfWord('Casa'));
        await tester.pump(const Duration(milliseconds: 100));
        await settle(tester);

        expect(find.byType(ReaderWordBubble), findsOneWidget);
        expect(clips.played, ['solo-casa']);
        expect(progress.word('casa')?.oida, 1);
        final bubbleFinder = find.byType(ReaderWordBubble);
        expect(
          find.descendant(of: bubbleFinder, matching: find.byType(NocheIcon)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: bubbleFinder, matching: find.text('Casa')),
          findsOneWidget,
        );

        // Tapping the bubble itself replays the solo clip and credits the normalized word 'casa'.
        await tester.tap(bubbleFinder);
        await tester.pump(const Duration(milliseconds: 100));
        await settle(tester);
        expect(clips.played, ['solo-casa', 'solo-casa']);
        expect(progress.word('casa')?.oida, 2);

        // Tap elsewhere dismisses bubble.
        await tester.tapAt(Offset(rect.left + 120, rect.bottom + 80));
        await settle(tester);
        expect(find.byType(ReaderWordBubble), findsNothing);

        // Tap purely numeric token "123": does not open a word bubble.
        await tester.tapAt(centerOfWord('123'));
        await settle(tester);
        expect(find.byType(ReaderWordBubble), findsNothing);

        // Tap unrecorded word "azul": bubble opens without speaker icon and plays nothing.
        await tester.tapAt(centerOfWord('azul'));
        await settle(tester);
        expect(find.byType(ReaderWordBubble), findsOneWidget);
        expect(clips.played, ['solo-casa', 'solo-casa']);
        expect(
          find.descendant(
            of: find.byType(ReaderWordBubble),
            matching: find.byType(NocheIcon),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'chapters sheet lists chapters, marks current with check disc, and jumps',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final services = fakeServices();
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await _addLongMultiChapterBook(store);

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: book.id),
          ),
        );
        await settle(tester);

        expect(find.text('La llegada a la costa'), findsOneWidget);
        expect(
          find.text('Part I'),
          findsNothing,
        ); // uppercase rendered as PART I
        expect(find.text('PART I'), findsOneWidget);
        expect(find.text('CAPÍTULO 1'), findsNothing);

        // Open Chapters sheet (let 200ms slide transition finish).
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.chapters)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chapters'), findsOneWidget);
        expect(find.text('El paseo por el faro'), findsOneWidget);
        // Tapping second chapter jumps to its first page.
        await tester.tap(find.text('El paseo por el faro'));
        await tester.pumpAndSettle();

        expect(find.text('PART II'), findsOneWidget);
        expect(find.text('El paseo por el faro'), findsOneWidget);

        // Swipe back turns to previous page (last page of chapter 1).
        await tester.fling(
          find.byType(ReaderPageView),
          const Offset(300, 0),
          800,
        );
        await settle(tester);
        expect(find.text('PART II'), findsNothing);
      },
    );

    testWidgets(
      'recorded course story book plays audio, cycles speed, lights sentence, and meets touch targets',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final course = TestCourse();
        final clips = TimedClips(length: const Duration(milliseconds: 200));
        final progress = FakeProgressStore();
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: 'uno'),
          ),
        );
        await settle(tester);

        // Audio controls visible for recorded book.
        expect(find.byType(NochePlayDisc), findsOneWidget);
        expect(find.text('0.9×'), findsOneWidget);

        // Touch targets >= 48x48 on header and footer buttons.
        for (final label in [
          NocheA11y.label(NocheA11y.back),
          NocheA11y.label(NocheA11y.textAndPage),
          NocheA11y.label(NocheA11y.chapters),
          NocheA11y.label(NocheA11y.sentenceAgain),
          NocheA11y.label(NocheA11y.listen),
        ]) {
          final size = tester.getSize(find.bySemanticsLabel(label));
          expect(size.width, greaterThanOrEqualTo(48), reason: label);
          expect(size.height, greaterThanOrEqualTo(48), reason: label);
        }

        // Cycle speed 0.9× -> 1× -> 0.75× -> 0.9×.
        await tester.tap(find.text('0.9×'));
        await settle(tester);
        expect(find.text('1×'), findsOneWidget);
        await tester.tap(find.text('1×'));
        await settle(tester);
        expect(find.text('0.75×'), findsOneWidget);
        await tester.tap(find.text('0.75×'));
        await settle(tester);
        expect(find.text('0.9×'), findsOneWidget);

        // Start Listen: plays first clip, lights active sentence, shows Pause disc.
        await tester.tap(find.byType(NochePlayDisc));
        await tester.pump();
        expect(clips.played, ['u1']);
        expect(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.pause)),
          findsOneWidget,
        );

        // Let first clip finish, then pause before leaving.
        await tester.pump(const Duration(milliseconds: 250));
        await settle(tester);
        expect(progress.word('hermana')?.oida, greaterThanOrEqualTo(1));

        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.pause)),
        );
        await settle(tester);
        expect(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.listen)),
          findsOneWidget,
        );
      },
    );

    testWidgets('RTL Arabic course renders cleanly without exceptions', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final course = _CourseWithWords(language: _arabicLanguage());
      final services = fakeServices(course: course);
      final store = ReadingStore(services.storage(ReadingStore.space));
      final book = await store.add(
        now: 10,
        title: 'البيت الأزرق',
        body: 'هذا بيت جميل في المدينة القديمة.\n\nالنافذة مفتوحة على البحر.',
        generated: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TextReader(services: services, id: book.id),
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byType(ReaderPageView))),
        TextDirection.rtl,
      );
    });

    testWidgets(
      'Listen on a continuation page plays the overlapping recorded sentence instead of jumping to page 1',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final longSentence = List.filled(
          45,
          'Caminamos despacio por la orilla del mar escuchando las olas.',
        ).join(' ');
        final course = _CourseWithWords(
          books: {
            'span-book': Book(
              id: 'span-book',
              title: 'Largo',
              readable: true,
              pages: [
                BookPage(image: 'img/1.png', clips: ['s1', 's2']),
              ],
            ),
          },
          stories: {
            'span-book': {
              'title': 'Largo',
              'clips': {
                's1': line('narr', 'Primera línea corta.'),
                's2': line('narr', longSentence),
              },
            },
          },
          recorded: {'s1', 's2'},
        );
        final clips = TimedClips(length: const Duration(milliseconds: 500));
        final services = fakeServices(course: course, clips: clips);

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              services: services,
              id: 'span-book',
              initialSettings: const ReaderSettings(step: 7),
            ),
          ),
        );
        await settle(tester);

        // Turn to page 2 (continuation of sentence s2).
        await tester.fling(
          find.byType(ReaderPageView),
          const Offset(-300, 0),
          800,
        );
        await settle(tester);
        expect(find.textContaining('2 / '), findsOneWidget);

        // Pressing Listen on page 2 plays overlapping sentence s2 without jumping back to page 1.
        await tester.tap(find.byType(NochePlayDisc));
        await tester.pump();
        expect(clips.played, ['s2']);
        expect(find.textContaining('2 / '), findsOneWidget);

        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.pause)),
        );
        await settle(tester);
      },
    );

    test('firstGraphemeEnd keeps decomposed accented drop cap intact', () {
      const decomposed = 'E\u0301rase una vez en la isla.';
      expect(firstGraphemeEnd(decomposed), 2);
      expect(decomposed.substring(0, firstGraphemeEnd(decomposed)), 'E\u0301');
    });

    test(
      'tight first-page height avoids overflowing drop cap below header',
      () {
        final doc = ReaderDocument(
          id: 'tight',
          title: 'Un título muy largo que ocupa varias líneas en una pantalla pequeña',
          chapters: [
            ReaderChapterDoc(
              label: 'Part I',
              title: 'Un título muy largo que ocupa varias líneas en una pantalla pequeña',
              paragraphs: [
                ReaderParagraph([
                  const ReaderSentence(
                    id: 's0',
                    text: 'Cuando llegamos a la costa ya era de noche y la brisa del mar entraba por cada ventana abierta.',
                  ),
                ]),
              ],
            ),
          ],
          hasAudio: false,
        );
        final pages = paginateDocument(
          doc: doc,
          contentWidth: 260,
          contentHeight: 220,
          settings: const ReaderSettings(step: 7),
          language: Language.spanish,
          textScaler: TextScaler.noScaling,
        );
        expect(pages.length, greaterThanOrEqualTo(2));
        // When the first page cannot fit the drop cap below the header, it does not force a drop cap there.
        final firstSlices = pages.first.slices;
        expect(firstSlices.any((s) => s.hasDropCap), isFalse);
      },
    );

    testWidgets(
      'reopening a book at a different text size restores the persisted text anchor',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final services = fakeServices();
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await _addLongMultiChapterBook(store);

        // Open at largest text size (step 7), jump to Chapter 2, and close.
        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('step7'),
              services: services,
              id: book.id,
              initialSettings: const ReaderSettings(step: 7),
            ),
          ),
        );
        await settle(tester);
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.chapters)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('El paseo por el faro'));
        await tester.pumpAndSettle();

        final saved = store.place(book.id);
        expect(saved.chapterIndex, 1);
        expect(saved.paragraphIndex, 0);
        expect(saved.charOffset, 0);

        // Reopen at smallest text size (step 1): page index differs, but anchor resolves to Chapter 2!
        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('step1'),
              services: services,
              id: book.id,
              initialSettings: const ReaderSettings(step: 1),
            ),
          ),
        );
        await settle(tester);
        expect(find.text('El paseo por el faro'), findsOneWidget);
      },
    );

    testWidgets(
      'viewport exposes accessible semantic actions to turn pages and finish the last page',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final nav = FakeNavigator();
        final services = fakeServices(nav: nav);
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await _addLongMultiChapterBook(store);

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              services: services,
              id: book.id,
              initialSettings: const ReaderSettings(step: 1),
            ),
          ),
        );
        await settle(tester);
        expect(find.text('1 / 2'), findsOneWidget);

        Semantics viewportSemantics() => tester
            .widgetList<Semantics>(find.byType(Semantics))
            .firstWhere(
              (s) =>
                  s.properties.customSemanticsActions?.keys.any(
                    (a) =>
                        a.label == ReaderTexts.nextPage ||
                        a.label == ReaderTexts.finishBook,
                  ) ??
                  false,
            );

        // Page 1 exposes Next page (not Previous page).
        var actions = viewportSemantics().properties.customSemanticsActions!;
        expect(
          actions.keys.map((a) => a.label),
          contains(ReaderTexts.nextPage),
        );
        expect(
          actions.keys.map((a) => a.label),
          isNot(contains(ReaderTexts.previousPage)),
        );

        // Invoking Next page turns to page 2 (last page).
        actions.entries
            .firstWhere((e) => e.key.label == ReaderTexts.nextPage)
            .value();
        await settle(tester);
        expect(find.text('2 / 2'), findsOneWidget);

        // Last page exposes Previous page and Finish book.
        actions = viewportSemantics().properties.customSemanticsActions!;
        expect(
          actions.keys.map((a) => a.label),
          containsAll([ReaderTexts.previousPage, ReaderTexts.finishBook]),
        );

        // Invoking Previous page returns to page 1.
        actions.entries
            .firstWhere((e) => e.key.label == ReaderTexts.previousPage)
            .value();
        await settle(tester);
        expect(find.text('1 / 2'), findsOneWidget);

        // Advance to last page and invoke Finish book -> navigates back.
        viewportSemantics().properties.onIncrease!();
        await settle(tester);
        viewportSemantics().properties.customSemanticsActions!.entries
            .firstWhere((e) => e.key.label == ReaderTexts.finishBook)
            .value();
        await settle(tester);
        expect(nav.backs, 1);
      },
    );
  });

  group('Reader screenshots', () {
    for (final size in _shotViewports) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('capture course Night and imported book shots at $tag', (
        tester,
      ) async {
        if (!_captureShots) return;

        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = size;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Course story book in Night with word marks stages 0..4, lit sentence, tapped word bubble.
        final shotClips = {
          'c1': line(
            'narr',
            'Cuando llegamos a Cabo Rojo, ya era de noche. La casa de Abuela estaba al final de la calle, con la luz encendida.',
          ),
          'c2': line('narr', 'La cocina olía a sofrito y a café.'),
          'c3': line(
            'narr',
            'En la estufa había una olla grande de arroz con gandules y en la mesa cuatro platos y una jarra de jugo de parcha.',
          ),
          'c4': line(
            'narr',
            'Afuera cantaban los coquíes y por la ventana entraba el aire del mar.',
          ),
        };
        final courseBook = Book(
          id: 'cabo-rojo',
          title: 'Un verano en Cabo Rojo',
          readable: true,
          pages: [
            BookPage(image: 'img/1.png', clips: ['c1']),
            BookPage(image: 'img/2.png', clips: ['c2', 'c3']),
            BookPage(image: 'img/3.png', clips: ['c4']),
          ],
        );
        final course = _CourseWithRepaso(
          books: {'cabo-rojo': courseBook},
          stories: {
            'cabo-rojo': {
              'title': 'Un verano en Cabo Rojo',
              'clips': shotClips,
            },
          },
          recorded: {'c1', 'c2', 'c3', 'c4', 'solo-parcha'},
          repaso: RepasoData(
            sentences: [],
            words: [
              RepasoWord(
                word: 'parcha',
                place: 'casa',
                scoring: RepasoScoring.cual,
                solo: 'solo-parcha',
              ),
            ],
          ),
        );

        final progress = FakeProgressStore();
        progress.import(
          jsonEncode({
            ...progress.raw,
            'palabras': {
              for (final known in [
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
                'en',
                'cocina',
                'y',
                'café',
                'había',
                'una',
                'grande',
                'arroz',
                'mesa',
                'cuatro',
                'platos',
                'jugo',
                'afuera',
                'por',
                'ventana',
                'el',
                'aire',
                'del',
                'mar',
              ])
                known: _earWord(known, 4).toJson(),
              'encendida': _earWord('encendida', 2).toJson(),
              'olla': _earWord('olla', 3).toJson(),
              'jarra': _earWord('jarra', 1).toJson(),
              'parcha': _earWord('parcha', 1).toJson(),
              // sofrito & gandules omitted -> stage 0 (solid blue underline)
            },
          }),
        );

        final clips = TimedClips(length: const Duration(milliseconds: 200));
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
        );

        await tester.pumpWidget(
          RepaintBoundary(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: TextReader(services: services, id: 'cabo-rojo'),
            ),
          ),
        );
        await settle(tester);

        // Start playback on c1, advance into c2 ("La cocina olía a sofrito y a café."), then tap "parcha".
        await tester.tap(find.byType(NochePlayDisc));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump();

        final parchaParagraph = find.textContaining(
          'parcha',
          findRichText: true,
        );
        final pRect = tester.getRect(parchaParagraph);
        final renderObj = tester.renderObject(parchaParagraph);
        Offset? parchaOffset;
        if (renderObj is RenderParagraph) {
          final plain = renderObj.text.toPlainText();
          final idx = plain.indexOf('parcha');
          if (idx >= 0) {
            final boxes = renderObj.getBoxesForSelection(
              TextSelection(baseOffset: idx, extentOffset: idx + 6),
            );
            if (boxes.isNotEmpty) {
              final localCenter = boxes.first.toRect().center;
              parchaOffset = renderObj.localToGlobal(localCenter);
            }
          }
        }
        await tester.tapAt(parchaOffset ?? pRect.center);
        await tester.pump(const Duration(milliseconds: 250));
        await settle(tester);
        expect(find.byType(ReaderWordBubble), findsOneWidget);
        await _saveScreenshot(tester, 'reader_course_night_$tag.png');

        // 2. Multi-chapter imported book at Chapter 2 start (unrecorded -> no audio controls).
        final services2 = fakeServices();
        final store2 = ReadingStore(services2.storage(ReadingStore.space));
        final importedBook = await _addLongMultiChapterBook(store2);

        await tester.pumpWidget(
          RepaintBoundary(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: TextReader(
                key: const ValueKey('imported-ch2'),
                services: services2,
                id: importedBook.id,
              ),
            ),
          ),
        );
        await settle(tester);
        await tester.tap(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.chapters)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('El paseo por el faro'));
        await tester.pumpAndSettle();
        await _saveScreenshot(tester, 'reader_imported_chapter_$tag.png');

        // 3. Long imported book at smallest text size (step 1).
        final servicesSmall = fakeServices();
        final storeSmall = ReadingStore(
          servicesSmall.storage(ReadingStore.space),
        );
        final smallBook = await _addLongMultiChapterBook(storeSmall);
        await tester.pumpWidget(
          RepaintBoundary(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: TextReader(
                key: const ValueKey('small'),
                services: servicesSmall,
                id: smallBook.id,
                initialSettings: const ReaderSettings(step: 1),
              ),
            ),
          ),
        );
        await settle(tester);
        await _saveScreenshot(tester, 'reader_small_text_$tag.png');

        // 4. Long imported book at largest text size (step 7).
        final servicesLarge = fakeServices();
        final storeLarge = ReadingStore(
          servicesLarge.storage(ReadingStore.space),
        );
        final largeBook = await _addLongMultiChapterBook(storeLarge);
        await tester.pumpWidget(
          RepaintBoundary(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: TextReader(
                key: const ValueKey('large'),
                services: servicesLarge,
                id: largeBook.id,
                initialSettings: const ReaderSettings(step: 7),
              ),
            ),
          ),
        );
        await settle(tester);
        await _saveScreenshot(tester, 'reader_large_text_$tag.png');
      });
    }
  });
}
