@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/feature_speaking.dart';
import 'package:feature_speaking/src/call_catalog.dart';
import 'package:feature_speaking/src/call_screen.dart';
import 'package:feature_speaking/src/hablar_tab.dart';
import 'package:feature_speaking/src/motion.dart';
import 'package:feature_speaking/src/wording.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/call_rig.dart';
import 'support/scripted_call.dart';
import 'support/world.dart';

bool _nocheFontsLoaded = false;

Future<void> _loadNocheFonts() async {
  if (_nocheFontsLoaded) return;
  for (final entry in nocheFontFiles.entries) {
    for (final prefix in ['', 'packages/coqui_ui/']) {
      final loader = FontLoader('$prefix${entry.key}');
      for (final path in entry.value.values) {
        loader.addFont(
          Future.value(
            ByteData.sublistView(
              File('../../core/coqui_ui/$path').readAsBytesSync(),
            ),
          ),
        );
      }
      await loader.load();
    }
  }
  _nocheFontsLoaded = true;
}

void _seedOpenWords(RecordingProgress progress, List<String> words) {
  if (words.isEmpty) return;
  final raw = jsonDecode(progress.export()) as Map<String, dynamic>;
  final palabras = Map<String, dynamic>.from(
    (raw['palabras'] as Map?) ?? const <String, dynamic>{},
  );
  for (final w in words) {
    palabras[w] = WordRecord(
      w: w,
      primera: 1794751200000,
      oida: 4,
      ear: SkillRecord(etapa: 3, n: 2, bien: 2),
    ).toJson();
  }
  raw['palabras'] = palabras;
  progress.import(jsonEncode(raw));
}

class _MultiCallCourse extends FakeCourseCatalog implements CallsCatalog {
  _MultiCallCourse({
    required List<Place> places,
    required this.callsByPlace,
    super.language,
  }) : _customPlaces = places;

  final List<Place> _customPlaces;
  final Map<String, List<CallBrief>> callsByPlace;

  @override
  List<Place> get places => _customPlaces;

  @override
  List<CallBrief> callsFor(String placeId) =>
      callsByPlace[placeId] ?? const <CallBrief>[];

  @override
  CallBrief? callFor(String placeId) {
    final list = callsByPlace[placeId];
    if (list == null || list.isEmpty) return null;
    for (final c in list) {
      if (c.isMain) return c;
    }
    return list.first;
  }
}

class _DelegatingLanguageCourse extends FakeCourseCatalog {
  _DelegatingLanguageCourse(this._delegate, {required super.language});

  final FakeCourseCatalog _delegate;

  @override
  List<Place> get places => _delegate.places;

  @override
  CallBrief? callFor(String placeId) => _delegate.callFor(placeId);

  @override
  ReviewPair? pairFor(String word) => _delegate.pairFor(word);

  @override
  Future<Map<String, dynamic>> story(String id) => _delegate.story(id);

  @override
  List<String> get goodbyeWords => _delegate.goodbyeWords;
}

final _karimArabicLanguage = Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-EG',
  partnerName: 'Karim',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  callAgentId: 'agent_arabic_karim',
  micWords: {
    'ready': 'جاهز',
    'listening': 'أسمعك…',
    'thinking': 'لحظة…',
    'theySpeak': 'كريم',
    'right': 'ممتاز',
    'notYet': 'مرة أخرى',
  },
  tabNames: {
    'map': 'الخريطة',
    'words': 'كلمات',
    'library': 'المكتبة',
    'speak': 'تكلم',
    'me': 'أنا',
  },
  a11yWords: {
    'close': 'Close',
    'micReady': 'Ready',
    'micListening': 'Listening',
    'micThinking': 'Thinking',
    'micTheySpeak': 'Speaking',
    'micRight': 'Right',
    'micNotYet': 'Try again',
  },
);

class _MotionSpeakRig {
  _MotionSpeakRig._({
    required this.clock,
    required this.progress,
    required this.course,
    required this.nav,
    required this.haptics,
    required this.call,
    required this.entitlements,
    required this.services,
  });

  final FakeClock clock;
  final RecordingProgress progress;
  final _MultiCallCourse course;
  final FakeNavigator nav;
  final FakeHaptics haptics;
  final ScriptedCall call;
  final FakeEntitlements entitlements;
  final Services services;

