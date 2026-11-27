import 'dart:async';
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

/// Mimics `PalabrasStore` persistence semantics: [heard] mutates memory without
/// saving to [kv] or firing [changes], while [addMinutes] and other write
/// methods persist the full store snapshot to [kv].
class _DeferredSaveProgressStore implements ProgressStore {
  _DeferredSaveProgressStore(this.kv, {Clock? clock})
    : _inner = FakeProgressStore(clock: clock, json: kv.read(storageKey));

  static const storageKey = 'progress';

  final FakeKeyValueStore kv;
  final FakeProgressStore _inner;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final List<double> addedMinutes = [];
  int persistCount = 0;

  void _persist() {
    persistCount++;
    kv.values[storageKey] = _inner.export();
    if (!_changes.isClosed) _changes.add(null);
  }

  void put(WordRecord record) {
    _inner.put(record);
    _persist();
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Map<String, dynamic> get raw => _inner.raw;

  @override
  Iterable<WordRecord> get words => _inner.words;

  @override
  WordRecord? word(String w) => _inner.word(w);

  @override
  StoryRecord? story(String id) => _inner.story(id);

  @override
  bool played(String id) => _inner.played(id);

  @override
  List<String> due(Skill skill, {int? at}) => _inner.due(skill, at: at);

  @override
  WordRecord heard(String w) => _inner.heard(w);

  @override
  SkillRecord answer(
    String w,
    Skill skill, {
    required bool ok,
    int? ms,
    bool intro = false,
  }) {
    final result = _inner.answer(w, skill, ok: ok, ms: ms, intro: intro);
    _persist();
    return result;
  }

  @override
  void storyFinished(StoryResult r) {
    _inner.storyFinished(r);
    _persist();
  }

  @override
  void presume(List<String> words, List<String> stories, List<Object?> log) {
    _inner.presume(words, stories, log);
    _persist();
  }

  @override
  void listened(String id) {
    _inner.listened(id);
    _persist();
  }

  @override
  bool hasRead(String id) => _inner.hasRead(id);

  @override
  void markRead(String id) {
    final before = _inner.saves;
    _inner.markRead(id);
    if (_inner.saves != before) _persist();
  }

  @override
  void addMinutes(double m) {
    addedMinutes.add(m);
    _inner.addMinutes(m);
    _persist();
  }

  @override
  double get minutes => _inner.minutes;

  @override
  int get streak => _inner.streak;

  @override
  bool openForSpeaking(String w) => _inner.openForSpeaking(w);

  @override
  Object? setting(String key) => _inner.setting(key);

  @override
  void setSetting(String key, Object value) {
    _inner.setSetting(key, value);
    _persist();
  }

  @override
  List<String> get added => _inner.added;

  @override
  void add(String wordOrGoal) {
    _inner.add(wordOrGoal);
    _persist();
  }

  @override
  Map<String, dynamic>? get levelResult => _inner.levelResult;

  @override
  String export() => _inner.export();

  @override
  void import(String json) {
    _inner.import(json);
    _persist();
  }

  @override
  void reset() {
    _inner.reset();
    _persist();
  }
}

class _SlowPreloadClips extends TimedClips {
  _SlowPreloadClips({super.length});

  Completer<List<String>> _preloadGate = Completer<List<String>>();

  void finishPreload([List<String> missing = const []]) {
    if (!_preloadGate.isCompleted) _preloadGate.complete(missing);
  }

  void resetPreload() {
    _preloadGate = Completer<List<String>>();
  }

  @override
  Future<List<String>> preload(Iterable<String> clipIds) {
    preloaded.addAll(clipIds);
    return _preloadGate.future;
  }
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
        expect(find.byKey(const Key('reader-play-disc')), findsNothing);
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
        await tester.pump(NocheMotion.quick);
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
        await tester.pump();
        await tester.pump(NocheMotion.press);
        await settle(tester);
        expect(find.byType(ReaderWordBubble), findsNothing);

        // Tap purely numeric token "123": does not open a word bubble.
        await tester.tapAt(centerOfWord('123'));
        await settle(tester);
        expect(find.byType(ReaderWordBubble), findsNothing);

