// Tests for the redesigned Hablar tab (Next Call hero + 10-stop map journey),
// all 31 call titles, lazy call.available caching, and the entitlements hook.
// Runs strictly against fakes in coqui_testing (never places a real call).
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_catalog.dart';
import 'package:feature_speaking/src/entitlements_hook.dart';
import 'package:feature_speaking/src/hablar_model.dart';
import 'package:feature_speaking/src/hablar_tab.dart';
import 'package:feature_speaking/src/speech_note.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/call_rig.dart';
import 'support/dev_app.dart' show devVoiceTestEntry;
import 'support/scripted_call.dart';
import 'support/world.dart';

class CountingCall extends ScriptedCall {
  CountingCall({super.available});
  int asked = 0;

  @override
  bool get available {
    asked++;
    return super.available;
  }
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Widget tab(
  World w, {
  String? callsLater,
  String? entry,
  bool note = false,
  CallEntitlementCheck entitlementCheck = defaultCallEntitlement,
  Set<String> completedCallIds = const {},
}) => w.app(
  HablarTab(
    key: UniqueKey(),
    services: w.services,
    callsLater: callsLater,
    voiceTestLabel: entry,
    showSpeechNote: note,
    entitlementCheck: entitlementCheck,
    completedCallIds: completedCallIds,
  ),
);

void main() {
  setUp(resetSpeechNoteDay);

  group('call catalog: titles and rules', () {
    test('every place has a main call plus 2-3 smaller calls, 31 total', () {
      expect(hablarCallCatalog.length, 10);
      var total = 0;
      for (final entry in hablarCallCatalog.entries) {
        final mains = entry.value.where((c) => c.isMain).toList();
        final smalls = entry.value.where((c) => !c.isMain).toList();
        expect(mains.length, 1, reason: entry.key);
        expect(smalls.length, inInclusiveRange(2, 3), reason: entry.key);
        for (final c in entry.value) {
          expect(c.titleEs.trim(), isNotEmpty);
          expect(c.jobEn.trim(), isNotEmpty);
          expect(c.titleEs.toLowerCase(), isNot(contains('call danny')));
          expect(c.titleEs.toLowerCase(), isNot(contains('llamar a danny')));
          expect(c.pixelAsset, isNull); // none until original pixel art is drawn
          total++;
        }
      }
      expect(total, 31);
    });
  });

  group('hablar: hero card and map journey (not a list)', () {
    testWidgets('never shows "Call Danny" or a 10-row card list', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'vacio');
      await tester.pumpWidget(tab(w));
      expect(find.text('Hablar'), findsOneWidget);
      expect(find.text('Call Danny'), findsNothing);
      expect(find.text('De visita en la casa'), findsOneWidget);
      expect(find.text('Opens when you finish La casa'), findsOneWidget);
      expect(find.text('Start call'), findsNothing);
      expect(find.text('I said it'), findsNothing);
      w.dispose();
    });

    testWidgets(
      'open: shows one clear Next Call hero with a >=52px Start call button',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(w));
        expect(find.text('De visita en la casa'), findsOneWidget);
        expect(
          find.text('Greet Danny, introduce yourself, and accept a drink.'),
          findsOneWidget,
        );
        expect(find.text('Start call'), findsOneWidget);
        expect(find.text(HablarTexts.practiceNoFail), findsOneWidget);
        final startBtn = tester.getSize(find.byType(CoquiButton));
        expect(startBtn.height, greaterThanOrEqualTo(48));

        await tester.tap(find.text('Start call'));
        await tester.pump();
        expect(w.nav.routes, [const CallRoute('casa')]);
        expect(w.haptics.ticks, 1);
        w.dispose();
      },
    );

    testWidgets(
      'tapping a place stop opens its main + smaller calls without duplicating primary CTA',
      (tester) async {
        Phone.android.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(w));
        await tester.tap(find.text('La casa'));
        await tester.pump();
        expect(find.text(HablarTexts.upNextAbove), findsOneWidget);
        expect(find.text('Un vaso de agua'), findsOneWidget);
        expect(find.text('¿Cómo estás?'), findsOneWidget);
        expect(find.text('Nos vemos'), findsOneWidget);
        // Smaller calls can start directly
        await tester.tap(find.text('Un vaso de agua'));
        await tester.pump();
        expect(w.nav.routes, [const CallRoute('casa')]);
        w.dispose();
      },
    );

    testWidgets('first-time reassurance retires once a call is completed', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'todo');
      await tester.pumpWidget(tab(w, completedCallIds: const {'casa_main'}));
      expect(find.text(HablarTexts.practiceNoFail), findsNothing);
      w.dispose();
    });

    testWidgets('no horizontal overflow across phone sizes', (tester) async {
      for (final phone in [Phone.android, Phone.iphone, Phone.small]) {
        phone.use(tester);
        final w = await World.create(seed: 'todo');
        await tester.pumpWidget(tab(w));
        expect(tester.takeException(), isNull, reason: phone.name);
        final box = tester.getRect(find.byType(TabPage));
        expect(box.right, lessThanOrEqualTo(phone.width), reason: phone.name);
        w.dispose();
      }
    });
  });

  group('hablar: entitlements and unavailable call library', () {
    testWidgets('tierLocked shows calm plan note instead of Start call', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'todo');
      await tester.pumpWidget(
        tab(w, entitlementCheck: () => CallEntitlement.upgradeRequired),
      );
      expect(find.text('Start call'), findsNothing);
      expect(find.text(HablarTexts.tierLockedLine), findsOneWidget);
      w.dispose();
    });

    testWidgets('call.available false caches failure until tab is rebuilt fresh', (
      tester,
    ) async {
      Phone.android.use(tester);
      final call = CountingCall(available: false);
      final w = await World.create(seed: 'todo', call: call);
      await tester.pumpWidget(tab(w));
      expect(call.asked, 1);
      expect(find.text('Calls with Danny open later.'), findsOneWidget);
      expect(find.text('Start call'), findsNothing);
      for (var i = 0; i < 5; i++) {
        w.progress.add('word $i');
        await tester.pump();
      }
      expect(call.asked, 1);
      await tester.pumpWidget(tab(w));
      expect(call.asked, 2);
      w.dispose();
    });
  });

  group('hablar: open words bottom sheet and voice test entry', () {
    testWidgets('tapping words-ready pill opens sheet with open words', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'vacio');
      await tester.pumpWidget(tab(w));
      await tester.tap(find.text('0 words ready'));
      await tester.pumpAndSettle();
      expect(find.text(HablarTexts.wordsTitle), findsOneWidget);
      expect(find.text(HablarTexts.wordsNone), findsOneWidget);
      w.dispose();
    });

    testWidgets('voice test entry routes to VoiceTestRoute when configured', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await World.create(seed: 'todo');
      await tester.pumpWidget(tab(w, entry: devVoiceTestEntry));
      await tester.scrollUntilVisible(
        find.text(devVoiceTestEntry),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(devVoiceTestEntry));
      await tester.pump();
      expect(w.nav.routes, [const VoiceTestRoute()]);
      w.dispose();
    });
  });
}
