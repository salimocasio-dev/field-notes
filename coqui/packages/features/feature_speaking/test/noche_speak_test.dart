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
import 'package:feature_speaking/src/call_controller.dart';
import 'package:feature_speaking/src/call_screen.dart';
import 'package:feature_speaking/src/hablar_model.dart';
import 'package:feature_speaking/src/hablar_tab.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/call_rig.dart';
import 'support/scripted_call.dart';

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

/// Structured multi-call course implementing [CallsCatalog] for testing
/// N4.6 Speak with per-story call unlocks, multiple calls per place, and
/// both Spanish (LTR) and Arabic (RTL) languages.
class _StructuredCourse extends FakeCourseCatalog implements CallsCatalog {
  _StructuredCourse({
    required List<Place> places,
    required this.callsByPlace,
    super.language,
  }) : _customPlaces = places;

  final List<Place> _customPlaces;
  final Map<String, List<CallBrief>> callsByPlace;

  @override
  List<Place> get places => _customPlaces;

  @override
  List<CallBrief> callsFor(String placeId) => callsByPlace[placeId] ?? const [];

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

class _SpeakRig {
  _SpeakRig._({
    required this.course,
    required this.progress,
    required this.nav,
    required this.haptics,
    required this.call,
    required this.services,
  });

  final _StructuredCourse course;
  final RecordingProgress progress;
  final FakeNavigator nav;
  final FakeHaptics haptics;
  final ScriptedCall call;
  final Services services;

