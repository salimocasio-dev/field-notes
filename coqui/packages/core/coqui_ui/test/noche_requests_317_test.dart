import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

void main() {
  group('NochePlayDisc icon cross-fade', () {
    testWidgets(
      'swapping play to pause cross-fades both icons in NocheMotion.quick',
      (t) async {
        var icon = NocheIcons.play;
        final set = await _pumpState(
          t,
          (c, s) => Center(
            child: NochePlayDisc(
              icon: icon,
              semanticLabel: 'Listen',
              onPressed: () {},
            ),
          ),
        );

        expect(find.byType(NocheIcon), findsOneWidget);
        expect(
          t.widget<NocheIcon>(find.byType(NocheIcon)).data,
          NocheIcons.play,
        );

        set(() => icon = NocheIcons.pause);
        await t.pump();
        await t.pump(NocheMotion.quick ~/ 2);

        final midIcons = t
            .widgetList<NocheIcon>(find.byType(NocheIcon))
            .toList();
        expect(midIcons.length, 2);
        expect(
          midIcons.map((i) => i.data),
          containsAll([NocheIcons.play, NocheIcons.pause]),
        );

        final midTransitions = t
            .widgetList<FadeTransition>(
              find.descendant(
                of: find.byType(NochePlayDisc),
                matching: find.byType(FadeTransition),
              ),
            )
            .map((ft) => ft.opacity.value)
            .toList();
        expect(midTransitions.length, 2);
        for (final op in midTransitions) {
          expect(op, inExclusiveRange(0.0, 1.0));
        }

        await t.pump(NocheMotion.quick);
        expect(find.byType(NocheIcon), findsOneWidget);
        expect(
          t.widget<NocheIcon>(find.byType(NocheIcon)).data,
          NocheIcons.pause,
        );
      },
    );
  });

  group('NocheSegmented icon, builder, and compact 0-padding mode', () {
    testWidgets(
      'compact 0-padding icon segmented has height 50, radius 25, slides thumb in move, retargets mid-flight',
      (t) async {
        var selected = 'tight';
        final set = await _pumpState(
          t,
          (c, s) => Center(
            child: NocheSegmented<String>(
              padding: EdgeInsetsDirectional.zero,
              backgroundColor: NocheColors.ground,
              semanticLabel: NocheA11y.label(NocheA11y.lineSpacing),
              selected: selected,
              onChanged: (v) => s(() => selected = v),
              options: const [
                NocheSegmentOption(
                  value: 'tight',
                  icon: NocheIcons.lineSpacingTight,
                  semanticLabel: 'Tight',
                ),
                NocheSegmentOption(
                  value: 'normal',
                  icon: NocheIcons.lineSpacingNormal,
                  semanticLabel: 'Normal',
                ),
                NocheSegmentOption(
                  value: 'loose',
                  icon: NocheIcons.lineSpacingLoose,
                  semanticLabel: 'Loose',
                ),
              ],
            ),
          ),
        );

        final segFinder = find.byType(NocheSegmented<String>);
        expect(t.getSize(segFinder).height, 50);

        final outerContainer = t.widget<Container>(
          find
              .descendant(of: segFinder, matching: find.byType(Container))
              .first,
        );
        final outerDeco = outerContainer.decoration! as BoxDecoration;
        expect(outerDeco.color, NocheColors.ground);
        expect(
          outerDeco.borderRadius,
          BorderRadius.circular(NocheSize.pillRadius + 1),
        );
        expect(
          find.descendant(of: segFinder, matching: find.byType(ClipRRect)),
          findsOneWidget,
        );

        final thumb = find.byKey(const ValueKey('noche_segmented_thumb'));
        final startX = t.getCenter(thumb).dx;

        // Move from tight (0) -> loose (2).
        set(() => selected = 'loose');
        await t.pump();
        await t.pump(NocheMotion.move ~/ 2);
        final midX = t.getCenter(thumb).dx;
        expect(midX, greaterThan(startX));

        // Retarget mid-flight back to normal (1) without jumping.
        set(() => selected = 'normal');
        await t.pump();
        expect(t.getCenter(thumb).dx, closeTo(midX, 0.5));

        await t.pump(NocheMotion.move);
        final endX = t.getCenter(thumb).dx;
        expect(endX, closeTo(390 / 2, 2.0));

        // Selected icon gets ground colour, unselected icons get text colour.
        final icons = t.widgetList<NocheIcon>(find.byType(NocheIcon)).toList();
        expect(icons[0].color, NocheColors.text);
        expect(icons[1].color, NocheColors.ground);
        expect(icons[2].color, NocheColors.text);
      },
    );

    testWidgets(
      'custom builder and icon+label options render and obey reduced motion',
      (t) async {
        var selected = 0;
        final set = await _pumpState(
          t,
          reduced: true,
          (c, s) => Center(
            child: NocheSegmented<int>(
              padding: EdgeInsetsDirectional.zero,
              selected: selected,
              onChanged: (v) => s(() => selected = v),
              options: [
                NocheSegmentOption(
                  value: 0,
                  semanticLabel: 'Custom option',
                  builder: (context, color, isSelected) => Text(
                    isSelected ? 'CUSTOM-ON' : 'CUSTOM-OFF',
                    style: TextStyle(color: color),
                  ),
                ),
                const NocheSegmentOption(
                  value: 1,
                  icon: NocheIcons.chevronUp,
                  label: 'Combo',
                ),
              ],
            ),
          ),
        );

        expect(find.text('CUSTOM-ON'), findsOneWidget);
        expect(find.text('Combo'), findsOneWidget);
        expect(find.byType(NocheIcon), findsOneWidget);

        final thumb = find.byKey(const ValueKey('noche_segmented_thumb'));
        final startX = t.getCenter(thumb).dx;

        set(() => selected = 1);
        await t.pump();
        final snappedX = t.getCenter(thumb).dx;
        expect(snappedX, greaterThan(startX));

        final thumbOp = t
            .widget<Opacity>(
              find.ancestor(of: thumb, matching: find.byType(Opacity)).first,
            )
            .opacity;
        expect(thumbOp, closeTo(0.0, 0.01));

        await t.pump(NocheMotion.quick);
        expect(find.text('CUSTOM-OFF'), findsOneWidget);
      },
    );
  });

  group('NocheDashes quickColorFade mode', () {
    testWidgets(
      'fades colour symmetrically on fill and empty in quick without width-wipe',
      (t) async {
        var done = 2;
        final set = await _pumpState(
          t,
          (c, s) => Center(
            child: NocheDashes.progress(
              count: 5,
              done: done,
              quickColorFade: true,
            ),
          ),
        );

        Color dashColor(int index) {
          final dash = find.byKey(ValueKey('noche_dash_$index'));
          final box = t.widget<Container>(
            find.descendant(of: dash, matching: find.byType(Container)).first,
          );
          return (box.decoration! as BoxDecoration).color!;
        }

        expect(dashColor(2), NocheColors.line);
        expect(dashColor(1), NocheColors.text);

        // Fill dash 2: notYet -> done
        set(() => done = 3);
        await t.pump();
        await t.pump(NocheMotion.quick ~/ 2);
        expect(find.byType(FractionallySizedBox), findsNothing);
        final midFill = dashColor(2);
        expect(midFill, isNot(NocheColors.line));
        expect(midFill, isNot(NocheColors.text));

        await t.pump(NocheMotion.quick);
        expect(dashColor(2), NocheColors.text);

        // Empty dash 2: done -> notYet
        set(() => done = 2);
        await t.pump();
        await t.pump(NocheMotion.quick ~/ 2);
        expect(find.byType(FractionallySizedBox), findsNothing);
        final midEmpty = dashColor(2);
        expect(midEmpty, isNot(NocheColors.text));
        expect(midEmpty, isNot(NocheColors.line));

        await t.pump(NocheMotion.quick);
        expect(dashColor(2), NocheColors.line);
      },
    );
  });

  group('showNocheSheet dynamic dismissibleListenable', () {
    testWidgets(
      'locks scrim, drag-down, close button, and popDisposition when false; unlocks when true; programmatic close still works and height stays locked',
      (t) async {
        final canDismiss = ValueNotifier<bool>(true);
        addTearDown(canDismiss.dispose);
        late VoidCallback sheetClose;
        late BuildContext sheetContext;
        var swapStep = 0;
        late StateSetter setSwap;

        await t.pumpWidget(
          _app(
            Builder(
              builder: (c) => Scaffold(
                body: Center(
                  child: NocheOutlineButton(
                    label: 'Open lockable',
                    onPressed: () => showNocheSheet<void>(
                      c,
                      title: 'Write story',
                      dismissibleListenable: canDismiss,
                      builder: (sc, close) {
                        sheetContext = sc;
                        sheetClose = close;
                        return StatefulBuilder(
                          builder: (ctx, setState) {
                            setSwap = setState;
                            return NocheSheetSwap(
                              contentKey: swapStep,
                              child: SizedBox(
                                height: swapStep == 0 ? 140 : 60,
                                child: Text('Step $swapStep'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await t.tap(find.text('Open lockable'));
        await t.pumpAndSettle();
        expect(find.text('Write story'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(NocheSheet),
            matching: find.bySemanticsLabel('Close'),
          ),
          findsOneWidget,
        );
        expect(
          ModalRoute.of(sheetContext)!.popDisposition,
          RoutePopDisposition.pop,
        );
        final initialHeight = t.getSize(find.byType(NocheSheet)).height;

        // Swap content and lock dismissal simultaneously.
        setSwap(() => swapStep = 1);
        canDismiss.value = false;
        await t.pumpAndSettle();

        expect(find.text('Step 1'), findsOneWidget);
        expect(t.getSize(find.byType(NocheSheet)).height, initialHeight);
        expect(
          find.descendant(
            of: find.byType(NocheSheet),
            matching: find.bySemanticsLabel('Close'),
          ),
          findsNothing,
        );
        expect(
          ModalRoute.of(sheetContext)!.popDisposition,
          RoutePopDisposition.doNotPop,
        );

        // Scrim tap does nothing while locked.
        await t.tapAt(const Offset(195, 40));
        await t.pumpAndSettle();
        expect(find.text('Write story'), findsOneWidget);

        // Drag down does nothing while locked.
        await t.drag(find.text('Write story'), const Offset(0, 150));
        await t.pumpAndSettle();
        expect(find.text('Write story'), findsOneWidget);

        // System back (maybePop) is vetoed by PopScope while locked.
        await Navigator.of(sheetContext).maybePop();
        await t.pumpAndSettle();
        expect(find.text('Write story'), findsOneWidget);

        // Unlock dismissal: close button & popDisposition return, height stays locked.
        canDismiss.value = true;
        await t.pumpAndSettle();
        expect(t.getSize(find.byType(NocheSheet)).height, initialHeight);
        expect(
          find.descendant(
            of: find.byType(NocheSheet),
            matching: find.bySemanticsLabel('Close'),
          ),
          findsOneWidget,
        );
        expect(
          ModalRoute.of(sheetContext)!.popDisposition,
          RoutePopDisposition.pop,
        );

        // Lock again and verify programmatic close() still dismisses.
        canDismiss.value = false;
        await t.pumpAndSettle();
        sheetClose();
        await t.pumpAndSettle();
        expect(find.text('Write story'), findsNothing);
      },
    );
  });

  group('showNocheSheet scrimless and headerless mode', () {
    testWidgets(
      'scrim: false omits barrier scrim, tap-above carries closeLabel and dismisses, drag-down dismisses without X button',
      (t) async {
        final handle = t.ensureSemantics();
        try {
          late BuildContext sheetContext;
          await t.pumpWidget(
            _app(
              Builder(
                builder: (c) => Scaffold(
                  body: Center(
                    child: NocheOutlineButton(
                      label: 'Open reader sheet',
                      onPressed: () => showNocheSheet<void>(
                        c,
                        scrim: false,
                        showCloseButton: false,
                        closeLabel: 'Close text and page',
                        builder: (sc, close) {
                          sheetContext = sc;
                          return const SizedBox(
                            height: 160,
                            child: Text('Reader controls'),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          await t.tap(find.text('Open reader sheet'));
          await t.pump();

          final surf = find.byKey(const ValueKey('noche_sheet_surface'));
          expect(t.widget(surf), isA<FractionalTranslation>());
          expect(
            t.widget<FractionalTranslation>(surf).translation.dy,
            closeTo(1.0, 0.01),
          );
          await t.pump(NocheMotion.pageIn ~/ 2);
          expect(
            t.widget<FractionalTranslation>(surf).translation.dy,
            closeTo(1.0 - NocheMotion.enter.transform(0.5), 0.03),
          );
          await t.pumpAndSettle();

          final route = ModalRoute.of(sheetContext)!;
          expect(route.barrierColor, isNull);
          expect(
            find.byKey(const ValueKey<String>('noche_sheet_scrim')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey<String>('noche_sheet_scrimless_closer')),
            findsOneWidget,
          );
          expect(find.bySemanticsLabel('Close text and page'), findsOneWidget);
          // No close X icon rendered.
          expect(
            find.byWidgetPredicate(
              (w) => w is NocheIcon && w.data == NocheIcons.close,
            ),
            findsNothing,
          );

          // Tap above dismisses.
          await t.tap(
            find.byKey(const ValueKey<String>('noche_sheet_scrimless_closer')),
          );
          await t.pump();
          await t.pump(NocheMotion.pageOut ~/ 2);
          expect(
            t.widget<FractionalTranslation>(surf).translation.dy,
            closeTo(NocheMotion.exit.transform(0.5), 0.03),
          );
          await t.pumpAndSettle();
          expect(find.text('Reader controls'), findsNothing);

          // Re-open and dismiss via drag-down on headerless sheet.
          await t.tap(find.text('Open reader sheet'));
          await t.pumpAndSettle();
          expect(find.text('Reader controls'), findsOneWidget);

          await t.drag(find.byType(NocheSheet), const Offset(0, 120));
          await t.pumpAndSettle();
          expect(find.text('Reader controls'), findsNothing);
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('scrimless sheet in reduced motion fades in quick', (t) async {
      await t.pumpWidget(
        _app(
          reduced: true,
          Builder(
            builder: (c) => Scaffold(
              body: Center(
                child: NocheOutlineButton(
                  label: 'Open reduced scrimless',
                  onPressed: () => showNocheSheet<void>(
                    c,
                    scrim: false,
                    showCloseButton: false,
                    closeLabel: 'Close text and page',
                    builder: (sc, close) => const Text('Reduced controls'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await t.tap(find.text('Open reduced scrimless'));
      await t.pump();
      final surf = find.byKey(const ValueKey('noche_sheet_surface'));
      expect(t.widget(surf), isA<Opacity>());
      expect(t.widget<Opacity>(surf).opacity, closeTo(0.0, 0.01));
      await t.pump(NocheMotion.quick ~/ 2);
      expect(t.widget<Opacity>(surf).opacity, inExclusiveRange(0.0, 1.0));
      await t.pump(NocheMotion.quick);
      expect(t.widget<Opacity>(surf).opacity, closeTo(1.0, 0.01));
    });
  });

  group('NochePillOption key support', () {
    testWidgets(
      'attaches key directly to tappable pill item and preserves sliding mark and semantics',
      (t) async {
        final handle = t.ensureSemantics();
        try {
          var selected = 'kitchen';
          await _pumpState(
            t,
            (c, s) => Center(
              child: NochePillGroup<String>(
                semanticLabel: 'Places',
                selected: selected,
                onChanged: (v) => s(() => selected = v),
                options: const [
                  NochePillOption(
                    key: Key('speak-place-kitchen'),
                    value: 'kitchen',
                    label: 'La cocina',
                  ),
                  NochePillOption(
                    key: Key('speak-place-park'),
                    value: 'park',
                    label: 'El parque',
                  ),
                ],
              ),
            ),
          );

          final kitchenKey = find.byKey(const Key('speak-place-kitchen'));
          final parkKey = find.byKey(const Key('speak-place-park'));
          expect(kitchenKey, findsOneWidget);
          expect(parkKey, findsOneWidget);

          final mark = find.byKey(const ValueKey('noche_pill_group_mark'));
          final startX = t.getCenter(mark).dx;

          await t.tap(parkKey);
          await t.pump();
          await t.pump(NocheMotion.move ~/ 2);
          final midX = t.getCenter(mark).dx;
          expect(midX, greaterThan(startX));

          await t.pump(NocheMotion.move);
          expect(selected, 'park');
          expect(t.getCenter(mark).dx, greaterThan(midX));

          final parkSem = t.getSemantics(parkKey).getSemanticsData();
          expect(parkSem.label, 'El parque');
          expect(parkSem.flagsCollection.isChecked, isNotNull);
        } finally {
          handle.dispose();
        }
      },
    );
  });
}