        // Tap unrecorded word "azul": bubble opens without speaker icon and plays nothing.
        await tester.tapAt(centerOfWord('azul'));
        await tester.pump(NocheMotion.quick);
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
        await tester.pumpAndSettle();
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
        expect(find.byKey(const Key('reader-play-disc')), findsOneWidget);
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
        await tester.tap(find.byKey(const Key('reader-play-disc')));
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
        await tester.pumpAndSettle();
        expect(find.textContaining('2 / '), findsOneWidget);

        // Pressing Listen on page 2 plays overlapping sentence s2 without jumping back to page 1.
        await tester.tap(find.byKey(const Key('reader-play-disc')));
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

    testWidgets(
      'playing a recorded sentence skips untracked function words and persists credited words and listening minutes on reopen',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final kv = FakeKeyValueStore();
        final clock = FakeClock();
        final progress = _DeferredSaveProgressStore(kv, clock: clock);
        // Existing tracked word in ProgressStore (not in course pairs or repaso).
        progress.put(_earWord('azul', 1));

        final course = _CourseWithRepaso(
          books: {
            'filter-book': Book(
              id: 'filter-book',
              title: 'Filtro',
              readable: true,
              pages: [
                BookPage(image: 'img/1.png', clips: ['f1']),
              ],
            ),
          },
          stories: {
            'filter-book': {
              'title': 'Filtro',
              'clips': {
                // 'parcha': solo audio word; 'azul': existing progress word;
                // 'casa': course.pairs vocabulary; 'la', 'de', 'y', 'grande': untracked.
                'f1': line('narr', 'La casa de parcha azul y grande.'),
              },
            },
          },
          recorded: {'f1'},
          repaso: RepasoData(
            sentences: const [],
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
        final clips = TimedClips(length: const Duration(milliseconds: 200));
        final nav = FakeNavigator();
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
          clock: clock,
          nav: nav,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: 'filter-book'),
          ),
        );
        await settle(tester);

        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        expect(clips.played, ['f1']);

        // Simulate 12 seconds of real audio playback on the injected Clock.
        clock.advance(const Duration(seconds: 12));
        await tester.pump(const Duration(milliseconds: 250));
        await settle(tester);

        // Close the reader.
        await tester.tap(find.byTooltip(ReaderTexts.close));
        await settle(tester);
        expect(nav.backs, 1);

        // Known words credited; arbitrary untracked function words never inserted.
        expect(progress.word('parcha')?.oida, 1);
        expect(progress.word('parcha')?.ear.etapa, 1);
        expect(progress.word('azul')?.oida, 1);
        expect(progress.word('casa')?.oida, 1);
        for (final untracked in ['la', 'de', 'y', 'grande']) {
          expect(
            progress.word(untracked),
            isNull,
            reason: 'untracked word "$untracked" must not pollute progress',
          );
        }

        // Listening duration logged via addMinutes and persisted to backing KV.
        expect(progress.addedMinutes, hasLength(1));
        expect(progress.minutes, closeTo(12 / 60, 1e-9));