  static _SpeakRig spanish({
    int casaPlayed = 11,
    int parquePlayed = 12,
    int cocinaPlayed = 6,
    int colmadoPlayed = 0,
    bool colmadoHasStories = true,
    int openWordCount = 41,
    bool callAvailable = true,
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
        stories: colmadoHasStories
            ? [for (var i = 1; i <= 6; i++) 'colmado-$i']
            : const [],
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

    final course = _StructuredCourse(
      places: places,
      callsByPlace: {for (final p in places) p.id: fromCatalog(p.id)},
    );

    final clock = FakeClock();
    final progress = RecordingProgress(clock: clock);
    void play(Place p, int count) {
      for (final id in p.stories.take(count)) {
        progress.storyFinished(StoryResult(id: id));
      }
    }

    play(places[0], casaPlayed);
    play(places[1], parquePlayed);
    play(places[2], cocinaPlayed);
    play(places[3], colmadoPlayed);

    const previewSeed = ['quiero', 'jugo', 'agua', 'leche', 'por favor'];
    _seedOpenWords(progress, [
      for (var i = 0; i < openWordCount; i++)
        i < previewSeed.length ? previewSeed[i] : 'palabra ${i + 1}',
    ]);

    final nav = FakeNavigator();
    final haptics = FakeHaptics();
    final call = ScriptedCall(available: callAvailable);
    return _SpeakRig._(
      course: course,
      progress: progress,
      nav: nav,
      haptics: haptics,
      call: call,
      services: fakeServices(
        progress: progress,
        course: course,
        call: call,
        nav: nav,
        haptics: haptics,
        clock: clock,
      ),
    );
  }

  static _SpeakRig arabic({
    int casaPlayed = 6,
    int parquePlayed = 6,
    int cocinaPlayed = 4,
    int openWordCount = 12,
  }) {
    final places = [
      Place(
        id: 'casa',
        n: 1,
        name: 'البيت',
        en: 'The house',
        stories: [for (var i = 1; i <= 6; i++) 'ar-casa-$i'],
      ),
      Place(
        id: 'parque',
        n: 2,
        name: 'الحديقة',
        en: 'The park',
        stories: [for (var i = 1; i <= 6; i++) 'ar-parque-$i'],
      ),
      Place(
        id: 'cocina',
        n: 3,
        name: 'المطبخ',
        en: 'The kitchen',
        stories: [for (var i = 1; i <= 6; i++) 'ar-cocina-$i'],
      ),
      Place(
        id: 'colmado',
        n: 4,
        name: 'الدكان',
        en: 'The shop',
        stories: [for (var i = 1; i <= 6; i++) 'ar-colmado-$i'],
      ),
    ];

    final callsByPlace = <String, List<CallBrief>>{
      'casa': [
        CallBrief(
          id: 'ar_casa_water',
          placeId: 'casa',
          title: 'كوب ماء',
          jobEn: 'Ask {partner} for a drink and say thanks.',
          minutes: 2,
          job: 'Ask for water',
          opening: 'مرحباً',
          isMain: false,
          agentId: arabicTestLanguage.callAgentId,
        ),
        CallBrief(
          id: 'ar_casa_main',
          placeId: 'casa',
          title: 'زيارة في البيت',
          jobEn: 'Greet {partner} and introduce yourself.',
          minutes: 5,
          job: 'Visit at home',
          opening: 'أهلاً',
          isMain: true,
          agentId: arabicTestLanguage.callAgentId,
        ),
      ],
      'parque': [
        CallBrief(
          id: 'ar_parque_dog',
          placeId: 'parque',
          title: 'انظر إلى الكلب',
          jobEn: 'Say what the dog is doing.',
          minutes: 2,
          job: 'Look at the dog',
          opening: 'مرحباً',
          isMain: false,
          agentId: arabicTestLanguage.callAgentId,
        ),
        CallBrief(
          id: 'ar_parque_main',
          placeId: 'parque',
          title: 'في الحديقة',
          jobEn: 'Describe the park with {partner}.',
          minutes: 5,
          job: 'At the park',
          opening: 'أهلاً',
          isMain: true,
          agentId: arabicTestLanguage.callAgentId,
        ),
      ],
      'cocina': [
        CallBrief(
          id: 'ar_cocina_drink',
          placeId: 'cocina',
          title: 'ماذا تريد أن تشرب؟',
          jobEn: 'Say what you want to drink.',
          minutes: 2,
          job: 'Choose a drink',
          opening: 'مرحباً',
          isMain: false,
          agentId: arabicTestLanguage.callAgentId,
        ),
        CallBrief(
          id: 'ar_cocina_eat',
          placeId: 'cocina',
          title: 'ماذا تحب أن تأكل؟',
          jobEn: 'Say which foods you like.',
          minutes: 2,
          job: 'Foods you like',
          opening: 'أهلاً',
          isMain: false,
          agentId: arabicTestLanguage.callAgentId,
        ),
        CallBrief(
          id: 'ar_cocina_main',
          placeId: 'cocina',
          title: 'أنا جائع',
          jobEn: 'Say you are hungry and what you want.',
          minutes: 5,
          job: 'Hungry in the kitchen',
          opening: 'أهلاً',
          isMain: true,
          agentId: arabicTestLanguage.callAgentId,
        ),
      ],
      'colmado': [
        CallBrief(
          id: 'ar_colmado_main',
          placeId: 'colmado',
          title: 'في الدكان',
          jobEn: 'Ask for prices and pay.',
          minutes: 5,
          job: 'At the shop',
          opening: 'أهلاً',
          isMain: true,
          agentId: arabicTestLanguage.callAgentId,
        ),
      ],
    };

    final course = _StructuredCourse(
      places: places,
      callsByPlace: callsByPlace,
      language: arabicTestLanguage,
    );

    final clock = FakeClock();
    final progress = RecordingProgress(clock: clock);
    void play(Place p, int count) {
      for (final id in p.stories.take(count)) {
        progress.storyFinished(StoryResult(id: id));
      }
    }

    play(places[0], casaPlayed);
    play(places[1], parquePlayed);
    play(places[2], cocinaPlayed);

    const arWords = [
      'أريد',
      'عصير',
      'ماء',
      'حليب',
      'من فضلك',
      'خبز',
      'بيت',
      'باب',
      'شمس',
      'قهوة',
      'شاي',
      'شكراً',
    ];
    _seedOpenWords(progress, [
      for (var i = 0; i < openWordCount; i++) arWords[i % arWords.length],
    ]);

    final nav = FakeNavigator();
    final haptics = FakeHaptics();
    final call = ScriptedCall();
    return _SpeakRig._(
      course: course,
      progress: progress,
      nav: nav,
      haptics: haptics,
      call: call,
      services: fakeServices(
        progress: progress,
        course: course,
        call: call,
        nav: nav,
        haptics: haptics,
        clock: clock,
      ),
    );
  }

  Widget screen({bool withTabBar = true, bool shortCallsEnabled = true}) {
    final lang = services.course.language;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: coquiTheme(),
      home: Scaffold(
        backgroundColor: NocheColors.ground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            HablarTab(services: services, shortCallsEnabled: shortCallsEnabled),
            if (withTabBar)
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: NocheTabBar(
                  selectedId: NocheTabs.speak,
                  tabNames: lang.tabNames,
                  script: lang.script,
                  languageCode: lang.code,
                  onTap: (_) {},
                ),
              ),
          ],
        ),
      ),
    );
  }

  void dispose() => call.dispose();
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

