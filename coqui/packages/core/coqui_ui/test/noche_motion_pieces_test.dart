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

Widget _harness(
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  Size size = const Size(390, 844),
}) => Directionality(
  textDirection: textDirection,
  child: MediaQuery(
    data: MediaQueryData(
      size: size,
      devicePixelRatio: 1,
      disableAnimations: disableAnimations,
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

double _translateX(WidgetTester tester, Finder finder) =>
    tester.widget<Transform>(finder).transform.getTranslation().x;

double _translateY(WidgetTester tester, Finder finder) =>
    tester.widget<Transform>(finder).transform.getTranslation().y;

double _scaleOf(WidgetTester tester, Finder finder) =>
    tester.widget<Transform>(finder).transform.storage[0];

double _opacityOfChild(WidgetTester tester, Finder descendant) => tester
    .widget<Opacity>(
      find.ancestor(of: descendant, matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  // 1. NocheTabBar
  group('1. NocheTabBar motion', () {
    testWidgets(
      'regular -> regular pill slides in move on travel; label color in quick, weight immediate',
      (tester) async {
        var selected = NocheTabs.library;
        late StateSetter setOuter;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: NocheTabBar(
                    selectedId: selected,
                    tabNames: _tabs,
                    onTap: (id) => setState(() => selected = id),
                  ),
                );
              },
            ),
          ),
        );

        final pillFinder = find.byKey(const ValueKey('noche_tab_pill'));
        final startX = tester.getCenter(pillFinder).dx;

        setOuter(() => selected = NocheTabs.me);
        await tester.pump();

        // Weight changes immediately on frame 0.
        expect(
          tester.widget<Text>(find.text('Me')).style!.fontWeight,
          FontWeight.w700,
        );
        expect(
          tester.widget<Text>(find.text('Library')).style!.fontWeight,
          FontWeight.w600,
        );
        // Position at start (t = 0).
        expect(tester.getCenter(pillFinder).dx, closeTo(startX, 0.01));

        // Midpoint (move ~/ 2 = 110ms) follows travel curve.
        await tester.pump(NocheMotion.move ~/ 2);
        final midX = tester.getCenter(pillFinder).dx;

        // Label color finishes at quick (140ms).
        await tester.pump(NocheMotion.quick - (NocheMotion.move ~/ 2));
        expect(
          tester.widget<Text>(find.text('Me')).style!.color,
          NocheColors.text,
        );
        expect(
          tester.widget<Text>(find.text('Library')).style!.color,
          NocheColors.label,
        );

        // End (move = 220ms).
        await tester.pump(NocheMotion.move - NocheMotion.quick);
        final endX = tester.getCenter(pillFinder).dx;
        expect(endX, greaterThan(startX));
        final expectedMid =
            startX + (endX - startX) * NocheMotion.travel.transform(0.5);
        expect(midX, closeTo(expectedMid, 1.0));
      },
    );

    testWidgets(
      'regular -> Map tucks pill (scale 0.5 + fade in quick) and Map -> regular emerges',
      (tester) async {
        var selected = NocheTabs.words;
        late StateSetter setOuter;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: NocheTabBar(
                    selectedId: selected,
                    tabNames: _tabs,
                    onTap: (id) => setState(() => selected = id),
                  ),
                );
              },
            ),
          ),
        );

        final pillFinder = find.byKey(const ValueKey('noche_tab_pill'));
        final pillTransform = find
            .ancestor(of: pillFinder, matching: find.byType(Transform))
            .first;

        expect(_opacityOfChild(tester, pillFinder), closeTo(1.0, 0.01));
        expect(_scaleOf(tester, pillTransform), closeTo(1.0, 0.01));

        // Go to Map: fades 1 -> 0 and scales 1 -> 0.5 in quick.
        setOuter(() => selected = NocheTabs.map);
        await tester.pump();
        await tester.pump(NocheMotion.quick ~/ 2);
        final midOpacity = _opacityOfChild(tester, pillFinder);
        final midScale = _scaleOf(tester, pillTransform);
        expect(midOpacity, greaterThan(0.0));
        expect(midOpacity, lessThan(1.0));
        expect(midScale, greaterThan(0.5));
        expect(midScale, lessThan(1.0));

        await tester.pump(NocheMotion.move);
        expect(_opacityOfChild(tester, pillFinder), closeTo(0.0, 0.01));
        expect(_scaleOf(tester, pillTransform), closeTo(0.5, 0.01));

        // Leave Map -> Speak: emerges back to opacity 1.0, scale 1.0.
        final mapX = tester.getCenter(pillFinder).dx;
        setOuter(() => selected = NocheTabs.speak);
        await tester.pump();
        await tester.pump(NocheMotion.quick ~/ 2);
        expect(_opacityOfChild(tester, pillFinder), greaterThan(0.0));
        expect(_scaleOf(tester, pillTransform), greaterThan(0.5));

        await tester.pump(NocheMotion.move);
        expect(_opacityOfChild(tester, pillFinder), closeTo(1.0, 0.01));
        expect(_scaleOf(tester, pillTransform), closeTo(1.0, 0.01));
        expect(tester.getCenter(pillFinder).dx, greaterThan(mapX));
      },
    );

    testWidgets(
      'reduced motion snaps position, keeps scale 1.0, fades in quick',
      (tester) async {
        var selected = NocheTabs.library;
        late StateSetter setOuter;
        await tester.pumpWidget(
          _harness(
            disableAnimations: true,
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: NocheTabBar(
                    selectedId: selected,
                    tabNames: _tabs,
                    onTap: (_) {},
                  ),
                );
              },
            ),
          ),
        );

        final pillFinder = find.byKey(const ValueKey('noche_tab_pill'));
        final pillTransform = find
            .ancestor(of: pillFinder, matching: find.byType(Transform))
            .first;
        final libX = tester.getCenter(pillFinder).dx;

        setOuter(() => selected = NocheTabs.me);
        await tester.pump();
        final snappedX = tester.getCenter(pillFinder).dx;
        expect(snappedX, greaterThan(libX));
        expect(_scaleOf(tester, pillTransform), closeTo(1.0, 0.001));
        expect(_opacityOfChild(tester, pillFinder), closeTo(0.0, 0.01));

        await tester.pump(NocheMotion.quick ~/ 2);
        expect(tester.getCenter(pillFinder).dx, closeTo(snappedX, 0.01));
        expect(_scaleOf(tester, pillTransform), closeTo(1.0, 0.001));
        expect(_opacityOfChild(tester, pillFinder), greaterThan(0.0));
        expect(_opacityOfChild(tester, pillFinder), lessThan(1.0));

        await tester.pump(NocheMotion.quick);
        expect(_opacityOfChild(tester, pillFinder), closeTo(1.0, 0.01));
      },
    );
  });

  // 2. NocheSegmented
  group('2. NocheSegmented motion', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
        'thumb slides in move on travel ($dir) and label color in quick',
        (tester) async {
          var selected = 0;
          late StateSetter setOuter;
          await tester.pumpWidget(
            _harness(
              textDirection: dir,
              StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return Center(
                    child: NocheSegmented<int>(
                      selected: selected,
                      onChanged: (v) => setState(() => selected = v),
                      options: const [
                        NocheSegmentOption(value: 0, label: 'One'),
                        NocheSegmentOption(value: 1, label: 'Two'),
                        NocheSegmentOption(value: 2, label: 'Three'),
                      ],
                    ),
                  );
                },
              ),
            ),
          );

          final thumb = find.byKey(const ValueKey('noche_segmented_thumb'));
          final startX = tester.getCenter(thumb).dx;

          setOuter(() => selected = 2);
          await tester.pump();
          expect(tester.getCenter(thumb).dx, closeTo(startX, 0.01));

          await tester.pump(NocheMotion.move ~/ 2);
          final midX = tester.getCenter(thumb).dx;

          await tester.pump(NocheMotion.move);
          final endX = tester.getCenter(thumb).dx;

          if (dir == TextDirection.ltr) {
            expect(endX, greaterThan(startX));
          } else {
            expect(endX, lessThan(startX));
          }
          final expectedMid =
              startX + (endX - startX) * NocheMotion.travel.transform(0.5);
          expect(midX, closeTo(expectedMid, 1.0));
          expect(
            tester.widget<Text>(find.text('Three')).style!.color,
            NocheColors.ground,
          );
        },
      );
    }

    testWidgets('reduced motion snaps thumb and fades in quick', (
      tester,
    ) async {
      var selected = 0;
      late StateSetter setOuter;
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Center(
                child: NocheSegmented<int>(
                  selected: selected,
                  onChanged: (v) => setState(() => selected = v),
                  options: const [
                    NocheSegmentOption(value: 0, label: 'One'),
                    NocheSegmentOption(value: 1, label: 'Two'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      final thumb = find.byKey(const ValueKey('noche_segmented_thumb'));
      final startX = tester.getCenter(thumb).dx;

      setOuter(() => selected = 1);
      await tester.pump();
      final snappedX = tester.getCenter(thumb).dx;
      expect(snappedX, greaterThan(startX));
      expect(_opacityOfChild(tester, thumb), closeTo(0.0, 0.01));

      await tester.pump(NocheMotion.quick ~/ 2);
      expect(tester.getCenter(thumb).dx, closeTo(snappedX, 0.01));
      expect(_opacityOfChild(tester, thumb), greaterThan(0.0));
      expect(_opacityOfChild(tester, thumb), lessThan(1.0));

      await tester.pump(NocheMotion.quick);
      expect(_opacityOfChild(tester, thumb), closeTo(1.0, 0.01));
    });
  });

  // 3. NochePillGroup
  group('3. NochePillGroup motion', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
        'variable-width pill mark slides start edge and width in move on travel ($dir)',
        (tester) async {
          var selected = 'short';
          late StateSetter setOuter;
          await tester.pumpWidget(
            _harness(
              textDirection: dir,
              StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return Center(
                    child: NochePillGroup<String>(
                      selected: selected,
                      onChanged: (v) => setState(() => selected = v),
                      options: const [
                        NochePillOption(value: 'short', label: 'A'),
                        NochePillOption(
                          value: 'long',
                          label: 'Much longer pill label',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );

          final mark = find.byKey(const ValueKey('noche_pill_group_mark'));
          final startRect = tester.getRect(mark);

          setOuter(() => selected = 'long');
          await tester.pump();
          expect(tester.getRect(mark), startRect);

          await tester.pump(NocheMotion.move ~/ 2);
          final midRect = tester.getRect(mark);

          await tester.pump(NocheMotion.move);
          final endRect = tester.getRect(mark);

          expect(endRect.width, greaterThan(startRect.width + 40));
          final p = NocheMotion.travel.transform(0.5);
          expect(
            midRect.width,
            closeTo(
              startRect.width + (endRect.width - startRect.width) * p,
              1.5,
            ),
          );
          expect(
            midRect.left,
            closeTo(startRect.left + (endRect.left - startRect.left) * p, 1.5),
          );
          if (dir == TextDirection.ltr) {
            expect(endRect.center.dx, greaterThan(startRect.center.dx));
          } else {
            expect(endRect.center.dx, lessThan(startRect.center.dx));
          }
          expect(
            tester
                .widget<Text>(find.text('Much longer pill label'))
                .style!
                .color,
            NocheColors.ground,
          );
        },
      );
    }

    testWidgets('reduced motion snaps mark start/width and fades in quick', (
      tester,
    ) async {
      var selected = 'short';
      late StateSetter setOuter;
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Center(
                child: NochePillGroup<String>(
                  selected: selected,
                  onChanged: (v) => setState(() => selected = v),
                  options: const [
                    NochePillOption(value: 'short', label: 'A'),
                    NochePillOption(
                      value: 'long',
                      label: 'Much longer pill label',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      final mark = find.byKey(const ValueKey('noche_pill_group_mark'));
      final startRect = tester.getRect(mark);

      setOuter(() => selected = 'long');
      await tester.pump();
      final snappedRect = tester.getRect(mark);
      expect(snappedRect.width, greaterThan(startRect.width + 40));
      expect(_opacityOfChild(tester, mark), closeTo(0.0, 0.01));

      await tester.pump(NocheMotion.quick);
      expect(_opacityOfChild(tester, mark), closeTo(1.0, 0.01));
    });
  });

  // 4. NocheSwitchRow
  group('4. NocheSwitchRow motion', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
        'knob travels in move on travel ($dir) and track/knob color in quick',
        (tester) async {
          var on = false;
          late StateSetter setOuter;
          await tester.pumpWidget(
            _harness(
              textDirection: dir,
              StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return Center(
                    child: NocheSwitchRow(
                      label: 'Toggle',
                      value: on,
                      onChanged: (v) => setState(() => on = v),
                    ),
                  );
                },
              ),
            ),
          );

          final knob = find.byKey(const ValueKey('noche_switch_knob'));
          final startX = tester.getCenter(knob).dx;

          setOuter(() => on = true);
          await tester.pump();
          expect(tester.getCenter(knob).dx, closeTo(startX, 0.01));

          await tester.pump(NocheMotion.move ~/ 2);
          final midX = tester.getCenter(knob).dx;

          await tester.pump(NocheMotion.move);
          final endX = tester.getCenter(knob).dx;

          if (dir == TextDirection.ltr) {
            expect(endX, greaterThan(startX));
          } else {
            expect(endX, lessThan(startX));
          }
          final expectedMid =
              startX + (endX - startX) * NocheMotion.travel.transform(0.5);
          expect(midX, closeTo(expectedMid, 1.0));

          final track = tester.widget<AnimatedContainer>(
            find.byKey(const ValueKey('noche_switch_track')),
          );
          expect(track.duration, NocheMotion.quick);
          expect(track.curve, NocheMotion.enter);
        },
      );
    }

    testWidgets('reduced motion snaps knob without traveling', (tester) async {
      var on = false;
      late StateSetter setOuter;
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Center(
                child: NocheSwitchRow(
                  label: 'Toggle',
                  value: on,
                  onChanged: (v) => setState(() => on = v),
                ),
              );
            },
          ),
        ),
      );

      final knob = find.byKey(const ValueKey('noche_switch_knob'));
      final startX = tester.getCenter(knob).dx;

      setOuter(() => on = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final snappedX = tester.getCenter(knob).dx;
      expect(snappedX, greaterThan(startX));
    });
  });

  // 5. NocheSheet, showNocheSheet & NocheSheetSwap
  group('5. NocheSheet, showNocheSheet & NocheSheetSwap motion', () {
    testWidgets(
      'sheet slides up in pageIn, scrim fades in move, closes down in pageOut',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: coquiTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: NocheOutlineButton(
                    label: 'Open',
                    onPressed: () {
                      showNocheSheet<void>(
                        context,
                        title: 'Menu',
                        builder: (context, close) => NocheOutlineButton(
                          label: 'Close now',
                          onPressed: close,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pump();

        final surfaceFinder = find.byKey(const ValueKey('noche_sheet_surface'));
        final scrimFinder = find.byKey(const ValueKey('noche_sheet_scrim'));

        // Start (t = 0): translated down by 1.0, scrim at 0.0.
        expect(
          tester.widget<FractionalTranslation>(surfaceFinder).translation.dy,
          closeTo(1.0, 0.01),
        );
        expect(tester.widget<Opacity>(scrimFinder).opacity, closeTo(0.0, 0.01));

        // Middle of pageIn (160ms): sheet mid-slide, scrim > 0.5.
        await tester.pump(NocheMotion.pageIn ~/ 2);
        final midDy = tester
            .widget<FractionalTranslation>(surfaceFinder)
            .translation
            .dy;
        expect(midDy, closeTo(1.0 - NocheMotion.enter.transform(0.5), 0.03));
        expect(tester.widget<Opacity>(scrimFinder).opacity, greaterThan(0.5));

        // At move (220ms): scrim has already reached 1.0!
        await tester.pump(NocheMotion.move - (NocheMotion.pageIn ~/ 2));
        expect(tester.widget<Opacity>(scrimFinder).opacity, closeTo(1.0, 0.01));

        // At pageIn (320ms): sheet settled at dy = 0.0.
        await tester.pump(NocheMotion.pageIn - NocheMotion.move);
        expect(
          tester.widget<FractionalTranslation>(surfaceFinder).translation.dy,
          closeTo(0.0, 0.01),
        );

        // Close: slides down in pageOut (200ms) on exit, scrim fades out in pageOut.
        await tester.tap(find.text('Close now'));
        await tester.pump();
        await tester.pump(NocheMotion.pageOut ~/ 2);
        expect(
          tester.widget<FractionalTranslation>(surfaceFinder).translation.dy,
          closeTo(NocheMotion.exit.transform(0.5), 0.03),
        );
        expect(
          tester.widget<Opacity>(scrimFinder).opacity,
          closeTo(1.0 - NocheMotion.exit.transform(0.5), 0.03),
        );

        await tester.pumpAndSettle();
        expect(find.text('Menu'), findsNothing);
      },
    );

    testWidgets(
      'showNocheSheet reduced motion fades in place without sliding',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: coquiTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: NocheOutlineButton(
                    label: 'Open',
                    onPressed: () {
                      showNocheSheet<void>(
                        context,
                        title: 'Reduced',
                        builder: (context, close) => const Text('Body'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pump();

        final surfaceFinder = find.byKey(const ValueKey('noche_sheet_surface'));
        expect(tester.widget(surfaceFinder), isA<Opacity>());
        expect(
          tester.widget<Opacity>(surfaceFinder).opacity,
          closeTo(0.0, 0.01),
        );

        await tester.pump(NocheMotion.quick ~/ 2);
        final midOpacity = tester.widget<Opacity>(surfaceFinder).opacity;
        expect(midOpacity, greaterThan(0.0));
        expect(midOpacity, lessThan(1.0));

        await tester.pump(NocheMotion.quick);
        expect(
          tester.widget<Opacity>(surfaceFinder).opacity,
          closeTo(1.0, 0.01),
        );
      },
    );

    testWidgets(
      'NocheSheet rows arrive after rowsAfter and NocheSheetSwap keeps exact height',
      (tester) async {
        var step = 0;
        late StateSetter setOuter;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return Align(
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
                        : const [
                            SizedBox(height: 30, child: Text('Short row')),
                          ],
                  ),
                );
              },
            ),
          ),
        );

        // Before rowsAfter (120ms), row 0 is still hidden.
        await tester.pump(const Duration(milliseconds: 60));
        expect(_opacityOfChild(tester, find.text('Row A')), closeTo(0.0, 0.01));
        await tester.pumpAndSettle();
        expect(_opacityOfChild(tester, find.text('Row A')), closeTo(1.0, 0.01));

        final initialHeight = tester.getSize(find.byType(NocheSheet)).height;

        // Trigger in-place swap to shorter content.
        setOuter(() => step = 1);
        await tester.pump();
        expect(tester.getSize(find.byType(NocheSheet)).height, initialHeight);

        // Mid outgoing (70ms < swapAfter 100ms): outgoing fading, incoming still 0.
        await tester.pump(const Duration(milliseconds: 70));
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('noche_sheet_swap_outgoing')),
              )
              .opacity,
          lessThan(1.0),
        );
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('noche_sheet_swap_incoming')),
              )
              .opacity,
          closeTo(0.0, 0.01),
        );
        expect(tester.getSize(find.byType(NocheSheet)).height, initialHeight);

        // After swapAfter + move/2 (210ms): incoming fading in.
        await tester.pump(const Duration(milliseconds: 140));
        final inMid = tester
            .widget<Opacity>(
              find.byKey(const ValueKey('noche_sheet_swap_incoming')),
            )
            .opacity;
        expect(inMid, greaterThan(0.0));
        expect(inMid, lessThan(1.0));

        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('noche_sheet_swap_incoming')),
              )
              .opacity,
          closeTo(1.0, 0.01),
        );
        expect(tester.getSize(find.byType(NocheSheet)).height, initialHeight);
      },
    );
  });

  // 6. NocheDashes
  group('6. NocheDashes motion', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
        'dash transitioning to done fills from start in move on travel ($dir)',
        (tester) async {
          var states = [
            NocheDashState.done,
            NocheDashState.current,
            NocheDashState.notYet,
          ];
          late StateSetter setOuter;
          await tester.pumpWidget(
            _harness(
              textDirection: dir,
              StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return Center(child: NocheDashes(states: states));
                },
              ),
            ),
          );

          setOuter(
            () => states = [
              NocheDashState.done,
              NocheDashState.done,
              NocheDashState.current,
            ],
          );
          await tester.pump();

          final dash1 = find.byKey(const ValueKey('noche_dash_1'));
          final fracFinder = find.descendant(
            of: dash1,
            matching: find.byType(FractionallySizedBox),
          );
          expect(
            tester.widget<FractionallySizedBox>(fracFinder).widthFactor,
            closeTo(0.0, 0.01),
          );

          await tester.pump(NocheMotion.move ~/ 2);
          expect(
            tester.widget<FractionallySizedBox>(fracFinder).widthFactor,
            closeTo(NocheMotion.travel.transform(0.5), 0.03),
          );
          final dashRect = tester.getRect(dash1);
          final fillRect = tester.getRect(
            find.descendant(
              of: fracFinder,
              matching: find.byType(DecoratedBox),
            ),
          );
          if (dir == TextDirection.ltr) {
            expect(fillRect.left, closeTo(dashRect.left, 0.5));
          } else {
            expect(fillRect.right, closeTo(dashRect.right, 0.5));
          }

          await tester.pump(NocheMotion.move);
          // Settled back to plain Container.
          expect(fracFinder, findsNothing);
        },
      );
    }

    testWidgets('reduced motion fades done dash in place at full width', (
      tester,
    ) async {
      var states = [NocheDashState.notYet];
      late StateSetter setOuter;
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Center(child: NocheDashes(states: states));
            },
          ),
        ),
      );

      setOuter(() => states = [NocheDashState.done]);
      await tester.pump();
      final dash0 = find.byKey(const ValueKey('noche_dash_0'));
      final frac = tester.widget<FractionallySizedBox>(
        find.descendant(of: dash0, matching: find.byType(FractionallySizedBox)),
      );
      expect(frac.widthFactor, 1.0);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(of: dash0, matching: find.byType(Opacity)),
            )
            .opacity,
        closeTo(0.0, 0.01),
      );

      await tester.pump(NocheMotion.quick ~/ 2);
      final midOp = tester
          .widget<Opacity>(
            find.descendant(of: dash0, matching: find.byType(Opacity)),
          )
          .opacity;
      expect(midOp, greaterThan(0.0));
      expect(midOp, lessThan(1.0));

      await tester.pump(NocheMotion.quick);
      expect(
        find.descendant(of: dash0, matching: find.byType(Opacity)),
        findsNothing,
      );
    });
  });

  // 7. NocheStageBar & NocheProgressBar
  group('7. NocheStageBar & NocheProgressBar motion', () {
    testWidgets('animateFrom grows once in settle on enter (start, mid, end)', (
      tester,
    ) async {
      await tester.pumpWidget(
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

      final stageFrac = find.descendant(
        of: find.byType(NocheStageBar),
        matching: find.byType(FractionallySizedBox),
      );
      final progFrac = find.descendant(
        of: find.byType(NocheProgressBar),
        matching: find.byType(FractionallySizedBox),
      );

      expect(
        tester.widget<FractionallySizedBox>(stageFrac).widthFactor,
        closeTo(0.25, 0.01),
      );
      expect(
        tester.widget<FractionallySizedBox>(progFrac).widthFactor,
        closeTo(0.2, 0.01),
      );

      await tester.pump(NocheMotion.settle ~/ 2);
      final p = NocheMotion.enter.transform(0.5);
      expect(
        tester.widget<FractionallySizedBox>(stageFrac).widthFactor,
        closeTo(0.25 + 0.75 * p, 0.03),
      );
      expect(
        tester.widget<FractionallySizedBox>(progFrac).widthFactor,
        closeTo(0.2 + 0.6 * p, 0.03),
      );

      await tester.pump(NocheMotion.settle);
      expect(
        tester.widget<FractionallySizedBox>(stageFrac).widthFactor,
        closeTo(1.0, 0.01),
      );
      expect(
        tester.widget<FractionallySizedBox>(progFrac).widthFactor,
        closeTo(0.8, 0.01),
      );
    });

    testWidgets(
      'reduced motion renders target width immediately and fades in quick',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            disableAnimations: true,
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

        final stageFrac = find.descendant(
          of: find.byType(NocheStageBar),
          matching: find.byType(FractionallySizedBox),
        );
        final stageOp = find.descendant(
          of: find.byType(NocheStageBar),
          matching: find.byType(Opacity),
        );
        expect(
          tester.widget<FractionallySizedBox>(stageFrac).widthFactor,
          closeTo(0.75, 0.01),
        );
        expect(tester.widget<Opacity>(stageOp).opacity, closeTo(0.0, 0.01));

        await tester.pump(NocheMotion.quick);
        expect(tester.widget<Opacity>(stageOp).opacity, closeTo(1.0, 0.01));
      },
    );
  });

  // 8. NocheBarChart
  group('8. NocheBarChart motion', () {
    double barClipFraction(WidgetTester tester, int i) {
      final clip = tester.widget<ClipRRect>(
        find.byKey(ValueKey('noche_bar_clip_$i')),
      );
      final rrect = clip.clipper!.getClip(const Size(20, 100));
      return rrect.height / 100.0;
    }

    testWidgets(
      'bars grow from 0 in settle on enter, first 5 stagger and 6th shares 5th start',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            const Center(
              child: NocheBarChart(
                items: [
                  NocheBarItem(label: '1', value: 10),
                  NocheBarItem(label: '2', value: 20),
                  NocheBarItem(label: '3', value: 30),
                  NocheBarItem(label: '4', value: 40),
                  NocheBarItem(label: '5', value: 50),
                  NocheBarItem(label: '6', value: 40),
                ],
              ),
            ),
          ),
        );

        // Start (t = 0): all bars clipped to 0.
        for (var i = 0; i < 6; i++) {
          expect(barClipFraction(tester, i), closeTo(0.0, 0.01));
        }

        // At 150ms: bar 0 > bar 1 > bar 2 > bar 3 > bar 4 == bar 5!
        await tester.pump(const Duration(milliseconds: 150));
        final fracs = [for (var i = 0; i < 6; i++) barClipFraction(tester, i)];
        expect(fracs[0], greaterThan(fracs[1]));
        expect(fracs[1], greaterThan(fracs[2]));
        expect(fracs[2], greaterThan(fracs[3]));
        expect(fracs[3], greaterThan(fracs[4]));
        expect(fracs[5], closeTo(fracs[4], 0.001));

        // End (stagger * 4 + settle = 120 + 480 = 600ms).
        await tester.pump(const Duration(milliseconds: 500));
        for (var i = 0; i < 6; i++) {
          expect(barClipFraction(tester, i), closeTo(1.0, 0.01));
        }
      },
    );

    testWidgets(
      'reduced motion fades all bars together at full height in quick',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            disableAnimations: true,
            const Center(
              child: NocheBarChart(
                items: [
                  NocheBarItem(label: '1', value: 10),
                  NocheBarItem(label: '2', value: 20),
                  NocheBarItem(label: '3', value: 30),
                ],
              ),
            ),
          ),
        );

        for (var i = 0; i < 3; i++) {
          expect(barClipFraction(tester, i), closeTo(1.0, 0.001));
          expect(
            _opacityOfChild(tester, find.byKey(ValueKey('noche_bar_clip_$i'))),
            closeTo(0.0, 0.01),
          );
        }

        await tester.pump(NocheMotion.quick ~/ 2);
        final o0 = _opacityOfChild(
          tester,
          find.byKey(const ValueKey('noche_bar_clip_0')),
        );
        final o2 = _opacityOfChild(
          tester,
          find.byKey(const ValueKey('noche_bar_clip_2')),
        );
        expect(o0, greaterThan(0.0));
        expect(o0, closeTo(o2, 0.001));

        await tester.pump(NocheMotion.quick);
        for (var i = 0; i < 3; i++) {
          expect(
            _opacityOfChild(tester, find.byKey(ValueKey('noche_bar_clip_$i'))),
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
      (tester) async {
        var state = NocheMicState.ready;
        late StateSetter setOuter;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return Center(
                  child: NocheMic.custom(
                    state: state,
                    micWords: _micWords,
                    level: 0.6,
                  ),
                );
              },
            ),
          ),
        );

        BoxDecoration discDec() =>
            tester
                    .widget<Container>(
                      find.byKey(const ValueKey('noche_mic_disc')),
                    )
                    .decoration!
                as BoxDecoration;

        // Initial mount on ready: no loops running, no halo.
        expect(tester.hasRunningAnimations, isFalse);
        expect(discDec().boxShadow, isNull);

        // ready -> listening: halo grows 0 -> 8 in move; mic color animates in quick; level bars loop.
        setOuter(() => state = NocheMicState.listening);
        await tester.pump();
        final barStart0Frame0 = tester
            .getSize(find.byKey(const ValueKey('noche_mic_bar_start_2')))
            .height;

        await tester.pump(NocheMotion.move ~/ 2);
        final midSpread = discDec().boxShadow!.single.spreadRadius;
        expect(midSpread, greaterThan(0.0));
        expect(midSpread, lessThan(8.0));

        // Bars are looping and modulating smoothly within 8..56.
        final barStart0Mid = tester
            .getSize(find.byKey(const ValueKey('noche_mic_bar_start_2')))
            .height;
        expect(barStart0Mid, isNot(closeTo(barStart0Frame0, 0.1)));
        expect(barStart0Mid, inInclusiveRange(8.0, 56.0));

        await tester.pump(NocheMotion.move);
        expect(discDec().boxShadow!.single.spreadRadius, closeTo(8.0, 0.01));
        expect(discDec().color, NocheColors.listening);

        // listening -> thinking: dots pulse in thinkingCycle; bars stopped.
        setOuter(() => state = NocheMicState.thinking);
        await tester.pump();
        await tester.pump(NocheMotion.quick);
        expect(discDec().color, NocheColors.otherSoft);
        expect(tester.hasRunningAnimations, isTrue);

        final dot0Finder = find.byKey(
          const ValueKey('noche_mic_thinking_dot_0'),
        );
        final opA = _opacityOfChild(tester, dot0Finder);
        await tester.pump(NocheMotion.thinkingCycle ~/ 3);
        final opB = _opacityOfChild(tester, dot0Finder);
        expect(opA, isNot(closeTo(opB, 0.05)));

        // thinking -> right: right ring expands 1.0 -> 1.5 and fades 0.9 -> 0 in settle once.
        setOuter(() => state = NocheMicState.right);
        await tester.pump();
        final ringFinder = find.byKey(const ValueKey('noche_mic_right_ring'));
        expect(ringFinder, findsOneWidget);

        await tester.pump(NocheMotion.settle ~/ 2);
        final ringTransform = find
            .ancestor(of: ringFinder, matching: find.byType(Transform))
            .first;
        final midRingScale = _scaleOf(tester, ringTransform);
        final midRingOpacity = _opacityOfChild(tester, ringFinder);
        expect(midRingScale, greaterThan(1.0));
        expect(midRingScale, lessThan(1.5));
        expect(midRingOpacity, greaterThan(0.0));
        expect(midRingOpacity, lessThan(0.9));

        await tester.pump(NocheMotion.settle);
        // Right ring finished and all loops stopped!
        expect(ringFinder, findsNothing);
        expect(tester.hasRunningAnimations, isFalse);

        // right -> notYet: draws 2 px text border in quick, no fill when settled.
        setOuter(() => state = NocheMicState.notYet);
        await tester.pump();
        await tester.pump(NocheMotion.quick);
        await tester.pump(const Duration(milliseconds: 1));
        expect(discDec().color, isNull);
        expect((discDec().border! as Border).top.color, NocheColors.text);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets(
      'reduced motion stops all loops, disables right ring, and holds still bars at level 0.5 when level == 0',
      (tester) async {
        var state = NocheMicState.listening;
        late StateSetter setOuter;
        await tester.pumpWidget(
          _harness(
            disableAnimations: true,
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return Center(
                  child: NocheMic.custom(
                    state: state,
                    micWords: _micWords,
                    level: 0.0,
                  ),
                );
              },
            ),
          ),
        );

        expect(tester.hasRunningAnimations, isFalse);
        final expectedStill = NocheMic.barHeightsForLevel(0.5, startSide: true);
        for (var i = 0; i < 5; i++) {
          expect(
            tester
                .getSize(find.byKey(ValueKey('noche_mic_bar_start_$i')))
                .height,
            closeTo(expectedStill[i], 0.01),
          );
        }

        // Thinking in reduced motion: no loop, all 3 dots at opacity 1.0.
        setOuter(() => state = NocheMicState.thinking);
        await tester.pump();
        await tester.pump(NocheMotion.quick);
        await tester.pump(const Duration(milliseconds: 1));
        expect(tester.hasRunningAnimations, isFalse);
        for (var i = 0; i < 3; i++) {
          expect(
            _opacityOfChild(
              tester,
              find.byKey(ValueKey('noche_mic_thinking_dot_$i')),
            ),
            closeTo(1.0, 0.01),
          );
        }

        // Right in reduced motion: no expanding ring.
        setOuter(() => state = NocheMicState.right);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('noche_mic_right_ring')),
          findsNothing,
        );
      },
    );
  });

  // 10. NocheOutlineGroup
  group('10. NocheOutlineGroup motion', () {
    testWidgets('vertical outline mark slides in move on travel', (
      tester,
    ) async {
      var selected = 'es';
      late StateSetter setOuter;
      await tester.pumpWidget(
        _harness(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Center(
                child: NocheOutlineGroup<String>(
                  axis: Axis.vertical,
                  selected: selected,
                  onChanged: (v) => setState(() => selected = v),
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
              );
            },
          ),
        ),
      );

      final mark = find.byKey(const ValueKey('noche_outline_group_mark'));
      final startY = tester.getTopLeft(mark).dy;

      setOuter(() => selected = 'ar');
      await tester.pump();
      expect(tester.getTopLeft(mark).dy, closeTo(startY, 0.01));

      await tester.pump(NocheMotion.move ~/ 2);
      final midY = tester.getTopLeft(mark).dy;

      await tester.pump(NocheMotion.move);
      final endY = tester.getTopLeft(mark).dy;
      expect(endY, greaterThan(startY));
      expect(
        midY,
        closeTo(
          startY + (endY - startY) * NocheMotion.travel.transform(0.5),
          1,
        ),
      );
    });

    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets('horizontal outline mark slides in move on travel ($dir)', (
        tester,
      ) async {
        var selected = 'a';
        late StateSetter setOuter;
        await tester.pumpWidget(
          _harness(
            textDirection: dir,
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return Center(
                  child: NocheOutlineGroup<String>(
                    axis: Axis.horizontal,
                    selected: selected,
                    onChanged: (v) => setState(() => selected = v),
                    options: const [
                      NocheOutlineOption(
                        value: 'a',
                        child: SizedBox(height: 64, child: Text('Font A')),
                      ),
                      NocheOutlineOption(
                        value: 'b',
                        child: SizedBox(height: 64, child: Text('Font B')),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        final mark = find.byKey(const ValueKey('noche_outline_group_mark'));
        final startX = tester.getCenter(mark).dx;

        setOuter(() => selected = 'b');
        await tester.pump();
        await tester.pump(NocheMotion.move ~/ 2);
        final midX = tester.getCenter(mark).dx;

        await tester.pump(NocheMotion.move);
        final endX = tester.getCenter(mark).dx;

        if (dir == TextDirection.ltr) {
          expect(endX, greaterThan(startX));
        } else {
          expect(endX, lessThan(startX));
        }
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
      tester,
    ) async {
      var selected = 'a';
      late StateSetter setOuter;
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Center(
                child: NocheOutlineGroup<String>(
                  axis: Axis.horizontal,
                  selected: selected,
                  onChanged: (v) => setState(() => selected = v),
                  options: const [
                    NocheOutlineOption(
                      value: 'a',
                      child: SizedBox(height: 64, child: Text('Font A')),
                    ),
                    NocheOutlineOption(
                      value: 'b',
                      child: SizedBox(height: 64, child: Text('Font B')),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      final mark = find.byKey(const ValueKey('noche_outline_group_mark'));
      final startX = tester.getCenter(mark).dx;

      setOuter(() => selected = 'b');
      await tester.pump();
      expect(tester.getCenter(mark).dx, greaterThan(startX));
      expect(_opacityOfChild(tester, mark), closeTo(0.0, 0.01));

      await tester.pump(NocheMotion.quick);
      expect(_opacityOfChild(tester, mark), closeTo(1.0, 0.01));
    });
  });

  // 11. TouchSign
  group('11. TouchSign motion', () {
    testWidgets(
      'rises and falls on travel with no overshoot and stands still in reduced motion',
      (tester) async {
        await tester.pumpWidget(_harness(const Center(child: TouchSign())));

        final transformFinder = find.descendant(
          of: find.byType(TouchSign),
          matching: find.byType(Transform),
        );

        // Start at 0.
        expect(_translateY(tester, transformFinder), closeTo(0.0, 0.01));

        // Mid-rise (settle ~/ 2): matches travel curve.
        await tester.pump(NocheMotion.settle ~/ 2);
        expect(
          _translateY(tester, transformFinder),
          closeTo(-TouchSign.bounce * NocheMotion.travel.transform(0.5), 0.1),
        );

        // Peak (settle): reaches -TouchSign.bounce, never overshoots.
        await tester.pump(NocheMotion.settle - (NocheMotion.settle ~/ 2));
        final peak = _translateY(tester, transformFinder);
        expect(peak, closeTo(-TouchSign.bounce, 0.05));
        expect(peak, greaterThanOrEqualTo(-TouchSign.bounce));

        // Full return (settle * 2): back to 0.
        await tester.pump(NocheMotion.settle);
        expect(_translateY(tester, transformFinder), closeTo(0.0, 0.05));

        // Reduced motion: does not move at all.
        await tester.pumpWidget(
          _harness(disableAnimations: true, const Center(child: TouchSign())),
        );
        await tester.pump(NocheMotion.settle ~/ 2);
        expect(_translateY(tester, transformFinder), 0.0);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );
  });

  // 12. NocheArrive
  group('12. NocheArrive motion', () {
    testWidgets(
      'staggers first 5 rows, 6th shares 5th start, next lands nextDelay after last staggered row',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            NocheArrive(
              delay: NocheMotion.rowsAfter,
              next: const Text('Next'),
              children: [for (var i = 0; i < 6; i++) Text('Row $i')],
            ),
          ),
        );

        Finder itemFinder(int i) =>
            find.byKey(ValueKey('noche_arrive_item_$i'));
        final nextFinder = find.byKey(const ValueKey('noche_arrive_next'));

        // Before delay (60ms < 120ms): all at dy == row (8), opacity == 0.
        await tester.pump(const Duration(milliseconds: 60));
        for (var i = 0; i < 6; i++) {
          expect(
            _translateY(tester, itemFinder(i)),
            closeTo(NocheMotion.row, 0.01),
          );
          expect(
            _opacityOfChild(tester, find.text('Row $i')),
            closeTo(0.0, 0.01),
          );
        }
        expect(_translateY(tester, nextFinder), closeTo(NocheMotion.row, 0.01));

        // At 260ms (rowsAfter 120 + stagger*4 120 + 20ms):
        // Row 0..4 are strictly descending in progress; Row 5 == Row 4; Next starts at 120+120+80=320ms so still 0!
        await tester.pump(const Duration(milliseconds: 200));
        final ops = [
          for (var i = 0; i < 6; i++)
            _opacityOfChild(tester, find.text('Row $i')),
        ];
        expect(ops[0], greaterThan(ops[1]));
        expect(ops[1], greaterThan(ops[2]));
        expect(ops[2], greaterThan(ops[3]));
        expect(ops[3], greaterThan(ops[4]));
        expect(ops[4], greaterThan(0.0));
        expect(ops[5], closeTo(ops[4], 0.001));
        expect(_opacityOfChild(tester, find.text('Next')), closeTo(0.0, 0.01));

        // At 430ms (next started at 320ms, so 110ms into move): Next is mid-rise.
        await tester.pump(const Duration(milliseconds: 170));
        final nextOp = _opacityOfChild(tester, find.text('Next'));
        expect(nextOp, closeTo(NocheMotion.enter.transform(0.5), 0.03));
        expect(
          _translateY(tester, nextFinder),
          closeTo(
            NocheMotion.row * (1.0 - NocheMotion.enter.transform(0.5)),
            0.3,
          ),
        );

        // End: all settled at opacity 1.0, dy 0.0.
        await tester.pumpAndSettle();
        for (var i = 0; i < 6; i++) {
          expect(_translateY(tester, itemFinder(i)), closeTo(0.0, 0.01));
          expect(
            _opacityOfChild(tester, find.text('Row $i')),
            closeTo(1.0, 0.01),
          );
        }
        expect(_translateY(tester, nextFinder), closeTo(0.0, 0.01));
        expect(_opacityOfChild(tester, find.text('Next')), closeTo(1.0, 0.01));
      },
    );

    testWidgets('reduced motion arrives all together with dy == 0 in quick', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          const NocheArrive(
            next: Text('Next'),
            children: [Text('Row 0'), Text('Row 1'), Text('Row 2')],
          ),
        ),
      );

      await tester.pump(NocheMotion.quick ~/ 2);
      final o0 = _opacityOfChild(tester, find.text('Row 0'));
      final o2 = _opacityOfChild(tester, find.text('Row 2'));
      final oNext = _opacityOfChild(tester, find.text('Next'));
      expect(o0, greaterThan(0.0));
      expect(o0, closeTo(o2, 0.001));
      expect(o0, closeTo(oNext, 0.001));
      expect(
        _translateY(tester, find.byKey(const ValueKey('noche_arrive_item_0'))),
        0.0,
      );
      expect(
        _translateY(tester, find.byKey(const ValueKey('noche_arrive_next'))),
        0.0,
      );

      await tester.pump(NocheMotion.quick);
      expect(_opacityOfChild(tester, find.text('Next')), closeTo(1.0, 0.01));
    });
  });

  // 13. NocheFollow
  group('13. NocheFollow motion', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      for (final side in NocheFollowSide.values) {
        testWidgets(
          'old fades in press, new enters from $side in $dir after followAfter',
          (tester) async {
            var key = 0;
            late StateSetter setOuter;
            await tester.pumpWidget(
              _harness(
                textDirection: dir,
                StatefulBuilder(
                  builder: (context, setState) {
                    setOuter = setState;
                    return NocheFollow(
                      contentKey: key,
                      side: side,
                      distance: NocheMotion.page,
                      child: Text('View $key'),
                    );
                  },
                ),
              ),
            );

            final incoming = find.byKey(
              const ValueKey('noche_follow_incoming'),
            );
            expect(_translateX(tester, incoming), 0.0);

            setOuter(() => key = 1);
            await tester.pump();

            // During followAfter (30ms < 60ms): outgoing fading, incoming hidden at +/-distance.
            await tester.pump(const Duration(milliseconds: 30));
            final outgoing = find.byKey(
              const ValueKey('noche_follow_outgoing'),
            );
            expect(outgoing, findsOneWidget);
            expect(tester.widget<Opacity>(outgoing).opacity, lessThan(1.0));
            expect(
              _opacityOfChild(tester, find.text('View 1')),
              closeTo(0.0, 0.01),
            );

            final expectedSign = (dir == TextDirection.ltr)
                ? (side == NocheFollowSide.end ? 1.0 : -1.0)
                : (side == NocheFollowSide.end ? -1.0 : 1.0);
            expect(
              _translateX(tester, incoming),
              closeTo(expectedSign * NocheMotion.page, 0.01),
            );

            // At followAfter + move/2 (170ms): outgoing gone (>= 90ms press), incoming mid-slide.
            await tester.pump(const Duration(milliseconds: 140));
            expect(outgoing, findsNothing);
            final p = NocheMotion.enter.transform(0.5);
            expect(
              _translateX(tester, incoming),
              closeTo(expectedSign * NocheMotion.page * (1.0 - p), 0.8),
            );
            expect(
              _opacityOfChild(tester, find.text('View 1')),
              closeTo(p, 0.03),
            );

            await tester.pumpAndSettle();
            expect(_translateX(tester, incoming), closeTo(0.0, 0.01));
            expect(
              _opacityOfChild(tester, find.text('View 1')),
              closeTo(1.0, 0.01),
            );
          },
        );
      }
    }

    testWidgets('reduced motion has zero horizontal offset', (tester) async {
      var key = 0;
      late StateSetter setOuter;
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return NocheFollow(
                contentKey: key,
                distance: NocheMotion.page,
                child: Text('View $key'),
              );
            },
          ),
        ),
      );

      setOuter(() => key = 1);
      await tester.pump();
      await tester.pump(NocheMotion.followAfter + (NocheMotion.quick ~/ 2));
      final incoming = find.byKey(const ValueKey('noche_follow_incoming'));
      expect(_translateX(tester, incoming), 0.0);
      final op = _opacityOfChild(tester, find.text('View 1'));
      expect(op, greaterThan(0.0));
      expect(op, lessThan(1.0));

      await tester.pumpAndSettle();
      expect(_opacityOfChild(tester, find.text('View 1')), closeTo(1.0, 0.01));
    });
  });

  // 14. NocheWindow
  group('14. NocheWindow motion', () {
    testWidgets(
      'single-screen rect, borderRadius, pictureOffset animate together in pageIn/pageOut without scaling child',
      (tester) async {
        var expanded = false;
        late StateSetter setOuter;
        const pictureKey = ValueKey('unscaled_pic');

        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return Stack(
                  children: [
                    NocheWindow(
                      rect: expanded
                          ? const Rect.fromLTWH(20, 40, 300, 180)
                          : const Rect.fromLTWH(40, 100, 140, 100),
                      borderRadius: expanded ? 8 : 24,
                      pictureOffset: expanded
                          ? Offset.zero
                          : const Offset(-40, -20),
                      pictureSize: const Size(320, 200),
                      leaving: !expanded,
                      child: const SizedBox(
                        key: pictureKey,
                        width: 320,
                        height: 200,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        final surface = find.byKey(const ValueKey('noche_window_surface'));
        expect(tester.getRect(surface), const Rect.fromLTWH(40, 100, 140, 100));
        expect(tester.getSize(find.byKey(pictureKey)), const Size(320, 200));

        // Expand (pageIn = 320ms).
        setOuter(() => expanded = true);
        await tester.pump();
        await tester.pump(NocheMotion.pageIn ~/ 2);
        final p = NocheMotion.enter.transform(0.5);
        final midRect = tester.getRect(surface);
        expect(midRect.width, closeTo(140 + (300 - 140) * p, 2.0));
        expect(midRect.height, closeTo(100 + (180 - 100) * p, 2.0));
        // Child size NEVER scales!
        expect(tester.getSize(find.byKey(pictureKey)), const Size(320, 200));

        await tester.pump(NocheMotion.pageIn);
        expect(tester.getRect(surface), const Rect.fromLTWH(20, 40, 300, 180));
        expect(tester.getSize(find.byKey(pictureKey)), const Size(320, 200));

        // Collapse (leaving: true -> pageOut = 200ms).
        setOuter(() => expanded = false);
        await tester.pump();
        await tester.pump(NocheMotion.pageOut ~/ 2);
        final outMidRect = tester.getRect(surface);
        expect(outMidRect.width, closeTo(300 + (140 - 300) * p, 2.0));
        expect(tester.getSize(find.byKey(pictureKey)), const Size(320, 200));

        await tester.pump(NocheMotion.pageOut);
        expect(tester.getRect(surface), const Rect.fromLTWH(40, 100, 140, 100));
      },
    );

    testWidgets('single-screen reduced motion snaps rect and fades in quick', (
      tester,
    ) async {
      var expanded = false;
      late StateSetter setOuter;
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Stack(
                children: [
                  NocheWindow(
                    rect: expanded
                        ? const Rect.fromLTWH(20, 40, 300, 180)
                        : const Rect.fromLTWH(40, 100, 140, 100),
                    pictureSize: const Size(320, 200),
                    child: const SizedBox(width: 320, height: 200),
                  ),
                ],
              );
            },
          ),
        ),
      );

      final surface = find.byKey(const ValueKey('noche_window_surface'));
      setOuter(() => expanded = true);
      await tester.pump();
      expect(tester.getRect(surface), const Rect.fromLTWH(20, 40, 300, 180));
      expect(_opacityOfChild(tester, surface), closeTo(0.0, 0.01));

      await tester.pump(NocheMotion.quick);
      expect(_opacityOfChild(tester, surface), closeTo(1.0, 0.01));
    });

    testWidgets(
      'cross-screen tag transition flies rect on push and pop while keeping child unscaled',
      (tester) async {
        const tag = 'story_hero';
        const picKey = ValueKey('hero_pic');

        await tester.pumpWidget(
          MaterialApp(
            theme: coquiTheme(),
            home: Builder(
              builder: (context) => Scaffold(
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
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            PageRouteBuilder<void>(
                              transitionDuration: NocheMotion.pageIn,
                              reverseTransitionDuration: NocheMotion.pageOut,
                              pageBuilder: (c, a, sa) => Scaffold(
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
                                        onPressed: () => Navigator.of(c).pop(),
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
                              transitionsBuilder: (c, a, sa, child) =>
                                  FadeTransition(opacity: a, child: child),
                            ),
                          );
                        },
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

        final surface = find.byKey(NocheWindow.surfaceKey(tag));
        final rectA = tester.getRect(surface);
        expect(rectA.size, const Size(140, 90));

        // Push second route.
        await tester.tap(find.byType(NocheWindow));
        await tester.pump();
        await tester.pump(NocheMotion.pageIn ~/ 2);
        final pushMidRect = tester.getRect(surface);
        expect(pushMidRect.width, greaterThan(140));
        expect(pushMidRect.width, lessThan(360));
        expect(pushMidRect.height, greaterThan(90));
        expect(pushMidRect.height, lessThan(220));
        expect(tester.getSize(find.byKey(picKey)), const Size(360, 220));

        await tester.pumpAndSettle();
        final rectB = tester.getRect(surface);
        expect(rectB.size, const Size(360, 220));

        // Pop back to first route.
        await tester.tap(find.byType(NocheWindow));
        await tester.pump();
        await tester.pump(NocheMotion.pageOut ~/ 2);
        final popMidRect = tester.getRect(surface);
        expect(popMidRect.width, greaterThan(140));
        expect(popMidRect.width, lessThan(360));
        expect(tester.getSize(find.byKey(picKey)), const Size(360, 220));

        await tester.pumpAndSettle();
        expect(tester.getRect(surface), rectA);
      },
    );

    testWidgets(
      'cross-screen tag under reduced motion does not mount Hero / does not fly',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            disableAnimations: true,
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
        final surface = find.byKey(NocheWindow.surfaceKey('reduced_tag'));
        expect(_opacityOfChild(tester, surface), closeTo(0.0, 0.01));
        await tester.pump(NocheMotion.quick);
        expect(_opacityOfChild(tester, surface), closeTo(1.0, 0.01));
      },
    );
  });

  // 15. NocheQuietLock
  group('15. NocheQuietLock motion', () {
    testWidgets(
      'tap brightens in press, holds lockHold, returns in move; active: false ignores taps',
      (tester) async {
        Color? seenColor;
        var taps = 0;

        await tester.pumpWidget(
          _harness(
            Center(
              child: NocheQuietLock(
                onTap: () => taps++,
                builder: (context, reasonColor) {
                  seenColor = reasonColor;
                  return Text('Locked', style: TextStyle(color: reasonColor));
                },
              ),
            ),
          ),
        );

        expect(seenColor, NocheColors.label);

        await tester.tap(find.text('Locked'));
        await tester.pump();
        expect(taps, 1);

        // Mid-press (45ms): between label and text.
        await tester.pump(NocheMotion.press ~/ 2);
        expect(seenColor, isNot(NocheColors.label));
        expect(seenColor, isNot(NocheColors.text));

        // End of press (90ms): full text brightness.
        await tester.pump(NocheMotion.press - (NocheMotion.press ~/ 2));
        expect(seenColor, NocheColors.text);

        // During lockHold (e.g. +700ms): stays full text brightness.
        await tester.pump(NocheMotion.lockHold ~/ 2);
        expect(seenColor, NocheColors.text);

        // End of lockHold (+700ms): still at text.
        await tester.pump(NocheMotion.lockHold - (NocheMotion.lockHold ~/ 2));
        expect(seenColor, NocheColors.text);

        // Mid-return (+110ms = move/2): dimming back.
        await tester.pump(NocheMotion.move ~/ 2);
        expect(seenColor, isNot(NocheColors.text));
        expect(seenColor, isNot(NocheColors.label));

        // End of return (+110ms): back to label.
        await tester.pump(NocheMotion.move);
        expect(seenColor, NocheColors.label);

        // active: false ignores taps.
        await tester.pumpWidget(
          _harness(
            Center(
              child: NocheQuietLock(
                active: false,
                onTap: () => taps++,
                builder: (context, reasonColor) => const Text('Inactive lock'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Inactive lock'));
        await tester.pump();
        expect(taps, 1);
      },
    );

    testWidgets('reduced motion holds same timing in place', (tester) async {
      Color? seenColor;
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          Center(
            child: NocheQuietLock(
              builder: (context, reasonColor) {
                seenColor = reasonColor;
                return const Text('Locked');
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Locked'));
      await tester.pump();
      await tester.pump(NocheMotion.reduced.press);
      expect(seenColor, NocheColors.text);

      await tester.pump(NocheMotion.reduced.lockHold);
      expect(seenColor, NocheColors.text);

      await tester.pump(NocheMotion.reduced.move);
      expect(seenColor, NocheColors.label);
    });
  });

  // 16. NocheLtr
  group('16. NocheLtr', () {
    testWidgets('forces TextDirection.ltr inside an RTL parent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          textDirection: TextDirection.rtl,
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
        tester.getCenter(find.text('First')).dx,
        lessThan(tester.getCenter(find.text('Second')).dx),
      );
    });
  });

  // 17. Gallery test: NocheMotionDevPage
  group('17. NocheMotionDevPage gallery', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets('renders cleanly in $dir and interactive controls respond', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: coquiTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Scaffold(body: NocheMotionDevPage(textDirection: dir)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Speaking'));
        await tester.pumpAndSettle();
        expect(find.text('Active panel: speaking'), findsOneWidget);

        await tester.tap(find.text('El parque'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
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
        final src = file.readAsStringSync();
        final matches = rawMotionRe.allMatches(src).toList();
        expect(
          matches.map((m) => m.group(0)).toList(),
          isEmpty,
          reason: '${file.path} contains raw Duration(, Curves., or Cubic(',
        );
      }
    });

    test('zero coqui_contracts imports and zero left/right/raw tokens in Noche motion files', () {
      const noContractsFiles = [
        'lib/src/noche_motion_pieces.dart',
        'lib/src/noche_chrome.dart',
        'lib/src/noche_controls.dart',
        'lib/src/noche_data.dart',
        'tool/gallery/noche_pieces.dart',
      ];
      for (final path in noContractsFiles) {
        final src = File(path).readAsStringSync();
        expect(
          src.contains('package:coqui_contracts/'),
          isFalse,
          reason: '$path must not import coqui_contracts',
        );
      }

      final piecesSrc = File('lib/src/noche_motion_pieces.dart')
          .readAsStringSync();
      expect(
        RegExp(r'\b(left|right)\b', caseSensitive: false).allMatches(piecesSrc),
        isEmpty,
        reason: 'noche_motion_pieces.dart contains left/right',
      );
      expect(
        RegExp(r'Color\s*\(\s*0x').allMatches(piecesSrc),
        isEmpty,
        reason: 'noche_motion_pieces.dart contains raw Color(0x...)',
      );
      expect(
        RegExp(r'\bfontFamily\b').allMatches(piecesSrc),
        isEmpty,
        reason: 'noche_motion_pieces.dart contains fontFamily',
      );
    });
  });

  // 19. Review regression tests
  group('19. Review regression tests', () {
    testWidgets(
      'NocheSheetSwap preserves mounted outgoing State without remounting, isolates incoming State, and keeps exact fixed height for shorter and taller content',
      (tester) async {
        final initCounts = <String, int>{};
        final createdWithLabel = <String, String>{};
        var step = 'A';
        late StateSetter setOuter;

        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                final double h = switch (step) {
                  'A' => 140,
                  'B' => 48, // shorter than initial
                  _ => 320, // taller than initial
                };
                return Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: NocheSheet(
                    title: 'Swap regression',
                    respectSafeArea: false,
                    scrollable: false,
                    contentKey: step,
                    child: _SwapStateProbe(
                      id: step,
                      height: h,
                      initCounts: initCounts,
                      createdWithLabel: createdWithLabel,
                    ),
                  ),
                );
              },
            ),
          ),
        );

        expect(initCounts['A'], 1);
        final initialSheetHeight = tester
            .getSize(find.byType(NocheSheet))
            .height;

        // Swap A -> B (shorter): A must NOT be remounted while fading out,
        // B must get a brand-new State (no leaked initialId from A),
        // and sheet height stays strictly fixed.
        setOuter(() => step = 'B');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(initCounts['A'], 1);
        expect(initCounts['B'], 1);
        expect(createdWithLabel['B'], 'B');
        expect(
          tester.getSize(find.byType(NocheSheet)).height,
          initialSheetHeight,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        expect(initCounts['A'], 1);
        expect(initCounts['B'], 1);
        expect(
          tester.getSize(find.byType(NocheSheet)).height,
          initialSheetHeight,
        );
        expect(tester.takeException(), isNull);

        // Swap B -> C (taller than initial): height STILL stays strictly fixed
        // with zero overflow exceptions!
        setOuter(() => step = 'C');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(initCounts['B'], 1);
        expect(initCounts['C'], 1);
        expect(createdWithLabel['C'], 'C');
        expect(
          tester.getSize(find.byType(NocheSheet)).height,
          initialSheetHeight,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(NocheSheet)).height,
          initialSheetHeight,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'showNocheSheet rapid double-tap on scrim during reverse animation does not pop underlying route',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: coquiTheme(),
            home: Builder(
              builder: (homeContext) => Scaffold(
                body: Center(
                  child: NocheOutlineButton(
                    label: 'Go to detail',
                    onPressed: () {
                      Navigator.of(homeContext).push<void>(
                        MaterialPageRoute<void>(
                          builder: (detailContext) => Scaffold(
                            body: Center(
                              child: NocheOutlineButton(
                                label: 'Open sheet',
                                onPressed: () {
                                  showNocheSheet<void>(
                                    detailContext,
                                    title: 'Sheet',
                                    builder: (c, close) => const SizedBox(
                                      height: 120,
                                      child: Text('Sheet content'),
                                    ),
                                  );
                                },
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
        );

        await tester.tap(find.text('Go to detail'));
        await tester.pumpAndSettle();
        expect(find.text('Open sheet'), findsOneWidget);

        await tester.tap(find.text('Open sheet'));
        await tester.pumpAndSettle();
        expect(find.text('Sheet content'), findsOneWidget);

        // First tap on scrim starts dismissing the sheet.
        await tester.tapAt(const Offset(195, 40));
        await tester.pump();
        // Rapid second tap on scrim halfway through reverse animation.
        await tester.pump(NocheMotion.pageOut ~/ 2);
        await tester.tapAt(const Offset(195, 40));
        await tester.pumpAndSettle();

        // Sheet is closed, and Detail route is STILL visible (not popped!).
        expect(find.text('Sheet content'), findsNothing);
        expect(find.text('Open sheet'), findsOneWidget);
      },
    );

    for (final reduced in [false, true]) {
      testWidgets(
        'NocheBarChart growing items from 2 to 6 after settling renders all 6 bars at full height (reduced: $reduced)',
        (tester) async {
          var items = const [
            NocheBarItem(label: '1', value: 10),
            NocheBarItem(label: '2', value: 20),
          ];
          late StateSetter setOuter;

          await tester.pumpWidget(
            _harness(
              disableAnimations: reduced,
              StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return Center(child: NocheBarChart(items: items));
                },
              ),
            ),
          );

          await tester.pumpAndSettle();

          setOuter(
            () => items = const [
              NocheBarItem(label: '1', value: 10),
              NocheBarItem(label: '2', value: 20),
              NocheBarItem(label: '3', value: 30),
              NocheBarItem(label: '4', value: 40),
              NocheBarItem(label: '5', value: 50),
              NocheBarItem(label: '6', value: 25),
            ],
          );
          await tester.pump();

          for (var i = 0; i < 6; i++) {
            final clipFinder = find.byKey(ValueKey('noche_bar_clip_$i'));
            final clip = tester.widget<ClipRRect>(clipFinder);
            final rrect = clip.clipper!.getClip(const Size(20, 100));
            expect(rrect.height, closeTo(100.0, 0.01));
            if (reduced) {
              expect(_opacityOfChild(tester, clipFinder), closeTo(1.0, 0.01));
            }
          }
        },
      );
    }

    testWidgets(
      'NocheBarChart growing items mid-flight still finishes all 6 bars to 1.0',
      (tester) async {
        var items = const [
          NocheBarItem(label: '1', value: 10),
          NocheBarItem(label: '2', value: 20),
        ];
        late StateSetter setOuter;

        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return Center(child: NocheBarChart(items: items));
              },
            ),
          ),
        );

        await tester.pump(NocheMotion.settle ~/ 2);
        setOuter(
          () => items = const [
            NocheBarItem(label: '1', value: 10),
            NocheBarItem(label: '2', value: 20),
            NocheBarItem(label: '3', value: 30),
            NocheBarItem(label: '4', value: 40),
            NocheBarItem(label: '5', value: 50),
            NocheBarItem(label: '6', value: 25),
          ],
        );
        await tester.pumpAndSettle();

        for (var i = 0; i < 6; i++) {
          final clip = tester.widget<ClipRRect>(
            find.byKey(ValueKey('noche_bar_clip_$i')),
          );
          final rrect = clip.clipper!.getClip(const Size(20, 100));
          expect(rrect.height, closeTo(100.0, 0.01));
        }
      },
    );

    for (final reduced in [false, true]) {
      testWidgets(
        'NocheArrive growing children after initial entrance renders new children at opacity 1.0 and dy 0 (reduced: $reduced)',
        (tester) async {
          var count = 2;
          var includeNext = false;
          late StateSetter setOuter;

          await tester.pumpWidget(
            _harness(
              disableAnimations: reduced,
              StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return NocheArrive(
                    next: includeNext ? const Text('Added next') : null,
                    children: [for (var i = 0; i < count; i++) Text('Item $i')],
                  );
                },
              ),
            ),
          );

          await tester.pumpAndSettle();

          setOuter(() {
            count = 6;
            includeNext = true;
          });
          await tester.pump();

          for (var i = 0; i < 6; i++) {
            expect(
              _translateY(tester, find.byKey(ValueKey('noche_arrive_item_$i'))),
              closeTo(0.0, 0.01),
            );
            expect(
              _opacityOfChild(tester, find.text('Item $i')),
              closeTo(1.0, 0.01),
            );
          }
          expect(
            _translateY(
              tester,
              find.byKey(const ValueKey('noche_arrive_next')),
            ),
            closeTo(0.0, 0.01),
          );
          expect(
            _opacityOfChild(tester, find.text('Added next')),
            closeTo(1.0, 0.01),
          );
        },
      );
    }
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Text('Probe ${widget.id} (init=$_initialId)'),
    );
  }
}