        // Reopen with a brand-new progress store from backing storage:
        // credited words and listening minutes survive.
        final reopened = _DeferredSaveProgressStore(kv, clock: clock);
        expect(reopened.word('parcha')?.oida, 1);
        expect(reopened.word('azul')?.oida, 1);
        expect(reopened.word('casa')?.oida, 1);
        expect(reopened.minutes, closeTo(12 / 60, 1e-9));
        for (final untracked in ['la', 'de', 'y', 'grande']) {
          expect(reopened.word(untracked), isNull);
        }
      },
    );

    testWidgets(
      'tapping a recorded word clip persists its ear credit and listening minutes on reopen, while silent reading logs no minutes',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final kv = FakeKeyValueStore();
        final clock = FakeClock();
        final progress = _DeferredSaveProgressStore(kv, clock: clock);
        final course = _CourseWithRepaso(
          repaso: RepasoData(
            sentences: const [],
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
        final clips = TimedClips(length: const Duration(milliseconds: 100));
        final nav = FakeNavigator();
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
          clock: clock,
          nav: nav,
        );
        final store = ReadingStore(services.storage(ReadingStore.space));
        final book = await store.add(
          now: 1,
          title: 'Silencio',
          body: 'La casa.',
          generated: false,
        );

        // 1. Open and close without playing any audio -> addMinutes is not called.
        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('silent'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);
        await tester.tap(find.byTooltip(ReaderTexts.close));
        await settle(tester);
        expect(progress.addedMinutes, isEmpty);
        expect(progress.minutes, 0);

        // 2. Reopen, tap recorded word "casa", let solo clip finish, close.
        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('word-tap'),
              services: services,
              id: book.id,
            ),
          ),
        );
        await settle(tester);

        final para = tester.renderObject(
          find.textContaining('casa', findRichText: true),
        ) as RenderParagraph;
        final plain = para.text.toPlainText();
        final idx = plain.indexOf('casa');
        final boxes = para.getBoxesForSelection(
          TextSelection(baseOffset: idx, extentOffset: idx + 'casa'.length),
        );
        await tester.tapAt(para.localToGlobal(boxes.first.toRect().center));
        await tester.pump();
        clock.advance(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 150));
        await settle(tester);

        await tester.tap(find.byTooltip(ReaderTexts.close));
        await settle(tester);

        expect(clips.played, ['solo-casa']);
        expect(progress.addedMinutes, hasLength(1));
        expect(progress.minutes, closeTo(3 / 60, 1e-9));

        // Fresh store from storage preserves both the word ear credit and minutes.
        final reopened = _DeferredSaveProgressStore(kv, clock: clock);
        expect(reopened.word('casa')?.oida, 1);
        expect(reopened.word('casa')?.ear.etapa, 1);
        expect(reopened.word('la'), isNull);
        expect(reopened.minutes, closeTo(3 / 60, 1e-9));
      },
    );

    testWidgets(
      'closing mid-narration flushes earlier ear credits and partial listening duration, while muted playback logs nothing',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final kv = FakeKeyValueStore();
        final clock = FakeClock();
        final progress = _DeferredSaveProgressStore(kv, clock: clock);
        final course = _CourseWithWords(
          books: {
            'two-lines': Book(
              id: 'two-lines',
              title: 'Dos',
              readable: true,
              pages: [
                BookPage(image: 'img/1.png', clips: ['l1', 'l2']),
              ],
            ),
          },
          stories: {
            'two-lines': {
              'title': 'Dos',
              'clips': {
                'l1': line('narr', 'La casa de papel.'),
                'l2': line('narr', 'El hermano llega.'),
              },
            },
          },
          recorded: {'l1', 'l2'},
        );
        final clips = TimedClips(length: const Duration(milliseconds: 200));
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
          clock: clock,
        );

        // 1. Muted playback must not credit words or log minutes.
        clips.muted = true;
        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('muted'),
              services: services,
              id: 'two-lines',
            ),
          ),
        );
        await settle(tester);
        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        clock.advance(const Duration(seconds: 6));
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byTooltip(ReaderTexts.close));
        await settle(tester);
        expect(progress.words, isEmpty);
        expect(progress.addedMinutes, isEmpty);

        // 2. Audible playback interrupted by Close during l2 flushes l1 credits + (6 + 3)s.
        clips.muted = false;
        clips.played.clear();
        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('audible'),
              services: services,
              id: 'two-lines',
            ),
          ),
        );
        await settle(tester);

        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        expect(clips.played, ['l1']);

        // Finish l1 (6s), l2 starts automatically; advance 3s into l2, then close.
        clock.advance(const Duration(seconds: 6));
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump();
        expect(clips.played, ['l1', 'l2']);

        clock.advance(const Duration(seconds: 3));
        await tester.tap(find.byTooltip(ReaderTexts.close));
        await settle(tester);

        final reopened = _DeferredSaveProgressStore(kv, clock: clock);
        expect(reopened.word('casa')?.oida, 1);
        expect(reopened.word('hermano'), isNull);
        expect(reopened.word('la'), isNull);
        expect(reopened.word('de'), isNull);
        expect(reopened.word('papel'), isNull);
        expect(reopened.minutes, closeTo(9 / 60, 1e-9));
      },
    );

    testWidgets(
      'clip preload delay is excluded from listening minutes on completion and on early close',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final kv = FakeKeyValueStore();
        final clock = FakeClock();
        final progress = _DeferredSaveProgressStore(kv, clock: clock);
        final course = _CourseWithWords(
          books: {
            'slow-load': Book(
              id: 'slow-load',
              title: 'Lento',
              readable: true,
              pages: [
                BookPage(image: 'img/1.png', clips: ['s1']),
              ],
            ),
          },
          stories: {
            'slow-load': {
              'title': 'Lento',
              'clips': {'s1': line('narr', 'La casa.')},
            },
          },
          recorded: {'s1'},
        );
        final clips = _SlowPreloadClips(
          length: const Duration(milliseconds: 200),
        );
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
          clock: clock,
        );

        // 1. Closing while clip is still preloading logs 0 listening minutes.
        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('close-during-preload'),
              services: services,
              id: 'slow-load',
            ),
          ),
        );
        await settle(tester);

        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        expect(clips.preloaded, ['s1']);
        expect(clips.played, isEmpty);

        clock.advance(const Duration(seconds: 15));
        await tester.tap(find.byTooltip(ReaderTexts.close));
        await settle(tester);
        clips.finishPreload();
        await settle(tester);
        expect(progress.addedMinutes, isEmpty);
        expect(progress.minutes, 0);

        // 2. Slow preload (10s) followed by 4s playback logs only 4s.
        clips.resetPreload();
        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('slow-preload-then-play'),
              services: services,
              id: 'slow-load',
            ),
          ),
        );
        await settle(tester);

        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        clock.advance(const Duration(seconds: 10));
        clips.finishPreload();
        await tester.pump();
        expect(clips.played, ['s1']);

        clock.advance(const Duration(seconds: 4));
        await tester.pump(const Duration(milliseconds: 250));
        await settle(tester);

        expect(progress.word('casa')?.oida, 1);
        expect(progress.minutes, closeTo(4 / 60, 1e-9));
      },
    );

    testWidgets(
      'backgrounding the app stops narration, flushes partial minutes, and allows timed resume',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final kv = FakeKeyValueStore();
        final clock = FakeClock();
        final progress = _DeferredSaveProgressStore(kv, clock: clock);
        final course = _CourseWithWords(
          books: {
            'bg-book': Book(
              id: 'bg-book',
              title: 'Fondo',
              readable: true,
              pages: [
                BookPage(image: 'img/1.png', clips: ['b1']),
              ],
            ),
          },
          stories: {
            'bg-book': {
              'title': 'Fondo',
              'clips': {'b1': line('narr', 'La casa.')},
            },
          },
          recorded: {'b1'},
        );
        final clips = TimedClips(length: const Duration(milliseconds: 300));
        final services = fakeServices(
          course: course,
          clips: clips,
          progress: progress,
          clock: clock,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(services: services, id: 'bg-book'),
          ),
        );
        await settle(tester);

        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        expect(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.pause)),
          findsOneWidget,
        );

        // Listen 3s, then app enters paused lifecycle state.
        clock.advance(const Duration(seconds: 3));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await settle(tester);

        expect(clips.stops, greaterThanOrEqualTo(1));
        expect(progress.minutes, closeTo(3 / 60, 1e-9));

        // Time spent backgrounded (60s) is not counted; resuming shows Listen and records fresh 6s play.
        clock.advance(const Duration(seconds: 60));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await settle(tester);
        expect(
          find.bySemanticsLabel(NocheA11y.label(NocheA11y.listen)),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        clock.advance(const Duration(seconds: 6));
        await tester.pump(const Duration(milliseconds: 350));
        await settle(tester);

        final reopened = _DeferredSaveProgressStore(kv, clock: clock);
        expect(reopened.word('casa')?.oida, 1);
        expect(reopened.minutes, closeTo(9 / 60, 1e-9));
      },
    );
  });

  _addMotionTests();

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
        await tester.tap(find.byKey(const Key('reader-play-disc')));
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

