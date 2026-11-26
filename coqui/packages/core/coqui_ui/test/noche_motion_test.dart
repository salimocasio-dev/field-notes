import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double _pressableScale(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.descendant(
      of: find.byType(Pressable),
      matching: find.byType(Transform),
    ),
  );
  return transform.transform.storage[0];
}

Finder _pressableColorFilteredFinder() => find.descendant(
  of: find.byType(Pressable),
  matching: find.byType(ColorFiltered),
);

Widget _wrapPressable({
  required VoidCallback? onPressed,
  bool disc = false,
  bool disableAnimations = false,
  ValueChanged<bool>? onPressedStateSeen,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Center(
        child: Pressable(
          onPressed: onPressed,
          disc: disc,
          builder: (context, pressed) {
            onPressedStateSeen?.call(pressed);
            return const SizedBox(width: 80, height: 48);
          },
        ),
      ),
    ),
  );
}

void main() {
  group('NocheMotion static tokens (Part 1.2)', () {
    test('durations match Part 1.2', () {
      expect(NocheMotion.press, const Duration(milliseconds: 90));
      expect(NocheMotion.pressBack, const Duration(milliseconds: 140));
      expect(NocheMotion.quick, const Duration(milliseconds: 140));
      expect(NocheMotion.move, const Duration(milliseconds: 220));
      expect(NocheMotion.pageIn, const Duration(milliseconds: 320));
      expect(NocheMotion.pageOut, const Duration(milliseconds: 200));
      expect(NocheMotion.settle, const Duration(milliseconds: 480));
      expect(NocheMotion.stagger, const Duration(milliseconds: 30));
      expect(NocheMotion.nextDelay, const Duration(milliseconds: 80));
      expect(NocheMotion.hop, const Duration(milliseconds: 200));
    });

    test('curves match Part 1.2 Cubic parameters', () {
      expect(NocheMotion.enter.a, 0.2);
      expect(NocheMotion.enter.b, 0.0);
      expect(NocheMotion.enter.c, 0.0);
      expect(NocheMotion.enter.d, 1.0);

      expect(NocheMotion.travel.a, 0.4);
      expect(NocheMotion.travel.b, 0.0);
      expect(NocheMotion.travel.c, 0.2);
      expect(NocheMotion.travel.d, 1.0);

      expect(NocheMotion.exit.a, 0.4);
      expect(NocheMotion.exit.b, 0.0);
      expect(NocheMotion.exit.c, 1.0);
      expect(NocheMotion.exit.d, 1.0);
    });

    test('distances, press scales, waits, loops, and ms() helper', () {
      expect(NocheMotion.row, 8.0);
      expect(NocheMotion.tab, 16.0);
      expect(NocheMotion.page, 24.0);
      expect(NocheMotion.pressScale, 0.97);
      expect(NocheMotion.pressScaleDisc, 0.94);
      expect(NocheMotion.pressDim, 0.10);

      expect(NocheMotion.followAfter, const Duration(milliseconds: 60));
      expect(NocheMotion.swapAfter, const Duration(milliseconds: 100));
      expect(NocheMotion.rowsAfter, const Duration(milliseconds: 120));
      expect(NocheMotion.lockHold, const Duration(milliseconds: 1400));

      expect(NocheMotion.loops, isTrue);

      expect(NocheMotion.ms(0), Duration.zero);
      expect(NocheMotion.ms(300), const Duration(milliseconds: 300));
      expect(() => NocheMotion.ms(-1), throwsAssertionError);
    });
  });

  group('NocheMotion.of(context)', () {
    testWidgets('normal mode returns all normal values', (tester) async {
      late NocheMotionData resolved;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              resolved = NocheMotion.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, NocheMotion.normal);
      expect(resolved.hashCode, NocheMotion.normal.hashCode);
      expect(resolved == NocheMotion.reduced, isFalse);

      expect(resolved.press, const Duration(milliseconds: 90));
      expect(resolved.pressBack, const Duration(milliseconds: 140));
      expect(resolved.quick, const Duration(milliseconds: 140));
      expect(resolved.move, const Duration(milliseconds: 220));
      expect(resolved.pageIn, const Duration(milliseconds: 320));
      expect(resolved.pageOut, const Duration(milliseconds: 200));
      expect(resolved.settle, const Duration(milliseconds: 480));
      expect(resolved.stagger, const Duration(milliseconds: 30));
      expect(resolved.nextDelay, const Duration(milliseconds: 80));
      expect(resolved.hop, const Duration(milliseconds: 200));

      expect(resolved.enter, NocheMotion.enter);
      expect(resolved.travel, NocheMotion.travel);
      expect(resolved.exit, NocheMotion.exit);

      expect(resolved.row, 8.0);
      expect(resolved.tab, 16.0);
      expect(resolved.page, 24.0);
      expect(resolved.pressScale, 0.97);
      expect(resolved.pressScaleDisc, 0.94);
      expect(resolved.pressDim, 0.10);

      expect(resolved.followAfter, const Duration(milliseconds: 60));
      expect(resolved.swapAfter, const Duration(milliseconds: 100));
      expect(resolved.rowsAfter, const Duration(milliseconds: 120));
      expect(resolved.lockHold, const Duration(milliseconds: 1400));

      expect(resolved.loops, isTrue);
      expect(resolved.reduced, isFalse);
    });

    testWidgets('reduced mode returns Part 1.4 values value by value', (
      tester,
    ) async {
      late NocheMotionData resolved;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              resolved = NocheMotion.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, NocheMotion.reduced);
      expect(resolved.hashCode, NocheMotion.reduced.hashCode);

      expect(resolved.press, NocheMotion.quick);
      expect(resolved.pressBack, NocheMotion.quick);
      expect(resolved.quick, NocheMotion.quick);
      expect(resolved.move, NocheMotion.quick);
      expect(resolved.pageIn, NocheMotion.quick);
      expect(resolved.pageOut, NocheMotion.quick);
      expect(resolved.settle, NocheMotion.quick);

      expect(resolved.stagger, Duration.zero);
      expect(resolved.nextDelay, Duration.zero);
      expect(resolved.hop, Duration.zero);

      expect(resolved.enter, NocheMotion.enter);
      expect(resolved.travel, NocheMotion.travel);
      expect(resolved.exit, NocheMotion.exit);

      expect(resolved.row, 0.0);
      expect(resolved.tab, 0.0);
      expect(resolved.page, 0.0);

      expect(resolved.pressScale, 1.0);
      expect(resolved.pressScaleDisc, 1.0);
      expect(resolved.pressDim, 0.10);

      expect(resolved.followAfter, const Duration(milliseconds: 60));
      expect(resolved.swapAfter, const Duration(milliseconds: 100));
      expect(resolved.rowsAfter, const Duration(milliseconds: 120));
      expect(resolved.lockHold, const Duration(milliseconds: 1400));

      expect(resolved.loops, isFalse);
      expect(resolved.reduced, isTrue);
    });
  });

  group('Pressable rule 1 motion', () {
    testWidgets('normal mode default scales to 0.97 and dims, then returns', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapPressable(onPressed: () {}));

      expect(_pressableScale(tester), closeTo(1.0, 1e-6));
      expect(_pressableColorFilteredFinder(), findsNothing);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump(kPressTimeout);
      await tester.pump(NocheMotion.press);

      expect(_pressableScale(tester), closeTo(0.97, 1e-6));
      expect(_pressableColorFilteredFinder(), findsOneWidget);
      final cf = tester.widget<ColorFiltered>(_pressableColorFilteredFinder());
      expect(
        cf.colorFilter,
        const ColorFilter.matrix(<double>[
          0.90,
          0,
          0,
          0,
          0,
          0,
          0.90,
          0,
          0,
          0,
          0,
          0,
          0.90,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
      );

      await gesture.up();
      await tester.pump();
      await tester.pump(NocheMotion.pressBack);

      expect(_pressableScale(tester), closeTo(1.0, 1e-6));
      expect(_pressableColorFilteredFinder(), findsNothing);
    });

    testWidgets(
      'normal mode disc: true scales to 0.94 and dims, then returns',
      (tester) async {
        await tester.pumpWidget(_wrapPressable(onPressed: () {}, disc: true));

        expect(_pressableScale(tester), closeTo(1.0, 1e-6));
        expect(_pressableColorFilteredFinder(), findsNothing);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Pressable)),
        );
        await tester.pump(kPressTimeout);
        await tester.pump(NocheMotion.press);

        expect(_pressableScale(tester), closeTo(0.94, 1e-6));
        expect(_pressableColorFilteredFinder(), findsOneWidget);

        await gesture.up();
        await tester.pump();
        await tester.pump(NocheMotion.pressBack);

        expect(_pressableScale(tester), closeTo(1.0, 1e-6));
        expect(_pressableColorFilteredFinder(), findsNothing);
      },
    );

    for (final isDisc in [false, true]) {
      testWidgets(
        'reduced motion (disc: $isDisc) keeps scale 1.0 while dimming',
        (tester) async {
          await tester.pumpWidget(
            _wrapPressable(
              onPressed: () {},
              disc: isDisc,
              disableAnimations: true,
            ),
          );

          expect(_pressableScale(tester), closeTo(1.0, 1e-6));
          expect(_pressableColorFilteredFinder(), findsNothing);

          final gesture = await tester.startGesture(
            tester.getCenter(find.byType(Pressable)),
          );
          await tester.pump(kPressTimeout);
          await tester.pump(NocheMotion.reduced.press);

          expect(_pressableScale(tester), closeTo(1.0, 1e-6));
          expect(_pressableColorFilteredFinder(), findsOneWidget);
          final cf = tester.widget<ColorFiltered>(
            _pressableColorFilteredFinder(),
          );
          expect(
            cf.colorFilter,
            const ColorFilter.matrix(<double>[
              0.90,
              0,
              0,
              0,
              0,
              0,
              0.90,
              0,
              0,
              0,
              0,
              0,
              0.90,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
          );

          await gesture.up();
          await tester.pump();
          await tester.pump(NocheMotion.reduced.pressBack);

          expect(_pressableScale(tester), closeTo(1.0, 1e-6));
          expect(_pressableColorFilteredFinder(), findsNothing);
        },
      );
    }

    testWidgets(
      'disabled Pressable stays at 1.0 with no dim, and resets mid-press',
      (tester) async {
        await tester.pumpWidget(_wrapPressable(onPressed: null));

        final gesture1 = await tester.startGesture(
          tester.getCenter(find.byType(Pressable)),
        );
        await tester.pump(kPressTimeout);
        await tester.pump(NocheMotion.press);
        expect(_pressableScale(tester), closeTo(1.0, 1e-6));
        expect(_pressableColorFilteredFinder(), findsNothing);
        await gesture1.up();
        await tester.pump();

        // Enable, press down, then disable mid-press.
        bool? lastPressed;
        await tester.pumpWidget(
          _wrapPressable(
            onPressed: () {},
            onPressedStateSeen: (v) => lastPressed = v,
          ),
        );
        final gesture2 = await tester.startGesture(
          tester.getCenter(find.byType(Pressable)),
        );
        await tester.pump(kPressTimeout);
        await tester.pump(NocheMotion.press);
        expect(lastPressed, isTrue);
        expect(_pressableScale(tester), closeTo(0.97, 1e-6));
        expect(_pressableColorFilteredFinder(), findsOneWidget);

        await tester.pumpWidget(
          _wrapPressable(
            onPressed: null,
            onPressedStateSeen: (v) => lastPressed = v,
          ),
        );
        expect(lastPressed, isFalse);
        expect(_pressableScale(tester), closeTo(1.0, 1e-6));
        expect(_pressableColorFilteredFinder(), findsNothing);

        await gesture2.up();
        await tester.pump();
      },
    );
  });
}