  static _MotionSpeakRig spanish({
    int casaPlayed = 11,
    int parquePlayed = 12,
    int cocinaPlayed = 6,
    int openWordCount = 24,
    Plan plan = Plan.courseAndCalls,
    bool reduceMotion = false,
  }) {
    final places = [
      Place(
        id: 'casa',
        n: 1,
        name: 'La casa',
        en: "Grandma's house",
        stories: [for (var i = 1; i <= 11; i++) 'casa-$i'],
      ),
      Place(
        id: 'parque',
        n: 2,
        name: 'El parque',
        en: 'The park',
        stories: [for (var i = 1; i <= 12; i++) 'parque-$i'],
      ),
      Place(
        id: 'cocina',
        n: 3,
        name: 'La cocina',
        en: 'The kitchen',
        stories: [for (var i = 1; i <= 9; i++) 'cocina-$i'],
      ),
      Place(
        id: 'colmado',
        n: 4,
        name: 'El colmado',
        en: 'The corner shop',
        stories: [for (var i = 1; i <= 6; i++) 'colmado-$i'],
      ),
    ];

    List<CallBrief> fromCatalog(String placeId) => [
      for (final s in callsForPlace(placeId))
        CallBrief(
          id: s.id,
          placeId: placeId,
          title: s.titleEs,
          jobEn: s.jobEn,
          minutes: s.minutes,
          job: s.jobEn,
          opening: 'Hola',
          isMain: s.isMain,
        ),
    ];

    final course = _MultiCallCourse(
      places: places,
      callsByPlace: {for (final p in places) p.id: fromCatalog(p.id)},
      language: Language.spanish,
    );
    final clock = FakeClock();
    final progress = RecordingProgress(clock: clock);
    for (var i = 1; i <= casaPlayed; i++) {
      progress.storyFinished(StoryResult(id: 'casa-$i'));
    }
    for (var i = 1; i <= parquePlayed; i++) {
      progress.storyFinished(StoryResult(id: 'parque-$i'));
    }
    for (var i = 1; i <= cocinaPlayed; i++) {
      progress.storyFinished(StoryResult(id: 'cocina-$i'));
    }
    const sampleWords = ['agua', 'café', 'mesa', 'pan', 'hola', 'gracias'];
    _seedOpenWords(progress, [
      for (var i = 0; i < openWordCount; i++)
        i < sampleWords.length ? sampleWords[i] : 'word$i',
    ]);

    final nav = FakeNavigator();
    final haptics = FakeHaptics();
    final call = ScriptedCall(stub: const {'manual'});
    final entitlements = FakeEntitlements(plan: plan);
    final services = fakeServices(
      progress: progress,
      course: course,
      nav: nav,
      haptics: haptics,
      call: call,
      clock: clock,
      entitlements: entitlements,
      reduceMotion: reduceMotion,
    );
    return _MotionSpeakRig._(
      clock: clock,
      progress: progress,
      course: course,
      nav: nav,
      haptics: haptics,
      call: call,
      entitlements: entitlements,
      services: services,
    );
  }

  static _MotionSpeakRig arabic({
    Language? language,
    Plan plan = Plan.courseAndCalls,
    bool reduceMotion = false,
  }) {
    final resolvedLanguage = language ?? _karimArabicLanguage;
    final places = [
      Place(
        id: 'casa',
        n: 1,
        name: 'البيت',
        en: 'The house',
        stories: [for (var i = 1; i <= 4; i++) 'a$i'],
      ),
      Place(
        id: 'cocina',
        n: 2,
        name: 'المطبخ',
        en: 'The kitchen',
        stories: [for (var i = 1; i <= 6; i++) 'b$i'],
      ),
      Place(
        id: 'souq',
        n: 3,
        name: 'السوق',
        en: 'The market',
        stories: [for (var i = 1; i <= 4; i++) 's$i'],
      ),
    ];
    final callsByPlace = <String, List<CallBrief>>{
      'casa': [
        CallBrief(
          id: 'casa_main',
          placeId: 'casa',
          title: 'في البيت',
          jobEn: 'Greet ${resolvedLanguage.partnerName}.',
          minutes: 5,
          agentId: resolvedLanguage.callAgentId,
          opening: 'مرحباً!',
          job: 'Greet ${resolvedLanguage.partnerName}.',
          isMain: true,
        ),
      ],
      'cocina': [
        CallBrief(
          id: 'cocina_tomar',
          placeId: 'cocina',
          title: 'ماذا تريد أن تشرب؟',
          jobEn: 'Say what you want to drink.',
          minutes: 2,
          agentId: resolvedLanguage.callAgentId,
          opening: 'ماذا تريد أن تشرب؟',
          job: 'Say what you want to drink.',
          isMain: false,
        ),
        CallBrief(
          id: 'cocina_main',
          placeId: 'cocina',
          title: 'أنا جائع',
          jobEn: 'Say you are hungry.',
          minutes: 5,
          agentId: resolvedLanguage.callAgentId,
          opening: 'هل أنت جائع؟',
          job: 'Say you are hungry.',
          isMain: true,
        ),
      ],
      'souq': [
        CallBrief(
          id: 'souq_main',
          placeId: 'souq',
          title: 'في السوق',
          jobEn: 'Chat at the market.',
          minutes: 5,
          agentId: resolvedLanguage.callAgentId,
          opening: 'أهلاً في السوق.',
          job: 'Chat at the market.',
          isMain: true,
        ),
      ],
    };

    final course = _MultiCallCourse(
      places: places,
      callsByPlace: callsByPlace,
      language: resolvedLanguage,
    );
    final clock = FakeClock();
    final progress = RecordingProgress(clock: clock);
    for (var i = 1; i <= 4; i++) {
      progress.storyFinished(StoryResult(id: 'a$i'));
    }
    for (var i = 1; i <= 3; i++) {
      progress.storyFinished(StoryResult(id: 'b$i'));
    }
    _seedOpenWords(progress, const ['ماء', 'قهوة', 'خبز']);

    final nav = FakeNavigator();
    final haptics = FakeHaptics();
    final call = ScriptedCall(stub: const {'manual'});
    final entitlements = FakeEntitlements(plan: plan);
    final services = fakeServices(
      progress: progress,
      course: course,
      nav: nav,
      haptics: haptics,
      call: call,
      clock: clock,
      entitlements: entitlements,
      reduceMotion: reduceMotion,
    );
    return _MotionSpeakRig._(
      clock: clock,
      progress: progress,
      course: course,
      nav: nav,
      haptics: haptics,
      call: call,
      entitlements: entitlements,
      services: services,
    );
  }

  Widget screen({bool disableAnimations = false}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: coquiTheme(),
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        disableAnimations: disableAnimations,
      ),
      child: Scaffold(
        body: HablarTab(services: services, shortCallsEnabled: true),
      ),
    ),
  );

  void dispose() {
    call.dispose();
    entitlements.dispose();
  }
}

class _ArabicCallWorld {
  _ArabicCallWorld._({
    required this.clock,
    required this.progress,
    required this.course,
    required this.call,
    required this.nav,
    required this.services,
  });

