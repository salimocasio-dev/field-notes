import 'dart:io';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/gallery/noche_pieces.dart';

const _tabs = {
  NocheTabs.library: 'Library',
  NocheTabs.words: 'Words',
  NocheTabs.map: 'Map',
  NocheTabs.speak: 'Speak',
  NocheTabs.me: 'Me',
};

const _micWords = {
  'ready': 'Tap to talk',
  'listening': 'Listening',
  'thinking': 'Thinking',
  'theySpeak': 'Listen',
  'right': 'Well done',
  'notYet': 'Try again',
};

const _seg3 = [
  NocheSegmentOption(value: 0, label: 'One'),
  NocheSegmentOption(value: 1, label: 'Two'),
  NocheSegmentOption(value: 2, label: 'Three'),
];

const _seg2 = [
  NocheSegmentOption(value: 0, label: 'One'),
  NocheSegmentOption(value: 1, label: 'Two'),
];

const _pillOpts = [
  NochePillOption(value: 'short', label: 'A'),
  NochePillOption(value: 'long', label: 'Much longer pill label'),
];

const _outlineHoriz = [
  NocheOutlineOption(
    value: 'a',
    child: SizedBox(height: 64, child: Text('Font A')),
  ),
  NocheOutlineOption(
    value: 'b',
    child: SizedBox(height: 64, child: Text('Font B')),
  ),
];

const _barItems2 = [
  NocheBarItem(label: '1', value: 10),
  NocheBarItem(label: '2', value: 20),
];

const _barItems6 = [
  NocheBarItem(label: '1', value: 10),
  NocheBarItem(label: '2', value: 20),
  NocheBarItem(label: '3', value: 30),
  NocheBarItem(label: '4', value: 40),
  NocheBarItem(label: '5', value: 50),
  NocheBarItem(label: '6', value: 40),
];

Widget _harness(
  Widget child, {
  TextDirection dir = TextDirection.ltr,
  bool reduced = false,
  Size size = const Size(390, 844),
}) => Directionality(
  textDirection: dir,
  child: MediaQuery(
    data: MediaQueryData(
      size: size,
      devicePixelRatio: 1,
      disableAnimations: reduced,
    ),
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Material(color: NocheColors.ground, child: child),
      ),
    ),
  ),
);

Future<StateSetter> _pumpState(
  WidgetTester tester,
  Widget Function(BuildContext, StateSetter) build, {
  TextDirection dir = TextDirection.ltr,
  bool reduced = false,
}) async {
  late StateSetter setOuter;
  await tester.pumpWidget(
    _harness(
      dir: dir,
      reduced: reduced,
      StatefulBuilder(builder: (c, s) => build(c, setOuter = s)),
    ),
  );
  return setOuter;
}

Widget _app(Widget home, {bool reduced = false}) => MaterialApp(
  theme: coquiTheme(),
  builder: reduced
      ? (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: true),
          child: child!,
        )
      : null,
  home: home,
);

double _tx(WidgetTester t, Finder f) =>
    t.widget<Transform>(f).transform.getTranslation().x;
double _ty(WidgetTester t, Finder f) =>
    t.widget<Transform>(f).transform.getTranslation().y;
double _scale(WidgetTester t, Finder f) =>
    t.widget<Transform>(f).transform.storage[0];
double _op(WidgetTester t, Finder child) => t
    .widget<Opacity>(
      find.ancestor(of: child, matching: find.byType(Opacity)).first,
    )
    .opacity;
double _clipFrac(WidgetTester t, int i) =>
    t
        .widget<ClipRRect>(find.byKey(ValueKey('noche_bar_clip_$i')))
        .clipper!
        .getClip(const Size(20, 100))
        .height /
    100.0;

