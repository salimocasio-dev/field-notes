@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/me_data.dart';
import 'package:feature_profile/src/yo_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/dev_app.dart';
import 'support/harness.dart';

/// Monday 23 Nov 2026 12:00 UTC -> prior 6 days are T, W, T, F, S, S, Today
/// (matching the weekday sequence on `docs/proyecto/noche/Noche-Yo.dc.html`).
final int _boardMondayUtcMs = DateTime.utc(
  2026,
  11,
  23,
  12,
).millisecondsSinceEpoch;

class _TenPlaceCourse extends FakeCourseCatalog {
  _TenPlaceCourse({required super.language, super.fetch})
    : _places = DevCourse().places;

  final List<Place> _places;

  @override
  List<Place> get places => _places;
}

/// Seeds a learner matching the shape of `Noche-Yo.dc.html`:
/// 212 total minutes, 6-day streak, 7 days of minutes `[28, 35, 30, 41, 36, 30, 12]`,
/// goal 30, 2 places done (currently on place 3, La cocina), 96 words heard
/// (41 Listening good, 17 Speaking good).
DevFixture _weekLearnerFixture({int? nowMs}) {
  final clockMs = nowMs ?? _boardMondayUtcMs;
  final todayUtc = DateTime.fromMillisecondsSinceEpoch(clockMs, isUtc: true);
  final daily = <int>[28, 35, 30, 41, 36, 30, 12];
  final minutosDia = <String, num>{};
  final dias = <String, int>{};
  for (var i = 0; i < daily.length; i++) {
    final offset = daily.length - 1 - i;
    final day = DateTime.utc(
      todayUtc.year,
      todayUtc.month,
      todayUtc.day - offset,
    );
    final key = utcIsoDay(day);
    minutosDia[key] = daily[i];
    // 6-day streak ending today (offsets 0..5).
    if (offset < 6) dias[key] = 1;
  }

  final rawJson = jsonEncode({
    'palabras': <String, dynamic>{},
    'dias': dias,
    'cuentos': <String, dynamic>{},
    'ajustes': {'min': 30, 'todo': 0, 'bienvenida': 1, 'habla': 1},
    'minutos': 212,
    'minutosDia': minutosDia,
    'v': 1,
  });

  final f = fixture(json: rawJson, nowMs: clockMs);
  // Finish first 2 places so current place is place 3 (La cocina).
  for (final place in f.services.course.places.take(2)) {
    for (final storyId in place.stories) {
      f.progress.storyFinished(StoryResult(id: storyId));
    }
  }
  // Seed 96 words: 41 listening good (etapa 4), 17 speaking good (etapa 4).
  for (var i = 0; i < 96; i++) {
    f.progress.put(
      WordRecord(
        w: 'palabra_$i',
        primera: clockMs,
        oida: 3,
        ear: SkillRecord(etapa: i < 41 ? 4 : 2),
        mouth: SkillRecord(etapa: i < 17 ? 4 : (i < 40 ? 2 : 0)),
      ),
    );
  }
  return f;
}

void _setPhone(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double dpr = 3.0,
}) {
  tester.view.physicalSize = Size(size.width * dpr, size.height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

Future<void> _pumpMeWithChrome(
  WidgetTester tester, {
  required Services services,
  Size size = const Size(390, 844),
  double dpr = 3.0,
  TextDirection textDirection = TextDirection.ltr,
  double Function(DateTime day)? minutesOn,
  int? streakFreezes,
  int? stageMax,
  Entitlements entitlements = const AllowAllEntitlements(),
  String? level,
  Key? boundaryKey,
}) async {
  _setPhone(tester, size: size, dpr: dpr);
  final lang = services.course.language;
  Widget content = Stack(
    fit: StackFit.expand,
    children: [
      YoScreen(
        services: services,
        minutesOn: minutesOn,
        streakFreezes: streakFreezes,
        stageMax: stageMax,
        entitlements: entitlements,
        level: level,
      ),
      Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: NocheTabBar(
          selectedId: NocheTabs.me,
          tabNames: lang.tabNames,
          script: lang.script,
          languageCode: lang.code,
          respectSafeArea: false,
          onTap: (_) {},
        ),
      ),
    ],
  );
  if (boundaryKey != null) {
    content = RepaintBoundary(key: boundaryKey, child: content);
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: coquiTheme(),
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(backgroundColor: NocheColors.ground, body: content),
      ),
    ),
  );
  await settle(tester);
}

