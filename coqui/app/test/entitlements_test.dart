import 'package:app/src/entitlements.dart';
import 'package:app/src/modules.dart';
import 'package:app/src/real_platform.dart';
import 'package:app/src/shell.dart';
import 'package:app/src/switches.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_map/feature_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

void main() {
  group('ReleaseEntitlements', () {
    test('preBilling(callsAllowed: true) grants course + calls', () async {
      final e = ReleaseEntitlements.preBilling(callsAllowed: true);

      expect(e, isA<ReleaseEntitlements>());
      expect(e, isNot(isA<AllowAllEntitlements>()));
      expect(e.has(Feature.everyPlace), isTrue);
      expect(e.has(Feature.library), isTrue);
      expect(e.has(Feature.calls), isTrue);
      expect(e.plan, Plan.courseAndCalls);

      for (final f in Feature.values) {
        expect(
          e.has(f),
          const {
            Feature.everyPlace,
            Feature.library,
            Feature.calls,
          }.contains(f),
        );
      }

      for (final p in Plan.values) {
        expect(e.priceOf(p), isNull);
        expect(e.callMinutes(p), isNull);
        await e.buy(p);
      }
      await e.restore();
      expect(await e.changes.isEmpty, isTrue);
    });

    test('preBilling(callsAllowed: false) grants course without calls', () {
      final e = ReleaseEntitlements.preBilling(callsAllowed: false);

      expect(e.has(Feature.everyPlace), isTrue);
      expect(e.has(Feature.library), isTrue);
      expect(e.has(Feature.calls), isFalse);
      expect(e.plan, Plan.course);
    });

    test('default-denies ungranted features and resolves plan cleanly', () {
      final none = ReleaseEntitlements(allowed: const {});
      for (final f in Feature.values) {
        expect(none.has(f), isFalse);
      }
      expect(none.plan, Plan.free);

      final placesOnly = ReleaseEntitlements(
        allowed: const {Feature.everyPlace},
      );
      expect(placesOnly.has(Feature.everyPlace), isTrue);
      expect(placesOnly.has(Feature.library), isFalse);
      expect(placesOnly.has(Feature.calls), isFalse);
      expect(placesOnly.plan, Plan.free);

      final courseOnly = ReleaseEntitlements(
        allowed: const {Feature.everyPlace, Feature.library},
      );
      expect(courseOnly.has(Feature.everyPlace), isTrue);
      expect(courseOnly.has(Feature.library), isTrue);
      expect(courseOnly.has(Feature.calls), isFalse);
      expect(courseOnly.plan, Plan.course);
    });

    test('makes a defensive unmodifiable copy of allowed features', () {
      final source = <Feature>{Feature.everyPlace};
      final e = ReleaseEntitlements(allowed: source);

      source.add(Feature.calls);
      source.add(Feature.library);

      expect(e.has(Feature.everyPlace), isTrue);
      expect(e.has(Feature.library), isFalse);
      expect(e.has(Feature.calls), isFalse);
      expect(e.plan, Plan.free);
      expect(() => e.allowed.add(Feature.calls), throwsUnsupportedError);
    });

    test('AllowAllEntitlements remains constructible for tests and fakes', () {
      const Entitlements fake = AllowAllEntitlements();
      expect(fake.plan, Plan.courseAndCalls);
      for (final f in Feature.values) {
        expect(fake.has(f), isTrue);
      }
    });
  });

  group('release wiring', () {
    test('realPlatform never uses AllowAllEntitlements', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      final platform = realPlatform(const AppSwitches());

      expect(platform.entitlements, isA<ReleaseEntitlements>());
      expect(platform.entitlements, isNot(isA<AllowAllEntitlements>()));
      expect(platform.entitlements.has(Feature.everyPlace), isTrue);
      expect(platform.entitlements.has(Feature.library), isTrue);
      expect(
        platform.entitlements.has(Feature.calls),
        platform.info.callsAllowed,
      );
    });

    test('coquiModules passes explicit entitlements to MapModule', () {
      final entitlements = ReleaseEntitlements.preBilling(callsAllowed: false);
      final modules = coquiModules(
        switches: const AppSwitches(),
        bookImageUrl: (path) => 'https://example.com/$path',
        entitlements: entitlements,
      );

      final mapModule = modules.whereType<MapModule>().single;
      expect(identical(mapModule.entitlements, entitlements), isTrue);
      expect(mapModule.entitlements, isNot(isA<AllowAllEntitlements>()));
    });

    testWidgets(
      'CoquiApp wires ReleaseEntitlements by default into Services and MapModule',
      (tester) async {
        final app = TestApp(tester);
        await app.open(stored: seed('curso'));

        expect(app.services.entitlements, isA<ReleaseEntitlements>());
        expect(app.services.entitlements, isNot(isA<AllowAllEntitlements>()));
        expect(app.services.entitlements.plan, Plan.courseAndCalls);

        final shell = tester.widget<AppShell>(find.byType(AppShell));
        final mapModule = shell.modules.whereType<MapModule>().single;
        expect(
          identical(mapModule.entitlements, app.services.entitlements),
          isTrue,
        );
        expect(mapModule.entitlements, isNot(isA<AllowAllEntitlements>()));
      },
    );

    testWidgets('CoquiApp propagates callsAllowed == false to entitlements', (
      tester,
    ) async {
      final app = TestApp(tester)..info.callsAllowed = false;
      await app.open(stored: seed('curso'));

      expect(app.services.entitlements.has(Feature.calls), isFalse);
      expect(app.services.entitlements.has(Feature.everyPlace), isTrue);
      expect(app.services.entitlements.has(Feature.library), isTrue);
      expect(app.services.entitlements.plan, Plan.course);

      final shell = tester.widget<AppShell>(find.byType(AppShell));
      final mapModule = shell.modules.whereType<MapModule>().single;
      expect(
        identical(mapModule.entitlements, app.services.entitlements),
        isTrue,
      );
    });

    testWidgets('CoquiApp propagates explicit default-deny entitlements', (
      tester,
    ) async {
      final app = TestApp(tester)
        ..entitlements = ReleaseEntitlements(allowed: const {});
      await app.open(stored: seed('curso'));

      for (final f in Feature.values) {
        expect(app.services.entitlements.has(f), isFalse);
      }
      expect(app.services.entitlements.plan, Plan.free);

      final shell = tester.widget<AppShell>(find.byType(AppShell));
      final mapModule = shell.modules.whereType<MapModule>().single;
      expect(
        identical(mapModule.entitlements, app.services.entitlements),
        isTrue,
      );
      for (final f in Feature.values) {
        expect(mapModule.entitlements.has(f), isFalse);
      }
    });

    testWidgets(
      'paid place route locks behind place-plan-card unless granted and routes to PlansRoute',
      (tester) async {
        final lockedApp = TestApp(tester)
          ..entitlements = ReleaseEntitlements(allowed: const {});
        await lockedApp.open(stored: seed('curso'));
        await lockedApp.go(const PlaceRoute('parque'));

        expect(findShellRoute(const PlaceRoute('parque')), findsOneWidget);
        expect(find.byKey(const Key('place-plan-card')), findsOneWidget);
        expect(find.byKey(const Key('place-see-plans')), findsOneWidget);
        expect(find.byKey(const Key('place-play-bar')), findsNothing);
        expect(tester.takeException(), isNull);

        await lockedApp.tap(find.byKey(const Key('place-see-plans')));
        await lockedApp.settle(rounds: 10);
        expect(findShellRoute(const PlansRoute()), findsOneWidget);
        expect(find.byKey(const Key('plans-scroll')), findsOneWidget);
        expect(lockedApp.tabBarShown, isFalse);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());

        final unlockedApp = TestApp(tester)
          ..entitlements = ReleaseEntitlements.preBilling(callsAllowed: true);
        await unlockedApp.open(stored: seed('curso'));
        await unlockedApp.go(const PlaceRoute('parque'));

        expect(findShellRoute(const PlaceRoute('parque')), findsOneWidget);
        expect(find.byKey(const Key('place-play-bar')), findsOneWidget);
        expect(find.byKey(const Key('place-plan-card')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