void main() {
  setUpAll(_loadNocheFonts);

  group('N4.6 Speak: model & unlock math', () {
    test(
      'La cocina (9 stories, 6 played) matches Noche-Hablar.dc.html state',
      () {
        final rig = _SpeakRig.spanish();
        final snap = buildHablarSnapshot(
          course: rig.course,
          progress: rig.progress,
          callsAvailable: () => true,
          shortCallsEnabled: true,
        );

        expect(snap.reachedStops.map((s) => s.place.name).toList(), [
          'La casa',
          'El parque',
          'La cocina',
        ]);
        expect(snap.nextLockedStop?.place.name, 'El colmado');
        expect(snap.defaultSelectedStop?.place.id, 'cocina');

        final cocina = snap.defaultSelectedStop!;
        expect(cocina.featuredCall?.spec.id, 'cocina_tomar');
        expect(cocina.featuredCall?.spec.titleEs, '¿Qué quieres tomar?');
        expect(cocina.featuredCall?.canStart, isTrue);

        final others = cocina.otherCalls;
        expect(others.length, 2);
        expect(others[0].spec.id, 'cocina_comer');
        expect(others[0].canStart, isTrue);
        expect(others[0].cardMetaLine, '2 min · open');
        expect(others[1].spec.id, 'cocina_main');
        expect(others[1].canStart, isFalse);
        expect(others[1].unlockAfterStory, 9);
        expect(others[1].cardMetaLine, '5 min · after story 9');

        expect(snap.openWords.length, 41);
        expect(snap.previewWords, [
          'quiero',
          'jugo',
          'agua',
          'leche',
          'por favor',
        ]);
        rig.dispose();
      },
    );

    test('all places reached leaves nextLockedStop null', () {
      final rig = _SpeakRig.spanish(
        casaPlayed: 11,
        parquePlayed: 12,
        cocinaPlayed: 9,
        colmadoPlayed: 6,
      );
      final snap = buildHablarSnapshot(
        course: rig.course,
        progress: rig.progress,
        callsAvailable: () => true,
      );
      expect(snap.reachedStops.length, 4);
      expect(snap.nextLockedStop, isNull);
      rig.dispose();
    });

    test('SpeakingModule.screenFor and CallController resolve CallRoute.callId to the exact CallBrief', () {
      final rig = _SpeakRig.spanish(cocinaPlayed: 6);
      const module = SpeakingModule();

      // Main call (callId omitted)
      final mainWidget = module.screenFor(
        const CallRoute('cocina'),
        rig.services,
      );
      expect(mainWidget, isA<CallScreen>());
      expect((mainWidget! as CallScreen).callId, isNull);
      final mainCtrl = CallController(
        session: rig.call,
        clock: FakeClock(),
        course: rig.course,
        progress: rig.progress,
        placeId: 'cocina',
      );
      expect(mainCtrl.brief?.id, 'cocina_main');
      expect(mainCtrl.brief?.minutes, 5);
      mainCtrl.dispose();

      // Specific short call (callId provided)
      final shortWidget = module.screenFor(
        const CallRoute('cocina', callId: 'cocina_tomar'),
        rig.services,
      );
      expect(shortWidget, isA<CallScreen>());
      expect((shortWidget! as CallScreen).callId, 'cocina_tomar');
      final shortCtrl = CallController(
        session: rig.call,
        clock: FakeClock(),
        course: rig.course,
        progress: rig.progress,
        placeId: 'cocina',
        callId: 'cocina_tomar',
      );
      expect(shortCtrl.brief?.id, 'cocina_tomar');
      expect(shortCtrl.brief?.title, '¿Qué quieres tomar?');
      expect(shortCtrl.brief?.minutes, 2);
      shortCtrl.dispose();

      // Unknown callId returns null instead of falling back to the main call
      expect(
        module.screenFor(
          const CallRoute('cocina', callId: 'does_not_exist'),
          rig.services,
        ),
        isNull,
      );
      rig.dispose();
    });

    test('places with zero stories stay locked after a completed place until a later place is played', () {
      final places = [
        Place(
          id: 'casa',
          n: 1,
          name: 'La casa',
          en: 'House',
          stories: const ['c1'],
        ),
        Place(
          id: 'colmado',
          n: 2,
          name: 'El colmado',
          en: 'Shop',
          stories: const [],
        ),
        Place(
          id: 'calle',
          n: 3,
          name: 'La calle',
          en: 'Street',
          stories: const ['s1'],
        ),
      ];
      final course = _StructuredCourse(places: places, callsByPlace: const {});
      final progress = RecordingProgress();
      progress.storyFinished(StoryResult(id: 'c1'));

      final beforeLater = buildHablarSnapshot(
        course: course,
        progress: progress,
        callsAvailable: () => true,
      );
      expect(beforeLater.reachedStops.map((s) => s.place.id), ['casa']);
      expect(beforeLater.nextLockedStop?.place.id, 'colmado');

      // Playing a story in a later place still reaches up to it.
      progress.storyFinished(StoryResult(id: 's1'));
      final afterLater = buildHablarSnapshot(
        course: course,
        progress: progress,
        callsAvailable: () => true,
      );
      expect(afterLater.reachedStops.map((s) => s.place.id), [
        'casa',
        'colmado',
        'calle',
      ]);
      expect(afterLater.nextLockedStop, isNull);
    });

    test('shortCallsEnabled defaults to false: smaller calls stay soon and never start until enabled', () {
      final rig = _SpeakRig.spanish(cocinaPlayed: 6);
      final snap = buildHablarSnapshot(
        course: rig.course,
        progress: rig.progress,
        callsAvailable: () => true,
      );
      final cocina = snap.stopById('cocina')!;
      for (final c in cocina.smallerCalls) {
        expect(c.state, HablarCallState.soon, reason: c.spec.id);
        expect(c.canStart, isFalse, reason: c.spec.id);
        expect(c.cardMetaLine, '2 min · coming soon');
      }
      // Main call is still gated by story 9.
      expect(cocina.mainCall!.state, HablarCallState.upcoming);
      expect(cocina.hasOpenCall, isFalse);
      // Finished places (casa, parque) still open their main calls.
      expect(snap.stopById('parque')!.mainCall!.canStart, isTrue);
      expect(snap.defaultSelectedStop?.place.id, 'parque');
      rig.dispose();
    });

    test('per-call fallback preserves backed calls even when one CallBrief has an empty title', () {
      final places = [
        Place(
          id: 'cocina',
          n: 1,
          name: 'La cocina',
          en: 'The kitchen',
          stories: const ['s1', 's2', 's3'],
        ),
      ];
      final course = _StructuredCourse(
        places: places,
        callsByPlace: {
          'cocina': [
            CallBrief(
              id: 'cocina_main',
              placeId: 'cocina',
              title: '',
              jobEn: '',
              minutes: 5,
              job: 'Main job',
              opening: 'Hola',
              isMain: true,
            ),
            CallBrief(
              id: 'cocina_tomar',
              placeId: 'cocina',
              title: '¿Qué quieres tomar?',
              jobEn: 'Say what you want to drink.',
              minutes: 2,
              job: 'Drink',
              opening: 'Hola',
              isMain: false,
            ),
          ],
        },
      );
      final progress = RecordingProgress();
      for (final id in places.first.stories) {
        progress.storyFinished(StoryResult(id: id));
      }
      final snap = buildHablarSnapshot(
        course: course,
        progress: progress,
        callsAvailable: () => true,
        shortCallsEnabled: true,
      );
      final cocina = snap.stops.single;
      expect(cocina.mainCall!.spec.titleEs, 'Tengo hambre');
      expect(cocina.mainCall!.canStart, isTrue);
      expect(cocina.smallerCalls.single.spec.id, 'cocina_tomar');
      expect(cocina.smallerCalls.single.canStart, isTrue);
    });

    test('threshold math handles 0 stories, 1 story with multiple calls, and out-of-order play', () {
      final places = [
        Place(
          id: 'casa',
          n: 1,
          name: 'La casa',
          en: 'House',
          stories: const ['a', 'b'],
        ),
        Place(
          id: 'parque',
          n: 2,
          name: 'El parque',
          en: 'Park',
          stories: const ['p1'],
        ),
        Place(
          id: 'cocina',
          n: 3,
          name: 'La cocina',
          en: 'Kitchen',
          stories: const [],
        ),
      ];
      final course = _StructuredCourse(
        places: places,
        callsByPlace: {
          'parque': [
            CallBrief(
              id: 'p_s1',
              placeId: 'parque',
              title: 'Short 1',
              jobEn: 'Job 1',
              minutes: 2,
              job: 'Job 1',
              opening: 'Hi',
              isMain: false,
            ),
            CallBrief(
              id: 'p_s2',
              placeId: 'parque',
              title: 'Short 2',
              jobEn: 'Job 2',
              minutes: 2,
              job: 'Job 2',
              opening: 'Hi',
              isMain: false,
            ),
            CallBrief(
              id: 'p_main',
              placeId: 'parque',
              title: 'Main',
              jobEn: 'Job M',
              minutes: 5,
              job: 'Job M',
              opening: 'Hi',
              isMain: true,
            ),
          ],
        },
      );
      final progress = RecordingProgress();
      // Play only parque's 1 story while casa is unfinished.
      progress.storyFinished(StoryResult(id: 'p1'));
      final snap = buildHablarSnapshot(
        course: course,
        progress: progress,
        callsAvailable: () => true,
        shortCallsEnabled: true,
      );
      // Playing p1 reaches up to parque even though casa is unfinished.
      expect(snap.reachedStops.map((s) => s.place.id), ['casa', 'parque']);
      // 1-story place: all calls clamp unlockAfterStory to 1 and open after p1.
      final parque = snap.stopById('parque')!;
      for (final c in parque.calls) {
        expect(c.unlockAfterStory, 1);
        expect(c.canStart, isTrue);
      }
      // 0-story place: unlockAfterStory is 0, calls stay upcoming.
      final cocina = snap.stops[2];
      for (final c in cocina.calls) {
        expect(c.unlockAfterStory, 0);
        expect(c.state, HablarCallState.upcoming);
      }
    });

    test('31-call CallsCatalog keeps empty/whitespace-opening calls in soon and skips callsAvailable', () {
      final places = [
        Place(
          id: 'casa',
          n: 1,
          name: 'La casa',
          en: "Grandma's house",
          stories: const ['c1', 'c2'],
        ),
        Place(
          id: 'parque',
          n: 2,
          name: 'El parque',
          en: 'The park',
          stories: const ['p1', 'p2'],
        ),
      ];

      // First test when no place has an authored opening.
      final unauthoredCourse = _StructuredCourse(
        places: places,
        callsByPlace: {
          'casa': [
            CallBrief(
              id: 'casa_agua',
              placeId: 'casa',
              title: 'Un vaso de agua',
              jobEn: 'Ask for a drink and say thanks.',
              minutes: 2,
              job: 'Ask for a drink.',
              opening: '',
              isMain: false,
            ),
            CallBrief(
              id: 'casa_main',
              placeId: 'casa',
              title: 'De visita en la casa',
              jobEn: 'Greet {partner}.',
              minutes: 5,
              job: 'Greet Danny.',
              opening: '   ',
              isMain: true,
            ),
          ],
          'parque': [
            CallBrief(
              id: 'parque_main',
              placeId: 'parque',
              title: 'El perro en el parque',
              jobEn: 'Describe the park.',
              minutes: 5,
              job: 'Describe the park.',
              opening: '',
              isMain: true,
            ),
          ],
        },
      );
      final p = RecordingProgress();
      for (final pl in places) {
        for (final id in pl.stories) {
          p.storyFinished(StoryResult(id: id));
        }
      }
      var asked = 0;
      final unauthoredSnap = buildHablarSnapshot(
        course: unauthoredCourse,
        progress: p,
        callsAvailable: () {
          asked++;
          return true;
        },
        shortCallsEnabled: true,
      );
      expect(asked, 0);
      for (final stop in unauthoredSnap.stops) {
        for (final c in stop.calls) {
          expect(c.state, HablarCallState.soon, reason: c.spec.id);
          expect(c.backedByCourse, isFalse, reason: c.spec.id);
          expect(c.canStart, isFalse, reason: c.spec.id);
        }
      }

      // Now give casa_main a live opening while smaller calls & parque remain unauthored.
      final mixedCourse = _StructuredCourse(
        places: places,
        callsByPlace: {
          'casa': [
            CallBrief(
              id: 'casa_agua',
              placeId: 'casa',
              title: 'Un vaso de agua',
              jobEn: 'Ask for a drink and say thanks.',
              minutes: 2,
              job: 'Ask for a drink.',
              opening: '',
              isMain: false,
            ),
            CallBrief(
              id: 'casa_main',
              placeId: 'casa',
              title: 'De visita en la casa',
              jobEn: 'Greet {partner}.',
              minutes: 5,
              job: 'Greet Danny.',
              opening: '¡Hola! Soy Danny. ¿Cómo estás?',
              isMain: true,
            ),
          ],
          'parque': unauthoredCourse.callsFor('parque'),
        },
      );
      final mixedSnap = buildHablarSnapshot(
        course: mixedCourse,
        progress: p,
        callsAvailable: () {
          asked++;
          return true;
        },
        shortCallsEnabled: true,
      );
      expect(asked, 1);
      final casa = mixedSnap.stopById('casa')!;
      expect(casa.smallerCalls.single.state, HablarCallState.soon);
      expect(casa.smallerCalls.single.canStart, isFalse);
      expect(casa.mainCall!.state, HablarCallState.ready);
      expect(casa.mainCall!.backedByCourse, isTrue);
      expect(
        mixedSnap.stopById('parque')!.mainCall!.state,
        HablarCallState.soon,
      );

      // SpeakingModule.screenFor also refuses unauthored calls.
      const module = SpeakingModule(shortCallsEnabled: true);
      final services = fakeServices(course: mixedCourse, progress: p);
      expect(
        module.screenFor(const CallRoute('casa'), services),
        isA<CallScreen>(),
      );
      expect(
        module.screenFor(
          const CallRoute('casa', callId: 'casa_main'),
          services,
        ),
        isA<CallScreen>(),
      );
      expect(
        module.screenFor(
          const CallRoute('casa', callId: 'casa_agua'),
          services,
        ),
        isNull,
      );
      expect(module.screenFor(const CallRoute('parque'), services), isNull);
    });

    test('non-Spanish courses never fall back to Spanish local call catalog entries', () async {
      final arabic = FakeCourseCatalog.arabic();
      await arabic.load();
      final p = RecordingProgress();
      for (final id in arabic.places.first.stories) {
        p.storyFinished(StoryResult(id: id));
      }
      final snap = buildHablarSnapshot(
        course: arabic,
        progress: p,
        callsAvailable: () => true,
        shortCallsEnabled: true,
      );
      expect(snap.stops.first.calls.length, 1);
      expect(
        snap.stops.first.calls.single.spec.titleEs,
        arabic.places.first.name,
      );
      expect(snap.stops.first.smallerCalls, isEmpty);
      for (final stop in snap.stops.skip(1)) {
        expect(stop.calls, isEmpty, reason: stop.place.id);
      }
    });
  });

  group('N4.6 Speak: UI structure, semantics, and interactions', () {
    testWidgets(
      'header shows language, Speak, singular/plural/zero word counts, and opens NocheSheet',
      (tester) async {
        tester.view.devicePixelRatio = 3.0;
        tester.view.physicalSize = const Size(390, 844) * 3.0;
        addTearDown(tester.view.reset);

        // 41 words
        final rig41 = _SpeakRig.spanish(openWordCount: 41);
        await tester.pumpWidget(rig41.screen());
        expect(find.text('SPANISH'), findsOneWidget);
        expect(find.text('Speak'), findsOneWidget);
        expect(find.text('41 words ready to say'), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('speak-words-button'))).height,
          greaterThanOrEqualTo(48),
        );

        await tester.tap(find.byKey(const Key('speak-words-button')));
        await tester.pumpAndSettle();
        expect(find.byType(NocheSheet), findsOneWidget);
        expect(find.text(HablarTexts.wordsTitle), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(NocheSheet),
            matching: find.byType(NocheChip),
          ),
          findsNWidgets(41),
        );
        await tester.tap(find.bySemanticsLabel('Close'));
        await tester.pumpAndSettle();
        rig41.dispose();

        // 1 word (singular)
        final rig1 = _SpeakRig.spanish(openWordCount: 1);
        await tester.pumpWidget(rig1.screen());
        expect(find.text('1 word ready to say'), findsOneWidget);
        rig1.dispose();

        // 0 words -> chips hidden on card, sheet shows wordsNone
        final rig0 = _SpeakRig.spanish(openWordCount: 0);
        await tester.pumpWidget(rig0.screen());
        expect(find.text('0 words ready to say'), findsOneWidget);
        expect(find.text('WORDS YOU CAN USE'), findsNothing);
        expect(find.byType(NocheChip), findsNothing);
        await tester.tap(find.byKey(const Key('speak-words-button')));
        await tester.pumpAndSettle();
        expect(find.text(HablarTexts.wordsNone), findsOneWidget);
        rig0.dispose();
      },
    );

    testWidgets(
      'place pills tablist exposes tabBar/tab roles, locked pill semantics, switching, and hides locked pill when all reached',
      (tester) async {
        tester.view.devicePixelRatio = 3.0;
        tester.view.physicalSize = const Size(390, 844) * 3.0;
        addTearDown(tester.view.reset);

        final semantics = tester.ensureSemantics();
        final rig = _SpeakRig.spanish();
        await tester.pumpWidget(rig.screen());

        final tabBarWidget = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.role == ui.SemanticsRole.tabBar &&
                w.properties.label == HablarTexts.placeTabListLabel,
          ),
        );
        expect(tabBarWidget.properties.label, 'Place');

        final tabWidgets = tester.widgetList<Semantics>(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.role == ui.SemanticsRole.tab,
          ),
        );
        // 3 reached tabs + 1 locked tab (+ 5 bottom bar tabs = 9 total, check at least 4 in place bar)
        expect(tabWidgets.length, greaterThanOrEqualTo(4));

        // Locked pill semantic label
        expect(
          find.bySemanticsLabel('El colmado, not reached yet'),
          findsOneWidget,
        );
        final lockedPill = find.byKey(const Key('speak-locked-place-pill'));
        expect(tester.getSize(lockedPill), const Size(48, 48));

        // Tapping a reached place switches the featured call card
        await tester.tap(find.text('La casa'));
        await tester.pump();
        expect(find.text('Un vaso de agua'), findsOneWidget);
        expect(rig.haptics.ticks, 1);

        // Tapping the locked pill does not switch or navigate
        await tester.tap(lockedPill);
        await tester.pump();
        expect(find.text('Un vaso de agua'), findsOneWidget);
        expect(rig.nav.routes, isEmpty);
        rig.dispose();

        // When all places are reached, no locked pill appears
        final allReached = _SpeakRig.spanish(
          casaPlayed: 11,
          parquePlayed: 12,
          cocinaPlayed: 9,
          colmadoPlayed: 6,
        );
        await tester.pumpWidget(allReached.screen());
        expect(find.byKey(const Key('speak-locked-place-pill')), findsNothing);
        allReached.dispose();
        semantics.dispose();
      },
    );

    testWidgets(
      'next-call card styles, other-call 88 px cards, and CallRoute navigation',
      (tester) async {
        tester.view.devicePixelRatio = 3.0;
        tester.view.physicalSize = const Size(390, 844) * 3.0;
        addTearDown(tester.view.reset);

        final rig = _SpeakRig.spanish();
        await tester.pumpWidget(rig.screen());

        // Eyebrow in NocheColors.next when open
        final eyebrow = tester.widget<Text>(
          find.text('NEXT CALL WITH DANNY · 2 MIN'),
        );
        expect(eyebrow.style?.color, NocheColors.next);

        // Call title 32/36 with Locale('es')
        final title = tester.widget<Text>(find.text('¿Qué quieres tomar?'));
        expect(title.locale, const Locale('es'));
        expect(title.style?.fontSize, 32);
        expect(title.style?.height, closeTo(36 / 32, 0.001));

        // Job line in bodyLarge + NocheColors.label
        final job = tester.widget<Text>(
          find.text('Say what you want to drink.'),
        );
        expect(job.style?.fontSize, 16);
        expect(job.style?.color, NocheColors.label);

        // Preview chips: 5 NocheChip items
        expect(find.text('WORDS YOU CAN USE'), findsOneWidget);
        expect(find.byType(NocheChip), findsNWidgets(5));

        // Other calls: 2-per-row, exact 88 px height for Latin 1- and 2-line titles
        final openCard = find.byKey(const Key('speak-other-call-cocina_comer'));
        final lockedCard = find.byKey(
          const Key('speak-other-call-cocina_main'),
        );
        expect(openCard, findsOneWidget);
        expect(lockedCard, findsOneWidget);
        expect(tester.getSize(openCard).height, 88);
        expect(tester.getSize(lockedCard).height, 88);
        expect(
          tester.getTopLeft(openCard).dy,
          tester.getTopLeft(lockedCard).dy,
        );
        expect(find.text('2 min · open'), findsOneWidget);
        expect(find.text('5 min · after story 9'), findsOneWidget);

        // Tapping locked other card does nothing
        await tester.tap(lockedCard);
        await tester.pump();
        expect(rig.nav.routes, isEmpty);

        // Tapping open other card navigates to CallRoute with callId
        await tester.tap(openCard);
        await tester.pump();
        expect(rig.nav.routes, [
          const CallRoute('cocina', callId: 'cocina_comer'),
        ]);

        // Tapping orange 96 px mic disc with halo navigates to featured CallRoute
        final discFinder = find.byKey(const Key('speak-call-disc'));
        final discWidget = tester.widget<NochePlayDisc>(discFinder);
        expect(discWidget.size, 96);
        expect(discWidget.halo, isTrue);
        expect(tester.getSize(discFinder), const Size(96, 96));

        await tester.tap(discFinder);
        await tester.pump();
        expect(
          rig.nav.routes.last,
          const CallRoute('cocina', callId: 'cocina_tomar'),
        );
        rig.dispose();

        // When locked (none open), eyebrow uses NocheColors.label and no call disc
        final lockedRig = _SpeakRig.spanish(
          casaPlayed: 0,
          parquePlayed: 0,
          cocinaPlayed: 0,
          openWordCount: 0,
        );
        await tester.pumpWidget(lockedRig.screen());
        final lockedEyebrow = tester.widget<Text>(
          find.text('NEXT CALL WITH DANNY · 2 MIN'),
        );
        expect(lockedEyebrow.style?.color, NocheColors.label);
        expect(find.byKey(const Key('speak-call-disc')), findsNothing);
        lockedRig.dispose();
      },
    );

    testWidgets(
      'completing a short call via CallProgressStore updates HablarTab and persists across restart',
      (tester) async {
        tester.view.devicePixelRatio = 3.0;
        tester.view.physicalSize = const Size(390, 844) * 3.0;
        addTearDown(tester.view.reset);

        final rig = _SpeakRig.spanish();
        rig.progress.markCallDone('cocina_tomar');

        // Re-import exported progress into a fresh store to simulate app restart.
        final restoredProgress = RecordingProgress()
          ..import(rig.progress.export());
        final restoredServices = fakeServices(
          progress: restoredProgress,
          course: rig.course,
          call: rig.call,
          nav: rig.nav,
          haptics: rig.haptics,
        );

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: coquiTheme(),
            home: Scaffold(
              backgroundColor: NocheColors.ground,
              body: HablarTab(
                services: restoredServices,
                shortCallsEnabled: true,
              ),
            ),
          ),
        );

        // Featured call advances to the next ready short call (cocina_comer),
        // while completed cocina_tomar moves to otherCalls with "2 min · done".
        expect(find.text('NEXT CALL WITH DANNY · 2 MIN'), findsOneWidget);
        expect(find.text('¿Qué te gusta comer?'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('speak-other-call-cocina_tomar')),
            matching: find.text('2 min · done'),
          ),
          findsOneWidget,
        );

        // If all ready calls in cocina are done, the featured card shows DONE eyebrow.
        restoredProgress.markCallDone('cocina_comer');
        await tester.pump();
        await tester.pump();
        expect(find.text('CALL WITH DANNY · 2 MIN · DONE'), findsOneWidget);
        final doneEyebrow = tester.widget<Text>(
          find.text('CALL WITH DANNY · 2 MIN · DONE'),
        );
        expect(doneEyebrow.style?.color, NocheColors.label);
        rig.dispose();
      },
    );

    testWidgets(
      'zero overflow and >=48 touch targets across all 5 states at 390x844 and 412x915',
      (tester) async {
        final configs = [
          (name: 'board_cocina', make: () => _SpeakRig.spanish()),
          (
            name: 'one_open',
            make: () => _SpeakRig.spanish(cocinaPlayed: 3, openWordCount: 18),
          ),
          (
            name: 'all_open',
            make: () => _SpeakRig.spanish(cocinaPlayed: 9, openWordCount: 55),
          ),
          (
            name: 'none_open',
            make: () => _SpeakRig.spanish(
              casaPlayed: 0,
              parquePlayed: 0,
              cocinaPlayed: 0,
              openWordCount: 0,
            ),
          ),
          (name: 'arabic', make: () => _SpeakRig.arabic()),
        ];

        for (final screen in const [
          (size: Size(390, 844), dpr: 3.0),
          (size: Size(412, 915), dpr: 2.625),
        ]) {
          for (final cfg in configs) {
            tester.view.devicePixelRatio = screen.dpr;
            tester.view.physicalSize = screen.size * screen.dpr;

            final rig = cfg.make();
            await tester.pumpWidget(rig.screen());
            await tester.pump();
            expect(
              tester.takeException(),
              isNull,
              reason:
                  '${cfg.name} at ${screen.size.width}x${screen.size.height}',
            );

            // Words header button >= 48x48
            final wordsSize = tester.getSize(
              find.byKey(const Key('speak-words-button')),
            );
            expect(wordsSize.height, greaterThanOrEqualTo(48));
            expect(wordsSize.width, greaterThanOrEqualTo(48));

            // Every NochePill is >= 48x48
            for (final element in find.byType(NochePill).evaluate()) {
              final box = element.renderObject! as RenderBox;
              expect(box.size.height, greaterThanOrEqualTo(48));
              expect(box.size.width, greaterThanOrEqualTo(48));
            }

            // Every other call card is >= 88 high
            for (final element
                in find
                    .byWidgetPredicate(
                      (w) =>
                          w is NocheCard &&
                          w.key is ValueKey<String> &&
                          (w.key! as ValueKey<String>).value.startsWith(
                            'speak-other-call-',
                          ),
                    )
                    .evaluate()) {
              final box = element.renderObject! as RenderBox;
              expect(
                box.size.height,
                greaterThanOrEqualTo(88),
                reason: '${cfg.name} other call card height',
              );
            }

            // If call disc present, verify 96x96
            final disc = find.byKey(const Key('speak-call-disc'));
            if (disc.evaluate().isNotEmpty) {
              expect(tester.getSize(disc), const Size(96, 96));
            }

            // Arabic RTL checks
            if (cfg.name == 'arabic') {
              final titleRect = tester.getRect(find.text('Speak'));
              final wordsRect = tester.getRect(
                find.byKey(const Key('speak-words-button')),
              );
              expect(titleRect.left, greaterThan(wordsRect.right));
              final arCallTitle = tester.widget<Text>(
                find.text('ماذا تريد أن تشرب؟'),
              );
              expect(arCallTitle.locale, const Locale('ar'));
              expect(
                arCallTitle.style?.fontFamily,
                endsWith(nocheFontNotoSansArabic),
              );
            }

            await tester.pumpWidget(const SizedBox.shrink());
            rig.dispose();
          }
        }
        tester.view.reset();
      },
    );
  });

  if (Platform.environment['COQUI_CAPTURE_SHOTS'] == '1') {
    testWidgets(
      'capture N4.6 Speak screenshots (board_cocina, one_open, all_open, none_open, arabic)',
      (tester) async {
        await _loadNocheFonts();
        final dir = Directory('test/screenshots')..createSync(recursive: true);

        Future<void> capture({
          required String filename,
          required _SpeakRig rig,
          required Size size,
          required double dpr,
        }) async {
          tester.view.devicePixelRatio = dpr;
          tester.view.physicalSize = size * dpr;
          addTearDown(tester.view.reset);

          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(key: boundaryKey, child: rig.screen()),
          );
          await tester.pumpAndSettle();

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
          await tester.pumpWidget(const SizedBox.shrink());
          rig.dispose();
        }

        const sizes = [
          (tag: '390x844', size: Size(390, 844), dpr: 3.0),
          (tag: '412x915', size: Size(412, 915), dpr: 2.625),
        ];

        for (final screen in sizes) {
          final states = [
            (tag: 'board_cocina', make: () => _SpeakRig.spanish()),
            (
              tag: 'one_open',
              make: () => _SpeakRig.spanish(cocinaPlayed: 3, openWordCount: 18),
            ),
            (
              tag: 'all_open',
              make: () => _SpeakRig.spanish(cocinaPlayed: 9, openWordCount: 55),
            ),
            (
              tag: 'none_open',
              make: () => _SpeakRig.spanish(
                casaPlayed: 0,
                parquePlayed: 0,
                cocinaPlayed: 0,
                openWordCount: 0,
              ),
            ),
            (tag: 'arabic', make: () => _SpeakRig.arabic()),
          ];
          for (final st in states) {
            await capture(
              filename: 'speak_${st.tag}_${screen.tag}.png',
              rig: st.make(),
              size: screen.size,
              dpr: screen.dpr,
            );
          }
        }
      },
    );
  }
}
