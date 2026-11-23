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
    expect(find.text('Generate a story'), findsOneWidget);
    expect(find.text('Add text'), findsOneWidget);
    expect(find.text('Uno'), findsNothing);
    expect(rig.course.bookAsked, isEmpty);
  });

  testWidgets('the dev shelf generates a story using a chosen practice word', (
    tester,
  ) async {
    await tester.pumpWidget(devApp());
    await ready(tester);
    await tester.tap(find.text('Generate a story'));
    await ready(tester);
    await tester.enterText(find.byType(TextFormField), 'jugo');
    await tester.tap(find.text('Generate'));
    await ready(tester);
    expect(find.byType(TextReader), findsOneWidget);
    expect(find.byType(CoquiTabBar), findsNothing);
    expect(find.byType(Image), findsNothing);

    await tester.tap(find.byTooltip(ReaderTexts.close));
    await ready(tester);
    expect(find.text('Generated story'), findsOneWidget);
    expect(find.text('Read story'), findsOneWidget);
  });

  testWidgets('reports when the generator has no vocabulary match', (
    tester,
  ) async {
    await tester.pumpWidget(devApp(options: const DevOptions(seed: 'vacio')));
    await ready(tester);
    await tester.tap(find.text('Generate a story'));
    await ready(tester);
    await tester.tap(find.text('Generate'));
    await ready(tester);
    expect(find.textContaining('no new story that fits'), findsOneWidget);
    expect(find.byType(TextReader), findsNothing);
  });

  testWidgets('imports text and resumes the saved page before A2', (
    tester,
  ) async {
    await tester.pumpWidget(devApp());
    await ready(tester);
    await tester.tap(find.text('Add text'));
    await ready(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Mi cuaderno');
    await tester.enterText(
      find.byType(TextFormField).last,
      'Tengo un cuaderno. Es azul. Tiene papel. Escribo aquí.',
    );
    await tester.tap(find.text('Add and read'));
    await ready(tester);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.byTooltip(ReaderTexts.nextPage));
    await ready(tester);
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip(ReaderTexts.close));
    await ready(tester);
    expect(find.text('Added text'), findsOneWidget);
    expect(find.textContaining('words met'), findsNothing);
    await tester.tap(find.text('Read'));
    await ready(tester);
    expect(find.text('2 / 2'), findsOneWidget);
  });

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
