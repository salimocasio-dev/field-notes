import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/feature_library.dart';
import 'package:feature_library/src/book_importer.dart';
import 'package:feature_library/src/import_screen.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/text_reader.dart';
import 'package:feature_library/src/wording.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart' show Rig, TestCourse, settle;

const List<Size> _viewports = [Size(390, 844), Size(412, 915)];

class _TestNavigator implements AppNavigator {
  final ValueNotifier<AppRoute?> current = ValueNotifier(null);
  int backs = 0;

  @override
  void go(AppRoute route) => current.value = route;

  @override
  void back() {
    backs++;
    current.value = null;
  }
}

class _FakeFilePicker implements ImportFilePicker {
  _FakeFilePicker(this.queue);

  final List<PickedImportFile?> queue;
  final List<List<String>> requestedExtensions = [];

  @override
  Future<PickedImportFile?> pick({
    required List<String> allowedExtensions,
  }) async {
    requestedExtensions.add(List<String>.of(allowedExtensions));
    if (queue.isEmpty) return null;
    return queue.removeAt(0);
  }
}

/// Fake store mimicking browser `localStorage` silent quota drop on large or
/// failing writes, with `DeletableKeyValueStore` support for rollback checks.
class _QuotaDropKeyValueStore implements KeyValueStore, DeletableKeyValueStore {
  _QuotaDropKeyValueStore({this.maxValueLength, this.dropKeyPrefix});

  final int? maxValueLength;
  final String? dropKeyPrefix;
  final Map<String, String> data = {};
  final List<String> deletedKeys = [];

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async {
    if (dropKeyPrefix != null && key.startsWith(dropKeyPrefix!)) {
      return; // Silent drop.
    }
    if (maxValueLength != null && value.length > maxValueLength!) {
      return; // Silent quota drop like browser localStorage.
    }
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deletedKeys.add(key);
    data.remove(key);
  }
}

class _RtlCatalog extends TestCourse implements LanguageCatalog {
  _RtlCatalog({required this.language});

  @override
  final Language language;
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

void _seedEarWords(FakeProgressStore store, Map<String, int> stages) {
  for (final entry in stages.entries) {
    store.put(
      WordRecord(
        w: entry.key,
        primera: 0,
        ear: SkillRecord(etapa: entry.value),
      ),
    );
  }
}

Future<void> _pumpImport(
  WidgetTester tester, {
  Key? screenKey,
  required Services services,
  Size size = const Size(390, 844),
  ImportFilePicker? filePicker,
  Future<void> Function()? stepYield,
  List<ImportJobState> initialJobs = const [],
  List<ImportErrorItem> initialErrors = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: ImportScreen(
        key: screenKey,
        services: services,
        filePicker: filePicker,
        stepYield: stepYield,
        initialJobs: initialJobs,
        initialErrors: initialErrors,
      ),
    ),
  );
  await settle(tester);
}