  final FakeClock clock;
  final RecordingProgress progress;
  final FakeCourseCatalog course;
  final ScriptedCall call;
  final FakeNavigator nav;
  final Services services;

  static Future<_ArabicCallWorld> create({
    Language? overrideLanguage,
    bool reduceMotion = false,
  }) async {
    final clock = FakeClock();
    final progress = RecordingProgress(clock: clock);
    final base = FakeCourseCatalog.arabic();
    await base.load();
    final course = overrideLanguage == null
        ? base
        : _DelegatingLanguageCourse(base, language: overrideLanguage);
    for (final id in course.places.first.stories) {
      progress.storyFinished(StoryResult(id: id));
    }
    final call = ScriptedCall(stub: const {'manual'});
    final nav = FakeNavigator();
    final services = fakeServices(
      progress: progress,
      course: course,
      call: call,
      nav: nav,
      clock: clock,
      reduceMotion: reduceMotion,
    );
    return _ArabicCallWorld._(
      clock: clock,
      progress: progress,
      course: course,
      call: call,
      nav: nav,
      services: services,
    );
  }

  Future<void> elapse(WidgetTester tester, int ms, {int step = 50}) async {
    var rem = ms;
    while (rem > 0) {
      final d = rem < step ? rem : step;
      clock.advance(Duration(milliseconds: d));
      await tester.pump(Duration(milliseconds: d));
      rem -= d;
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    call.dispose();
  }
}

double _translateX(WidgetTester tester, Finder finder) =>
    tester.widget<Transform>(finder).transform.storage[12];

double _translateY(WidgetTester tester, Finder finder) =>
    tester.widget<Transform>(finder).transform.storage[13];

double _opacityOfMotion(WidgetTester tester, Key motionKey) {
  final finder = find.descendant(
    of: find.byKey(motionKey),
    matching: find.byType(Opacity),
  );
  return tester.widget<Opacity>(finder.first).opacity;
}

void main() {
  setUpAll(_loadNocheFonts);

  group('N8.15 Speak tab: NochePillGroup + NocheFollow (LTR & RTL)', () {
    testWidgets(
      'switching places toward start and end slides NochePillGroup mark and NocheFollow by tab distance in Spanish LTR',
      (tester) async {
        Phone.iphone.use(tester);
        final rig = _MotionSpeakRig.spanish();
        addTearDown(rig.dispose);

        await tester.pumpWidget(rig.screen());
        await tester.pumpAndSettle();

        expect(find.byType(NochePillGroup<String>), findsOneWidget);
        expect(find.byKey(const Key('speak-place-follow')), findsOneWidget);

        // Selected default is La cocina (index 2). Switch toward start -> La casa (index 0).
        await tester.tap(find.byKey(const Key('speak-place-casa')));
        await tester.pump();
        final followIncoming = find.descendant(
          of: find.byKey(const Key('speak-place-follow')),
          matching: find.byKey(const ValueKey('noche_follow_incoming')),
        );
        // Start of transition: dx = -tab (-16) in LTR when going toward start.
        expect(
          _translateX(tester, followIncoming),
          closeTo(-NocheMotion.tab, 0.01),
        );

        // Middle: followAfter (60) + move ~/ 2 (110) = 170 ms.
        await tester.pump(NocheMotion.followAfter + NocheMotion.move ~/ 2);
        final midStartDx = _translateX(tester, followIncoming);
        expect(midStartDx, lessThan(0));
        expect(midStartDx, greaterThan(-NocheMotion.tab));

        // End: settled at dx == 0.
        await tester.pumpAndSettle();
        expect(_translateX(tester, followIncoming), closeTo(0, 0.001));
        expect(find.text('Un vaso de agua'), findsOneWidget);

        // Switch toward end -> La cocina (index 2).
        await tester.tap(find.byKey(const Key('speak-place-cocina')));
        await tester.pump();
        expect(
          _translateX(tester, followIncoming),
          closeTo(NocheMotion.tab, 0.01),
        );

        await tester.pump(NocheMotion.followAfter + NocheMotion.move ~/ 2);
        final midEndDx = _translateX(tester, followIncoming);
        expect(midEndDx, greaterThan(0));
        expect(midEndDx, lessThan(NocheMotion.tab));

        await tester.pumpAndSettle();
        expect(_translateX(tester, followIncoming), closeTo(0, 0.001));
        expect(find.text('¿Qué quieres tomar?'), findsOneWidget);
      },
    );

    testWidgets(
      'Arabic RTL mirrors NocheFollow slide direction and keeps numbers wrapped in NocheLtr',
      (tester) async {
        Phone.iphone.use(tester);
        final rig = _MotionSpeakRig.arabic();
        addTearDown(rig.dispose);

        await tester.pumpWidget(rig.screen());
        await tester.pumpAndSettle();

        // Header count wrapped in NocheLtr.
        final wordsText = find.text(SpeakWording.wordsReadyToSay(3));
        expect(wordsText, findsOneWidget);
        expect(
          find.ancestor(of: wordsText, matching: find.byType(NocheLtr)),
          findsOneWidget,
        );

        // Default selected is المطبخ (index 1). Switch toward start -> البيت (index 0).
        // In RTL, side=start enters from visual right (+tab).
        await tester.tap(find.byKey(const Key('speak-place-casa')));
        await tester.pump();
        final followIncoming = find.descendant(
          of: find.byKey(const Key('speak-place-follow')),
          matching: find.byKey(const ValueKey('noche_follow_incoming')),
        );
        expect(
          _translateX(tester, followIncoming),
          closeTo(NocheMotion.tab, 0.01),
        );

        await tester.pump(NocheMotion.followAfter + NocheMotion.move ~/ 2);
        expect(_translateX(tester, followIncoming), greaterThan(0));
        expect(_translateX(tester, followIncoming), lessThan(NocheMotion.tab));

        await tester.pumpAndSettle();
        expect(_translateX(tester, followIncoming), closeTo(0, 0.001));

        // Switch toward end -> المطبخ (index 1): in RTL enters from visual left (-tab).
        await tester.tap(find.byKey(const Key('speak-place-cocina')));
        await tester.pump();
        expect(
          _translateX(tester, followIncoming),
          closeTo(-NocheMotion.tab, 0.01),
        );

        await tester.pump(NocheMotion.followAfter + NocheMotion.move ~/ 2);
        expect(_translateX(tester, followIncoming), lessThan(0));
        expect(
          _translateX(tester, followIncoming),
          greaterThan(-NocheMotion.tab),
        );

        await tester.pumpAndSettle();
        expect(_translateX(tester, followIncoming), closeTo(0, 0.001));
      },
    );
  });

  group('N8.15 Speak tab: progress-locked taps (NocheQuietLock)', () {
    testWidgets(
      'tapping locked place pill shows "After La cocina" for lockHold without haptics, nav, or place switch',
      (tester) async {
        Phone.iphone.use(tester);
        final semantics = tester.ensureSemantics();
        final rig = _MotionSpeakRig.spanish();
        addTearDown(rig.dispose);

        await tester.pumpWidget(rig.screen());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('speak-locked-place-hint')), findsNothing);
        final lockedPill = find.byKey(const Key('speak-locked-place-pill'));
        expect(lockedPill, findsOneWidget);
        expect(tester.getSize(lockedPill), const Size(48, 48));

        await tester.tap(lockedPill);
        await tester.pump();

        // No haptics, no nav, place stays La cocina.
        expect(rig.haptics.ticks, 0);
        expect(rig.nav.routes, isEmpty);
        expect(find.text('¿Qué quieres tomar?'), findsOneWidget);

        // During press -> lockHold: hint is visible with "After La cocina", height 40.
        await tester.pump(NocheMotion.press);
        final hintFinder = find.byKey(const Key('speak-locked-place-hint'));
        expect(hintFinder, findsOneWidget);
        expect(tester.getSize(hintFinder).height, 40);
        expect(
          find.bySemanticsLabel(SpeakWording.afterPlace('La cocina')),
          findsOneWidget,
        );
        expect(
          _opacityOfMotion(
            tester,
            const ValueKey('speak-locked-place-hint-motion'),
          ),
          closeTo(1.0, 0.01),
        );
        expect(
          _translateY(
            tester,
            find.byKey(const ValueKey('speak-locked-place-hint-motion')),
          ),
          closeTo(0.0, 0.01),
        );

        // Still held partway through lockHold.
        await tester.pump(NocheMotion.lockHold ~/ 2);
        expect(hintFinder, findsOneWidget);
        expect(
          _opacityOfMotion(
            tester,
            const ValueKey('speak-locked-place-hint-motion'),
          ),
          closeTo(1.0, 0.01),
        );

        // Gone after press + lockHold + move.
        await tester.pump(
          NocheMotion.lockHold ~/ 2 +
              NocheMotion.move +
              const Duration(milliseconds: 20),
        );
        await tester.pump();
        expect(hintFinder, findsNothing);
        semantics.dispose();
      },
    );

    testWidgets(
      'tapping progress-locked other call card lights reason text label -> text for lockHold and returns in move without nav',
      (tester) async {
        Phone.iphone.use(tester);
        final rig = _MotionSpeakRig.spanish();
        addTearDown(rig.dispose);

        await tester.pumpWidget(rig.screen());
        await tester.pumpAndSettle();

        final lockedCard = find.byKey(
          const Key('speak-other-call-cocina_main'),
        );
        expect(lockedCard, findsOneWidget);
        expect(tester.widget(lockedCard), isA<NocheQuietLock>());

        final metaFinder = find.descendant(
          of: lockedCard,
          matching: find.text(SpeakWording.cardMetaAfterStory(5, 9)),
        );
        expect(metaFinder, findsOneWidget);
        expect(
          find.ancestor(of: metaFinder, matching: find.byType(NocheLtr)),
          findsOneWidget,
        );
        expect(tester.widget<Text>(metaFinder).style?.color, NocheColors.label);

        await tester.tap(lockedCard);
        await tester.pump();
        await tester.pump(NocheMotion.press);

        // Held at bright NocheColors.text during lockHold.
        expect(tester.widget<Text>(metaFinder).style?.color, NocheColors.text);
        expect(rig.nav.routes, isEmpty);
        expect(rig.call.starts, 0);

        // Returns gently to NocheColors.label after lockHold + move.
        await tester.pump(
          NocheMotion.lockHold +
              NocheMotion.move +
              const Duration(milliseconds: 20),
        );
        await tester.pump();
        expect(tester.widget<Text>(metaFinder).style?.color, NocheColors.label);
      },
    );
  });

  group('N8.15 Plan.course no-calls guard (#97 N3.3)', () {
    testWidgets(
      'Plan.course keeps speak-plan-card, hides disc, keeps tierLocked as NocheCard.standard, and blocks CallRoute',
      (tester) async {
        Phone.iphone.use(tester);
        final rig = _MotionSpeakRig.spanish(plan: Plan.course);
        addTearDown(rig.dispose);

        await tester.pumpWidget(rig.screen());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('speak-plan-card')), findsOneWidget);
        expect(find.byKey(const Key('speak-call-disc')), findsNothing);
        expect(find.byType(Hero), findsNothing);

        // tierLocked card stays NocheCard(standard), NOT NocheQuietLock.
        final tierCard = find.byKey(const Key('speak-other-call-cocina_comer'));
        expect(tester.widget(tierCard), isA<NocheCard>());
        expect(
          tester.widget<NocheCard>(tierCard).variant,
          NocheCardVariant.standard,
        );
        expect(tester.widget<NocheCard>(tierCard).onPressed, isNull);

        // Progress-locked card is NocheQuietLock.
        final progressCard = find.byKey(
          const Key('speak-other-call-cocina_main'),
        );
        expect(tester.widget(progressCard), isA<NocheQuietLock>());

        // Tapping locked place pill, progress-locked card, and tierLocked card opens no route & starts no call.
        await tester.tap(find.byKey(const Key('speak-locked-place-pill')));
        await tester.pump();
        await tester.tap(progressCard);
        await tester.pump();
        await tester.tap(tierCard);
        await tester.pump();
        expect(rig.nav.routes, isEmpty);
        expect(rig.call.starts, 0);

        // Module route guard returns null under Plan.course.
        expect(
          const SpeakingModule().screenFor(
            const CallRoute('cocina'),
            rig.services,
          ),
          isNull,
        );
      },
    );
  });

  group('N8.15 Call disc Hero + Speak quick fade via buildNocheCallRoute', () {
    testWidgets(
      'pushing CallScreen fades HablarTab in quick while Hero disc flies to CallScreen NocheMic',
      (tester) async {
        Phone.iphone.use(tester);
        final w = await World.create(seed: 'todo', stub: const {'manual'});
        final navigatorKey = GlobalKey<NavigatorState>();
        final heroController = HeroController();
        addTearDown(heroController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: coquiTheme(),
            home: Scaffold(
              body: Builder(
                builder: (navContext) => Navigator(
                  key: navigatorKey,
                  observers: [heroController],
                  onGenerateRoute: (_) => buildNocheCallRoute<void>(
                    context: navContext,
                    builder: (_) => HablarTab(services: w.services),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('speak-outgoing-opacity')),
              )
              .opacity,
          closeTo(1.0, 0.001),
        );

        // Push CallScreen via buildNocheCallRoute.
        navigatorKey.currentState!.push<void>(
          buildNocheCallRoute<void>(
            context: navigatorKey.currentContext!,
            builder: (_) => CallScreen(services: w.services, placeId: 'casa'),
          ),
        );
        // Frame 0 mounts route and starts ticker; pump(quick ~/ 2) advances 70 ms.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(NocheMotion.quick ~/ 2);
        final midOpacity = tester
            .widget<Opacity>(
              find.byKey(const ValueKey('speak-outgoing-opacity')),
            )
            .opacity;
        expect(midOpacity, greaterThan(0.0));
        expect(midOpacity, lessThan(1.0));
        expect(tester.takeException(), isNull);

        // After quick (160 ms): Speak outgoing opacity has reached 0 while route finishes pageIn.
        await tester.pump(const Duration(milliseconds: 90));
        final afterQuickOpacity = tester
            .widget<Opacity>(
              find.byKey(const ValueKey('speak-outgoing-opacity')),
            )
            .opacity;
        expect(afterQuickOpacity, closeTo(0.0, 0.01));

        // Finish route transition + CallScreen entrance.
        await tester.pump(
          NocheMotion.pageIn + const Duration(milliseconds: 200),
        );
        expect(find.byKey(const Key('call-screen')), findsOneWidget);
        expect(find.byKey(const Key('call-mic-stage')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await w.close(tester);
      },
    );
  });

  group('N8.15 CallScreen arrivals, in-call motion, Call done, Error, Help', () {
    testWidgets(
      'chrome fades after 200 ms, picture rises after 160 ms, show_picture swaps without zoom, ringing says Calling Danny, and partner/heard/note lines rise',
      (tester) async {
        Phone.iphone.use(tester);
        final w = await World.create(seed: 'todo', stub: const {'manual'});

        await tester.pumpWidget(
          w.app(CallScreen(services: w.services, placeId: 'casa')),
        );
        await tester.pump();

        // At t = 0: bar opacity is 0, picture is shifted down by row (8).
        expect(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('call-bar-opacity')))
              .opacity,
          closeTo(0.0, 0.01),
        );
        expect(
          _translateY(
            tester,
            find.byKey(const ValueKey('call-picture-motion')),
          ),
          closeTo(NocheMotion.row, 0.01),
        );

        // At t = 250 ms: picture is mid-rise (started at 160 ms), bar is mid-fade (started at 200 ms).
        await tester.pump(const Duration(milliseconds: 250));
        final midBarOpacity = tester
            .widget<Opacity>(find.byKey(const ValueKey('call-bar-opacity')))
            .opacity;
        expect(midBarOpacity, greaterThan(0.0));
        expect(midBarOpacity, lessThan(1.0));
        final midPicDy = _translateY(
          tester,
          find.byKey(const ValueKey('call-picture-motion')),
        );
        expect(midPicDy, greaterThan(0.0));
        expect(midPicDy, lessThan(NocheMotion.row));

        // At t = 450 ms: entrance completed.
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('call-bar-opacity')))
              .opacity,
          closeTo(1.0, 0.01),
        );
        expect(
          _translateY(
            tester,
            find.byKey(const ValueKey('call-picture-motion')),
          ),
          closeTo(0.0, 0.01),
        );

        // Timer wrapped in NocheLtr.
        expect(
          find.ancestor(
            of: find.text('00:00'),
            matching: find.byType(NocheLtr),
          ),
          findsOneWidget,
        );

        // Ringing: NocheMicState.thinking with "Calling Danny".
        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        expect(
          tester.widget<NocheMic>(find.byType(NocheMic)).state,
          NocheMicState.thinking,
        );
        expect(find.text(SpeakWording.callingPartner('Danny')), findsOneWidget);

        // Partner speaks: partner line rises by row in move (220 ms).
        w.call.go('connect');
        w.call.go('danny1');
        await tester.pump();
        await w.elapse(tester, 100);
        final partnerMotion = find.byKey(
          const ValueKey('call-partner-line-motion'),
        );
        final midPartnerDy = _translateY(tester, partnerMotion);
        expect(midPartnerDy, greaterThan(0.0));
        expect(midPartnerDy, lessThan(NocheMotion.row));

        await w.elapse(tester, 250);
        expect(_translateY(tester, partnerMotion), closeTo(0.0, 0.01));

        // show_picture triggers rise without zooming PictureFrame.
        w.call.emit(const Tool('show_picture', {'picture': 'puerta'}));
        await tester.pump();
        await w.elapse(tester, 100);
        final swapDy = _translateY(
          tester,
          find.byKey(const ValueKey('call-picture-motion')),
        );
        expect(swapDy, greaterThan(0.0));
        expect(swapDy, lessThan(NocheMotion.row));
        for (final t in tester.widgetList<Transform>(
          find.ancestor(
            of: find.byType(PictureFrame),
            matching: find.byType(Transform),
          ),
        )) {
          expect(t.transform.storage[0], closeTo(1.0, 0.001));
          expect(t.transform.storage[5], closeTo(1.0, 0.001));
        }
        await w.elapse(tester, 250);
        expect(
          _translateY(
            tester,
            find.byKey(const ValueKey('call-picture-motion')),
          ),
          closeTo(0.0, 0.01),
        );

        // Help tap shows rising help note.
        await tester.tap(find.text('Help'));
        await tester.pump();
        await w.elapse(tester, 100);
        final noteMotion = find.byKey(const ValueKey('call-note-motion'));
        expect(_translateY(tester, noteMotion), greaterThan(0.0));
        await w.elapse(tester, 250);
        expect(_translateY(tester, noteMotion), closeTo(0.0, 0.01));

        // Your turn -> heard line rises in NocheColors.right.
        w.call.go('you1');
        await w.elapse(tester, 200);
        w.call.emit(const Heard('Hola, puerta'));
        await tester.pump();
        await w.elapse(tester, 100);
        final heardMotion = find.byKey(
          const ValueKey('call-heard-line-motion'),
        );
        expect(_translateY(tester, heardMotion), greaterThan(0.0));
        expect(
          tester.widget<Text>(find.text('Hola, puerta')).style?.color,
          NocheColors.right,
        );
        await w.elapse(tester, 250);
        expect(_translateY(tester, heardMotion), closeTo(0.0, 0.01));

        await w.close(tester);
      },
    );

    testWidgets(
      'hanging up fades live call in quick, staggers first 5 40-high word pills only (pills 5 & 6 share pill 4), and lands Back button last',
      (tester) async {
        Phone.iphone.use(tester);
        final w = await World.create(seed: 'todo', stub: const {'manual'});

        await tester.pumpWidget(
          w.app(CallScreen(services: w.services, placeId: 'casa')),
        );
        await tester.pump(const Duration(milliseconds: 450));

        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        w.call.go('connect');
        await w.elapse(tester, 200);
        w.call.go('danny1');
        await w.elapse(tester, 300);
        w.call.go('you1');
        await w.elapse(tester, 200);

        // Speak 7 known La casa words so we exercise indices 0..6 (cap at index 4).
        w.call.emit(const Heard('hola gracias bien casa puerta silla agua'));
        await w.elapse(tester, 100);

        // Hang up via close X.
        await tester.tap(find.byKey(const Key('call-close')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        // Outgoing live call fades out in quick (140 ms).
        await tester.pump(const Duration(milliseconds: 70));
        final exitFade = find.byKey(const ValueKey('call-exit-fade'));
        expect(exitFade, findsOneWidget);
        final exitOpacity = tester.widget<Opacity>(exitFade).opacity;
        expect(exitOpacity, greaterThan(0.0));
        expect(exitOpacity, lessThan(1.0));

        // At t = 351 ms (doneStartAfter 160 + 191): outgoing fade is done;
        // pills 0..4 are strictly ordered (starts 220, 250, 280, 310, 340 ms),
        // pills 5 & 6 share pill 4's progress, and Back button (starts 420 ms) is still at 0!
        await tester.pump(const Duration(milliseconds: 280));
        expect(find.byKey(const ValueKey('call-exit-fade')), findsNothing);

        final p0 = _opacityOfMotion(
          tester,
          const ValueKey('call-done-word-motion-0'),
        );
        final p1 = _opacityOfMotion(
          tester,
          const ValueKey('call-done-word-motion-1'),
        );
        final p2 = _opacityOfMotion(
          tester,
          const ValueKey('call-done-word-motion-2'),
        );
        final p3 = _opacityOfMotion(
          tester,
          const ValueKey('call-done-word-motion-3'),
        );
        final p4 = _opacityOfMotion(
          tester,
          const ValueKey('call-done-word-motion-4'),
        );
        final p5 = _opacityOfMotion(
          tester,
          const ValueKey('call-done-word-motion-5'),
        );
        final p6 = _opacityOfMotion(
          tester,
          const ValueKey('call-done-word-motion-6'),
        );
        final pBack = _opacityOfMotion(
          tester,
          const ValueKey('call-done-back-motion'),
        );

        expect(p0, greaterThan(p1));
        expect(p1, greaterThan(p2));
        expect(p2, greaterThan(p3));
        expect(p3, greaterThan(p4));
        expect(p4, greaterThan(0.0));
        expect(p5, closeTo(p4, 0.001));
        expect(p6, closeTo(p4, 0.001));
        expect(pBack, closeTo(0.0, 0.001));

        // Finish summary arrival (total 420 + 220 = 640 ms).
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          _opacityOfMotion(tester, const ValueKey('call-done-title-motion')),
          closeTo(1.0, 0.001),
        );
        expect(
          _opacityOfMotion(tester, const ValueKey('call-done-back-motion')),
          closeTo(1.0, 0.001),
        );
        expect(
          find.ancestor(
            of: find.text('1 min · 7 words said'),
            matching: find.byType(NocheLtr),
          ),
          findsOneWidget,
        );
        for (var i = 0; i < 7; i++) {
          final pill = find.byKey(ValueKey('call-done-word-$i'));
          expect(pill, findsOneWidget);
          expect(tester.getSize(pill).height, 40);
          final dec =
              tester.widget<Container>(pill).decoration! as BoxDecoration;
          expect((dec.border! as Border).top.color, NocheColors.lessonBorder);
          expect(dec.borderRadius, BorderRadius.circular(20));
        }

        await w.close(tester);
      },
    );

    testWidgets(
      'error screen arrives calmly after doneStartAfter with row rise',
      (tester) async {
        Phone.iphone.use(tester);
        final w = await World.create(seed: 'todo', stub: const {'mic'});

        await tester.pumpWidget(
          w.app(CallScreen(services: w.services, placeId: 'casa')),
        );
        await tester.pump(const Duration(milliseconds: 450));

        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        // Wait for mic refusal event to enter CallState.err.
        for (var i = 0; i < 20; i++) {
          await w.elapse(tester, 50);
          if (find
              .byKey(const ValueKey('call-error-motion'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
        }
        final errMotion = find.byKey(const ValueKey('call-error-motion'));
        expect(errMotion, findsOneWidget);
        // Before doneStartAfter completes, dy > 0; after 500 ms, settled at dy == 0, opacity == 1.
        expect(_translateY(tester, errMotion), greaterThan(0.0));

        await w.elapse(tester, 500);
        expect(_translateY(tester, errMotion), closeTo(0.0, 0.01));
        expect(
          _opacityOfMotion(tester, const ValueKey('call-error-motion')),
          closeTo(1.0, 0.01),
        );

        await w.close(tester);
      },
    );
  });

  group('N8.15 Reduced motion (disableAnimations: true)', () {
    testWidgets(
      'HablarTab and CallScreen keep dx == 0, dy == 0, disable Hero, and arrive Call done together in quick',
      (tester) async {
        Phone.iphone.use(tester);

        // 1. HablarTab under reduced motion: no Hero, dx == 0 on follow, dy == 0 on lock hint.
        final rig = _MotionSpeakRig.spanish();
        addTearDown(rig.dispose);
        await tester.pumpWidget(rig.screen(disableAnimations: true));
        await tester.pumpAndSettle();

        expect(find.byType(Hero), findsNothing);

        await tester.tap(find.byKey(const Key('speak-place-casa')));
        await tester.pump();
        final followIncoming = find.descendant(
          of: find.byKey(const Key('speak-place-follow')),
          matching: find.byKey(const ValueKey('noche_follow_incoming')),
        );
        expect(_translateX(tester, followIncoming), closeTo(0.0, 0.001));
        await tester.pump(NocheMotion.followAfter + NocheMotion.quick ~/ 2);
        expect(_translateX(tester, followIncoming), closeTo(0.0, 0.001));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('speak-locked-place-pill')));
        await tester.pump();
        await tester.pump(NocheMotion.quick ~/ 2);
        expect(
          _translateY(
            tester,
            find.byKey(const ValueKey('speak-locked-place-hint-motion')),
          ),
          closeTo(0.0, 0.001),
        );

        // 2. CallScreen under reduced motion: dy == 0 on picture, lines, and summary arrives together.
        final w = await World.create(
          seed: 'todo',
          stub: const {'manual'},
          reduceMotion: true,
        );
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: w.app(CallScreen(services: w.services, placeId: 'casa')),
          ),
        );
        await tester.pump();
        expect(find.byType(Hero), findsNothing);
        expect(
          _translateY(
            tester,
            find.byKey(const ValueKey('call-picture-motion')),
          ),
          closeTo(0.0, 0.001),
        );
        await tester.pump(const Duration(milliseconds: 400));

        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        w.call.go('connect');
        await w.elapse(tester, 100);
        w.call.go('danny1');
        await w.elapse(tester, 50);
        expect(
          _translateY(
            tester,
            find.byKey(const ValueKey('call-partner-line-motion')),
          ),
          closeTo(0.0, 0.001),
        );
        w.call.go('you1');
        await w.elapse(tester, 100);
        w.call.emit(const Heard('hola gracias bien casa puerta silla agua'));
        await w.elapse(tester, 100);

        await tester.tap(find.byKey(const Key('call-close')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        // Mid-quick after doneStartAfter (160 + 70 = 230 ms): title, summary, pills, and back button share identical opacity with dy == 0.
        await tester.pump(const Duration(milliseconds: 230));
        final titleOp = _opacityOfMotion(
          tester,
          const ValueKey('call-done-title-motion'),
        );
        final summaryOp = _opacityOfMotion(
          tester,
          const ValueKey('call-done-summary-motion'),
        );
        final word0Op = _opacityOfMotion(
          tester,
          const ValueKey('call-done-word-motion-0'),
        );
        final word4Op = _opacityOfMotion(
          tester,
          const ValueKey('call-done-word-motion-4'),
        );
        final backOp = _opacityOfMotion(
          tester,
          const ValueKey('call-done-back-motion'),
        );
        expect(titleOp, greaterThan(0.0));
        expect(titleOp, lessThan(1.0));
        expect(summaryOp, closeTo(titleOp, 0.001));
        expect(word0Op, closeTo(titleOp, 0.001));
        expect(word4Op, closeTo(titleOp, 0.001));
        expect(backOp, closeTo(titleOp, 0.001));
        expect(
          _translateY(
            tester,
            find.byKey(const ValueKey('call-done-back-motion')),
          ),
          closeTo(0.0, 0.001),
        );

        await w.close(tester);
      },
    );
  });

  group('N8.15 Arabic RTL CallScreen checks', () {
    testWidgets(
      'CallScreen shows Calling Karim / Calling Tariq, Arabic micWords, and RTL Call done with NocheLtr summary line',
      (tester) async {
        Phone.iphone.use(tester);

        // Verify custom Arabic partner Karim -> "Calling Karim".
        final karimWorld = await _ArabicCallWorld.create(
          overrideLanguage: _karimArabicLanguage,
        );
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: coquiTheme(),
            home: Scaffold(
              body: CallScreen(services: karimWorld.services, placeId: 'casa'),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 450));
        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        expect(find.text(SpeakWording.callingPartner('Karim')), findsOneWidget);
        await karimWorld.close(tester);

        // Verify FakeCourseCatalog.arabic() (Tariq): ringing, Arabic micWords, RTL Call done.
        final w = await _ArabicCallWorld.create();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: coquiTheme(),
            home: Scaffold(
              body: CallScreen(services: w.services, placeId: 'casa'),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 450));

        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        expect(
          find.text(SpeakWording.callingPartner(w.course.language.partnerName)),
          findsOneWidget,
        );

        w.call.go('connect');
        await w.elapse(tester, 200);
        expect(
          find.text(w.course.language.micWords['theySpeak']!),
          findsOneWidget,
        );

        w.call.emit(const Mode('listening'));
        await w.elapse(tester, 150);
        expect(
          find.text(w.course.language.micWords['listening']!),
          findsOneWidget,
        );

        w.call.emit(const Heard('مرحباً! هذا باب و بيت.'));
        await w.elapse(tester, 100);

        await tester.tap(find.byKey(const Key('call-close')));
        await w.elapse(tester, 700);

        expect(find.text('Call done'), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('1 min · 3 words said'),
            matching: find.byType(NocheLtr),
          ),
          findsOneWidget,
        );
        expect(find.text('Back to تكلم'), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          expect(
            tester.getSize(find.byKey(ValueKey('call-done-word-$i'))).height,
            40,
          );
        }

        await w.close(tester);
      },
    );
  });

  if (Platform.environment['COQUI_CAPTURE_SHOTS'] == '1') {
    testWidgets('capture N8.15 CallScreen screenshots at 390x844 and 412x915', (
      tester,
    ) async {
      await _loadNocheFonts();
      final dir = Directory('test/screenshots')..createSync(recursive: true);

      const sizes = [
        (tag: '390x844', size: Size(390, 844), dpr: 3.0),
        (tag: '412x915', size: Size(412, 915), dpr: 2.625),
      ];

      Future<void> snapBoundary(
        GlobalKey boundaryKey,
        String filename,
        double dpr,
      ) async {
        final bytes = await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: dpr);
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          image.dispose();
          return byteData!.buffer.asUint8List();
        });
        File('${dir.path}/$filename').writeAsBytesSync(bytes!);
      }

      for (final screen in sizes) {
        tester.view.devicePixelRatio = screen.dpr;
        tester.view.physicalSize = screen.size * screen.dpr;
        addTearDown(tester.view.reset);

        // Spanish live states + Call done
        final w = await World.create(seed: 'todo', stub: const {'manual'});
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: w.app(CallScreen(services: w.services, placeId: 'casa')),
          ),
        );
        await tester.pump(const Duration(milliseconds: 450));

        // 1. Ringing
        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await snapBoundary(
          boundaryKey,
          'call_ringing_${screen.tag}.png',
          screen.dpr,
        );

        // 2. They speak (Danny)
        w.call.go('connect');
        w.call.go('danny1');
        await w.elapse(tester, 450);
        await snapBoundary(
          boundaryKey,
          'call_they_speak_${screen.tag}.png',
          screen.dpr,
        );

        // 3. Listening (Your turn)
        w.call.go('you1');
        await w.elapse(tester, 250);
        w.call.go('talk1');
        await w.elapse(tester, 350);
        await snapBoundary(
          boundaryKey,
          'call_listening_${screen.tag}.png',
          screen.dpr,
        );

        // 4. Thinking (One moment)
        w.call.emit(const Heard('Hola. Bien, gracias.'));
        await w.elapse(tester, 500);
        w.call.go('quiet1');
        await w.elapse(tester, 800);
        await snapBoundary(
          boundaryKey,
          'call_thinking_${screen.tag}.png',
          screen.dpr,
        );

        // 5. Call done (Spanish, 7 words)
        w.call.emit(const Heard('hola gracias bien casa puerta silla agua'));
        await w.elapse(tester, 100);
        await tester.tap(find.byKey(const Key('call-close')));
        await w.elapse(tester, 750);
        await snapBoundary(
          boundaryKey,
          'call_done_${screen.tag}.png',
          screen.dpr,
        );
        await w.close(tester);

        // 6. Call done (Arabic RTL)
        final ar = await _ArabicCallWorld.create();
        final arKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: arKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: coquiTheme(),
              home: Scaffold(
                body: CallScreen(services: ar.services, placeId: 'casa'),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 450));
        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        ar.call.go('connect');
        await ar.elapse(tester, 200);
        ar.call.emit(const Mode('listening'));
        await ar.elapse(tester, 150);
        ar.call.emit(const Heard('مرحباً! هذا باب و بيت.'));
        await ar.elapse(tester, 100);
        await tester.tap(find.byKey(const Key('call-close')));
        await ar.elapse(tester, 750);
        await snapBoundary(
          arKey,
          'call_done_arabic_${screen.tag}.png',
          screen.dpr,
        );
        await ar.close(tester);
      }
    });
  }
}
