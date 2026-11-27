@TestOn('vm')
library;

import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_profile/src/plans_screen.dart';
import 'package:feature_profile/src/yo_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

bool _fontsLoaded = false;

Future<void> _loadNocheFonts() async {
  if (_fontsLoaded) return;
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
  _fontsLoaded = true;
}

Future<void> _pumpPlans(
  WidgetTester tester, {
  required Services services,
  Size size = const Size(390, 844),
  double dpr = 1,
  TextDirection textDirection = TextDirection.ltr,
  GlobalKey? boundaryKey,
}) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(size.width * dpr, size.height * dpr);
  addTearDown(tester.view.reset);

  final screen = const ProfileModule().screenFor(const PlansRoute(), services)!;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: coquiTheme(),
      home: Directionality(
        textDirection: textDirection,
        child: RepaintBoundary(
          key: boundaryKey,
          child: Scaffold(backgroundColor: NocheColors.ground, body: screen),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('PlansScreen behaviour (N3.2)', () {
    testWidgets(
      'Free plan tags Free, highlights Course with single Get Course button, and wires buy/restore/back',
      (tester) async {
        final nav = FakeNavigator();
        final entitlements = FakeEntitlements(
          plan: Plan.free,
          prices: {Plan.course: r'$9.99', Plan.courseAndCalls: r'$19.99'},
          minutes: {Plan.courseAndCalls: 120},
        );
        addTearDown(entitlements.dispose);
        final services = fakeServices(nav: nav, entitlements: entitlements);

        await _pumpPlans(tester, services: services);

        expect(find.byType(PlansScreen), findsOneWidget);
        expect(find.byKey(const Key('plans-screen')), findsOneWidget);
        expect(find.text('Plans'), findsOneWidget);
        expect(
          find.text('One plan covers every language you learn.'),
          findsOneWidget,
        );

        // Exact card order: Free -> Course -> Course + Calls.
        final freeY = tester
            .getTopLeft(find.byKey(const Key('plans-card-free')))
            .dy;
        final courseY = tester
            .getTopLeft(find.byKey(const Key('plans-card-course')))
            .dy;
        final callsY = tester
            .getTopLeft(find.byKey(const Key('plans-card-course-and-calls')))
            .dy;
        expect(freeY, lessThan(courseY));
        expect(courseY, lessThan(callsY));

        // Free holds the single "Your plan" tag.
        expect(find.byKey(const Key('plans-current-tag')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('plans-card-free')),
            matching: find.text('Your plan'),
          ),
          findsOneWidget,
        );
        expect(find.text('No cost'), findsOneWidget);
        expect(find.text('The first place in every language'), findsOneWidget);
        expect(
          find.text('Review of the words you learn there'),
          findsOneWidget,
        );

        // Course is the next tier up: 2px next border + single orange button.
        final courseCard = tester.widget<NocheCard>(
          find.descendant(
            of: find.byKey(const Key('plans-card-course')),
            matching: find.byType(NocheCard),
          ),
        );
        expect(courseCard.variant, NocheCardVariant.highlight);
        expect(find.text(r'$9.99 a month'), findsOneWidget);
        expect(find.text('Every place and every story'), findsOneWidget);
        expect(
          find.text('Library: new stories written for your level'),
          findsOneWidget,
        );
        expect(
          find.text('Review for listening, speaking and reading'),
          findsOneWidget,
        );

        // Course + Calls is standard border and has no orange button.
        final callsCard = tester.widget<NocheCard>(
          find.descendant(
            of: find.byKey(const Key('plans-card-course-and-calls')),
            matching: find.byType(NocheCard),
          ),
        );
        expect(callsCard.variant, NocheCardVariant.standard);
        expect(find.text(r'$19.99 a month'), findsOneWidget);
        expect(find.text('Everything in Course'), findsOneWidget);
        expect(find.text('Live calls with a speaking partner'), findsOneWidget);
        expect(find.text('120 minutes of calls a month'), findsOneWidget);

        // Only one orange button on the screen.
        expect(find.byType(NochePrimaryButton), findsOneWidget);
        expect(find.text('Get Course'), findsOneWidget);
        expect(find.text('Get Course + Calls'), findsNothing);

        // Buy, restore, back, and exact foot line.
        await tester.tap(find.byKey(const Key('plans-buy-course')));
        await tester.pump();
        expect(entitlements.bought, [Plan.course]);

        await tester.tap(find.byKey(const Key('plans-restore')));
        await tester.pump();
        expect(entitlements.restores, 1);

        expect(
          find.text(
            'You manage or cancel your plan in your app store account.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('plans-back')));
        await tester.pump();
        expect(nav.backs, 1);
      },
    );

    testWidgets(
      'Course plan tags Course and highlights Course + Calls with Get Course + Calls',
      (tester) async {
        final entitlements = FakeEntitlements(
          plan: Plan.course,
          prices: {Plan.course: r'$9.99', Plan.courseAndCalls: r'$19.99'},
          minutes: {Plan.courseAndCalls: 120},
        );
        addTearDown(entitlements.dispose);
        final services = fakeServices(entitlements: entitlements);

        await _pumpPlans(tester, services: services);

        expect(
          find.descendant(
            of: find.byKey(const Key('plans-card-course')),
            matching: find.text('Your plan'),
          ),
          findsOneWidget,
        );
        final courseCard = tester.widget<NocheCard>(
          find.descendant(
            of: find.byKey(const Key('plans-card-course')),
            matching: find.byType(NocheCard),
          ),
        );
        expect(courseCard.variant, NocheCardVariant.standard);

        final callsCard = tester.widget<NocheCard>(
          find.descendant(
            of: find.byKey(const Key('plans-card-course-and-calls')),
            matching: find.byType(NocheCard),
          ),
        );
        expect(callsCard.variant, NocheCardVariant.highlight);

        expect(find.byType(NochePrimaryButton), findsOneWidget);
        expect(find.text('Get Course + Calls'), findsOneWidget);
        expect(find.text('Get Course'), findsNothing);

        await tester.tap(find.byKey(const Key('plans-buy-course-and-calls')));
        await tester.pump();
        expect(entitlements.bought, [Plan.courseAndCalls]);
      },
    );

    testWidgets(
      'AllowAllEntitlements / Course + Calls shows no orange button and omits null prices & call minutes',
      (tester) async {
        final services = fakeServices(
          entitlements: const AllowAllEntitlements(),
        );

        await _pumpPlans(tester, services: services);

        expect(
          find.descendant(
            of: find.byKey(const Key('plans-card-course-and-calls')),
            matching: find.text('Your plan'),
          ),
          findsOneWidget,
        );
        expect(find.byType(NochePrimaryButton), findsNothing);
        for (final card in tester.widgetList<NocheCard>(
          find.byType(NocheCard),
        )) {
          expect(card.variant, NocheCardVariant.standard);
        }
        // Null prices and null call minutes leave those lines out completely.
        expect(find.textContaining('a month'), findsNothing);
        expect(find.textContaining('[PRICE]'), findsNothing);
        expect(find.textContaining('[MINUTES]'), findsNothing);
        expect(find.textContaining('minutes of calls'), findsNothing);
      },
    );

    testWidgets('updates reactively when entitlements.plan changes', (
      tester,
    ) async {
      final entitlements = FakeEntitlements(plan: Plan.free);
      addTearDown(entitlements.dispose);
      final services = fakeServices(entitlements: entitlements);

      await _pumpPlans(tester, services: services);
      expect(find.text('Get Course'), findsOneWidget);

      entitlements.plan = Plan.course;
      await tester.pump();
      await tester.pump();
      expect(find.text('Get Course'), findsNothing);
      expect(find.text('Get Course + Calls'), findsOneWidget);

      entitlements.plan = Plan.courseAndCalls;
      await tester.pump();
      await tester.pump();
      expect(find.byType(NochePrimaryButton), findsNothing);
    });

    testWidgets(
      'Me row reads Services.entitlements live and routes to PlansRoute -> PlansScreen',
      (tester) async {
        final nav = FakeNavigator();
        final entitlements = FakeEntitlements(plan: Plan.free);
        addTearDown(entitlements.dispose);
        final services = fakeServices(nav: nav, entitlements: entitlements);

        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(412, 1600);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: coquiTheme(),
            home: Scaffold(
              backgroundColor: NocheColors.ground,
              body: YoScreen(services: services),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.descendant(
            of: find.byKey(const Key('me-plan-row')),
            matching: find.text('Your plan'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('me-plan-row')),
            matching: find.text('Free'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('me-plan-row')),
            matching: find.text('Manage ›'),
          ),
          findsOneWidget,
        );

        entitlements.plan = Plan.course;
        await tester.pump();
        await tester.pump();
        expect(
          find.descendant(
            of: find.byKey(const Key('me-plan-row')),
            matching: find.text('Course'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('me-plan-row')));
        await tester.pump();
        expect(nav.routes, [const PlansRoute()]);
        expect(
          const ProfileModule().screenFor(nav.routes.last, services),
          isA<PlansScreen>(),
        );
      },
    );

    testWidgets(
      'meets 48x48 touch targets, renders cleanly at both phone sizes, and mirrors in RTL',
      (tester) async {
        final entitlements = FakeEntitlements(
          plan: Plan.course,
          prices: {Plan.course: r'$9.99', Plan.courseAndCalls: r'$19.99'},
          minutes: {Plan.courseAndCalls: 120},
        );
        addTearDown(entitlements.dispose);
        final services = fakeServices(entitlements: entitlements);

        for (final size in const [Size(390, 844), Size(412, 915)]) {
          await _pumpPlans(tester, services: services, size: size);
          expect(tester.takeException(), isNull);
          for (final key in const [
            Key('plans-back'),
            Key('plans-buy-course-and-calls'),
            Key('plans-restore'),
          ]) {
            final rect = tester.getRect(find.byKey(key));
            expect(
              rect.width,
              greaterThanOrEqualTo(NocheSize.touch),
              reason: '$key width ${rect.width} < ${NocheSize.touch}',
            );
            expect(
              rect.height,
              greaterThanOrEqualTo(NocheSize.touch),
              reason: '$key height ${rect.height} < ${NocheSize.touch}',
            );
          }
        }

        // RTL check: back button sits to the right of the "Plans" title, while
        // price lines and digit-leading bullets stay LTR via NocheLtr.
        await _pumpPlans(
          tester,
          services: services,
          textDirection: TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(
            tester.element(find.byKey(const Key('plans-screen'))),
          ),
          TextDirection.rtl,
        );
        final backRect = tester.getRect(find.byKey(const Key('plans-back')));
        final titleRect = tester.getRect(find.text('Plans'));
        expect(backRect.center.dx, greaterThan(titleRect.center.dx));

        for (final ltrText in const [
          r'$9.99 a month',
          r'$19.99 a month',
          '120 minutes of calls a month',
        ]) {
          expect(
            Directionality.of(tester.element(find.text(ltrText))),
            TextDirection.ltr,
            reason: '$ltrText should stay LTR via NocheLtr in RTL',
          );
        }
      },
    );
  });

  group('PlansScreen goldens (all three plans)', () {
    for (final entry in const [
      (plan: Plan.free, file: 'plans_free.png'),
      (plan: Plan.course, file: 'plans_course.png'),
      (plan: Plan.courseAndCalls, file: 'plans_course_and_calls.png'),
    ]) {
      testWidgets('matches golden on ${entry.plan.name}', (tester) async {
        await _loadNocheFonts();
        final entitlements = FakeEntitlements(
          plan: entry.plan,
          prices: {Plan.course: r'$9.99', Plan.courseAndCalls: r'$19.99'},
          minutes: {Plan.courseAndCalls: 120},
        );
        addTearDown(entitlements.dispose);
        final services = fakeServices(entitlements: entitlements);
        final boundaryKey = GlobalKey();

        await _pumpPlans(
          tester,
          services: services,
          size: const Size(390, 844),
          dpr: 1,
          boundaryKey: boundaryKey,
        );

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/${entry.file}'),
        );
      });
    }
  });
}