class _MotionRecordingCanvas implements Canvas {
  final List<({RRect rrect, int argb, double alpha})> rrects = [];

  @override
  void drawRRect(RRect rrect, Paint paint) {
    rrects.add((
      rrect: rrect,
      argb: paint.color.toARGB32(),
      alpha: paint.color.a,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

_MotionRecordingCanvas _paintReaderDecorations(WidgetTester tester) {
  final canvas = _MotionRecordingCanvas();
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

double _followIncomingDx(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const ValueKey('noche_follow_incoming')))
    .transform
    .getTranslation()
    .x;

double _bubbleMotionDy(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const Key('reader-word-bubble-motion')))
    .transform
    .getTranslation()
    .y;

double _bubbleOpacity(WidgetTester tester) => tester
    .widget<Opacity>(find.byKey(const Key('reader-word-bubble-opacity')))
    .opacity;

Offset _centerOfWordToken(WidgetTester tester, String word) {
  final para = tester.renderObject(
    find.textContaining(word, findRichText: true).first,
  ) as RenderParagraph;
  final plain = para.text.toPlainText();
  final idx = plain.indexOf(word);
  expect(idx, greaterThanOrEqualTo(0), reason: 'word "$word" not found');
  final boxes = para.getBoxesForSelection(
    TextSelection(baseOffset: idx, extentOffset: idx + word.length),
  );
  expect(boxes, isNotEmpty, reason: 'no box for "$word"');
  return para.localToGlobal(boxes.first.toRect().center);
}

void _addMotionTests() {
  group('N8.13 Reader motion', () {
    testWidgets(
      'page turn uses NocheFollow with distance page in Spanish LTR and animates progress bar',
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
            home: TextReader(
              services: services,
              id: book.id,
              initialSettings: const ReaderSettings(step: 1),
            ),
          ),
        );
        await settle(tester);

        expect(find.text('1 / 2'), findsOneWidget);
        final follow = tester.widget<NocheFollow>(
          find.byKey(const Key('reader-page-follow')),
        );
        expect(follow.distance, NocheMotion.page);
        expect(
          tester.widget<NocheProgressBar>(find.byType(NocheProgressBar)).value,
          closeTo(0.5, 1e-6),
        );

        // Turn forward via swipe left: incoming page arrives from end (+x in LTR).
        await tester.fling(
          find.byType(ReaderPageView),
          const Offset(-300, 0),
          800,
        );
        await tester.pump();
        expect(_followIncomingDx(tester), closeTo(NocheMotion.page, 0.01));

        await tester.pump(NocheMotion.followAfter + NocheMotion.move ~/ 2);
        final midDxFwd = _followIncomingDx(tester);
        expect(midDxFwd, greaterThan(0));
        expect(midDxFwd, lessThan(NocheMotion.page));
        final midProgress = tester
            .widget<NocheProgressBar>(find.byType(NocheProgressBar))
            .value;
        expect(midProgress, greaterThan(0.5));
        expect(midProgress, lessThan(1.0));

        await tester.pump(NocheMotion.move);
        await tester.pump();
        expect(_followIncomingDx(tester), 0.0);
        expect(
          tester.widget<NocheProgressBar>(find.byType(NocheProgressBar)).value,
          closeTo(1.0, 1e-6),
        );
        expect(find.text('2 / 2'), findsOneWidget);

        // Turn back via tap on start edge: incoming page arrives from start (-x in LTR).
        final readerRect = tester.getRect(find.byType(TextReader));
        await tester.tapAt(Offset(readerRect.left + 20, readerRect.center.dy));
        await tester.pump();
        expect(_followIncomingDx(tester), closeTo(-NocheMotion.page, 0.01));

        await tester.pump(NocheMotion.followAfter + NocheMotion.move ~/ 2);
        final midDxBack = _followIncomingDx(tester);
        expect(midDxBack, lessThan(0));
        expect(midDxBack, greaterThan(-NocheMotion.page));

        await tester.pump(NocheMotion.move);
        await tester.pump();
        expect(_followIncomingDx(tester), 0.0);
        expect(find.text('1 / 2'), findsOneWidget);
      },
    );

    testWidgets(
      'page turn mirrors direction in Arabic RTL and keeps numbers LTR via NocheLtr',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final course = _CourseWithWords(language: _arabicLanguage());
        final services = fakeServices(course: course);
        final store = ReadingStore(services.storage(ReadingStore.space));
        final longAr = List.filled(
          18,
          'هذا بيت جدة الكبير في المدينة القديمة والنافذة مفتوحة على البحر.',
        ).join(' ');
        final book = await store.add(
          now: 20,
          title: 'رحلة البيت',
          body: longAr,
          generated: false,
          chapters: [
            ReadingChapter(
              label: 'القسم الأول',
              title: 'بيت جدة',
              paragraphs: [longAr],
            ),
            const ReadingChapter(
              label: 'القسم الثاني',
              title: 'باب البيت',
              paragraphs: ['الآن جدة عند باب البيت.'],
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              services: services,
              id: book.id,
              initialSettings: const ReaderSettings(step: 6),
            ),
          ),
        );
        await settle(tester);

        expect(
          Directionality.of(
            tester.element(find.byKey(const Key('reader-page-counter'))),
          ),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(tester.element(find.textContaining('min'))),
          TextDirection.ltr,
        );

        // Turn forward in RTL: end side is left (-x).
        final readerRect = tester.getRect(find.byType(TextReader));
        await tester.tapAt(Offset(readerRect.left + 20, readerRect.center.dy));
        await tester.pump();
        expect(_followIncomingDx(tester), closeTo(-NocheMotion.page, 0.01));

        await tester.pump(NocheMotion.followAfter + NocheMotion.move ~/ 2);
        final midRtlFwd = _followIncomingDx(tester);
        expect(midRtlFwd, lessThan(0));
        expect(midRtlFwd, greaterThan(-NocheMotion.page));

        await tester.pump(NocheMotion.move);
        await tester.pump();
        expect(_followIncomingDx(tester), 0.0);
        expect(find.textContaining('2 / '), findsOneWidget);

        // Turn back in RTL via swipe left: start side is right (+x).
        await tester.fling(
          find.byType(ReaderPageView),
          const Offset(-300, 0),
          800,
        );
        await tester.pump();
        expect(_followIncomingDx(tester), closeTo(NocheMotion.page, 0.01));

        await tester.pump(NocheMotion.followAfter + NocheMotion.move ~/ 2);
        final midRtlBack = _followIncomingDx(tester);
        expect(midRtlBack, greaterThan(0));
        expect(midRtlBack, lessThan(NocheMotion.page));

        await tester.pump(NocheMotion.move);
        await tester.pump();
        expect(_followIncomingDx(tester), 0.0);
        expect(find.textContaining('1 / '), findsOneWidget);
      },
    );

    testWidgets(
      'listening cross-fades play/pause icons, transitions lit sentence in quick, and auto-turns page with first sentence lit',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final filler = List.filled(
          16,
          'Caminamos despacio por la orilla del mar escuchando las olas.',
        ).join(' ');
        final course = _CourseWithWords(
          books: {
            'auto-turn': Book(
              id: 'auto-turn',
              title: 'Turno',
              readable: true,
              pages: [
                BookPage(image: 'img/1.png', clips: ['a1', 'a2']),
                BookPage(image: 'img/2.png', clips: ['b1']),
              ],
            ),
          },
          stories: {
            'auto-turn': {
              'title': 'Turno',
              'clips': {
                'a1': line('narr', 'Primera frase en la cocina.'),
                'a2': line('narr', filler),
                'b1': line('narr', 'Primera frase de la segunda página.'),
              },
            },
          },
          recorded: {'a1', 'a2', 'b1'},
        );
        final clips = TimedClips(length: const Duration(milliseconds: 300));
        final services = fakeServices(course: course, clips: clips);

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              services: services,
              id: 'auto-turn',
              initialSettings: const ReaderSettings(step: 7),
            ),
          ),
        );
        await settle(tester);

        double playIconOpacity() => tester
            .widget<FadeTransition>(
              find.descendant(
                of: find.byKey(const Key('reader-play-icon')),
                matching: find.byType(FadeTransition),
              ),
            )
            .opacity
            .value;

        double pauseIconOpacity() => tester
            .widget<FadeTransition>(
              find.descendant(
                of: find.byKey(const Key('reader-pause-icon')),
                matching: find.byType(FadeTransition),
              ),
            )
            .opacity
            .value;

        expect(playIconOpacity(), 1.0);
        expect(pauseIconOpacity(), 0.0);

        // Tap Listen: play/pause cross-fade in quick.
        await tester.tap(find.byKey(const Key('reader-play-disc')));
        await tester.pump();
        await tester.pump(NocheMotion.quick ~/ 2);
        expect(playIconOpacity(), greaterThan(0.0));
        expect(playIconOpacity(), lessThan(1.0));
        expect(pauseIconOpacity(), greaterThan(0.0));
        expect(pauseIconOpacity(), lessThan(1.0));

        await tester.pump(NocheMotion.quick ~/ 2);
        expect(playIconOpacity(), 0.0);
        expect(pauseIconOpacity(), 1.0);
        expect(clips.played, ['a1']);

        // Finish a1 (300 - 140 = 160ms left) -> advances to a2 on same page.
        await tester.pump(const Duration(milliseconds: 160));
        await tester.pump();
        expect(clips.played, ['a1', 'a2']);

        // Midpoint of quick sentence-lit transition: outgoing a1 and incoming a2 both have partial alpha.
        await tester.pump(NocheMotion.quick ~/ 2);
        final midLit = _paintReaderDecorations(tester);
        final litRectsMid = midLit.rrects
            .where(
              (r) =>
                  (r.argb & 0x00FFFFFF) ==
                  (NocheColors.litSentence.toARGB32() & 0x00FFFFFF),
            )
            .toList();
        expect(litRectsMid.length, greaterThanOrEqualTo(2));
        expect(litRectsMid.any((r) => r.alpha > 0.0 && r.alpha < 1.0), isTrue);

        await tester.pump(NocheMotion.quick ~/ 2);
        // Finish a2 (300 - 140 = 160ms left) -> auto-turns to page with b1 lit as it arrives.
        await tester.pump(const Duration(milliseconds: 160));
        await tester.pump();
        expect(clips.played, ['a1', 'a2', 'b1']);
        expect(_followIncomingDx(tester), greaterThan(0));

        // First sentence of arrived page is already lit at full alpha during arrival.
        final arrivedLit = _paintReaderDecorations(tester);
        final fullLitRects = arrivedLit.rrects
            .where((r) => r.argb == NocheColors.litSentence.toARGB32())
            .toList();
        expect(fullLitRects, isNotEmpty);

        await tester.pump(NocheMotion.followAfter + NocheMotion.move);
        await tester.pump(const Duration(milliseconds: 350));
        await settle(tester);
      },
    );

    testWidgets(
      'word tap highlights in quick, bubble rises by row and exits in press, and stays clamped inside page in Spanish and Arabic',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Spanish LTR edge-word clamping + rise/exit motion.
        final courseEs = _CourseWithRepaso(
          repaso: RepasoData(
            sentences: const [],
            words: [
              RepasoWord(
                word: 'extraordinaria',
                place: 'casa',
                scoring: RepasoScoring.cual,
                solo: 'solo-casa',
              ),
            ],
          ),
        );
        final clipsEs = TimedClips(length: const Duration(milliseconds: 50));
        final servicesEs = fakeServices(course: courseEs, clips: clipsEs);
        final storeEs = ReadingStore(servicesEs.storage(ReadingStore.space));
        final bookEs = await storeEs.add(
          now: 1,
          title: 'Bordes',
          body: '¡Extraordinaria! Ya extraordinariamente.',
          generated: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('clamp-es'),
              services: servicesEs,
              id: bookEs.id,
            ),
          ),
        );
        await settle(tester);

        // Tap first word ("Extraordinaria") on line -> bubble rises in quick and clamps to page start.
        await tester.tapAt(_centerOfWordToken(tester, 'Extraordinaria'));
        await tester.pump();
        expect(_bubbleOpacity(tester), 0.0);
        expect(_bubbleMotionDy(tester), closeTo(NocheMotion.row, 0.01));

        await tester.pump(NocheMotion.quick ~/ 2);
        final midBubbleDy = _bubbleMotionDy(tester);
        expect(midBubbleDy, greaterThan(0.0));
        expect(midBubbleDy, lessThan(NocheMotion.row));
        expect(_bubbleOpacity(tester), greaterThan(0.0));
        expect(_bubbleOpacity(tester), lessThan(1.0));
        final midWordDec = _paintReaderDecorations(tester);
        expect(
          midWordDec.rrects.any(
            (r) =>
                (r.argb & 0x00FFFFFF) ==
                    (NocheColors.listening.toARGB32() & 0x00FFFFFF) &&
                r.alpha > 0.0 &&
                r.alpha < 1.0,
          ),
          isTrue,
        );

        await tester.pump(NocheMotion.quick ~/ 2);
        await tester.pump(const Duration(milliseconds: 60));
        expect(_bubbleMotionDy(tester), 0.0);
        expect(_bubbleOpacity(tester), 1.0);

        final firstBubbleRect = tester.getRect(
          find.byKey(const Key('reader-word-bubble-body')),
        );
        expect(firstBubbleRect.left, greaterThanOrEqualTo(16.0));
        expect(firstBubbleRect.right, lessThanOrEqualTo(390.0 - 16.0));
        // Guardrail 5: bubble holds only the word (plus speaker/dots), no translation.
        final bubbleTexts = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(ReaderWordBubble),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data)
            .toList();
        expect(bubbleTexts, ['Extraordinaria']);

        // Dismiss bubble -> exits in press.
        final readerRect = tester.getRect(find.byType(TextReader));
        await tester.tapAt(
          Offset(readerRect.center.dx, readerRect.bottom - 160),
        );
        await tester.pump();
        await tester.pump(NocheMotion.press ~/ 2);
        expect(find.byType(ReaderWordBubble), findsOneWidget);
        expect(_bubbleOpacity(tester), greaterThan(0.0));
        expect(_bubbleOpacity(tester), lessThan(1.0));
        expect(_bubbleMotionDy(tester), greaterThan(0.0));

        await tester.pump(NocheMotion.press);
        await tester.pump();
        expect(find.byType(ReaderWordBubble), findsNothing);

        // Tap last word on line ("extraordinariamente") -> bubble clamps inside right/end edge.
        await tester.tapAt(_centerOfWordToken(tester, 'extraordinariamente'));
        await tester.pump();
        await tester.pump(NocheMotion.quick);
        final lastBubbleRect = tester.getRect(
          find.byKey(const Key('reader-word-bubble-body')),
        );
        expect(lastBubbleRect.left, greaterThanOrEqualTo(16.0));
        expect(lastBubbleRect.right, lessThanOrEqualTo(390.0 - 16.0));

        // 2. Arabic RTL edge-word clamping (first word on right edge, last word on left edge).
        final courseAr = _CourseWithWords(language: _arabicLanguage());
        final servicesAr = fakeServices(course: courseAr);
        final storeAr = ReadingStore(servicesAr.storage(ReadingStore.space));
        final bookAr = await storeAr.add(
          now: 2,
          title: 'الحدود',
          body: 'مستشفى المدينة الكبيرة.\n\nالنافذة المفتوحة.',
          generated: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TextReader(
              key: const ValueKey('clamp-ar'),
              services: servicesAr,
              id: bookAr.id,
            ),
          ),
        );
        await settle(tester);

        await tester.tapAt(_centerOfWordToken(tester, 'مستشفى'));
        await tester.pump();
        await tester.pump(NocheMotion.quick);
        final arFirstRect = tester.getRect(
          find.byKey(const Key('reader-word-bubble-body')),
        );
        expect(arFirstRect.left, greaterThanOrEqualTo(16.0));
        expect(arFirstRect.right, lessThanOrEqualTo(390.0 - 16.0));

        await tester.tapAt(
          Offset(readerRect.center.dx, readerRect.bottom - 160),
        );
        await tester.pump();
        await tester.pump(NocheMotion.press);
        await tester.pump();

        await tester.tapAt(_centerOfWordToken(tester, 'المفتوحة'));
        await tester.pump();
        await tester.pump(NocheMotion.quick);
        final arLastRect = tester.getRect(
          find.byKey(const Key('reader-word-bubble-body')),
        );
        expect(arLastRect.left, greaterThanOrEqualTo(16.0));
        expect(arLastRect.right, lessThanOrEqualTo(390.0 - 16.0));
      },
    );

    testWidgets(
      'reduced motion disables horizontal page travel and bubble rise while fading in place',
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
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: MaterialApp(
              home: TextReader(
                services: services,
                id: book.id,
                initialSettings: const ReaderSettings(step: 1),
              ),
            ),
          ),
        );
        await settle(tester);

        // Page turn keeps dx == 0 under reduced motion and progress snaps.
        await tester.fling(
          find.byType(ReaderPageView),
          const Offset(-300, 0),
          800,
        );
        await tester.pump();
        expect(_followIncomingDx(tester), 0.0);
        await tester.pump(NocheMotion.followAfter + NocheMotion.quick ~/ 2);
        expect(_followIncomingDx(tester), 0.0);
        await tester.pump(NocheMotion.quick);
        expect(find.text('2 / 2'), findsOneWidget);

        // Word bubble stays at dy == 0 while fading in.
        await tester.tapAt(_centerOfWordToken(tester, 'mañana'));
        await tester.pump();
        expect(_bubbleMotionDy(tester), 0.0);
        await tester.pump(NocheMotion.quick ~/ 2);
        expect(_bubbleMotionDy(tester), 0.0);
        expect(_bubbleOpacity(tester), greaterThan(0.0));
        expect(_bubbleOpacity(tester), lessThan(1.0));
        await tester.pump(NocheMotion.quick);
        expect(_bubbleMotionDy(tester), 0.0);
        expect(_bubbleOpacity(tester), 1.0);
      },
    );
  });
}
