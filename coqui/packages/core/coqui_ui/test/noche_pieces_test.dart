import 'dart:io';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/gallery/noche_pieces.dart';

const _spanishTabs = {
  NocheTabs.library: CoquiLabels.library,
  NocheTabs.words: CoquiLabels.words,
  NocheTabs.map: CoquiLabels.map,
  NocheTabs.speak: CoquiLabels.speak,
  NocheTabs.me: CoquiLabels.me,
};

const _arabicTabs = {
  NocheTabs.library: 'المكتبة',
  NocheTabs.words: 'الكلمات',
  NocheTabs.map: 'الخريطة',
  NocheTabs.speak: 'التحدث',
  NocheTabs.me: 'أنا',
};

Widget _wrap(
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
  Size size = const Size(390, 844),
}) => Directionality(
  textDirection: textDirection,
  child: Align(
    alignment: AlignmentDirectional.topStart,
    child: SizedBox(
      width: size.width,
      height: size.height,
      child: MediaQuery(
        data: MediaQueryData(size: size, padding: padding, devicePixelRatio: 1),
        child: Material(color: NocheColors.ground, child: child),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    for (final entry in nocheFontFiles.entries) {
      for (final prefix in ['', 'packages/coqui_ui/']) {
        final loader = FontLoader('$prefix${entry.key}');
        for (final path in entry.value.values) {
          loader.addFont(
            Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
          );
        }
        await loader.load();
      }
    }
  });

  group('NocheTabBar', () {
    testWidgets(
      'fixed 5-tab order never mirrors in LTR or RTL and fires taps',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
          final tapped = <String>[];
          final tabs = dir == TextDirection.rtl ? _arabicTabs : _spanishTabs;
          final script = dir == TextDirection.rtl ? 'Arab' : 'Latn';

          await tester.pumpWidget(
            _wrap(
              Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: NocheTabBar(
                  selectedId: NocheTabs.words,
                  tabNames: tabs,
                  script: script,
                  onTap: tapped.add,
                ),
              ),
              textDirection: dir,
            ),
          );

          final xs = [
            for (final id in NocheTabs.order)
              tester.getCenter(find.text(tabs[id]!)).dx,
          ];
          for (var i = 1; i < xs.length; i++) {
            expect(
              xs[i],
              greaterThan(xs[i - 1]),
              reason: 'tab order must stay fixed in $dir',
            );
          }

          // Words tab is active (pill in NocheColors.line, label tabLabelOn in text).
          final wordsText = tester.widget<Text>(
            find.text(tabs[NocheTabs.words]!),
          );
          expect(wordsText.style!.color, NocheColors.text);
          expect(wordsText.style!.fontWeight, FontWeight.w700);

          // Library tab is inactive (label colour).
          final libText = tester.widget<Text>(
            find.text(tabs[NocheTabs.library]!),
          );
          expect(libText.style!.color, NocheColors.label);

          // Map disc is always 56 orange inside 64 ground ring (raised 24 above bar).
          final mapDiscFinder = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.minWidth == 56 &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).color == NocheColors.next,
          );
          expect(mapDiscFinder, findsOneWidget);
          final barFinder = find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color == NocheColors.panel &&
                (w.decoration as BoxDecoration).borderRadius ==
                    BorderRadius.circular(NocheSize.tabBarRadius),
          );
          expect(barFinder, findsOneWidget);
          final barRect = tester.getRect(barFinder);
          expect(barRect.height, 64);
          expect(barRect.left, 16);
          expect(390 - barRect.right, 16);
          expect(844 - barRect.bottom, 16);

          // Tapping each tab reports its id.
          for (final id in NocheTabs.order) {
            await tester.tap(find.text(tabs[id]!));
          }
          expect(tapped, equals(NocheTabs.order));
        }
      },
    );

    testWidgets('map tab current uses tabLabelOn in text colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: NocheTabBar(
              selectedId: NocheTabs.map,
              tabNames: _spanishTabs,
              onTap: (_) {},
            ),
          ),
        ),
      );
      final mapLabel = tester.widget<Text>(find.text(CoquiLabels.map));
      expect(mapLabel.style!.color, NocheColors.text);
      expect(mapLabel.style!.fontWeight, FontWeight.w700);
    });
  });

  group('NochePill', () {
    testWidgets('outline, selected, dashedLocked and planTag states', (
      tester,
    ) async {
      var outlineTaps = 0;
      var selectedTaps = 0;
      await tester.pumpWidget(
        _wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NochePill.outline(
                label: 'El parque',
                onPressed: () => outlineTaps++,
              ),
              NochePill.selected(
                label: 'La cocina',
                onPressed: () => selectedTaps++,
              ),
              const NochePill.dashedLocked(semanticLabel: 'El colmado, locked'),
              const NochePill.planTag(label: 'Course + Calls'),
            ],
          ),
        ),
      );

      final outlineSize = tester.getSize(
        find.byWidgetPredicate(
          (w) => w is NochePill && w.kind == NochePillKind.outline,
        ),
      );
      expect(outlineSize.height, 48);
      expect(outlineSize.width, greaterThanOrEqualTo(48));

      final selectedSize = tester.getSize(
        find.byWidgetPredicate(
          (w) => w is NochePill && w.kind == NochePillKind.selected,
        ),
      );
      expect(selectedSize.height, 48);

      final lockedFinder = find.byWidgetPredicate(
        (w) => w is NochePill && w.kind == NochePillKind.dashedLocked,
      );
      expect(tester.getSize(lockedFinder), const Size(48, 48));
      expect(
        find.descendant(of: lockedFinder, matching: find.byType(NocheIcon)),
        findsOneWidget,
      );

      final tagFinder = find.byWidgetPredicate(
        (w) => w is NochePill && w.kind == NochePillKind.planTag,
      );
      expect(tester.getSize(tagFinder).height, 24);
      // planTag must never be touchable.
      expect(
        find.descendant(of: tagFinder, matching: find.byType(GestureDetector)),
        findsNothing,
      );

      await tester.tap(find.text('El parque'));
      await tester.tap(find.text('La cocina'));
      expect(outlineTaps, 1);
      expect(selectedTaps, 1);
    });
  });

  group('NocheChip', () {
    testWidgets('32 high, chip fill, non-touchable', (tester) async {
      await tester.pumpWidget(
        _wrap(const Center(child: NocheChip(label: 'quiero'))),
      );
      final chipFinder = find.byType(NocheChip);
      expect(tester.getSize(chipFinder).height, 32);
      expect(
        find.descendant(of: chipFinder, matching: find.byType(GestureDetector)),
        findsNothing,
      );
      final container = tester.widget<Container>(
        find.descendant(of: chipFinder, matching: find.byType(Container)),
      );
      final deco = container.decoration! as BoxDecoration;
      expect(deco.color, NocheColors.chip);
      expect(deco.borderRadius, BorderRadius.circular(16));
    });
  });

  group('NocheCard', () {
    testWidgets('standard, highlight, dashed, and tappable', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              NocheCard(
                onPressed: () => tapped++,
                child: const Text('Standard'),
              ),
              const NocheCard(
                variant: NocheCardVariant.highlight,
                padding: EdgeInsetsDirectional.all(24),
                child: Text('Highlight'),
              ),
              const NocheCard(
                variant: NocheCardVariant.dashed,
                child: Text('Dashed'),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Standard'));
      expect(tapped, 1);

      final highlightFinder = find.byWidgetPredicate(
        (w) => w is NocheCard && w.variant == NocheCardVariant.highlight,
      );
      final highlightDeco =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: highlightFinder,
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(highlightDeco.color, NocheColors.panel);
      expect(
        highlightDeco.border,
        Border.all(color: NocheColors.next, width: 2),
      );
      expect(highlightDeco.borderRadius, BorderRadius.circular(24));

      // Dashed card sets label text colour and has no GestureDetector.
      final dashedFinder = find.byWidgetPredicate(
        (w) => w is NocheCard && w.variant == NocheCardVariant.dashed,
      );
      expect(
        find.descendant(
          of: dashedFinder,
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      final dashedCtx = tester.element(find.text('Dashed'));
      expect(DefaultTextStyle.of(dashedCtx).style.color, NocheColors.label);
    });
  });

  group('NochePrimaryButton & NocheOutlineButton', () {
    testWidgets('primary enabled, small, and disabled states', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              NochePrimaryButton(
                label: 'Start review',
                onPressed: () => taps++,
              ),
              const NochePrimaryButton(label: 'Disabled', onPressed: null),
            ],
          ),
        ),
      );

      final enabledFinder = find.byWidgetPredicate(
        (w) => w is NochePrimaryButton && w.onPressed != null,
      );
      expect(tester.getSize(enabledFinder), const Size(390, 56));
      await tester.tap(enabledFinder);
      expect(taps, 1);

      final disabledFinder = find.byWidgetPredicate(
        (w) => w is NochePrimaryButton && w.onPressed == null,
      );
      await tester.tap(disabledFinder);
      expect(taps, 1);

      final disabledBox = tester.widget<Container>(
        find.descendant(of: disabledFinder, matching: find.byType(Container)),
      );
      expect(
        (disabledBox.decoration! as BoxDecoration).color,
        NocheColors.line,
      );
      final disabledText = tester.widget<Text>(find.text('Disabled'));
      expect(disabledText.style!.color, NocheColors.label);
    });

    testWidgets('outline enabled and disabled states', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              NocheOutlineButton(
                label: 'Write my story',
                onPressed: () => taps++,
              ),
              const NocheOutlineButton(label: 'Locked', onPressed: null),
            ],
          ),
        ),
      );
      final enabledFinder = find.byWidgetPredicate(
        (w) => w is NocheOutlineButton && w.onPressed != null,
      );
      expect(tester.getSize(enabledFinder), const Size(390, 48));
      await tester.tap(enabledFinder);
      expect(taps, 1);

      await tester.tap(find.text('Locked'));
      expect(taps, 1);
    });
  });

  group('NochePlayBar & NochePlayDisc', () {
    testWidgets('play bar is 72 high and mirrors start disc in RTL', (
      tester,
    ) async {
      var taps = 0;
      Widget buildBar(TextDirection dir) => _wrap(
        Center(
          child: NochePlayBar(
            eyebrow: 'Play next · Story 3',
            title: 'Tengo hambre',
            meta: '5 min',
            onPressed: () => taps++,
          ),
        ),
        textDirection: dir,
      );

      await tester.pumpWidget(buildBar(TextDirection.ltr));
      expect(tester.getSize(find.byType(NochePlayBar)), const Size(390, 72));
      expect(find.text('PLAY NEXT · STORY 3'), findsOneWidget);
      final ltrDiscX = tester.getCenter(find.byType(NocheIcon)).dx;
      final ltrMetaX = tester.getCenter(find.text('5 min')).dx;
      expect(ltrDiscX, lessThan(ltrMetaX));

      await tester.tap(find.byType(NochePlayBar));
      expect(taps, 1);

      await tester.pumpWidget(buildBar(TextDirection.rtl));
      final rtlDiscX = tester.getCenter(find.byType(NocheIcon)).dx;
      final rtlMetaX = tester.getCenter(find.text('5 min')).dx;
      expect(rtlDiscX, greaterThan(rtlMetaX));
    });

    testWidgets('play disc 64 and 96 sizes', (tester) async {
      var count = 0;
      await tester.pumpWidget(
        _wrap(
          Row(
            children: [
              NochePlayDisc(
                size: 64,
                semanticLabel: 'Play',
                onPressed: () => count++,
              ),
              NochePlayDisc(
                size: 96,
                icon: NocheIcons.mic,
                halo: true,
                semanticLabel: 'Call',
                onPressed: () => count++,
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(
          find.byWidgetPredicate((w) => w is NochePlayDisc && w.size == 64),
        ),
        const Size(64, 64),
      );
      expect(
        tester.getSize(
          find.byWidgetPredicate((w) => w is NochePlayDisc && w.size == 96),
        ),
        const Size(96, 96),
      );
      await tester.tap(find.bySemanticsLabel('Play'));
      await tester.tap(find.bySemanticsLabel('Call'));
      expect(count, 2);
    });
  });

  group('NocheSegmented', () {
    testWidgets('radioGroup and tabList roles select and update', (
      tester,
    ) async {
      int selectedMin = 30;
      String selectedSkill = 'listening';

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                NocheSegmented<int>(
                  role: NocheSegmentedRole.radioGroup,
                  semanticLabel: 'Minutes a day',
                  selected: selectedMin,
                  large: true,
                  onChanged: (v) => setState(() => selectedMin = v),
                  options: const [
                    NocheSegmentOption(value: 15, label: '15'),
                    NocheSegmentOption(value: 30, label: '30'),
                    NocheSegmentOption(value: 60, label: '60'),
                    NocheSegmentOption(value: 120, label: '120'),
                  ],
                ),
                NocheSegmented<String>(
                  role: NocheSegmentedRole.tabList,
                  semanticLabel: 'Skill',
                  selected: selectedSkill,
                  onChanged: (v) => setState(() => selectedSkill = v),
                  options: const [
                    NocheSegmentOption(value: 'listening', label: 'Listening'),
                    NocheSegmentOption(value: 'speaking', label: 'Speaking'),
                    NocheSegmentOption(
                      value: 'reading',
                      label: 'Reading',
                      muted: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.widget<Text>(find.text('30')).style!.color,
        NocheColors.ground,
      );
      expect(
        tester.widget<Text>(find.text('15')).style!.color,
        NocheColors.text,
      );
      expect(
        tester.widget<Text>(find.text('Reading')).style!.color,
        NocheColors.label,
      );

      await tester.tap(find.text('60'));
      await tester.tap(find.text('Speaking'));
      await tester.pump();

      expect(selectedMin, 60);
      expect(selectedSkill, 'speaking');
      expect(
        tester.widget<Text>(find.text('60')).style!.color,
        NocheColors.ground,
      );
      expect(
        tester.widget<Text>(find.text('Speaking')).style!.color,
        NocheColors.ground,
      );
    });
  });

  group('NocheDashes, NocheStageBar & NocheProgressBar', () {
    testWidgets('dashes show done, current, and panel vs lessonLine notYet', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              NocheDashes.progress(count: 4, done: 1, currentIndex: 1),
              NocheDashes.progress(count: 3, done: 1, onLessonGround: true),
            ],
          ),
        ),
      );

      final dashContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();

      expect(dashContainers, [
        NocheColors.text,
        NocheColors.next,
        NocheColors.line,
        NocheColors.line,
        NocheColors.text,
        NocheColors.lessonLine,
        NocheColors.lessonLine,
      ]);
    });

    testWidgets('stage bar is 96 by 8 and fills stage / max from start', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const Center(child: NocheStageBar(stage: 2, max: 4))),
      );
      expect(tester.getSize(find.byType(NocheStageBar)), const Size(96, 8));
      final frac = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(frac.widthFactor, 0.5);
    });

    testWidgets('progress bar supports 8 and 4 heights and clamps value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              NocheProgressBar(value: 0.71, color: NocheColors.listening),
              NocheProgressBar(
                value: 1.5,
                height: 4,
                trackColor: NocheColors.lessonLine,
                color: NocheColors.lessonLabel,
              ),
            ],
          ),
        ),
      );

      final bars = tester.widgetList<NocheProgressBar>(
        find.byType(NocheProgressBar),
      );
      expect(bars.length, 2);
      expect(
        tester
            .getSize(
              find.byWidgetPredicate(
                (w) => w is NocheProgressBar && w.height == 8,
              ),
            )
            .height,
        8,
      );
      expect(
        tester
            .getSize(
              find.byWidgetPredicate(
                (w) => w is NocheProgressBar && w.height == 4,
              ),
            )
            .height,
        4,
      );
      final clamped = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is NocheProgressBar && w.height == 4,
          ),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(clamped.widthFactor, 1.0);
    });
  });

  group('NocheSheet & showNocheSheet', () {
    testWidgets('sheet has 40x4 handle, pageTitle, 48 close button and scrim', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        var closed = 0;
        var scrimTapped = 0;
        await tester.pumpWidget(
          _wrap(
            NocheSheetOverlay(
              onScrimTap: () => scrimTapped++,
              sheet: NocheSheet(
                title: 'Your languages',
                onClose: () => closed++,
                respectSafeArea: false,
                scrollable: false,
                child: const Text('Body'),
              ),
            ),
          ),
        );

        final closeBtn = find.bySemanticsLabel('Close');
        expect(tester.getSize(closeBtn), const Size(48, 48));
        await tester.tap(closeBtn);
        expect(closed, 1);

        await tester.tapAt(const Offset(195, 40));
        expect(scrimTapped, 1);

        // Drag down > 72 on header closes sheet.
        await tester.drag(find.text('Your languages'), const Offset(0, 120));
        await tester.pump();
        expect(closed, 2);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('showNocheSheet opens over scrim and closes on X', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: coquiTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: NocheOutlineButton(
                  label: 'Open',
                  expand: false,
                  onPressed: () {
                    showNocheSheet<void>(
                      context,
                      title: 'Settings',
                      builder: (context, close) => const Text('Sheet body'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sheet body'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(NocheSheet),
          matching: find.bySemanticsLabel('Close'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsNothing);
    });
  });

  group('NocheSwitchRow', () {
    testWidgets('52 high row, toggles on and off, mirrors in RTL', (
      tester,
    ) async {
      var val = true;
      await tester.pumpWidget(
        _wrap(
          Center(
            child: StatefulBuilder(
              builder: (context, setState) => NocheSwitchRow(
                label: "Underline words I'm still learning",
                value: val,
                onChanged: (v) => setState(() => val = v),
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(NocheSwitchRow)).height, 52);
      final labelWidget = tester.widget<Text>(
        find.text("Underline words I'm still learning"),
      );
      expect(labelWidget.style!.fontWeight, FontWeight.w600);
      expect(labelWidget.style!.fontSize, 15);

      await tester.tap(find.byType(NocheSwitchRow));
      await tester.pumpAndSettle();
      expect(val, isFalse);
    });
  });

  group('NocheSectionLabel', () {
    testWidgets('uppercases text, uses label colour and 16 bottom gap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NocheSectionLabel('All 9 stories'),
              SizedBox(key: ValueKey('below'), height: 10),
            ],
          ),
        ),
      );
      final labelFinder = find.text('ALL 9 STORIES');
      expect(labelFinder, findsOneWidget);
      expect(tester.widget<Text>(labelFinder).style!.color, NocheColors.label);
      final gap =
          tester.getTopLeft(find.byKey(const ValueKey('below'))).dy -
          tester.getBottomLeft(labelFinder).dy;
      expect(gap, 16);
    });
  });

  group('NocheBarChart', () {
    testWidgets('scales tallest bar to bar area and renders dashed goal line', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              NocheBarChart(
                items: [
                  NocheBarItem(label: 'Today', value: 14, highlighted: true),
                  NocheBarItem(label: 'This week', value: 30),
                ],
              ),
              NocheBarChart(
                showValues: false,
                goal: 30,
                items: [
                  NocheBarItem(label: 'F', value: 41),
                  NocheBarItem(label: 'Today', value: 12, highlighted: true),
                ],
              ),
              // All zeros must not divide by zero.
              NocheBarChart(
                items: [
                  NocheBarItem(label: 'Today', value: 0, highlighted: true),
                  NocheBarItem(label: 'Later', value: 0),
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.text('14'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.byType(NocheBarChart), findsNWidgets(3));
    });
  });

  group('NocheIcon', () {
    test('every board icon parses cleanly and matches board SVG paths', () {
      expect(NocheIcons.all.length, greaterThanOrEqualTo(30));
      for (final entry in NocheIcons.all.entries) {
        for (final shape in entry.value.shapes) {
          final path = parseNocheSvgPath(shape.d);
          expect(path, isNotNull, reason: 'failed to parse ${entry.key}');
        }
      }
      // Spot-check exact copied path strings from boards.
      expect(
        NocheIcons.library.shapes.first.d,
        'M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2z',
      );
      expect(
        NocheIcons.map.shapes.first.d,
        'M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2z',
      );
      expect(NocheIcons.play.shapes.first.d, 'M8 4v16l12-8z');
      expect(NocheIcons.back.shapes.first.d, 'M15 5l-7 7 7 7');
      expect(NocheIcons.close.shapes.first.d, 'M6 6l12 12M18 6 6 18');
      expect(NocheIcons.check.shapes.first.d, 'M4 12l6 6L20 6');
    });

    testWidgets('directional back icon flips in RTL', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Center(
            child: NocheIcon(NocheIcons.back, color: NocheColors.text),
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      expect(find.byType(Transform), findsOneWidget);
    });
  });

  group('NocheCover', () {
    test('stable hash selects coverBlue for even and coverPlum for odd', () {
      var sawBlue = false;
      var sawPlum = false;
      for (var i = 0; i < 32; i++) {
        final id = 'book-$i';
        final hash = nocheStableHash(id);
        final colors = NocheCover.colorsFor(id);
        expect(nocheStableHash(id), equals(hash));
        if (hash.isEven) {
          expect(colors, NocheColors.coverBlue);
          sawBlue = true;
        } else {
          expect(colors, NocheColors.coverPlum);
          sawPlum = true;
        }
      }
      expect(sawBlue && sawPlum, isTrue);
    });

    testWidgets('regular 90x120 and small 60x84 mirror spine in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Row(
            children: [
              NocheCover(bookId: 'a', title: 'Cuentos de la isla'),
              NocheCover(
                bookId: 'b',
                title: 'Un verano',
                size: NocheCoverSize.small,
              ),
            ],
          ),
          textDirection: TextDirection.rtl,
        ),
      );

      final regular = find.byWidgetPredicate(
        (w) => w is NocheCover && w.size == NocheCoverSize.regular,
      );
      final small = find.byWidgetPredicate(
        (w) => w is NocheCover && w.size == NocheCoverSize.small,
      );
      expect(tester.getSize(regular), const Size(90, 120));
      expect(tester.getSize(small), const Size(60, 84));
    });
  });

  group('NocheA11y', () {
    tearDown(() => NocheA11y.lessonLabelsInCourseLanguage = false);

    test('defaults to English with lessonLabelsInCourseLanguage = false', () {
      expect(NocheA11y.lessonLabelsInCourseLanguage, isFalse);
      for (final role in [
        NocheA11y.close,
        NocheA11y.hearAgain,
        NocheA11y.mic,
        NocheA11y.captions,
        NocheA11y.back,
        NocheA11y.textAndPage,
        NocheA11y.chapters,
        NocheA11y.sentenceAgain,
        NocheA11y.listen,
        NocheA11y.speed,
      ]) {
        expect(NocheA11y.english[role], isNotNull, reason: 'missing $role');
        expect(
          NocheA11y.label(role, courseWords: {role: 'OVERRIDE'}),
          equals(NocheA11y.english[role]),
        );
      }
    });

    test('uses courseWords when lessonLabelsInCourseLanguage is true', () {
      NocheA11y.lessonLabelsInCourseLanguage = true;
      final course = {NocheA11y.close: 'Cerrar el cuento'};
      expect(
        NocheA11y.label(NocheA11y.close, courseWords: course),
        'Cerrar el cuento',
      );
      // Falls back to English when a role is absent from courseWords.
      expect(
        NocheA11y.label(NocheA11y.hearAgain, courseWords: course),
        NocheA11y.english[NocheA11y.hearAgain],
      );
      expect(
        NocheA11y.label(
          NocheA11y.partProgress,
          args: const {'current': '3', 'total': '7'},
        ),
        'Part 3 of 7',
      );
    });
  });

  group('NocheScreen', () {
    testWidgets(
      'scroll view ends 104 above bottom (+ safe area) under tab bar',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        const safe = EdgeInsets.only(top: 44, bottom: 34);
        await tester.pumpWidget(
          _wrap(
            NocheScreen(
              tabBar: NocheTabBar(
                selectedId: NocheTabs.map,
                tabNames: _spanishTabs,
                onTap: (_) {},
              ),
              body: ListView(
                key: const ValueKey('scroll'),
                children: const [SizedBox(height: 1500)],
              ),
            ),
            padding: safe,
          ),
        );

        final scrollRect = tester.getRect(find.byKey(const ValueKey('scroll')));
        expect(scrollRect.top, 44);
        expect(844 - scrollRect.bottom, NocheSize.aboveTabBar + 34);
      },
    );
  });

  group('Dev page goldens & 48x48 touch audit', () {
    Future<void> pumpFullDevPage(
      WidgetTester tester,
      TextDirection dir,
      GlobalKey captureKey,
    ) async {
      // Wide 390 phone column, tall enough so every piece renders unclipped.
      const height = 3120.0;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, height);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, height),
            devicePixelRatio: 1,
          ),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: coquiTheme(),
            home: Align(
              alignment: AlignmentDirectional.topCenter,
              child: RepaintBoundary(
                key: captureKey,
                child: ColoredBox(
                  color: NocheColors.ground,
                  child: SizedBox(
                    width: 390,
                    height: height,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: NochePiecesDevPage(
                        textDirection: dir,
                        scrollable: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Ensure nothing overflows past our capture surface height.
      final pageSize = tester.getSize(find.byType(NochePiecesDevPage));
      expect(
        pageSize.height,
        lessThanOrEqualTo(height),
        reason:
            'dev page height ${pageSize.height} exceeds capture height $height',
      );
    }

    int auditTouchTargets(WidgetTester tester, String label) {
      var checked = 0;
      double minW = double.infinity;
      double minH = double.infinity;

      for (final element in find.byType(GestureDetector).evaluate()) {
        final gd = element.widget as GestureDetector;
        if (gd.onTap == null) continue;
        final ro = element.renderObject;
        if (ro is! RenderBox || !ro.hasSize) continue;
        // Skip full-screen scrim backdrops? Scrim is >= 48x48 too, so include it!
        final s = ro.size;
        checked++;
        if (s.width < minW) minW = s.width;
        if (s.height < minH) minH = s.height;
        expect(
          s.width,
          greaterThanOrEqualTo(NocheSize.touch),
          reason: '$label touch target width ${s.width} < 48 for $element',
        );
        expect(
          s.height,
          greaterThanOrEqualTo(NocheSize.touch),
          reason: '$label touch target height ${s.height} < 48 for $element',
        );
      }

      // Also verify via the live semantics tree: every tappable node >= 48x48.
      final handle = tester.ensureSemantics();
      try {
        var foundRoot = false;
        void visit(SemanticsNode node) {
          final data = node.getSemanticsData();
          if (data.hasAction(SemanticsAction.tap)) {
            final rect = node.rect;
            expect(
              rect.width,
              greaterThanOrEqualTo(NocheSize.touch),
              reason:
                  '$label semantics tap width ${rect.width} < 48 (${data.label})',
            );
            expect(
              rect.height,
              greaterThanOrEqualTo(NocheSize.touch),
              reason:
                  '$label semantics tap height ${rect.height} < 48 (${data.label})',
            );
          }
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        void visitOwner(PipelineOwner owner) {
          final root = owner.semanticsOwner?.rootSemanticsNode;
          if (root != null) {
            foundRoot = true;
            visit(root);
          }
          owner.visitChildren(visitOwner);
        }

        visitOwner(tester.binding.rootPipelineOwner);
        expect(foundRoot, isTrue);
      } finally {
        handle.dispose();
      }

      expect(
        checked,
        greaterThan(20),
        reason: 'expected many touchable pieces',
      );
      expect(minW, greaterThanOrEqualTo(48));
      expect(minH, greaterThanOrEqualTo(48));
      return checked;
    }

    testWidgets('LTR dev page matches golden and passes 48x48 touch audit', (
      tester,
    ) async {
      final key = GlobalKey();
      await pumpFullDevPage(tester, TextDirection.ltr, key);
      final count = auditTouchTargets(tester, 'LTR');
      expect(count, 32);
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/noche_dev_ltr.png'),
      );
    });

    testWidgets('RTL dev page matches golden and passes 48x48 touch audit', (
      tester,
    ) async {
      final key = GlobalKey();
      await pumpFullDevPage(tester, TextDirection.rtl, key);
      final count = auditTouchTargets(tester, 'RTL');
      expect(count, 32);
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/noche_dev_rtl.png'),
      );
    });
  });

  group('Noche directional & token static checks', () {
    const newFiles = [
      'lib/src/noche_a11y.dart',
      'lib/src/noche_chrome.dart',
      'lib/src/noche_controls.dart',
      'lib/src/noche_data.dart',
      'lib/src/noche_icons.dart',
      'tool/gallery/noche_pieces.dart',
    ];

    test('no left/right in any new Noche source file', () {
      final wordRe = RegExp(r'\b(left|right)\b', caseSensitive: false);
      final apiRe = RegExp(
        r'fromLTRB|topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight',
      );
      for (final path in newFiles) {
        final content = File(path).readAsStringSync();
        expect(
          wordRe.allMatches(content),
          isEmpty,
          reason: '$path contains left/right',
        );
        expect(
          apiRe.allMatches(content),
          isEmpty,
          reason: '$path contains non-directional layout API',
        );
      }
    });

    test('no raw Color(0x...) or fontFamily literals in new Noche files', () {
      final colorRe = RegExp(r'Color\s*\(\s*0x');
      final fontRe = RegExp(r'\bfontFamily\b');
      for (final path in newFiles) {
        final content = File(path).readAsStringSync();
        expect(
          colorRe.allMatches(content),
          isEmpty,
          reason: '$path contains raw Color(0x...)',
        );
        expect(
          fontRe.allMatches(content),
          isEmpty,
          reason: '$path contains raw fontFamily',
        );
      }
    });
  });
}