void main() {
  group('LibraryWording and pure importer helpers', () {
    test('formatList, formatFileSize, and bookMetaLine formatting', () {
      expect(LibraryWording.formatList(const []), '');
      expect(LibraryWording.formatList(const ['TXT']), 'TXT');
      expect(LibraryWording.formatList(const ['EPUB', 'TXT']), 'EPUB or TXT');
      expect(
        LibraryWording.formatList(const ['EPUB', 'PDF', 'TXT']),
        'EPUB, PDF or TXT',
      );

      expect(LibraryWording.formatFileSize(512), '512 B');
      expect(LibraryWording.formatFileSize(1536), '1.5 KB');
      expect(LibraryWording.formatFileSize(24 * 1024), '24 KB');
      expect(
        LibraryWording.formatFileSize((8.4 * 1024 * 1024).round()),
        '8.4 MB',
      );

      expect(
        LibraryWording.bookMetaLine(format: LibraryWording.formatTxt, pages: 1),
        'TXT · 1 page',
      );
      expect(
        LibraryWording.bookMetaLine(
          format: LibraryWording.formatTxt,
          pages: 12,
          chapters: 1,
        ),
        'TXT · 12 pages',
      );
      expect(
        LibraryWording.bookMetaLine(
          format: LibraryWording.formatTxt,
          pages: 86,
          chapters: 9,
        ),
        'TXT · 86 pages · 9 chapters',
      );
    });

    test('parsePlainTextParagraphs strips BOM, folds wrapped lines, splits on blank lines, and never guesses chapters', () {
      const raw =
          '\uFEFFCHAPTER 1\r\n'
          'Primera línea envuelta\r\n'
          '  en la misma idea.\r\n'
          '\r\n'
          '   \t  \n'
          'PARTE DOS\n'
          'Segunda idea  con\tespacios.\r'
          'Continúa aquí.\n\n\n'
          'Tercera idea.';

      final paragraphs = parsePlainTextParagraphs(raw);
      expect(paragraphs, [
        'CHAPTER 1 Primera línea envuelta en la misma idea.',
        'PARTE DOS Segunda idea con espacios. Continúa aquí.',
        'Tercera idea.',
      ]);
    });

    test('title derivation from file name and pasted text', () {
      expect(deriveBookTitleFromFileName('Mi libro.txt'), 'Mi libro');
      expect(deriveBookTitleFromFileName('dir/sub/NOVELA.TXT'), 'NOVELA');
      expect(
        deriveBookTitleFromFileName('  .txt  '),
        LibraryWording.untitledBook,
      );

      expect(
        deriveBookTitleFromText('Título propio', const ['Otro texto']),
        'Título propio',
      );
      expect(
        deriveBookTitleFromText('   ', const [
          'Uno dos tres cuatro cinco seis siete ocho.',
        ]),
        'Uno dos tres cuatro cinco seis',
      );
      expect(
        deriveBookTitleFromText(null, const []),
        LibraryWording.untitledBook,
      );
    });

    test('ReadingStore stores body under body:<id>, reads legacy inline JSON, and cleans up on silent quota drop', () async {
      final kv = FakeKeyValueStore();
      final store = ReadingStore(kv);

      // Legacy inline entry remains readable.
      await kv.write(
        'texts',
        jsonEncode([
          {
            'id': 'biblioteca-legacy-0',
            'title': 'Viejo',
            'body': 'Texto antiguo.',
            'generated': false,
          },
        ]),
      );

      final added = await store.add(
        now: 500,
        title: 'Nuevo',
        body: 'Párrafo uno.\n\nPárrafo dos.',
        generated: false,
        format: LibraryWording.formatTxt,
        byteSize: 42,
        importedAt: 500,
        estimatedPages: 3,
      );

      expect(
        kv.read(ReadingStore.bodyKeyFor(added.id)),
        'Párrafo uno.\n\nPárrafo dos.',
      );
      final rawIndex = jsonDecode(kv.read('texts')!) as List;
      final addedIndex = rawIndex.first as Map;
      expect(addedIndex['bodyKey'], ReadingStore.bodyKeyFor(added.id));
      expect(addedIndex.containsKey('body'), isFalse);

      // Both new and legacy entries hydrate properly across a fresh store.
      final reloaded = ReadingStore(kv);
      expect(reloaded.texts().length, 2);
      final fetched = reloaded.text(added.id);
      expect(fetched?.body, 'Párrafo uno.\n\nPárrafo dos.');
      expect(fetched?.format, LibraryWording.formatTxt);
      expect(fetched?.byteSize, 42);
      expect(fetched?.importedAt, 500);
      expect(fetched?.estimatedPages, 3);
      expect(reloaded.text('biblioteca-legacy-0')?.body, 'Texto antiguo.');

      // Silent quota drop on body write throws ReadingStorageFullException.
      final dropBodyKv = _QuotaDropKeyValueStore(maxValueLength: 5);
      final dropBodyStore = ReadingStore(dropBodyKv);
      await expectLater(
        dropBodyStore.add(
          now: 1,
          title: 'Grande',
          body: 'Más de cinco caracteres.',
          generated: false,
        ),
        throwsA(isA<ReadingStorageFullException>()),
      );
      expect(dropBodyKv.data, isEmpty);

      // Silent quota drop on index write cleans up the written body key.
      final dropIndexKv = _QuotaDropKeyValueStore(dropKeyPrefix: 'texts');
      final dropIndexStore = ReadingStore(dropIndexKv);
      await expectLater(
        dropIndexStore.add(
          now: 2,
          title: 'Libro',
          body: 'Hola.',
          generated: false,
        ),
        throwsA(isA<ReadingStorageFullException>()),
      );
      expect(dropIndexKv.data, isEmpty);
      expect(dropIndexKv.deletedKeys, [
        ReadingStore.bodyKeyFor('biblioteca-2-0'),
      ]);
    });
  });

  group('ImportScreen layout and copy', () {
    for (final size in _viewports) {
      testWidgets(
        'renders cleanly at ${size.width.toInt()}x${size.height.toInt()} with exact N5.4 controls',
        (tester) async {
          final rig = Rig();
          await _pumpImport(tester, services: rig.services, size: size);

          expect(tester.takeException(), isNull);
          expect(find.text(LibraryWording.importTitle), findsOneWidget);
          expect(
            find.text(LibraryWording.importIntro(supportedImportFormats)),
            findsOneWidget,
          );
          expect(find.text(LibraryWording.pasteTextTile), findsOneWidget);
          expect(find.text(LibraryWording.chooseFileButton), findsOneWidget);

          // Exactly one orange primary button on screen.
          expect(find.byType(NochePrimaryButton), findsOneWidget);

          // Unshipped N5.8/N5.9/Share items must be absent.
          expect(find.text('Web page'), findsNothing);
          expect(find.text('YouTube video'), findsNothing);
          expect(
            find.text('Or from any app: Share, then Coquí.'),
            findsNothing,
          );
          expect(
            find.text(LibraryWording.addingNowHeading.toUpperCase()),
            findsNothing,
          );
          expect(
            find.text(LibraryWording.readyHeading.toUpperCase()),
            findsNothing,
          );
        },
      );
    }

    testWidgets('close button calls nav.back()', (tester) async {
      final rig = Rig();
      await _pumpImport(tester, services: rig.services);

      await tester.tap(find.bySemanticsLabel(LibraryWording.importClose));
      await tester.pump();
      expect(rig.nav.backs, 1);
    });
  });

  group('Adding now 3-step progress card', () {
    testWidgets(
      'displays Step 1, Step 2, and Step 3 with 3-dash progress bar and filename/size',
      (tester) async {
        final rig = Rig();
        final stepCompleters = [
          Completer<void>(),
          Completer<void>(),
          Completer<void>(),
        ];
        var yieldIndex = 0;

        // Multi-page text so Step 2 also shows page counts.
        final longText = List.generate(
          25,
          (i) => 'Casa árbol niño agua perro gato sol luna mar río noche día.',
        ).join('\n\n');
        final bytes = Uint8List.fromList(utf8.encode(longText));
        final picker = _FakeFilePicker([
          PickedImportFile(name: 'El faro.txt', bytes: bytes),
        ]);

        await _pumpImport(
          tester,
          services: rig.services,
          filePicker: picker,
          stepYield: () => stepCompleters[yieldIndex++].future,
        );

        await tester.tap(find.text(LibraryWording.chooseFileButton));
        await tester.pump();

        // Step 1: Opening the file.
        expect(
          find.text(LibraryWording.addingNowHeading.toUpperCase()),
          findsOneWidget,
        );
        expect(find.text('El faro.txt'), findsOneWidget);
        expect(
          find.text(LibraryWording.formatFileSize(bytes.length)),
          findsOneWidget,
        );
        expect(
          find.text(
            '${LibraryWording.stepOfTotal(1)} ${LibraryWording.stepOpeningDetail}',
            findRichText: true,
          ),
          findsOneWidget,
        );
        var bars = tester
            .widgetList<NocheProgressBar>(find.byType(NocheProgressBar))
            .toList();
        expect(bars.length, 3);
        for (final bar in bars) {
          expect(bar.color, NocheColors.text);
          expect(bar.trackColor, NocheColors.line);
        }
        expect(bars[0].value, greaterThan(0));
        expect(bars[1].value, 0);
        expect(bars[2].value, 0);

        // Advance to Step 2: Reading the pages.
        stepCompleters[0].complete();
        await tester.pump();
        await tester.pump();
        expect(
          find.textContaining(
            LibraryWording.stepOfTotal(2),
            findRichText: true,
          ),
          findsOneWidget,
        );
        bars = tester
            .widgetList<NocheProgressBar>(find.byType(NocheProgressBar))
            .toList();
        expect(bars[0].value, 1.0);
        expect(bars[1].value, greaterThan(0));
        expect(bars[2].value, 0);

        // Advance to Step 3: Checking words.
        stepCompleters[1].complete();
        await tester.pump();
        await tester.pump();
        expect(
          find.text(
            '${LibraryWording.stepOfTotal(3)} ${LibraryWording.stepCheckingDetail}',
            findRichText: true,
          ),
          findsOneWidget,
        );
        bars = tester
            .widgetList<NocheProgressBar>(find.byType(NocheProgressBar))
            .toList();
        expect(bars[0].value, 1.0);
        expect(bars[1].value, 1.0);
        expect(bars[2].value, greaterThan(0));

        // Finish import -> moves from Adding now to Ready.
        stepCompleters[2].complete();
        await settle(tester);
        expect(
          find.text(LibraryWording.addingNowHeading.toUpperCase()),
          findsNothing,
        );
        expect(
          find.text(LibraryWording.readyHeading.toUpperCase()),
          findsOneWidget,
        );
        // Book title appears on both NocheCover and the Ready row title.
        expect(find.text('El faro'), findsNWidgets(2));
      },
    );
  });

  group('Importing a TXT file end-to-end', () {
    testWidgets(
      'parses blank-line paragraphs without guessing chapters, computes coverage, persists across restart, and opens in TextReader',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final nav = _TestNavigator();
        final clock = FakeClock();
        final progress = FakeProgressStore();
        _seedEarWords(progress, {'casa': 2, 'arbol': 3, 'agua': 4});
        final spaces = <String, FakeKeyValueStore>{};
        Services makeServices() => fakeServices(
          progress: progress,
          clock: clock,
          nav: nav,
          storage: (space) => spaces.putIfAbsent(space, FakeKeyValueStore.new),
        );

        const rawTxt =
            'CHAPTER ONE\n'
            'Casa árbol agua.\n'
            'Casa.\n'
            '\n'
            'Perro desconocido.';
        final picker = _FakeFilePicker([
          PickedImportFile(
            name: 'Cuento de la isla.txt',
            bytes: Uint8List.fromList(utf8.encode(rawTxt)),
          ),
        ]);

        var services = makeServices();
        const module = LibraryModule();

        Widget buildApp() => MaterialApp(
          home: ValueListenableBuilder<AppRoute?>(
            valueListenable: nav.current,
            builder: (context, route, _) {
              if (route is BookRoute) {
                return module.screenFor(route, services)!;
              }
              return ImportScreen(
                services: services,
                filePicker: picker,
                stepYield: () async {},
              );
            },
          ),
        );

        await tester.pumpWidget(buildApp());
        await settle(tester);

        await tester.tap(find.text(LibraryWording.chooseFileButton));
        await settle(tester);

        expect(picker.requestedExtensions, [
          ['txt'],
        ]);

        // Verify stored ReadingText structure: 2 paragraphs, chapters == null.
        final store = ReadingStore(services.storage(ReadingStore.space));
        final savedBooks = store.texts();
        expect(savedBooks.length, 1);
        final book = savedBooks.first;
        expect(book.title, 'Cuento de la isla');
        expect(book.chapters, isNull);
        expect(book.format, LibraryWording.formatTxt);
        final doc = ReaderDocument.fromPersonal(book);
        expect(doc.chapters.length, 1);
        expect(doc.chapters.first.paragraphs.length, 2);
        expect(
          doc.chapters.first.paragraphs[0].text,
          'CHAPTER ONE Casa árbol agua. Casa.',
        );
        expect(doc.chapters.first.paragraphs[1].text, 'Perro desconocido.');

        // Coverage: qualifying Latin words = CHAPTER, ONE, Casa, árbol, agua, Casa, Perro, desconocido (8 total; 4 heard -> 50%).
        const expectedPercent = 50;
        expect(find.text('Cuento de la isla'), findsNWidgets(2));
        expect(
          find.text(
            LibraryWording.bookMetaLine(
              format: LibraryWording.formatTxt,
              pages: book.estimatedPages!,
            ),
          ),
          findsOneWidget,
        );
        final cover = tester.widget<NocheCover>(find.byType(NocheCover));
        expect(cover.size, NocheCoverSize.small);
        final coverageBar = tester.widget<NocheProgressBar>(
          find.byType(NocheProgressBar),
        );
        expect(coverageBar.color, NocheColors.listening);
        expect(coverageBar.value, closeTo(0.5, 1e-9));
        expect(
          find.text(
            '${LibraryWording.coverageHeadline(expectedPercent)} ${LibraryWording.coveragePhraseStretch}',
            findRichText: true,
          ),
          findsOneWidget,
        );

        // Live coverage update when progress changes.
        _seedEarWords(progress, {
          'chapter': 1,
          'one': 1,
          'casa': 2,
          'arbol': 3,
          'agua': 4,
          'perro': 1,
          'desconocido': 1,
        });
        await settle(tester);
        expect(
          find.text(
            '${LibraryWording.coverageHeadline(100)} ${LibraryWording.coveragePhraseEasy}',
            findRichText: true,
          ),
          findsOneWidget,
        );

        // Simulate app restart with fresh Services backed by same persistent storage.
        services = makeServices();
        await tester.pumpWidget(buildApp());
        await settle(tester);
        expect(find.text('Cuento de la isla'), findsNWidgets(2));

        // Tap Ready row -> opens TextReader via BookRoute with paragraphs.
        await tester.tap(find.text('Cuento de la isla').last);
        await settle(tester);
        expect(find.byType(TextReader), findsOneWidget);
        expect(nav.current.value, BookRoute(book.id));
        expect(
          find.textContaining('Perro desconocido.', findRichText: true),
          findsOneWidget,
        );
      },
    );
  });

  group('Paste text flow', () {
    testWidgets(
      'PasteTextScreen disables Add when blank, imports with optional or auto-derived title, and opens in TextReader',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final nav = _TestNavigator();
        final progress = FakeProgressStore();
        _seedEarWords(progress, {'hola': 3, 'casa': 2});
        final services = fakeServices(progress: progress, nav: nav);
        const module = LibraryModule();

        await tester.pumpWidget(
          MaterialApp(
            home: ValueListenableBuilder<AppRoute?>(
              valueListenable: nav.current,
              builder: (context, route, _) {
                if (route is BookRoute) {
                  return module.screenFor(route, services)!;
                }
                return ImportScreen(services: services, stepYield: () async {});
              },
            ),
          ),
        );
        await settle(tester);

        // 1) Open Paste text screen, verify Add button disabled while empty/whitespace.
        await tester.tap(find.text(LibraryWording.pasteTextTile));
        await tester.pumpAndSettle();
        expect(find.byType(PasteTextScreen), findsOneWidget);

        var addButton = tester.widget<NochePrimaryButton>(
          find.widgetWithText(
            NochePrimaryButton,
            LibraryWording.pasteAddButton,
          ),
        );
        expect(addButton.onPressed, isNull);

        await tester.enterText(find.byType(TextField).last, '   \n\t  ');
        await tester.pump();
        addButton = tester.widget<NochePrimaryButton>(
          find.widgetWithText(
            NochePrimaryButton,
            LibraryWording.pasteAddButton,
          ),
        );
        expect(addButton.onPressed, isNull);

        // Enter explicit title and two paragraphs.
        await tester.enterText(find.byType(TextFormField), 'Mis notas');
        await tester.enterText(
          find.byType(TextField).last,
          'Hola casa\nsegunda línea.\n\nHola casa.',
        );
        await tester.pump();
        addButton = tester.widget<NochePrimaryButton>(
          find.widgetWithText(
            NochePrimaryButton,
            LibraryWording.pasteAddButton,
          ),
        );
        expect(addButton.onPressed, isNotNull);

        await tester.tap(find.text(LibraryWording.pasteAddButton));
        await tester.pumpAndSettle();
        await settle(tester);

        expect(find.byType(ImportScreen), findsOneWidget);
        expect(find.text('Mis notas'), findsNWidgets(2));
        expect(
          find.text(
            LibraryWording.bookMetaLine(
              format: LibraryWording.formatPasted,
              pages: 1,
            ),
          ),
          findsOneWidget,
        );

        final store = ReadingStore(services.storage(ReadingStore.space));
        final firstBook = store.texts().first;
        expect(firstBook.chapters, isNull);
        expect(firstBook.format, LibraryWording.formatPasted);
        expect(
          ReaderDocument.fromPersonal(firstBook)
              .chapters
              .first
              .paragraphs
              .length,
          2,
        );

        // 2) Paste again without a title -> derives title from first paragraph.
        await tester.tap(find.text(LibraryWording.pasteTextTile));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          'Hola casa hola casa.',
        );
        await tester.pump();
        await tester.tap(find.text(LibraryWording.pasteAddButton));
        await tester.pumpAndSettle();
        await settle(tester);

        expect(find.text('Hola casa hola casa.'), findsNWidgets(2));
        // 100% coverage for 'Hola casa hola casa.'.
        expect(
          find.text(
            '${LibraryWording.coverageHeadline(100)} ${LibraryWording.coveragePhraseEasy}',
            findRichText: true,
          ),
          findsOneWidget,
        );

        // Tap Ready row -> opens TextReader via BookRoute.
        await tester.tap(find.text('Mis notas').last);
        await settle(tester);
        expect(find.byType(TextReader), findsOneWidget);
        expect(nav.current.value, BookRoute(firstBook.id));
      },
    );
  });

  group('Error cards (calm 1 px text border, no red)', () {
    testWidgets(
      'handles locked .azw3, unsupported .pdf, invalid UTF-8/NUL .txt, empty .txt, storage full, and unavailable picker',
      (tester) async {
        final rig = Rig();
        final picker = _FakeFilePicker([
          PickedImportFile(
            name: 'La isla de noche.azw3',
            bytes: Uint8List.fromList(utf8.encode('locked')),
          ),
          PickedImportFile(
            name: 'Guia.pdf',
            bytes: Uint8List.fromList(utf8.encode('%PDF-1.4')),
          ),
          PickedImportFile(
            name: 'Roto.txt',
            bytes: Uint8List.fromList([0xFF, 0xFE, 0x00, 0x01]),
          ),
          PickedImportFile(
            name: 'Vacio.txt',
            bytes: Uint8List.fromList(utf8.encode('   \n\n\t ')),
          ),
        ]);

        await _pumpImport(
          tester,
          screenKey: const ValueKey('errors-files'),
          services: rig.services,
          filePicker: picker,
          stepYield: () async {},
        );

        // 1. Locked .azw3
        await tester.tap(find.text(LibraryWording.chooseFileButton));
        await settle(tester);
        expect(find.text('La isla de noche.azw3'), findsOneWidget);
        expect(find.text(LibraryWording.errorLockedBook), findsOneWidget);
        final lockIcons = tester
            .widgetList<NocheIcon>(find.byType(NocheIcon))
            .where((i) => i.data == NocheIcons.lock);
        expect(lockIcons, isNotEmpty);

        // Verify error card border is 1 px NocheColors.text and transparent fill.
        final errorContainer = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) {
              final d = c.decoration;
              return d is BoxDecoration &&
                  d.color == null &&
                  d.border == Border.all(color: NocheColors.text, width: 1) &&
                  d.borderRadius == BorderRadius.circular(NocheSize.cardRadius);
            });
        expect(errorContainer, isNotEmpty);

        // 2. Unsupported .pdf
        await tester.tap(find.text(LibraryWording.chooseFileButton));
        await settle(tester);
        expect(find.text('Guia.pdf'), findsOneWidget);
        expect(
          find.text(
            LibraryWording.errorUnsupportedFormat(supportedImportFormats),
          ),
          findsOneWidget,
        );

        // 3. Invalid UTF-8 / binary NUL .txt
        await tester.tap(find.text(LibraryWording.chooseFileButton));
        await settle(tester);
        expect(find.text('Roto.txt'), findsOneWidget);
        expect(find.text(LibraryWording.errorInvalidText), findsOneWidget);

        // 4. Empty .txt
        await tester.tap(find.text(LibraryWording.chooseFileButton));
        await settle(tester);
        expect(find.text('Vacio.txt'), findsOneWidget);
        expect(find.text(LibraryWording.errorEmptyText), findsOneWidget);

        // 5. Storage quota failure (silent drop)
        final quotaStore = _QuotaDropKeyValueStore(maxValueLength: 5);
        final quotaServices = fakeServices(storage: (_) => quotaStore);
        final quotaPicker = _FakeFilePicker([
          PickedImportFile(
            name: 'Largo.txt',
            bytes: Uint8List.fromList(utf8.encode('Un texto bastante largo.')),
          ),
        ]);
        await _pumpImport(
          tester,
          screenKey: const ValueKey('errors-quota'),
          services: quotaServices,
          filePicker: quotaPicker,
          stepYield: () async {},
        );
        await tester.tap(find.text(LibraryWording.chooseFileButton));
        await settle(tester);
        expect(find.text('Largo.txt'), findsOneWidget);
        expect(find.text(LibraryWording.errorStorageFull), findsOneWidget);
        expect(quotaStore.data, isEmpty);

        // 6. Unavailable file picker (null)
        final noPickerRig = Rig();
        await _pumpImport(
          tester,
          screenKey: const ValueKey('errors-no-picker'),
          services: noPickerRig.services,
        );
        await tester.tap(find.text(LibraryWording.chooseFileButton));
        await settle(tester);
        expect(
          find.text(LibraryWording.errorPickerUnavailable),
          findsOneWidget,
        );
      },
    );
  });

  group('RTL Arabic course support', () {
    testWidgets(
      'mirrors ImportScreen layout, imports Arabic text with accurate coverage, and opens in TextReader',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final arabic = _arabicLanguage();
        final course = _RtlCatalog(language: arabic);
        final nav = _TestNavigator();
        final progress = FakeProgressStore();
        _seedEarWords(progress, {'كتاب': 2, 'بيت': 3});
        final services = fakeServices(
          course: course,
          progress: progress,
          nav: nav,
        );
        final picker = _FakeFilePicker([
          PickedImportFile(
            name: 'قصة.txt',
            bytes: Uint8List.fromList(utf8.encode('كِتَابُ بيت.\n\nشجرة جبل.')),
          ),
        ]);
        const module = LibraryModule();

        await tester.pumpWidget(
          MaterialApp(
            home: ValueListenableBuilder<AppRoute?>(
              valueListenable: nav.current,
              builder: (context, route, _) {
                if (route is BookRoute) {
                  return module.screenFor(route, services)!;
                }
                return ImportScreen(
                  services: services,
                  filePicker: picker,
                  stepYield: () async {},
                );
              },
            ),
          ),
        );
        await settle(tester);

        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(
            tester.element(find.text(LibraryWording.importTitle)),
          ),
          TextDirection.rtl,
        );

        await tester.tap(find.text(LibraryWording.chooseFileButton));
        await settle(tester);

        // 2 heard of 4 Arabic words -> 50%.
        expect(find.text('قصة'), findsNWidgets(2));
        expect(
          find.text(
            '${LibraryWording.coverageHeadline(50)} ${LibraryWording.coveragePhraseStretch}',
            findRichText: true,
          ),
          findsOneWidget,
        );

        // Open in TextReader.
        await tester.tap(find.text('قصة').last);
        await settle(tester);
        expect(find.byType(TextReader), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('ReadingStore split-body rollback and concurrency', () {
    test('non-DeletableKeyValueStore shrinks orphaned body to empty string when texts write throws', () async {
      final storeKv = _NonDeletableTextsThrowingStore();
      final store = ReadingStore(storeKv);

      await expectLater(
        store.add(
          now: 100,
          title: 'Grande',
          body: 'Mucho texto aquí.',
          generated: false,
          format: LibraryWording.formatTxt,
        ),
        throwsA(isA<ReadingStorageFullException>()),
      );

      final bodyKey = ReadingStore.bodyKeyFor('${personalBookPrefix}100-0');
      expect(storeKv.data[bodyKey], '');
      expect(storeKv.data['texts'], isNull);
    });

    test(
      'KeyValueStore throwing on write throws ReadingStorageFullException',
      () async {
        final storeKv = _ThrowingWriteStore();
        final store = ReadingStore(storeKv);

        await expectLater(
          store.add(
            now: 200,
            title: 'Lleno',
            body: 'Casa azul.',
            generated: false,
          ),
          throwsA(isA<ReadingStorageFullException>()),
        );
      },
    );

    test('concurrent add calls across separate ReadingStore instances preserve both books and keep bodyKey split', () async {
      final sharedKv = _AsyncDelayStore();
      final storeA = ReadingStore(sharedKv);
      final storeB = ReadingStore(sharedKv);

      final results = await Future.wait([
        storeA.add(
          now: 500,
          title: 'Libro A',
          body: 'Texto A.',
          generated: false,
          format: LibraryWording.formatTxt,
        ),
        storeB.add(
          now: 500,
          title: 'Libro B',
          body: 'Texto B.',
          generated: false,
          format: LibraryWording.formatPasted,
        ),
      ]);

      await storeA.markOpened(results[0].id, 600);

      final loaded = storeA.texts();
      expect(loaded.map((t) => t.title).toSet(), {'Libro A', 'Libro B'});
      expect(loaded.map((t) => t.id).toSet().length, 2);

      final rawIndex = jsonDecode(sharedKv.read('texts')!) as List;
      for (final entry in rawIndex.cast<Map>()) {
        expect(entry['bodyKey'], isA<String>());
        expect(entry.containsKey('body'), isFalse);
      }
    });
  });
}

class _NonDeletableTextsThrowingStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async {
    if (key == 'texts') {
      throw StateError('QuotaExceededError');
    }
    data[key] = value;
  }
}

class _ThrowingWriteStore implements KeyValueStore {
  @override
  String? read(String key) => null;

  @override
  Future<void> write(String key, String value) async {
    throw StateError('QuotaExceededError');
  }
}

class _AsyncDelayStore implements KeyValueStore, DeletableKeyValueStore {
  final Map<String, String> data = {};

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}
