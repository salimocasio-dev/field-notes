import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/feature_library.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/reading_home.dart';
import 'package:feature_library/src/text_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/dev_main.dart';
import 'support.dart' show Rig, settle;

Future<void> ready(WidgetTester tester) async {
  await settle(tester);
  await tester.pump(const Duration(milliseconds: 300));
  await settle(tester);
}

void main() {
  test('the module owns Biblioteca and book routes', () {
    final rig = Rig();
    const module = LibraryModule();
    expect(module.id, 'library');
    expect(module.tab(rig.services).label, CoquiLabels.library);
    expect(
      module.screenFor(const BookRoute('uno'), rig.services),
      isA<TextReader>(),
    );
    for (final route in <AppRoute>[
      const StoryRoute('uno'),
      const StoryRoute('uno', listen: true),
      const ReviewRoute(),
      const LevelCheckRoute(),
      const CallRoute('casa'),
      const VoiceTestRoute(),
      const TabRoute('library'),
    ]) {
      expect(module.screenFor(route, rig.services), isNull, reason: '$route');
    }
  });

  testWidgets('the shelf leaves finished course transcripts out', (
    tester,
  ) async {
    final rig = Rig()..played(['uno']);
    const module = LibraryModule();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: module.tab(rig.services).builder),
        ),
      ),
    );
    await ready(tester);
    expect(find.byType(ReadingHome), findsOneWidget);
    expect(find.text('Write my story'), findsOneWidget);
    expect(find.text('+ Add your own'), findsNothing);
    expect(find.text('Uno'), findsNothing);
    expect(rig.course.bookAsked, isEmpty);
  });

  testWidgets('the dev shelf generates a story using a chosen practice word', (
    tester,
  ) async {
    await tester.pumpWidget(devApp());
    await ready(tester);
    expect(find.byType(NocheTabBar), findsOneWidget);
    await tester.tap(find.widgetWithText(NocheOutlineButton, 'Write my story'));
    await ready(tester);
    await tester.enterText(find.byType(TextFormField), 'jugo');
    await tester.tap(find.widgetWithText(NochePrimaryButton, 'Write my story'));
    await ready(tester);
    expect(find.byType(TextReader), findsOneWidget);
    expect(find.byType(NocheTabBar), findsNothing);
    expect(find.byType(Image), findsNothing);

    await tester.tap(find.byTooltip(ReaderTexts.close));
    await ready(tester);
    expect(find.byType(NocheTabBar), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
  });

  testWidgets('reports when the generator has no vocabulary match', (
    tester,
  ) async {
    await tester.pumpWidget(devApp(options: const DevOptions(seed: 'vacio')));
    await ready(tester);
    await tester.tap(find.widgetWithText(NocheOutlineButton, 'Write my story'));
    await ready(tester);
    await tester.tap(find.widgetWithText(NochePrimaryButton, 'Write my story'));
    await ready(tester);
    expect(find.textContaining('no new story that fits'), findsOneWidget);
    expect(find.byType(TextReader), findsNothing);
  });

  testWidgets(
    'a pre-stored book resumes its saved page before A2 via Continue reading and the shelf Book tile',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final nav = DevNavigator();
      final clock = FakeClock();
      final services = fakeServices(clock: clock, nav: nav);
      final store = ReadingStore(services.storage(ReadingStore.space));
      final book = await store.add(
        now: 100,
        title: 'Mi cuaderno',
        body: 'Tengo un cuaderno. Es azul. Tiene papel. Escribo aquí.',
        generated: false,
      );
      await store.savePlace(
        book.id,
        const ReadingPlace(page: 0, openedAt: 200),
      );

      const module = LibraryModule();
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<AppRoute?>(
            valueListenable: nav.current,
            builder: (context, route, _) {
              if (route is BookRoute) {
                return module.screenFor(route, services)!;
              }
              return ReadingHome(services: services);
            },
          ),
        ),
      );
      await ready(tester);
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Continue reading'), findsOneWidget);

      await tester.ensureVisible(find.text('Book'));
      await tester.tap(find.text('Book'));
      await ready(tester);
      expect(find.byType(TextReader), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.byTooltip(ReaderTexts.nextPage));
      await ready(tester);
      expect(find.text('2 / 2'), findsOneWidget);
      await tester.tap(find.byTooltip(ReaderTexts.close));
      await ready(tester);

      expect(find.byType(ReadingHome), findsOneWidget);
      expect(find.text('Book'), findsOneWidget);
      expect(
        find.text('Page 2 of 2 · 1 min left in the chapter'),
        findsOneWidget,
      );
      expect(store.place(book.id).words, isEmpty);

      await tester.tap(find.text('Continue reading'));
      await ready(tester);
      expect(find.byType(TextReader), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
    },
  );

  testWidgets('a text that is not there says so in one line; the X goes back', (
    tester,
  ) async {
    for (final id in ['biblioteca-gone', 'no-such-book']) {
      final rig = Rig();
      const module = LibraryModule();
      await tester.pumpWidget(
        MaterialApp(home: module.screenFor(BookRoute(id), rig.services)!),
      );
      await ready(tester);
      expect(find.text(ReaderTexts.textUnavailable), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.byTooltip(ReaderTexts.close));
      expect(rig.nav.routes, isEmpty);
      expect(rig.nav.backs, 1, reason: id);
    }
  });

  testWidgets('an existing book route opens the book\'s lines as text', (
    tester,
  ) async {
    final rig = Rig();
    const module = LibraryModule();
    await tester.pumpWidget(
      MaterialApp(
        home: module.screenFor(const BookRoute('uno'), rig.services)!,
      ),
    );
    await ready(tester);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(
      find.textContaining('Me llamo Carmen', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets(
    'a word tap plays only its recorded word and credits one audible ear meeting',
    (tester) async {
      final course = _WordCatalog();
      final clips = FakeClipPlayer();
      final progress = FakeProgressStore();
      final services = fakeServices(
        course: course,
        clips: clips,
        progress: progress,
      );
      final store = ReadingStore(services.storage(ReadingStore.space));
      final text = await store.add(
        now: 0,
        title: 'Prueba',
        body: '¡Casa!',
        generated: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: TextReader(services: services, id: text.id),
        ),
      );
      await ready(tester);

      final rich = find.text('¡Casa!', findRichText: true);
      expect(rich, findsOneWidget);
      final box = tester.getRect(rich);
      final point = Offset(box.left + 24, box.top + 18);
      await tester.tapAt(point);
      await ready(tester);
      expect(clips.played, ['one-word']);
      expect(progress.word('casa')?.oida, 1);
      expect(progress.hasRead(text.id), isFalse);
      expect(store.place(text.id).words, isEmpty);

      clips.muted = true;
      await tester.tapAt(point);
      await ready(tester);
      expect(progress.word('casa')?.oida, 1);
    },
  );

  testWidgets('verified A2 enables encountered vocabulary and completion', (
    tester,
  ) async {
    final progress = FakeProgressStore();
    progress.import(
      jsonEncode({
        ...progress.raw,
        'nivel': {'cefr': 'A2'},
      }),
    );
    final services = fakeServices(progress: progress);
    final store = ReadingStore(services.storage(ReadingStore.space));
    final text = await store.add(
      now: 0,
      title: 'Prueba',
      body: '¡Hola! ¡Hola, casa!',
      generated: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TextReader(services: services, id: text.id),
      ),
    );
    await ready(tester);
    expect(store.place(text.id).words, {'hola', 'casa'});
    await tester.tap(find.text(CoquiLabels.fin));
    await ready(tester);
    expect(progress.hasRead(text.id), isTrue);
  });
}

class _WordCatalog extends FakeCourseCatalog {
  @override
  RepasoData get repaso => RepasoData(
    sentences: [],
    words: [
      RepasoWord(
        word: 'casa',
        place: 'casa',
        scoring: RepasoScoring.cual,
        solo: 'one-word',
      ),
    ],
  );

  @override
  ClipInfo? clip(String id) => id == 'one-word'
      ? ClipInfo(
          id: id,
          who: 'narr',
          text: 'Casa.',
          startMs: 0,
          endMs: 500,
          url: '',
        )
      : super.clip(id);
}