void main() {
  // 1. NocheTabBar
  group('1. NocheTabBar motion', () {
    testWidgets(
      'regular -> regular pill slides in move on travel; label color in quick, weight immediate',
      (t) async {
        var selected = NocheTabs.library;
        final set = await _pumpState(
          t,
          (c, s) => Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: NocheTabBar(
              selectedId: selected,
              tabNames: _tabs,
              onTap: (id) => s(() => selected = id),
            ),
          ),
        );
        final pill = find.byKey(const ValueKey('noche_tab_pill'));
        final startX = t.getCenter(pill).dx;

        set(() => selected = NocheTabs.me);
        await t.pump();
        expect(
          t.widget<Text>(find.text('Me')).style!.fontWeight,
          FontWeight.w700,
        );
        expect(
          t.widget<Text>(find.text('Library')).style!.fontWeight,
          FontWeight.w600,
        );
        expect(t.getCenter(pill).dx, closeTo(startX, 0.01));

        await t.pump(NocheMotion.move ~/ 2);
        final midX = t.getCenter(pill).dx;

        await t.pump(NocheMotion.quick - (NocheMotion.move ~/ 2));
        expect(t.widget<Text>(find.text('Me')).style!.color, NocheColors.text);
        expect(
          t.widget<Text>(find.text('Library')).style!.color,
          NocheColors.label,
        );

        await t.pump(NocheMotion.move - NocheMotion.quick);
        final endX = t.getCenter(pill).dx;
        expect(endX, greaterThan(startX));
        expect(
          midX,
          closeTo(
            startX + (endX - startX) * NocheMotion.travel.transform(0.5),
            1.0,
          ),
        );
      },
    );

    testWidgets(
      'regular -> Map tucks pill (scale 0.5 + fade in quick) and Map -> regular emerges',
      (t) async {
        var selected = NocheTabs.words;
        final set = await _pumpState(
          t,
          (c, s) => Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: NocheTabBar(
              selectedId: selected,
              tabNames: _tabs,
              onTap: (id) => s(() => selected = id),
            ),
          ),
        );
        final pill = find.byKey(const ValueKey('noche_tab_pill'));
        final xform = find
            .ancestor(of: pill, matching: find.byType(Transform))
            .first;
        expect(_op(t, pill), closeTo(1.0, 0.01));
        expect(_scale(t, xform), closeTo(1.0, 0.01));

        set(() => selected = NocheTabs.map);
        await t.pump();
        await t.pump(NocheMotion.quick ~/ 2);
        expect(_op(t, pill), inExclusiveRange(0.0, 1.0));
        expect(_scale(t, xform), inExclusiveRange(0.5, 1.0));

        await t.pump(NocheMotion.move);
        expect(_op(t, pill), closeTo(0.0, 0.01));
        expect(_scale(t, xform), closeTo(0.5, 0.01));

        final mapX = t.getCenter(pill).dx;
        set(() => selected = NocheTabs.speak);
        await t.pump();
        await t.pump(NocheMotion.quick ~/ 2);
        expect(_op(t, pill), greaterThan(0.0));
        expect(_scale(t, xform), greaterThan(0.5));

        await t.pump(NocheMotion.move);
        expect(_op(t, pill), closeTo(1.0, 0.01));
        expect(_scale(t, xform), closeTo(1.0, 0.01));
        expect(t.getCenter(pill).dx, greaterThan(mapX));
      },
    );

    testWidgets(
      'reduced motion snaps position, keeps scale 1.0, fades in quick',
      (t) async {
        var selected = NocheTabs.library;
        final set = await _pumpState(
          t,
          reduced: true,
          (c, s) => Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: NocheTabBar(
              selectedId: selected,
              tabNames: _tabs,
              onTap: (_) {},
            ),
          ),
        );
        final pill = find.byKey(const ValueKey('noche_tab_pill'));
        final xform = find
            .ancestor(of: pill, matching: find.byType(Transform))
            .first;
        final libX = t.getCenter(pill).dx;

        set(() => selected = NocheTabs.me);
        await t.pump();
        final snappedX = t.getCenter(pill).dx;
        expect(snappedX, greaterThan(libX));
        expect(_scale(t, xform), closeTo(1.0, 0.001));
        expect(_op(t, pill), closeTo(0.0, 0.01));

        await t.pump(NocheMotion.quick ~/ 2);
        expect(t.getCenter(pill).dx, closeTo(snappedX, 0.01));
        expect(_scale(t, xform), closeTo(1.0, 0.001));
        expect(_op(t, pill), inExclusiveRange(0.0, 1.0));

        await t.pump(NocheMotion.quick);
        expect(_op(t, pill), closeTo(1.0, 0.01));
      },
    );
  });

  // 2. NocheSegmented
  group('2. NocheSegmented motion', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
        'thumb slides in move on travel ($dir) and label color in quick',
        (t) async {
          var selected = 0;
          final set = await _pumpState(
            t,
            dir: dir,
            (c, s) => Center(
              child: NocheSegmented<int>(
                selected: selected,
                onChanged: (v) => s(() => selected = v),
                options: _seg3,
              ),
            ),
          );
          final thumb = find.byKey(const ValueKey('noche_segmented_thumb'));
          final startX = t.getCenter(thumb).dx;

          set(() => selected = 2);
          await t.pump();
          expect(t.getCenter(thumb).dx, closeTo(startX, 0.01));

          await t.pump(NocheMotion.move ~/ 2);
          final midX = t.getCenter(thumb).dx;
          await t.pump(NocheMotion.move);
          final endX = t.getCenter(thumb).dx;

          expect(
            dir == TextDirection.ltr ? endX > startX : endX < startX,
            isTrue,
          );
          expect(
            midX,
            closeTo(
              startX + (endX - startX) * NocheMotion.travel.transform(0.5),
              1.0,
            ),
          );
          expect(
            t.widget<Text>(find.text('Three')).style!.color,
            NocheColors.ground,
          );
        },
      );
    }

    testWidgets('reduced motion snaps thumb and fades in quick', (t) async {
      var selected = 0;
      final set = await _pumpState(
        t,
        reduced: true,
        (c, s) => Center(
          child: NocheSegmented<int>(
            selected: selected,
            onChanged: (v) => s(() => selected = v),
            options: _seg2,
          ),
        ),
      );
      final thumb = find.byKey(const ValueKey('noche_segmented_thumb'));
      final startX = t.getCenter(thumb).dx;

      set(() => selected = 1);
      await t.pump();
      final snappedX = t.getCenter(thumb).dx;
      expect(snappedX, greaterThan(startX));
      expect(_op(t, thumb), closeTo(0.0, 0.01));

      await t.pump(NocheMotion.quick ~/ 2);
      expect(t.getCenter(thumb).dx, closeTo(snappedX, 0.01));
      expect(_op(t, thumb), inExclusiveRange(0.0, 1.0));

      await t.pump(NocheMotion.quick);
      expect(_op(t, thumb), closeTo(1.0, 0.01));
    });
  });

  // 3. NochePillGroup
  group('3. NochePillGroup motion', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
        'variable-width pill mark slides start edge and width in move on travel ($dir)',
        (t) async {
          var selected = 'short';
          final set = await _pumpState(
            t,
            dir: dir,
            (c, s) => Center(
              child: NochePillGroup<String>(
                selected: selected,
                onChanged: (v) => s(() => selected = v),
                options: _pillOpts,
              ),
            ),
          );
          final mark = find.byKey(const ValueKey('noche_pill_group_mark'));
          final startR = t.getRect(mark);

          set(() => selected = 'long');
          await t.pump();
          expect(t.getRect(mark), startR);

          await t.pump(NocheMotion.move ~/ 2);
          final midR = t.getRect(mark);
          await t.pump(NocheMotion.move);
          final endR = t.getRect(mark);

          expect(endR.width, greaterThan(startR.width + 40));
          final p = NocheMotion.travel.transform(0.5);
          expect(
            midR.width,
            closeTo(startR.width + (endR.width - startR.width) * p, 1.5),
          );
          expect(
            midR.left,
            closeTo(startR.left + (endR.left - startR.left) * p, 1.5),
          );
          expect(
            dir == TextDirection.ltr
                ? endR.center.dx > startR.center.dx
                : endR.center.dx < startR.center.dx,
            isTrue,
          );
          expect(
            t.widget<Text>(find.text('Much longer pill label')).style!.color,
            NocheColors.ground,
          );
        },
      );
    }

    testWidgets('reduced motion snaps mark start/width and fades in quick', (
      t,
    ) async {
      var selected = 'short';
      final set = await _pumpState(
        t,
        reduced: true,
        (c, s) => Center(
          child: NochePillGroup<String>(
            selected: selected,
            onChanged: (v) => s(() => selected = v),
            options: _pillOpts,
          ),
        ),
      );
      final mark = find.byKey(const ValueKey('noche_pill_group_mark'));
      final startR = t.getRect(mark);

      set(() => selected = 'long');
      await t.pump();
      expect(t.getRect(mark).width, greaterThan(startR.width + 40));
      expect(_op(t, mark), closeTo(0.0, 0.01));
      await t.pump(NocheMotion.quick);
      expect(_op(t, mark), closeTo(1.0, 0.01));
    });
  });

  // 4. NocheSwitchRow
  group('4. NocheSwitchRow motion', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
        'knob travels in move on travel ($dir) and track/knob color in quick',
        (t) async {
          var on = false;
          final set = await _pumpState(
            t,
            dir: dir,
            (c, s) => Center(
              child: NocheSwitchRow(
                label: 'Toggle',
                value: on,
                onChanged: (v) => s(() => on = v),
              ),
            ),
          );
          final knob = find.byKey(const ValueKey('noche_switch_knob'));
          final startX = t.getCenter(knob).dx;

          set(() => on = true);
          await t.pump();
          expect(t.getCenter(knob).dx, closeTo(startX, 0.01));

          await t.pump(NocheMotion.move ~/ 2);
          final midX = t.getCenter(knob).dx;
          await t.pump(NocheMotion.move);
          final endX = t.getCenter(knob).dx;

          expect(
            dir == TextDirection.ltr ? endX > startX : endX < startX,
            isTrue,
          );
          expect(
            midX,
            closeTo(
              startX + (endX - startX) * NocheMotion.travel.transform(0.5),
              1.0,
            ),
          );
          final track = t.widget<AnimatedContainer>(
            find.byKey(const ValueKey('noche_switch_track')),
          );
          expect(track.duration, NocheMotion.quick);
          expect(track.curve, NocheMotion.enter);
        },
      );
    }

    testWidgets('reduced motion snaps knob without traveling', (t) async {
      var on = false;
      final set = await _pumpState(
        t,
        reduced: true,
        (c, s) => Center(
          child: NocheSwitchRow(
            label: 'Toggle',
            value: on,
            onChanged: (v) => s(() => on = v),
          ),
        ),
      );
      final knob = find.byKey(const ValueKey('noche_switch_knob'));
      final startX = t.getCenter(knob).dx;
      set(() => on = true);
      await t.pump();
      await t.pump(const Duration(milliseconds: 1));
      expect(t.getCenter(knob).dx, greaterThan(startX));
    });
  });

  // 5. NocheSheet, showNocheSheet & NocheSheetSwap
  group('5. NocheSheet, showNocheSheet & NocheSheetSwap motion', () {
    testWidgets(
      'sheet slides up in pageIn, scrim fades in move, closes down in pageOut',
      (t) async {
        await t.pumpWidget(
          _app(
            Builder(
              builder: (c) => Scaffold(
                body: Center(
                  child: NocheOutlineButton(
                    label: 'Open',
                    onPressed: () => showNocheSheet<void>(
                      c,
                      title: 'Menu',
                      builder: (c, close) => NocheOutlineButton(
                        label: 'Close now',
                        onPressed: close,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('Open'));
        await t.pump();

        final surf = find.byKey(const ValueKey('noche_sheet_surface'));
        final scrim = find.byKey(const ValueKey('noche_sheet_scrim'));
        expect(
          t.widget<FractionalTranslation>(surf).translation.dy,
          closeTo(1.0, 0.01),
        );
        expect(t.widget<Opacity>(scrim).opacity, closeTo(0.0, 0.01));

        await t.pump(NocheMotion.pageIn ~/ 2);
        expect(
          t.widget<FractionalTranslation>(surf).translation.dy,
          closeTo(1.0 - NocheMotion.enter.transform(0.5), 0.03),
        );
        expect(t.widget<Opacity>(scrim).opacity, greaterThan(0.5));

        await t.pump(NocheMotion.move - (NocheMotion.pageIn ~/ 2));
        expect(t.widget<Opacity>(scrim).opacity, closeTo(1.0, 0.01));

        await t.pump(NocheMotion.pageIn - NocheMotion.move);
        expect(
          t.widget<FractionalTranslation>(surf).translation.dy,
          closeTo(0.0, 0.01),
        );

        await t.tap(find.text('Close now'));
        await t.pump();
        await t.pump(NocheMotion.pageOut ~/ 2);
        expect(
          t.widget<FractionalTranslation>(surf).translation.dy,
          closeTo(NocheMotion.exit.transform(0.5), 0.03),
        );
        expect(
          t.widget<Opacity>(scrim).opacity,
          closeTo(1.0 - NocheMotion.exit.transform(0.5), 0.03),
        );

        await t.pumpAndSettle();
        expect(find.text('Menu'), findsNothing);
      },
    );

    testWidgets(
      'showNocheSheet reduced motion fades in place without sliding',
      (t) async {
        await t.pumpWidget(
          _app(
            reduced: true,
            Builder(
              builder: (c) => Scaffold(
                body: Center(
                  child: NocheOutlineButton(
                    label: 'Open',
                    onPressed: () => showNocheSheet<void>(
                      c,
                      title: 'Reduced',
                      builder: (c, close) => const Text('Body'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('Open'));
        await t.pump();
        final surf = find.byKey(const ValueKey('noche_sheet_surface'));
        expect(t.widget(surf), isA<Opacity>());
        expect(t.widget<Opacity>(surf).opacity, closeTo(0.0, 0.01));
        await t.pump(NocheMotion.quick ~/ 2);
        expect(t.widget<Opacity>(surf).opacity, inExclusiveRange(0.0, 1.0));
        await t.pump(NocheMotion.quick);
        expect(t.widget<Opacity>(surf).opacity, closeTo(1.0, 0.01));
      },
    );

    testWidgets(
      'NocheSheet rows arrive after rowsAfter and NocheSheetSwap keeps exact height',
      (t) async {
        var step = 0;
        final set = await _pumpState(
          t,
          (c, s) => Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: NocheSheet(
              title: 'Sheet',
              respectSafeArea: false,
              scrollable: false,
              contentKey: step,
              rows: step == 0
                  ? const [
                      SizedBox(height: 60, child: Text('Row A')),
                      SizedBox(height: 60, child: Text('Row B')),
                    ]
                  : const [SizedBox(height: 30, child: Text('Short row'))],
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 60));
        expect(_op(t, find.text('Row A')), closeTo(0.0, 0.01));
        await t.pumpAndSettle();
        expect(_op(t, find.text('Row A')), closeTo(1.0, 0.01));

        final initialH = t.getSize(find.byType(NocheSheet)).height;
        final outOp = find.byKey(const ValueKey('noche_sheet_swap_outgoing'));
        final inOp = find.byKey(const ValueKey('noche_sheet_swap_incoming'));

        set(() => step = 1);
        await t.pump();
        expect(t.getSize(find.byType(NocheSheet)).height, initialH);

        await t.pump(const Duration(milliseconds: 70));
        expect(t.widget<Opacity>(outOp).opacity, lessThan(1.0));
        expect(t.widget<Opacity>(inOp).opacity, closeTo(0.0, 0.01));
        expect(t.getSize(find.byType(NocheSheet)).height, initialH);

        await t.pump(const Duration(milliseconds: 140));
        expect(t.widget<Opacity>(inOp).opacity, inExclusiveRange(0.0, 1.0));

        await t.pumpAndSettle();
        expect(t.widget<Opacity>(inOp).opacity, closeTo(1.0, 0.01));
        expect(t.getSize(find.byType(NocheSheet)).height, initialH);
      },
    );
  });

  // 6. NocheDashes
  group('6. NocheDashes motion', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
        'dash transitioning to done fills from start in move on travel ($dir)',
        (t) async {
          var states = [
            NocheDashState.done,
            NocheDashState.current,
            NocheDashState.notYet,
          ];
          final set = await _pumpState(
            t,
            dir: dir,
            (c, s) => Center(child: NocheDashes(states: states)),
          );

          set(
            () => states = [
              NocheDashState.done,
              NocheDashState.done,
              NocheDashState.current,
            ],
          );
          await t.pump();
          final dash1 = find.byKey(const ValueKey('noche_dash_1'));
          final frac = find.descendant(
            of: dash1,
            matching: find.byType(FractionallySizedBox),
          );
          expect(
            t.widget<FractionallySizedBox>(frac).widthFactor,
            closeTo(0.0, 0.01),
          );

          await t.pump(NocheMotion.move ~/ 2);
          expect(
            t.widget<FractionallySizedBox>(frac).widthFactor,
            closeTo(NocheMotion.travel.transform(0.5), 0.03),
          );
          final dashR = t.getRect(dash1);
          final fillR = t.getRect(
            find.descendant(of: frac, matching: find.byType(DecoratedBox)),
          );
          if (dir == TextDirection.ltr) {
            expect(fillR.left, closeTo(dashR.left, 0.5));
          } else {
            expect(fillR.right, closeTo(dashR.right, 0.5));
          }
          await t.pump(NocheMotion.move);
          expect(frac, findsNothing);
        },
      );
    }

    testWidgets('reduced motion fades done dash in place at full width', (
      t,
    ) async {
      var states = [NocheDashState.notYet];
      final set = await _pumpState(
        t,
        reduced: true,
        (c, s) => Center(child: NocheDashes(states: states)),
      );
      set(() => states = [NocheDashState.done]);
      await t.pump();
      final d0 = find.byKey(const ValueKey('noche_dash_0'));
      final opF = find.descendant(of: d0, matching: find.byType(Opacity));
      expect(
        t
            .widget<FractionallySizedBox>(
              find.descendant(
                of: d0,
                matching: find.byType(FractionallySizedBox),
              ),
            )
            .widthFactor,
        1.0,
      );
      expect(t.widget<Opacity>(opF).opacity, closeTo(0.0, 0.01));

      await t.pump(NocheMotion.quick ~/ 2);
      expect(t.widget<Opacity>(opF).opacity, inExclusiveRange(0.0, 1.0));
      await t.pump(NocheMotion.quick);
      expect(opF, findsNothing);
    });
  });

  // 7. NocheStageBar & NocheProgressBar
  group('7. NocheStageBar & NocheProgressBar motion', () {
    testWidgets('animateFrom grows once in settle on enter (start, mid, end)', (
      t,
    ) async {
      await t.pumpWidget(
        _harness(
          const Column(
            children: [
              NocheStageBar(stage: 4, max: 4, animateFrom: 0.25),
              NocheProgressBar(
                value: 0.8,
                color: NocheColors.next,
                animateFrom: 0.2,
              ),
            ],
          ),
        ),
      );
      final sF = find.descendant(
        of: find.byType(NocheStageBar),
        matching: find.byType(FractionallySizedBox),
      );
      final pF = find.descendant(
        of: find.byType(NocheProgressBar),
        matching: find.byType(FractionallySizedBox),
      );
      expect(
        t.widget<FractionallySizedBox>(sF).widthFactor,
        closeTo(0.25, 0.01),
      );
      expect(
        t.widget<FractionallySizedBox>(pF).widthFactor,
        closeTo(0.2, 0.01),
      );

      await t.pump(NocheMotion.settle ~/ 2);
      final p = NocheMotion.enter.transform(0.5);
      expect(
        t.widget<FractionallySizedBox>(sF).widthFactor,
        closeTo(0.25 + 0.75 * p, 0.03),
      );
      expect(
        t.widget<FractionallySizedBox>(pF).widthFactor,
        closeTo(0.2 + 0.6 * p, 0.03),
      );

      await t.pump(NocheMotion.settle);
      expect(
        t.widget<FractionallySizedBox>(sF).widthFactor,
        closeTo(1.0, 0.01),
      );
      expect(
        t.widget<FractionallySizedBox>(pF).widthFactor,
        closeTo(0.8, 0.01),
      );
    });

    testWidgets(
      'reduced motion renders target width immediately and fades in quick',
      (t) async {
        await t.pumpWidget(
          _harness(
            reduced: true,
            const Column(
              children: [
                NocheStageBar(stage: 3, max: 4, animateFrom: 0.0),
                NocheProgressBar(
                  value: 0.6,
                  color: NocheColors.next,
                  animateFrom: 0.0,
                ),
              ],
            ),
          ),
        );
        final sF = find.descendant(
          of: find.byType(NocheStageBar),
          matching: find.byType(FractionallySizedBox),
        );
        final sOp = find.descendant(
          of: find.byType(NocheStageBar),
          matching: find.byType(Opacity),
        );
        expect(
          t.widget<FractionallySizedBox>(sF).widthFactor,
          closeTo(0.75, 0.01),
        );
        expect(t.widget<Opacity>(sOp).opacity, closeTo(0.0, 0.01));
        await t.pump(NocheMotion.quick);
        expect(t.widget<Opacity>(sOp).opacity, closeTo(1.0, 0.01));
      },
    );
  });

  // 8. NocheBarChart
  group('8. NocheBarChart motion', () {
    testWidgets(
      'bars grow from 0 in settle on enter, first 5 stagger and 6th shares 5th start',
      (t) async {
        await t.pumpWidget(
          _harness(const Center(child: NocheBarChart(items: _barItems6))),
        );
        for (var i = 0; i < 6; i++) {
          expect(_clipFrac(t, i), closeTo(0.0, 0.01));
        }
        await t.pump(const Duration(milliseconds: 150));
        final f = [for (var i = 0; i < 6; i++) _clipFrac(t, i)];
        for (var i = 0; i < 4; i++) {
          expect(f[i], greaterThan(f[i + 1]));
        }
        expect(f[5], closeTo(f[4], 0.001));

        await t.pump(const Duration(milliseconds: 500));
        for (var i = 0; i < 6; i++) {
          expect(_clipFrac(t, i), closeTo(1.0, 0.01));
        }
      },
    );

    testWidgets(
      'reduced motion fades all bars together at full height in quick',
      (t) async {
        await t.pumpWidget(
          _harness(
            reduced: true,
            Center(child: NocheBarChart(items: _barItems6.sublist(0, 3))),
          ),
        );
        for (var i = 0; i < 3; i++) {
          expect(_clipFrac(t, i), closeTo(1.0, 0.001));
          expect(
            _op(t, find.byKey(ValueKey('noche_bar_clip_$i'))),
            closeTo(0.0, 0.01),
          );
        }
        await t.pump(NocheMotion.quick ~/ 2);
        final o0 = _op(t, find.byKey(const ValueKey('noche_bar_clip_0')));
        expect(o0, greaterThan(0.0));
        expect(
          o0,
          closeTo(
            _op(t, find.byKey(const ValueKey('noche_bar_clip_2'))),
            0.001,
          ),
        );

        await t.pump(NocheMotion.quick);
        for (var i = 0; i < 3; i++) {
          expect(
            _op(t, find.byKey(ValueKey('noche_bar_clip_$i'))),
            closeTo(1.0, 0.01),
          );
        }
      },
    );
  });

  // 9. NocheMic
  group('9. NocheMic motion', () {
    testWidgets(
      'halo in move, color/border/word/icon swap in quick, right ring once in settle, loops stop on leave',
      (t) async {
        var state = NocheMicState.ready;
        final set = await _pumpState(
          t,
          (c, s) => Center(
            child: NocheMic.custom(
              state: state,
              micWords: _micWords,
              level: 0.6,
            ),
          ),
        );
        BoxDecoration dec() =>
            t
                    .widget<Container>(
                      find.byKey(const ValueKey('noche_mic_disc')),
                    )
                    .decoration!
                as BoxDecoration;

        expect(t.hasRunningAnimations, isFalse);
        expect(dec().boxShadow, isNull);

        set(() => state = NocheMicState.listening);
        await t.pump();
        final bar0 = t
            .getSize(find.byKey(const ValueKey('noche_mic_bar_start_2')))
            .height;
        await t.pump(NocheMotion.move ~/ 2);
        expect(
          dec().boxShadow!.single.spreadRadius,
          inExclusiveRange(0.0, 8.0),
        );
        final barMid = t
            .getSize(find.byKey(const ValueKey('noche_mic_bar_start_2')))
            .height;
        expect(barMid, isNot(closeTo(bar0, 0.1)));
        expect(barMid, inInclusiveRange(8.0, 56.0));

        await t.pump(NocheMotion.move);
        expect(dec().boxShadow!.single.spreadRadius, closeTo(8.0, 0.01));
        expect(dec().color, NocheColors.listening);

        set(() => state = NocheMicState.thinking);
        await t.pump();
        await t.pump(NocheMotion.quick);
        expect(dec().color, NocheColors.otherSoft);
        expect(t.hasRunningAnimations, isTrue);

        final dot0 = find.byKey(const ValueKey('noche_mic_thinking_dot_0'));
        final opA = _op(t, dot0);
        await t.pump(NocheMotion.thinkingCycle ~/ 3);
        expect(opA, isNot(closeTo(_op(t, dot0), 0.05)));

        set(() => state = NocheMicState.right);
        await t.pump();
        final ring = find.byKey(const ValueKey('noche_mic_right_ring'));
        expect(ring, findsOneWidget);
        await t.pump(NocheMotion.settle ~/ 2);
        final ringT = find
            .ancestor(of: ring, matching: find.byType(Transform))
            .first;
        expect(_scale(t, ringT), inExclusiveRange(1.0, 1.5));
        expect(_op(t, ring), inExclusiveRange(0.0, 0.9));

        await t.pump(NocheMotion.settle);
        expect(ring, findsNothing);
        expect(t.hasRunningAnimations, isFalse);

        set(() => state = NocheMicState.notYet);
        await t.pump();
        await t.pump(NocheMotion.quick);
        await t.pump(const Duration(milliseconds: 1));
        expect(dec().color, isNull);
        expect((dec().border! as Border).top.color, NocheColors.text);
        expect(t.hasRunningAnimations, isFalse);
      },
    );

    testWidgets(
      'reduced motion stops all loops, disables right ring, and holds still bars at level 0.5 when level == 0',
      (t) async {
        var state = NocheMicState.listening;
        final set = await _pumpState(
          t,
          reduced: true,
          (c, s) => Center(
            child: NocheMic.custom(
              state: state,
              micWords: _micWords,
              level: 0.0,
            ),
          ),
        );
        expect(t.hasRunningAnimations, isFalse);
        final stillH = NocheMic.barHeightsForLevel(0.5, startSide: true);
        for (var i = 0; i < 5; i++) {
          expect(
            t.getSize(find.byKey(ValueKey('noche_mic_bar_start_$i'))).height,
            closeTo(stillH[i], 0.01),
          );
        }

        set(() => state = NocheMicState.thinking);
        await t.pump();
        await t.pump(NocheMotion.quick);
        await t.pump(const Duration(milliseconds: 1));
        expect(t.hasRunningAnimations, isFalse);
        for (var i = 0; i < 3; i++) {
          expect(
            _op(t, find.byKey(ValueKey('noche_mic_thinking_dot_$i'))),
            closeTo(1.0, 0.01),
          );
        }

        set(() => state = NocheMicState.right);
        await t.pump();
        expect(
          find.byKey(const ValueKey('noche_mic_right_ring')),
          findsNothing,
        );
      },
    );
  });

  // 10. NocheOutlineGroup
  group('10. NocheOutlineGroup motion', () {
    testWidgets('vertical outline mark slides in move on travel', (t) async {
      var selected = 'es';
      final set = await _pumpState(
        t,
        (c, s) => Center(
          child: NocheOutlineGroup<String>(
            axis: Axis.vertical,
            selected: selected,
            onChanged: (v) => s(() => selected = v),
            options: const [
              NocheOutlineOption(
                value: 'es',
                child: SizedBox(height: 56, child: Text('Spanish')),
              ),
              NocheOutlineOption(
                value: 'ar',
                child: SizedBox(height: 56, child: Text('Arabic')),
              ),
            ],
          ),
        ),
      );
      final mark = find.byKey(const ValueKey('noche_outline_group_mark'));
      final startY = t.getTopLeft(mark).dy;
      set(() => selected = 'ar');
      await t.pump();
      expect(t.getTopLeft(mark).dy, closeTo(startY, 0.01));
      await t.pump(NocheMotion.move ~/ 2);
      final midY = t.getTopLeft(mark).dy;
      await t.pump(NocheMotion.move);
      final endY = t.getTopLeft(mark).dy;
      expect(endY, greaterThan(startY));
      expect(
        midY,
        closeTo(
          startY + (endY - startY) * NocheMotion.travel.transform(0.5),
          1.0,
        ),
      );
    });

    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets('horizontal outline mark slides in move on travel ($dir)', (
        t,
      ) async {
        var selected = 'a';
        final set = await _pumpState(
          t,
          dir: dir,
          (c, s) => Center(
            child: NocheOutlineGroup<String>(
              axis: Axis.horizontal,
              selected: selected,
              onChanged: (v) => s(() => selected = v),
              options: _outlineHoriz,
            ),
          ),
        );
        final mark = find.byKey(const ValueKey('noche_outline_group_mark'));
        final startX = t.getCenter(mark).dx;
        set(() => selected = 'b');
        await t.pump();
        await t.pump(NocheMotion.move ~/ 2);
        final midX = t.getCenter(mark).dx;
        await t.pump(NocheMotion.move);
        final endX = t.getCenter(mark).dx;
        expect(
          dir == TextDirection.ltr ? endX > startX : endX < startX,
          isTrue,
        );
        expect(
          midX,
          closeTo(
            startX + (endX - startX) * NocheMotion.travel.transform(0.5),
            1.0,
          ),
        );
      });
    }

    testWidgets('reduced motion snaps outline mark and fades in quick', (
      t,
    ) async {
      var selected = 'a';
      final set = await _pumpState(
        t,
        reduced: true,
        (c, s) => Center(
          child: NocheOutlineGroup<String>(
            axis: Axis.horizontal,
            selected: selected,
            onChanged: (v) => s(() => selected = v),
            options: _outlineHoriz,
          ),
        ),
      );
      final mark = find.byKey(const ValueKey('noche_outline_group_mark'));
      final startX = t.getCenter(mark).dx;
      set(() => selected = 'b');
      await t.pump();
      expect(t.getCenter(mark).dx, greaterThan(startX));
      expect(_op(t, mark), closeTo(0.0, 0.01));
      await t.pump(NocheMotion.quick);
      expect(_op(t, mark), closeTo(1.0, 0.01));
    });
  });

  // 11. TouchSign
  group('11. TouchSign motion', () {
    testWidgets(
      'rises and falls on travel with no overshoot and stands still in reduced motion',
      (t) async {
        await t.pumpWidget(_harness(const Center(child: TouchSign())));
        final xform = find.descendant(
          of: find.byType(TouchSign),
          matching: find.byType(Transform),
        );
        expect(_ty(t, xform), closeTo(0.0, 0.01));

        await t.pump(NocheMotion.settle ~/ 2);
        expect(
          _ty(t, xform),
          closeTo(-TouchSign.bounce * NocheMotion.travel.transform(0.5), 0.1),
        );

        await t.pump(NocheMotion.settle - (NocheMotion.settle ~/ 2));
        final peak = _ty(t, xform);
        expect(peak, closeTo(-TouchSign.bounce, 0.05));
        expect(peak, greaterThanOrEqualTo(-TouchSign.bounce));

        await t.pump(NocheMotion.settle);
        expect(_ty(t, xform), closeTo(0.0, 0.05));

        await t.pumpWidget(
          _harness(reduced: true, const Center(child: TouchSign())),
        );
        await t.pump(NocheMotion.settle ~/ 2);
        expect(_ty(t, xform), 0.0);
        expect(t.hasRunningAnimations, isFalse);
      },
    );
  });

  // 12. NocheArrive
  group('12. NocheArrive motion', () {
    testWidgets(
      'staggers first 5 rows, 6th shares 5th start, next lands nextDelay after last staggered row',
      (t) async {
        await t.pumpWidget(
          _harness(
            NocheArrive(
              delay: NocheMotion.rowsAfter,
              next: const Text('Next'),
              children: [for (var i = 0; i < 6; i++) Text('Row $i')],
            ),
          ),
        );
        Finder item(int i) => find.byKey(ValueKey('noche_arrive_item_$i'));
        final nextF = find.byKey(const ValueKey('noche_arrive_next'));

        await t.pump(const Duration(milliseconds: 60));
        for (var i = 0; i < 6; i++) {
          expect(_ty(t, item(i)), closeTo(NocheMotion.row, 0.01));
          expect(_op(t, find.text('Row $i')), closeTo(0.0, 0.01));
        }
        expect(_ty(t, nextF), closeTo(NocheMotion.row, 0.01));

        await t.pump(const Duration(milliseconds: 200));
        final ops = [for (var i = 0; i < 6; i++) _op(t, find.text('Row $i'))];
        for (var i = 0; i < 4; i++) {
          expect(ops[i], greaterThan(ops[i + 1]));
        }
        expect(ops[4], greaterThan(0.0));
        expect(ops[5], closeTo(ops[4], 0.001));
        expect(_op(t, find.text('Next')), closeTo(0.0, 0.01));

        await t.pump(const Duration(milliseconds: 170));
        expect(
          _op(t, find.text('Next')),
          closeTo(NocheMotion.enter.transform(0.5), 0.03),
        );
        expect(
          _ty(t, nextF),
          closeTo(
            NocheMotion.row * (1.0 - NocheMotion.enter.transform(0.5)),
            0.3,
          ),
        );

        await t.pumpAndSettle();
        for (var i = 0; i < 6; i++) {
          expect(_ty(t, item(i)), closeTo(0.0, 0.01));
          expect(_op(t, find.text('Row $i')), closeTo(1.0, 0.01));
        }
        expect(_ty(t, nextF), closeTo(0.0, 0.01));
        expect(_op(t, find.text('Next')), closeTo(1.0, 0.01));
      },
    );

    testWidgets('reduced motion arrives all together with dy == 0 in quick', (
      t,
    ) async {
      await t.pumpWidget(
        _harness(
          reduced: true,
          const NocheArrive(
            next: Text('Next'),
            children: [Text('Row 0'), Text('Row 1'), Text('Row 2')],
          ),
        ),
      );
      await t.pump(NocheMotion.quick ~/ 2);
      final o0 = _op(t, find.text('Row 0'));
      expect(o0, greaterThan(0.0));
      expect(o0, closeTo(_op(t, find.text('Row 2')), 0.001));
      expect(o0, closeTo(_op(t, find.text('Next')), 0.001));
      expect(_ty(t, find.byKey(const ValueKey('noche_arrive_item_0'))), 0.0);
      expect(_ty(t, find.byKey(const ValueKey('noche_arrive_next'))), 0.0);
      await t.pump(NocheMotion.quick);
      expect(_op(t, find.text('Next')), closeTo(1.0, 0.01));
    });
  });

  // 13. NocheFollow
  group('13. NocheFollow motion', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      for (final side in NocheFollowSide.values) {
        testWidgets(
          'old fades in press, new enters from $side in $dir after followAfter',
          (t) async {
            var key = 0;
            final set = await _pumpState(
              t,
              dir: dir,
              (c, s) => NocheFollow(
                contentKey: key,
                side: side,
                distance: NocheMotion.page,
                child: Text('View $key'),
              ),
            );
            final inc = find.byKey(const ValueKey('noche_follow_incoming'));
            final out = find.byKey(const ValueKey('noche_follow_outgoing'));
            expect(_tx(t, inc), 0.0);

            set(() => key = 1);
            await t.pump();
            await t.pump(const Duration(milliseconds: 30));
            expect(out, findsOneWidget);
            expect(t.widget<Opacity>(out).opacity, lessThan(1.0));
            expect(_op(t, find.text('View 1')), closeTo(0.0, 0.01));

            final sign = (dir == TextDirection.ltr)
                ? (side == NocheFollowSide.end ? 1.0 : -1.0)
                : (side == NocheFollowSide.end ? -1.0 : 1.0);
            expect(_tx(t, inc), closeTo(sign * NocheMotion.page, 0.01));

            await t.pump(const Duration(milliseconds: 140));
            expect(out, findsNothing);
            final p = NocheMotion.enter.transform(0.5);
            expect(
              _tx(t, inc),
              closeTo(sign * NocheMotion.page * (1.0 - p), 0.8),
            );
            expect(_op(t, find.text('View 1')), closeTo(p, 0.03));

            await t.pumpAndSettle();
            expect(_tx(t, inc), closeTo(0.0, 0.01));
            expect(_op(t, find.text('View 1')), closeTo(1.0, 0.01));
          },
        );
      }
    }

    testWidgets('reduced motion has zero horizontal offset', (t) async {
      var key = 0;
      final set = await _pumpState(
        t,
        reduced: true,
        (c, s) => NocheFollow(
          contentKey: key,
          distance: NocheMotion.page,
          child: Text('View $key'),
        ),
      );
      set(() => key = 1);
      await t.pump();
      await t.pump(NocheMotion.followAfter + (NocheMotion.quick ~/ 2));
      expect(_tx(t, find.byKey(const ValueKey('noche_follow_incoming'))), 0.0);
      expect(_op(t, find.text('View 1')), inExclusiveRange(0.0, 1.0));
      await t.pumpAndSettle();
      expect(_op(t, find.text('View 1')), closeTo(1.0, 0.01));
    });
  });

  // 14. NocheWindow
  group('14. NocheWindow motion', () {
    testWidgets(
      'single-screen rect, borderRadius, pictureOffset animate together in pageIn/pageOut without scaling child',
      (t) async {
        var expanded = false;
        const picKey = ValueKey('unscaled_pic');
        final set = await _pumpState(
          t,
          (c, s) => Stack(
            children: [
              NocheWindow(
                rect: expanded
                    ? const Rect.fromLTWH(20, 40, 300, 180)
                    : const Rect.fromLTWH(40, 100, 140, 100),
                borderRadius: expanded ? 8 : 24,
                pictureOffset: expanded ? Offset.zero : const Offset(-40, -20),
                pictureSize: const Size(320, 200),
                leaving: !expanded,
                child: const SizedBox(key: picKey, width: 320, height: 200),
              ),
            ],
          ),
        );
        final surf = find.byKey(const ValueKey('noche_window_surface'));
        expect(t.getRect(surf), const Rect.fromLTWH(40, 100, 140, 100));
        expect(t.getSize(find.byKey(picKey)), const Size(320, 200));

        final p = NocheMotion.enter.transform(0.5);
        set(() => expanded = true);
        await t.pump();
        await t.pump(NocheMotion.pageIn ~/ 2);
        expect(t.getRect(surf).width, closeTo(140 + 160 * p, 2.0));
        expect(t.getRect(surf).height, closeTo(100 + 80 * p, 2.0));
        expect(t.getSize(find.byKey(picKey)), const Size(320, 200));

        await t.pump(NocheMotion.pageIn);
        expect(t.getRect(surf), const Rect.fromLTWH(20, 40, 300, 180));
        expect(t.getSize(find.byKey(picKey)), const Size(320, 200));

        set(() => expanded = false);
        await t.pump();
        await t.pump(NocheMotion.pageOut ~/ 2);
        expect(t.getRect(surf).width, closeTo(300 - 160 * p, 2.0));
        expect(t.getSize(find.byKey(picKey)), const Size(320, 200));

        await t.pump(NocheMotion.pageOut);
        expect(t.getRect(surf), const Rect.fromLTWH(40, 100, 140, 100));
      },
    );

    testWidgets('single-screen reduced motion snaps rect and fades in quick', (
      t,
    ) async {
      var expanded = false;
      final set = await _pumpState(
        t,
        reduced: true,
        (c, s) => Stack(
          children: [
            NocheWindow(
              rect: expanded
                  ? const Rect.fromLTWH(20, 40, 300, 180)
                  : const Rect.fromLTWH(40, 100, 140, 100),
              pictureSize: const Size(320, 200),
              child: const SizedBox(width: 320, height: 200),
            ),
          ],
        ),
      );
      final surf = find.byKey(const ValueKey('noche_window_surface'));
      set(() => expanded = true);
      await t.pump();
      expect(t.getRect(surf), const Rect.fromLTWH(20, 40, 300, 180));
      expect(_op(t, surf), closeTo(0.0, 0.01));
      await t.pump(NocheMotion.quick);
      expect(_op(t, surf), closeTo(1.0, 0.01));
    });

    testWidgets(
      'cross-screen tag transition flies rect on push and pop while keeping child unscaled',
      (t) async {
        const tag = 'story_hero';
        const picKey = ValueKey('hero_pic');
        await t.pumpWidget(
          _app(
            Builder(
              builder: (c) => Scaffold(
                body: Stack(
                  children: [
                    PositionedDirectional(
                      start: 20,
                      top: 60,
                      width: 140,
                      height: 90,
                      child: NocheWindow(
                        tag: tag,
                        borderRadius: 24,
                        pictureOffset: const Offset(-40, -20),
                        pictureSize: const Size(360, 220),
                        onPressed: () => Navigator.of(c).push<void>(
                          PageRouteBuilder<void>(
                            transitionDuration: NocheMotion.pageIn,
                            reverseTransitionDuration: NocheMotion.pageOut,
                            pageBuilder: (c2, a, sa) => Scaffold(
                              body: Stack(
                                children: [
                                  PositionedDirectional(
                                    start: 10,
                                    top: 20,
                                    width: 360,
                                    height: 220,
                                    child: NocheWindow(
                                      tag: tag,
                                      borderRadius: 8,
                                      pictureOffset: Offset.zero,
                                      pictureSize: const Size(360, 220),
                                      onPressed: () => Navigator.of(c2).pop(),
                                      child: const SizedBox(
                                        key: picKey,
                                        width: 360,
                                        height: 220,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            transitionsBuilder: (c2, a, sa, child) =>
                                FadeTransition(opacity: a, child: child),
                          ),
                        ),
                        child: const SizedBox(
                          key: picKey,
                          width: 360,
                          height: 220,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final surf = find.byKey(NocheWindow.surfaceKey(tag));
        final rectA = t.getRect(surf);
        expect(rectA.size, const Size(140, 90));

        await t.tap(find.byType(NocheWindow));
        await t.pump();
        await t.pump(NocheMotion.pageIn ~/ 2);
        expect(t.getRect(surf).width, inExclusiveRange(140.0, 360.0));
        expect(t.getRect(surf).height, inExclusiveRange(90.0, 220.0));
        expect(t.getSize(find.byKey(picKey)), const Size(360, 220));

        await t.pumpAndSettle();
        expect(t.getRect(surf).size, const Size(360, 220));

        await t.tap(find.byType(NocheWindow));
        await t.pump();
        await t.pump(NocheMotion.pageOut ~/ 2);
        expect(t.getRect(surf).width, inExclusiveRange(140.0, 360.0));
        expect(t.getSize(find.byKey(picKey)), const Size(360, 220));

        await t.pumpAndSettle();
        expect(t.getRect(surf), rectA);
      },
    );

    testWidgets(
      'cross-screen tag under reduced motion does not mount Hero / does not fly',
      (t) async {
        await t.pumpWidget(
          _harness(
            reduced: true,
            const SizedBox(
              width: 140,
              height: 90,
              child: NocheWindow(
                tag: 'reduced_tag',
                pictureSize: Size(300, 180),
                child: SizedBox(width: 300, height: 180),
              ),
            ),
          ),
        );
        expect(find.byType(Hero), findsNothing);
        final surf = find.byKey(NocheWindow.surfaceKey('reduced_tag'));
        expect(_op(t, surf), closeTo(0.0, 0.01));
        await t.pump(NocheMotion.quick);
        expect(_op(t, surf), closeTo(1.0, 0.01));
      },
    );
  });

  // 15. NocheQuietLock
  group('15. NocheQuietLock motion', () {
    testWidgets(
      'tap brightens in press, holds lockHold, returns in move; active: false ignores taps',
      (t) async {
        Color? seen;
        var taps = 0;
        await t.pumpWidget(
          _harness(
            Center(
              child: NocheQuietLock(
                onTap: () => taps++,
                builder: (c, color) =>
                    Text('Locked', style: TextStyle(color: seen = color)),
              ),
            ),
          ),
        );
        expect(seen, NocheColors.label);

        await t.tap(find.text('Locked'));
        await t.pump();
        expect(taps, 1);

        await t.pump(NocheMotion.press ~/ 2);
        expect(seen, isNot(NocheColors.label));
        expect(seen, isNot(NocheColors.text));

        await t.pump(NocheMotion.press - (NocheMotion.press ~/ 2));
        expect(seen, NocheColors.text);

        await t.pump(NocheMotion.lockHold ~/ 2);
        expect(seen, NocheColors.text);
        await t.pump(NocheMotion.lockHold - (NocheMotion.lockHold ~/ 2));
        expect(seen, NocheColors.text);

        await t.pump(NocheMotion.move ~/ 2);
        expect(seen, isNot(NocheColors.text));
        expect(seen, isNot(NocheColors.label));
        await t.pump(NocheMotion.move);
        expect(seen, NocheColors.label);

        await t.pumpWidget(
          _harness(
            Center(
              child: NocheQuietLock(
                active: false,
                onTap: () => taps++,
                builder: (c, color) => const Text('Inactive lock'),
              ),
            ),
          ),
        );
        await t.tap(find.text('Inactive lock'));
        await t.pump();
        expect(taps, 1);
      },
    );

    testWidgets('reduced motion holds same timing in place', (t) async {
      Color? seen;
      await t.pumpWidget(
        _harness(
          reduced: true,
          Center(
            child: NocheQuietLock(
              builder: (c, color) {
                seen = color;
                return const Text('Locked');
              },
            ),
          ),
        ),
      );
      await t.tap(find.text('Locked'));
      await t.pump();
      await t.pump(NocheMotion.reduced.press);
      expect(seen, NocheColors.text);
      await t.pump(NocheMotion.reduced.lockHold);
      expect(seen, NocheColors.text);
      await t.pump(NocheMotion.reduced.move);
      expect(seen, NocheColors.label);
    });
  });

  // 16. NocheLtr
  group('16. NocheLtr', () {
    testWidgets('forces TextDirection.ltr inside an RTL parent', (t) async {
      await t.pumpWidget(
        _harness(
          dir: TextDirection.rtl,
          const Center(
            child: NocheLtr(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('First'), SizedBox(width: 16), Text('Second')],
              ),
            ),
          ),
        ),
      );
      expect(
        t.getCenter(find.text('First')).dx,
        lessThan(t.getCenter(find.text('Second')).dx),
      );
    });
  });

  // 17. Gallery test: NocheMotionDevPage
  group('17. NocheMotionDevPage gallery', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets('renders cleanly in $dir and interactive controls respond', (
        t,
      ) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(390, 844);
        addTearDown(t.view.reset);

        await t.pumpWidget(
          _app(
            reduced: true,
            Scaffold(body: NocheMotionDevPage(textDirection: dir)),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);

        await t.tap(find.text('Speaking'));
        await t.pumpAndSettle();
        expect(find.text('Active panel: speaking'), findsOneWidget);

        await t.tap(find.text('El parque'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  });

  // 18. Static guard tests
  group('18. Static motion and boundary guards', () {
    test('zero raw Duration(, Curves., or Cubic( outside lib/src/noche_motion.dart', () {
      final rawMotionRe = RegExp(r'Duration\(|Curves\.|Cubic\(');
      final dartFiles =
          Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        if (file.path.endsWith('noche_motion.dart')) continue;
        expect(
          rawMotionRe
              .allMatches(file.readAsStringSync())
              .map((m) => m.group(0))
              .toList(),
          isEmpty,
          reason: '${file.path} contains raw Duration(, Curves., or Cubic(',
        );
      }
    });

    test('zero coqui_contracts imports and zero left/right/raw tokens in Noche motion files', () {
      for (final path in const [
        'lib/src/noche_motion_pieces.dart',
        'lib/src/noche_chrome.dart',
        'lib/src/noche_controls.dart',
        'lib/src/noche_data.dart',
        'tool/gallery/noche_pieces.dart',
      ]) {
        expect(
          File(path).readAsStringSync().contains('package:coqui_contracts/'),
          isFalse,
          reason: '$path imports coqui_contracts',
        );
      }
      final src = File('lib/src/noche_motion_pieces.dart').readAsStringSync();
      expect(
        RegExp(r'\b(left|right)\b', caseSensitive: false).allMatches(src),
        isEmpty,
      );
      expect(RegExp(r'Color\s*\(\s*0x').allMatches(src), isEmpty);
      expect(RegExp(r'\bfontFamily\b').allMatches(src), isEmpty);
    });
  });

  // 19. Review regression tests
  group('19. Review regression tests', () {
    testWidgets(
      'NocheSheetSwap preserves mounted outgoing State without remounting, isolates incoming State, and keeps exact fixed height for shorter and taller content',
      (t) async {
        final inits = <String, int>{};
        final created = <String, String>{};
        var step = 'A';
        final set = await _pumpState(
          t,
          (c, s) => Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: NocheSheet(
              title: 'Swap regression',
              respectSafeArea: false,
              scrollable: false,
              contentKey: step,
              child: _SwapStateProbe(
                id: step,
                height: switch (step) {
                  'A' => 140,
                  'B' => 48,
                  _ => 320,
                },
                initCounts: inits,
                createdWithLabel: created,
              ),
            ),
          ),
        );
        expect(inits['A'], 1);
        final initialH = t.getSize(find.byType(NocheSheet)).height;

        for (final (next, prev) in const [('B', 'A'), ('C', 'B')]) {
          set(() => step = next);
          await t.pump();
          await t.pump(const Duration(milliseconds: 50));
          expect(inits[prev], 1);
          expect(inits[next], 1);
          expect(created[next], next);
          expect(t.getSize(find.byType(NocheSheet)).height, initialH);
          expect(t.takeException(), isNull);

          await t.pumpAndSettle();
          expect(inits[prev], 1);
          expect(inits[next], 1);
          expect(t.getSize(find.byType(NocheSheet)).height, initialH);
          expect(t.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'showNocheSheet rapid double-tap on scrim during reverse animation does not pop underlying route',
      (t) async {
        await t.pumpWidget(
          _app(
            Builder(
              builder: (homeC) => Scaffold(
                body: Center(
                  child: NocheOutlineButton(
                    label: 'Go to detail',
                    onPressed: () => Navigator.of(homeC).push<void>(
                      MaterialPageRoute<void>(
                        builder: (detailC) => Scaffold(
                          body: Center(
                            child: NocheOutlineButton(
                              label: 'Open sheet',
                              onPressed: () => showNocheSheet<void>(
                                detailC,
                                title: 'Sheet',
                                builder: (c, close) => const SizedBox(
                                  height: 120,
                                  child: Text('Sheet content'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('Go to detail'));
        await t.pumpAndSettle();
        await t.tap(find.text('Open sheet'));
        await t.pumpAndSettle();
        expect(find.text('Sheet content'), findsOneWidget);

        await t.tapAt(const Offset(195, 40));
        await t.pump();
        await t.pump(NocheMotion.pageOut ~/ 2);
        await t.tapAt(const Offset(195, 40));
        await t.pumpAndSettle();

        expect(find.text('Sheet content'), findsNothing);
        expect(find.text('Open sheet'), findsOneWidget);
      },
    );

    for (final reduced in [false, true]) {
      testWidgets(
        'NocheBarChart growing items from 2 to 6 after settling renders all 6 bars at full height (reduced: $reduced)',
        (t) async {
          var items = _barItems2;
          final set = await _pumpState(
            t,
            reduced: reduced,
            (c, s) => Center(child: NocheBarChart(items: items)),
          );
          await t.pumpAndSettle();
          set(() => items = _barItems6);
          await t.pump();
          for (var i = 0; i < 6; i++) {
            expect(_clipFrac(t, i), closeTo(1.0, 0.01));
            if (reduced) {
              expect(
                _op(t, find.byKey(ValueKey('noche_bar_clip_$i'))),
                closeTo(1.0, 0.01),
              );
            }
          }
        },
      );
    }

    testWidgets(
      'NocheBarChart growing items mid-flight still finishes all 6 bars to 1.0',
      (t) async {
        var items = _barItems2;
        final set = await _pumpState(
          t,
          (c, s) => Center(child: NocheBarChart(items: items)),
        );
        await t.pump(NocheMotion.settle ~/ 2);
        set(() => items = _barItems6);
        await t.pumpAndSettle();
        for (var i = 0; i < 6; i++) {
          expect(_clipFrac(t, i), closeTo(1.0, 0.01));
        }
      },
    );

    for (final reduced in [false, true]) {
      testWidgets(
        'NocheArrive growing children after initial entrance renders new children at opacity 1.0 and dy 0 (reduced: $reduced)',
        (t) async {
          var count = 2;
          var hasNext = false;
          final set = await _pumpState(
            t,
            reduced: reduced,
            (c, s) => NocheArrive(
              next: hasNext ? const Text('Added next') : null,
              children: [for (var i = 0; i < count; i++) Text('Item $i')],
            ),
          );
          await t.pumpAndSettle();
          set(() {
            count = 6;
            hasNext = true;
          });
          await t.pump();
          for (var i = 0; i < 6; i++) {
            expect(
              _ty(t, find.byKey(ValueKey('noche_arrive_item_$i'))),
              closeTo(0.0, 0.01),
            );
            expect(_op(t, find.text('Item $i')), closeTo(1.0, 0.01));
          }
          expect(
            _ty(t, find.byKey(const ValueKey('noche_arrive_next'))),
            closeTo(0.0, 0.01),
          );
          expect(_op(t, find.text('Added next')), closeTo(1.0, 0.01));
        },
      );
    }

    testWidgets(
      'NocheFollow preserves mounted outgoing State without remounting and isolates incoming State',
      (t) async {
        final inits = <String, int>{};
        final created = <String, String>{};
        var step = 'A';
        final set = await _pumpState(
          t,
          (c, s) => NocheFollow(
            contentKey: step,
            child: _SwapStateProbe(
              id: step,
              height: 80,
              initCounts: inits,
              createdWithLabel: created,
            ),
          ),
        );
        expect(inits['A'], 1);

        set(() => step = 'B');
        await t.pump();
        await t.pump(const Duration(milliseconds: 30));
        expect(inits['A'], 1);
        expect(inits['B'], 1);
        expect(created['B'], 'B');
        expect(find.text('Probe A (init=A)'), findsOneWidget);
        expect(find.text('Probe B (init=B)'), findsOneWidget);

        await t.pumpAndSettle();
        expect(inits['A'], 1);
        expect(inits['B'], 1);
        expect(find.text('Probe A (init=A)'), findsNothing);
        expect(find.text('Probe B (init=B)'), findsOneWidget);
      },
    );

    testWidgets(
      'showNocheSheet close() removes non-current sheet route when another route is pushed on top',
      (t) async {
        late VoidCallback sheetClose;
        await t.pumpWidget(
          _app(
            Builder(
              builder: (homeC) => Scaffold(
                body: Center(
                  child: NocheOutlineButton(
                    label: 'Open sheet',
                    onPressed: () => showNocheSheet<void>(
                      homeC,
                      title: 'Underneath sheet',
                      builder: (sheetC, close) {
                        sheetClose = close;
                        return NocheOutlineButton(
                          label: 'Push top route',
                          onPressed: () => Navigator.of(sheetC).push<void>(
                            MaterialPageRoute<void>(
                              builder: (topC) => Scaffold(
                                body: Center(
                                  child: NocheOutlineButton(
                                    label: 'Pop top route',
                                    onPressed: () => Navigator.of(topC).pop(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('Open sheet'));
        await t.pumpAndSettle();
        await t.tap(find.text('Push top route'));
        await t.pumpAndSettle();

        sheetClose();
        await t.pumpAndSettle();
        expect(find.text('Pop top route'), findsOneWidget);

        await t.tap(find.text('Pop top route'));
        await t.pumpAndSettle();
        expect(find.text('Underneath sheet'), findsNothing);
        expect(find.text('Open sheet'), findsOneWidget);
      },
    );

    testWidgets(
      'showNocheSheet dismissible scrim exposes close semantics without breaking sheet Close button',
      (t) async {
        final handle = t.ensureSemantics();
        try {
          await t.pumpWidget(
            _app(
              Builder(
                builder: (c) => Scaffold(
                  body: Center(
                    child: NocheOutlineButton(
                      label: 'Open',
                      onPressed: () => showNocheSheet<void>(
                        c,
                        title: 'Accessible sheet',
                        builder: (c, close) => const Text('Sheet body'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.tap(find.text('Open'));
          await t.pumpAndSettle();
          expect(
            t
                .getSemantics(find.byKey(const ValueKey('noche_sheet_scrim')))
                .label,
            NocheA11y.label(NocheA11y.closeSheet),
          );
          expect(
            find.descendant(
              of: find.byType(NocheSheet),
              matching: find.bySemanticsLabel(
                NocheA11y.label(NocheA11y.closeSheet),
              ),
            ),
            findsOneWidget,
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('NocheTabBar hides pill when selectedId is unknown', (t) async {
      await t.pumpWidget(
        _harness(
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: NocheTabBar(
              selectedId: 'unknown_tab_id',
              tabNames: _tabs,
              onTap: (_) {},
            ),
          ),
        ),
      );
      expect(
        _op(t, find.byKey(const ValueKey('noche_tab_pill'))),
        closeTo(0.0, 0.01),
      );
    });
  });
}

class _SwapStateProbe extends StatefulWidget {
  const _SwapStateProbe({
    required this.id,
    required this.height,
    required this.initCounts,
    required this.createdWithLabel,
  });
  final String id;
  final double height;
  final Map<String, int> initCounts;
  final Map<String, String> createdWithLabel;
  @override
  State<_SwapStateProbe> createState() => _SwapStateProbeState();
}

class _SwapStateProbeState extends State<_SwapStateProbe> {
  late final String _initialId;
  @override
  void initState() {
    super.initState();
    _initialId = widget.id;
    widget.initCounts[widget.id] = (widget.initCounts[widget.id] ?? 0) + 1;
    widget.createdWithLabel[widget.id] = _initialId;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: Text('Probe ${widget.id} (init=$_initialId)'),
  );
}