void main() {
  group('me_data unit tests', () {
    test(
      'builds 7-day rolling UTC bars with weekday initials and Today last',
      () {
        final f = _weekLearnerFixture();
        final data = buildMeViewData(services: f.services);
        expect(data.totalMinutes, 212);
        expect(data.streak, 6);
        expect(data.streakLabel, '6 days');
        expect(data.streakFreezes, isNull);
        expect(data.streakFreezesLabel, isNull);
        expect(data.goalMinutes, 30);
        expect(data.selectedMinutePill, 30);
        expect(data.weekBars.map((b) => b.label).toList(), [
          'T',
          'W',
          'T',
          'F',
          'S',
          'S',
          'Today',
        ]);
        expect(data.weekBars.map((b) => b.roundedMinutes).toList(), [
          28,
          35,
          30,
          41,
          36,
          30,
          12,
        ]);
        expect(data.weekBars.last.isToday, isTrue);
        expect(
          data.weekChartSemanticLabel,
          'Minutes listened in the last 7 days: 28, 35, 30, 41, 36, 30, and 12 so far today. Your goal is 30 a day.',
        );
        expect(data.currentPlace?.n, 3);
        expect(data.currentPlace?.name, 'La cocina');
        expect(data.placeTotal, 10);
        expect(data.placeDashes, [
          NocheDashState.done,
          NocheDashState.done,
          NocheDashState.current,
          NocheDashState.notYet,
          NocheDashState.notYet,
          NocheDashState.notYet,
          NocheDashState.notYet,
          NocheDashState.notYet,
          NocheDashState.notYet,
          NocheDashState.notYet,
        ]);
        expect(
          data.placeDashesSemanticLabel,
          'Places: 2 done, on place 3, 7 to go',
        );
        expect(data.totalWords, 96);
        expect(data.listeningGood, 41);
        expect(data.speakingGood, 17);
        expect(data.tracksReading, isFalse);
        expect(data.planName, 'Course + Calls');
      },
    );

    test('streak singular/plural and streakFreezes switch (Part 1.7)', () {
      final f = fixture(seed: 'vacio');
      final oneFreeze = buildMeViewData(services: f.services, streakFreezes: 1);
      expect(oneFreeze.streakFreezesLabel, '1 freeze saved');

      final twoFreezes = buildMeViewData(
        services: f.services,
        streakFreezes: 2,
      );
      expect(twoFreezes.streakFreezesLabel, '2 freezes saved');

      final noFreezes = buildMeViewData(services: f.services);
      expect(noFreezes.streakFreezesLabel, isNull);
    });

    test('respects custom stageMax, minutesOn callback, level, and Plan', () {
      final f = _weekLearnerFixture();
      final data = buildMeViewData(
        services: f.services,
        stageMax: 5,
        minutesOn: (_) => 15,
        entitlements: FakeEntitlements(plan: Plan.free),
        level: 'A2',
      );
      // At stageMax = 5, words at etapa 4 are not good yet.
      expect(data.listeningGood, 0);
      expect(data.speakingGood, 0);
      expect(data.weekBars.every((b) => b.roundedMinutes == 15), isTrue);
      expect(data.level, 'A2');
      expect(data.tracksReading, isTrue);
      expect(data.planName, 'Free');
    });
  });

  group('N4.7 Me screen widget behaviour', () {
    testWidgets(
      'new learner hides streak and freeze line, shows 0s and A1 place 1',
      (tester) async {
        final f = fixture(seed: 'vacio', nowMs: _boardMondayUtcMs);
        await _pumpMeWithChrome(tester, services: f.services);

        expect(find.text('Me'), findsOneWidget);
        expect(find.text('How Coquí works'), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('me-total-minutes'))).data,
          '0',
        );
        expect(find.text('minutes listened'), findsOneWidget);
        expect(find.text('all languages'), findsOneWidget);
        expect(find.byKey(const Key('me-streak')), findsNothing);
        expect(find.byKey(const Key('me-streak-freezes')), findsNothing);
        expect(find.textContaining('freeze'), findsNothing);

        expect(find.text('Spanish'), findsOneWidget);
        expect(find.text('A1 · place 1 of 10'), findsOneWidget);
        expect(find.text('La casa'), findsOneWidget);
        expect(find.text('0 of 0 good'), findsNWidgets(2));
        expect(find.text('Reading'), findsOneWidget);
        expect(find.text('Open now. Counts from A2.'), findsOneWidget);

        expect(find.text('MINUTES A DAY'), findsOneWidget);
        expect(find.text('Your plan'), findsOneWidget);
        expect(find.text('Course + Calls'), findsOneWidget);
        expect(find.text('Manage ›'), findsOneWidget);
      },
    );

    testWidgets(
      'week learner shows streak, 7-day chart with goal, hides freeze when null, shows freeze when non-null',
      (tester) async {
        final f = _weekLearnerFixture();
        await _pumpMeWithChrome(tester, services: f.services);

        expect(
          tester.widget<Text>(find.byKey(const Key('me-total-minutes'))).data,
          '212',
        );
        expect(find.byKey(const Key('me-streak')), findsOneWidget);
        expect(find.text('6 days'), findsOneWidget);
        expect(find.byKey(const Key('me-streak-freezes')), findsNothing);

        final chart = tester.widget<NocheBarChart>(
          find.byKey(const Key('me-week-chart')),
        );
        expect(chart.items, hasLength(7));
        expect(chart.items.last.label, 'Today');
        expect(chart.items.last.highlighted, isTrue);
        expect(chart.goal, 30);

        expect(find.text('A1 · place 3 of 10'), findsOneWidget);
        expect(find.text('La cocina'), findsOneWidget);
        expect(find.text('41 of 96 good'), findsOneWidget);
        expect(find.text('17 of 96 good'), findsOneWidget);

        // Part 1.7 switch: setting streakFreezes non-null displays the line under the streak.
        await _pumpMeWithChrome(tester, services: f.services, streakFreezes: 1);
        expect(find.byKey(const Key('me-streak-freezes')), findsOneWidget);
        expect(find.text('1 freeze saved'), findsOneWidget);
      },
    );

    testWidgets(
      'language chip routes to LanguagesRoute and plan row routes to PlansRoute',
      (tester) async {
        final f = _weekLearnerFixture();
        final entitlements = FakeEntitlements(plan: Plan.course);
        await _pumpMeWithChrome(
          tester,
          services: f.services,
          entitlements: entitlements,
        );

        expect(find.text('Course'), findsOneWidget);

        await tester.tap(find.byKey(const Key('me-language-chip')));
        await settle(tester);
        expect(f.nav.routes, [const LanguagesRoute()]);

        await tester.tap(find.byKey(const Key('me-plan-row')));
        await settle(tester);
        expect(f.nav.routes, [const LanguagesRoute(), const PlansRoute()]);
        expect(f.haptics.ticks, 2);

        // Entitlement changes update the row reactively.
        entitlements.plan = Plan.free;
        await settle(tester);
        expect(find.text('Free'), findsOneWidget);
      },
    );

    testWidgets(
      'every interactive control meets the 48x48 touch target minimum',
      (tester) async {
        final f = _weekLearnerFixture();
        await pumpYo(tester, f);

        for (final key in const [
          Key('yo-how-it-works'),
          Key('me-language-chip'),
          Key('me-plan-row'),
          Key('yo-todo'),
          Key('yo-habla'),
          Key('yo-level-check'),
          Key('about-row'),
        ]) {
          final size = tester.getSize(find.byKey(key));
          expect(
            size.height,
            greaterThanOrEqualTo(NocheSize.touch),
            reason: '$key height ${size.height} < ${NocheSize.touch}',
          );
          expect(
            size.width,
            greaterThanOrEqualTo(NocheSize.touch),
            reason: '$key width ${size.width} < ${NocheSize.touch}',
          );
        }

        for (final m in const ['15', '30', '60', '120']) {
          final segOption = find.descendant(
            of: find.byKey(const Key('yo-minutes-segmented')),
            matching: find.text(m),
          );
          final gesture = find.ancestor(
            of: segOption,
            matching: find.byType(GestureDetector),
          );
          final size = tester.getSize(gesture.first);
          expect(
            size.height,
            greaterThanOrEqualTo(NocheSize.touch),
            reason:
                'Minutes pill $m height ${size.height} < ${NocheSize.touch}',
          );
        }
      },
    );

    testWidgets('renders cleanly in both phone sizes and mirrors in RTL', (
      tester,
    ) async {
      for (final size in const [Size(390, 844), Size(412, 915)]) {
        final f = _weekLearnerFixture();
        await _pumpMeWithChrome(tester, services: f.services, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('Me'), findsOneWidget);
        expect(find.text('Your plan'), findsOneWidget);
      }

      // RTL mirroring with Arabic test course.
      final clock = FakeClock(_boardMondayUtcMs);
      final arCourse = _TenPlaceCourse(
        language: arabicTestLanguage,
        fetch: arabicSampleFile,
      );
      final arStore = FakeProgressStore(clock: clock);
      arStore.addMinutes(45);
      final services = fakeServices(
        progress: arStore,
        course: arCourse,
        clock: clock,
      );
      await _pumpMeWithChrome(
        tester,
        services: services,
        textDirection: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      // In RTL, the start-aligned "Me" header sits to the right of the end-aligned pill.
      final titleRect = tester.getRect(find.text('Me'));
      final pillRect = tester.getRect(find.byKey(const Key('yo-how-it-works')));
      expect(titleRect.center.dx, greaterThan(pillRect.center.dx));
    });
  });

  if (Platform.environment['COQUI_CAPTURE_SHOTS'] == '1') {
    testWidgets('capture N4.7 Part 1.6 screenshots', (tester) async {
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

      final dir = Directory('test/screenshots')..createSync(recursive: true);

      for (final screen in [
        (tag: '390x844', size: const Size(390, 844), dpr: 3.0),
        (tag: '412x915', size: const Size(412, 915), dpr: 2.625),
      ]) {
        for (final variant in const ['new_learner', 'week_minutes']) {
          final f = variant == 'new_learner'
              ? fixture(seed: 'vacio', nowMs: _boardMondayUtcMs)
              : _weekLearnerFixture();
          final boundaryKey = GlobalKey();
          await _pumpMeWithChrome(
            tester,
            services: f.services,
            size: screen.size,
            dpr: screen.dpr,
            boundaryKey: boundaryKey,
          );

          final bytes = await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: screen.dpr);
            final byteData = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            return byteData!.buffer.asUint8List();
          });
          File('${dir.path}/me_${variant}_${screen.tag}.png')
              .writeAsBytesSync(bytes!);

          if (variant == 'week_minutes' && screen.tag == '390x844') {
            await tester.drag(
              find.byKey(const Key('me-scroll')),
              const Offset(0, -500),
            );
            await settle(tester);
            final scrolledBytes = await tester.runAsync(() async {
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: screen.dpr);
              final byteData = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              return byteData!.buffer.asUint8List();
            });
            File('${dir.path}/me_scrolled_${screen.tag}.png')
                .writeAsBytesSync(scrolledBytes!);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });
  }
}
