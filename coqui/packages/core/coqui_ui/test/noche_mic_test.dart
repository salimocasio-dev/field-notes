import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/gallery/noche_mic.dart';

final Language _customLatinLanguage = Language(
  code: 'en',
  englishName: 'Synthetic Latin',
  nativeName: 'Synthetic Latin',
  recognitionLocale: 'en-US',
  direction: LanguageDirection.ltr,
  script: 'Latn',
  partnerName: 'Alex',
  callAgentId: 'test_agent_latin',
  micWords: const {
    'ready': 'Tap now',
    'listening': 'Hearing you',
    'thinking': 'One sec',
    'theySpeak': 'Listen up',
    'right': 'Nice job',
    'notYet': 'Try again',
  },
  tabNames: const {
    'library': 'Library',
    'words': 'Words',
    'map': 'Map',
    'speak': 'Speak',
    'me': 'Me',
  },
  a11yWords: const {
    NocheA11y.micReady: 'Course ready label',
    NocheA11y.micListening: 'Course listening label',
    NocheA11y.micThinking: 'Course thinking label',
    NocheA11y.micTheySpeak: 'Course theySpeak label',
    NocheA11y.micRight: 'Course right label',
  },
);

final Language _arabicLanguage = Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-SA',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  partnerName: 'سالم',
  callAgentId: 'test_agent_arab',
  micWords: const {
    'ready': 'المس وتحدث',
    'listening': 'أسمعك',
    'thinking': 'لحظة واحدة',
    'theySpeak': 'استمع',
    'right': 'أحسنت!',
    'notYet': 'مرة أخرى',
  },
  tabNames: const {
    'library': 'المكتبة',
    'words': 'الكلمات',
    'map': 'الخريطة',
    'speak': 'التحدث',
    'me': 'أنا',
  },
);

Widget _wrap(
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
  Size size = const Size(390, 844),
}) => Directionality(
  textDirection: textDirection,
  child: Align(
    alignment: AlignmentDirectional.topStart,
    child: SizedBox(
      width: size.width,
      height: size.height,
      child: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: 1),
        child: Material(color: NocheColors.lessonGround, child: child),
      ),
    ),
  ),
);

Container _discContainer(WidgetTester tester) =>
    tester.widget<Container>(find.byKey(const ValueKey('noche_mic_disc')));

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

  tearDown(() {
    NocheA11y.lessonLabelsInCourseLanguage = false;
  });

  group('NocheMic six states', () {
    testWidgets('every state matches disc, icon/dots, bars, and word tokens', (
      tester,
    ) async {
      final expected =
          <
            NocheMicState,
            ({
              Color? fill,
              Color? border,
              bool halo,
              NocheIconData? icon,
              double? iconSize,
              double? iconStroke,
              Color? iconColor,
              bool thinkingDots,
              Color? barColor,
              Color wordColor,
            })
          >{
            NocheMicState.ready: (
              fill: NocheColors.next,
              border: null,
              halo: false,
              icon: NocheIcons.mic,
              iconSize: 40,
              iconStroke: 2,
              iconColor: NocheColors.onAccent,
              thinkingDots: false,
              barColor: null,
              wordColor: NocheColors.next,
            ),
            NocheMicState.listening: (
              fill: NocheColors.listening,
              border: null,
              halo: true,
              icon: NocheIcons.mic,
              iconSize: 40,
              iconStroke: 2,
              iconColor: NocheColors.ground,
              thinkingDots: false,
              barColor: NocheColors.listening,
              wordColor: NocheColors.listening,
            ),
            NocheMicState.thinking: (
              fill: NocheColors.otherSoft,
              border: NocheColors.other,
              halo: false,
              icon: null,
              iconSize: null,
              iconStroke: null,
              iconColor: null,
              thinkingDots: true,
              barColor: null,
              wordColor: NocheColors.other,
            ),
            NocheMicState.theySpeak: (
              fill: NocheColors.micResting,
              border: null,
              halo: false,
              icon: NocheIcons.mic,
              iconSize: 40,
              iconStroke: 2,
              iconColor: NocheColors.lessonLabel,
              thinkingDots: false,
              barColor: NocheColors.other,
              wordColor: NocheColors.other,
            ),
            NocheMicState.right: (
              fill: NocheColors.right,
              border: null,
              halo: false,
              icon: NocheIcons.check,
              iconSize: 44,
              iconStroke: 3,
              iconColor: NocheColors.onAccent,
              thinkingDots: false,
              barColor: null,
              wordColor: NocheColors.right,
            ),
            NocheMicState.notYet: (
              fill: null,
              border: NocheColors.text,
              halo: false,
              icon: NocheIcons.replay,
              iconSize: 40,
              iconStroke: 2,
              iconColor: NocheColors.text,
              thinkingDots: false,
              barColor: null,
              wordColor: NocheColors.text,
            ),
          };

      for (final state in NocheMicState.values) {
        final spec = expected[state]!;
        await tester.pumpWidget(
          _wrap(
            Center(
              child: NocheMic(
                key: ValueKey(state),
                state: state,
                language: Language.spanish,
                level: 1.0,
                onPressed: () {},
              ),
            ),
          ),
        );

        final discFinder = find.byKey(const ValueKey('noche_mic_disc'));
        expect(tester.getSize(discFinder), const Size(96, 96));

        final decoration = _discContainer(tester).decoration! as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);
        expect(decoration.color, spec.fill);

        if (spec.border == null) {
          expect(decoration.border, isNull);
        } else {
          final border = decoration.border! as Border;
          expect(border.top.color, spec.border);
          expect(border.top.width, 2);
          expect(border.isUniform, isTrue);
        }

        if (spec.halo) {
          expect(decoration.boxShadow, isNotNull);
          expect(decoration.boxShadow!.length, 1);
          expect(decoration.boxShadow!.single.color, NocheColors.listeningSoft);
          expect(decoration.boxShadow!.single.spreadRadius, 8);
        } else {
          expect(decoration.boxShadow, isNull);
        }

        if (spec.thinkingDots) {
          expect(find.byType(NocheIcon), findsNothing);
          final dotRects = <Rect>[];
          for (var i = 0; i < 3; i++) {
            final dotFinder = find.byKey(ValueKey('noche_mic_thinking_dot_$i'));
            expect(dotFinder, findsOneWidget);
            expect(tester.getSize(dotFinder), const Size(12, 12));
            final dotDec =
                tester.widget<Container>(dotFinder).decoration!
                    as BoxDecoration;
            expect(dotDec.shape, BoxShape.circle);
            expect(dotDec.color, NocheColors.other);
            dotRects.add(tester.getRect(dotFinder));
          }
          expect(dotRects[1].left - dotRects[0].right, closeTo(8, 0.01));
          expect(dotRects[2].left - dotRects[1].right, closeTo(8, 0.01));
        } else {
          final iconWidget = tester.widget<NocheIcon>(find.byType(NocheIcon));
          expect(iconWidget.data, spec.icon);
          expect(iconWidget.size, spec.iconSize);
          expect(iconWidget.strokeWidth, spec.iconStroke);
          expect(iconWidget.color, spec.iconColor);
        }

        if (spec.barColor == null) {
          expect(
            find.byKey(const ValueKey('noche_mic_bars_start')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('noche_mic_bars_end')),
            findsNothing,
          );
        } else {
          expect(
            find.byKey(const ValueKey('noche_mic_bars_start')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('noche_mic_bars_end')),
            findsOneWidget,
          );
          for (final side in ['start', 'end']) {
            for (var i = 0; i < 5; i++) {
              final barFinder = find.byKey(
                ValueKey('noche_mic_bar_${side}_$i'),
              );
              expect(barFinder, findsOneWidget);
              final barContainer = tester.widget<Container>(
                find.descendant(
                  of: barFinder,
                  matching: find.byType(Container),
                ),
              );
              final barDec = barContainer.decoration! as BoxDecoration;
              expect(barDec.color, spec.barColor);
              expect(barDec.borderRadius, BorderRadius.circular(2));
            }
          }
        }

        final expectedWord = Language.spanish.micWords[state.wordKey]!;
        final textFinder = find.text(expectedWord);
        expect(textFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.locale, Locale(Language.spanish.code));
        expect(textWidget.maxLines, 1);
        expect(textWidget.softWrap, isFalse);
        expect(textWidget.style!.color, spec.wordColor);
        expect(textWidget.style!.fontSize, 16);
        expect(textWidget.style!.height, closeTo(24 / 16, 0.001));
        expect(textWidget.style!.fontWeight, FontWeight.w700);
      }
    });

    testWidgets('compactLabel switches status word between 16/24 and 14/14', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Center(
            child: NocheMic(
              state: NocheMicState.ready,
              language: Language.spanish,
              compactLabel: true,
            ),
          ),
        ),
      );
      final compactText = tester.widget<Text>(
        find.text(Language.spanish.micWords['ready']!),
      );
      expect(compactText.style!.fontSize, 14);
      expect(compactText.style!.height, closeTo(14 / 14, 0.001));
      expect(compactText.style!.fontWeight, FontWeight.w700);
    });
  });

  group('NocheMic transitions and calm guarantees', () {
    testWidgets('thinking shows immediately on frame 0 with zero delay', (
      tester,
    ) async {
      var currentState = NocheMicState.listening;
      late StateSetter setOuterState;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              setOuterState = setState;
              return Center(
                child: NocheMic(
                  state: currentState,
                  language: _customLatinLanguage,
                  level: 0.8,
                ),
              );
            },
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('noche_mic_bars_start')),
        findsOneWidget,
      );
      expect(find.text('Hearing you'), findsOneWidget);

      setOuterState(() => currentState = NocheMicState.thinking);
      await tester.pump();

      expect(find.byKey(const ValueKey('noche_mic_bars_start')), findsNothing);
      expect(find.byKey(const ValueKey('noche_mic_bars_end')), findsNothing);
      expect(
        find.byKey(const ValueKey('noche_mic_thinking_dot_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('noche_mic_thinking_dot_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('noche_mic_thinking_dot_2')),
        findsOneWidget,
      );
      expect(find.text('One sec'), findsOneWidget);
      await tester.pump(NocheMotion.quick);
      final dec = _discContainer(tester).decoration! as BoxDecoration;
      expect(dec.color, NocheColors.otherSoft);
    });

    testWidgets('notYet never uses red and never shakes across frames', (
      tester,
    ) async {
      var currentState = NocheMicState.thinking;
      late StateSetter setOuterState;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              setOuterState = setState;
              return Center(
                child: NocheMic(
                  state: currentState,
                  language: _customLatinLanguage,
                ),
              );
            },
          ),
        ),
      );

      setOuterState(() => currentState = NocheMicState.notYet);
      await tester.pump();

      final discFinder = find.byKey(const ValueKey('noche_mic_disc'));
      final initialCenter = tester.getCenter(discFinder);

      for (final dt in const [
        Duration(milliseconds: 16),
        Duration(milliseconds: 32),
        Duration(milliseconds: 50),
        Duration(milliseconds: 100),
        Duration(milliseconds: 250),
        Duration(milliseconds: 500),
      ]) {
        await tester.pump(dt);
        expect(tester.getCenter(discFinder), initialCenter);
      }

      // Check all colours in the notYet mic: only NocheColors.text (achromatic off-white), never red.
      final dec = _discContainer(tester).decoration! as BoxDecoration;
      expect(dec.color, isNull);
      final borderColor = (dec.border! as Border).top.color;
      final iconColor = tester.widget<NocheIcon>(find.byType(NocheIcon)).color;
      final textColor = tester
          .widget<Text>(find.text(_customLatinLanguage.micWords['notYet']!))
          .style!
          .color!;
      for (final c in [borderColor, iconColor, textColor]) {
        expect(c, NocheColors.text);
        final hsl = HSLColor.fromColor(c);
        // Cool off-white hue (~207 deg), never red (0/360 deg).
        expect(hsl.hue, inInclusiveRange(150.0, 270.0));
        expect(c.r, lessThanOrEqualTo(c.b));
      }
    });
  });

  group('NocheMic level-driven voice bars', () {
    const testLevels = [
      -10.0,
      -0.1,
      0.0,
      0.25,
      0.5,
      0.75,
      1.0,
      1.5,
      99.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ];

    test('barHeightsForLevel clamps to 8..56, exact at 0 and 1, monotonic', () {
      for (final lvl in testLevels) {
        final start = NocheMic.barHeightsForLevel(lvl, startSide: true);
        final end = NocheMic.barHeightsForLevel(lvl, startSide: false);
        expect(start.length, 5);
        expect(end.length, 5);
        for (final h in [...start, ...end]) {
          expect(h, inInclusiveRange(8.0, 56.0));
        }
      }

      expect(NocheMic.barHeightsForLevel(0.0, startSide: true), const [
        8.0,
        8.0,
        8.0,
        8.0,
        8.0,
      ]);
      expect(NocheMic.barHeightsForLevel(0.0, startSide: false), const [
        8.0,
        8.0,
        8.0,
        8.0,
        8.0,
      ]);
      expect(NocheMic.barHeightsForLevel(1.0, startSide: true), const [
        16.0,
        32.0,
        48.0,
        24.0,
        40.0,
      ]);
      expect(NocheMic.barHeightsForLevel(1.0, startSide: false), const [
        40.0,
        24.0,
        56.0,
        32.0,
        16.0,
      ]);
      expect(NocheMic.barHeightsForLevel(double.nan, startSide: true), const [
        8.0,
        8.0,
        8.0,
        8.0,
        8.0,
      ]);
      expect(
        NocheMic.barHeightsForLevel(double.infinity, startSide: false),
        const [8.0, 8.0, 8.0, 8.0, 8.0],
      );
      expect(
        NocheMic.barHeightsForLevel(double.negativeInfinity, startSide: true),
        const [8.0, 8.0, 8.0, 8.0, 8.0],
      );

      final monotonicLevels = [0.0, 0.25, 0.5, 0.75, 1.0];
      for (final startSide in [true, false]) {
        for (var i = 0; i < 5; i++) {
          var prev = 0.0;
          for (final lvl in monotonicLevels) {
            final h = NocheMic.barHeightsForLevel(lvl, startSide: startSide)[i];
            expect(h, greaterThanOrEqualTo(prev));
            if (lvl > 0.0) {
              expect(h, greaterThan(prev));
            }
            prev = h;
          }
        }
      }
    });

    testWidgets(
      'rendered bars match geometry and level heights in listening and theySpeak',
      (tester) async {
        for (final state in [
          NocheMicState.listening,
          NocheMicState.theySpeak,
        ]) {
          for (final lvl in testLevels) {
            await tester.pumpWidget(
              _wrap(
                Center(
                  child: NocheMic(
                    state: state,
                    language: _customLatinLanguage,
                    level: lvl,
                  ),
                ),
              ),
            );

            final expectedStart = NocheMic.barHeightsForLevel(
              lvl,
              startSide: true,
            );
            final expectedEnd = NocheMic.barHeightsForLevel(
              lvl,
              startSide: false,
            );

            final startGroupRect = tester.getRect(
              find.byKey(const ValueKey('noche_mic_bars_start')),
            );
            final discRect = tester.getRect(
              find.byKey(const ValueKey('noche_mic_disc')),
            );
            final endGroupRect = tester.getRect(
              find.byKey(const ValueKey('noche_mic_bars_end')),
            );

            expect(discRect.left - startGroupRect.right, closeTo(16.0, 0.01));
            expect(endGroupRect.left - discRect.right, closeTo(16.0, 0.01));

            for (final side in [
              ('start', expectedStart),
              ('end', expectedEnd),
            ]) {
              final rects = <Rect>[];
              for (var i = 0; i < 5; i++) {
                final finder = find.byKey(
                  ValueKey('noche_mic_bar_${side.$1}_$i'),
                );
                expect(finder, findsOneWidget);
                final size = tester.getSize(finder);
                expect(size.width, closeTo(4.0, 0.01));
                expect(size.height, closeTo(side.$2[i], 0.01));
                expect(size.height, inInclusiveRange(8.0, 56.0));
                rects.add(tester.getRect(finder));
              }
              for (var i = 1; i < 5; i++) {
                expect(rects[i].left - rects[i - 1].right, closeTo(4.0, 0.01));
              }
            }
          }
        }
      },
    );
  });

  group('NocheMic languages and RTL', () {
    testWidgets(
      'renders custom synthetic Language micWords for all six states',
      (tester) async {
        for (final state in NocheMicState.values) {
          await tester.pumpWidget(
            _wrap(
              Center(
                child: NocheMic(state: state, language: _customLatinLanguage),
              ),
            ),
          );
          expect(
            find.text(_customLatinLanguage.micWords[state.wordKey]!),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets(
      'Arabic RTL uses Noto Sans Arabic, Locale(ar), and mirrors start/end bars',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            Center(
              child: NocheMic(
                state: NocheMicState.listening,
                language: _arabicLanguage,
                level: 1.0,
              ),
            ),
            textDirection: TextDirection.rtl,
          ),
        );

        final textWidget = tester.widget<Text>(
          find.text(_arabicLanguage.micWords['listening']!),
        );
        expect(textWidget.locale, const Locale('ar'));
        expect(
          textWidget.style!.fontFamily,
          'packages/$coquiFontPackage/$nocheFontNotoSansArabic',
        );

        final startCenter = tester.getCenter(
          find.byKey(const ValueKey('noche_mic_bars_start')),
        );
        final discCenter = tester.getCenter(
          find.byKey(const ValueKey('noche_mic_disc')),
        );
        final endCenter = tester.getCenter(
          find.byKey(const ValueKey('noche_mic_bars_end')),
        );
        expect(startCenter.dx, greaterThan(discCenter.dx));
        expect(discCenter.dx, greaterThan(endCenter.dx));
      },
    );
  });

  group('NocheMic accessibility and touch target', () {
    testWidgets(
      'uses English NocheA11y labels by default even with overrides',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          expect(NocheA11y.lessonLabelsInCourseLanguage, isFalse);
          const expectedLabels = {
            NocheMicState.ready: 'Microphone, ready',
            NocheMicState.listening: 'Microphone, listening',
            NocheMicState.thinking: 'Microphone, thinking',
            NocheMicState.theySpeak: 'Microphone, they speak',
            NocheMicState.right: 'Microphone, heard right',
            NocheMicState.notYet: 'Microphone, not yet',
          };
          for (final entry in expectedLabels.entries) {
            await tester.pumpWidget(
              _wrap(
                Center(
                  child: NocheMic(
                    state: entry.key,
                    language: _customLatinLanguage,
                    onPressed: () {},
                  ),
                ),
              ),
            );
            expect(find.bySemanticsLabel(entry.value), findsOneWidget);
          }
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'uses course a11yWords when lessonLabelsInCourseLanguage is true and falls back when missing',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          NocheA11y.lessonLabelsInCourseLanguage = true;
          await tester.pumpWidget(
            _wrap(
              Center(
                child: NocheMic(
                  state: NocheMicState.ready,
                  language: _customLatinLanguage,
                  onPressed: () {},
                ),
              ),
            ),
          );
          expect(find.bySemanticsLabel('Course ready label'), findsOneWidget);

          // micNotYet is intentionally absent from _customLatinLanguage.a11yWords.
          await tester.pumpWidget(
            _wrap(
              Center(
                child: NocheMic(
                  state: NocheMicState.notYet,
                  language: _customLatinLanguage,
                  onPressed: () {},
                ),
              ),
            ),
          );
          expect(find.bySemanticsLabel('Microphone, not yet'), findsOneWidget);
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'touch target is 96x96, fires onPressed, and respects disabled',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          var taps = 0;
          await tester.pumpWidget(
            _wrap(
              Center(
                child: NocheMic(
                  state: NocheMicState.ready,
                  language: _customLatinLanguage,
                  onPressed: () => taps++,
                ),
              ),
            ),
          );

          final pressableFinder = find.byType(Pressable);
          final size = tester.getSize(pressableFinder);
          expect(size, const Size(96, 96));
          expect(size.width, greaterThanOrEqualTo(NocheSize.touch));
          expect(size.height, greaterThanOrEqualTo(NocheSize.touch));

          await tester.tap(pressableFinder);
          await tester.pump();
          expect(taps, 1);

          await tester.pumpWidget(
            _wrap(
              Center(
                child: NocheMic(
                  state: NocheMicState.ready,
                  language: _customLatinLanguage,
                  onPressed: null,
                ),
              ),
            ),
          );

          final semNode = tester.getSemantics(
            find.bySemanticsLabel('Microphone, ready'),
          );
          expect(semNode.flagsCollection.isEnabled.toBoolOrNull(), isFalse);

          await tester.tap(find.byType(Pressable));
          await tester.pump();
          expect(taps, 1);
        } finally {
          handle.dispose();
        }
      },
    );
  });

  group('NocheMic static guards', () {
    const guardedFiles = [
      'lib/src/noche_mic.dart',
      'lib/src/noche_a11y.dart',
      'tool/gallery/noche_mic.dart',
    ];

    test('no raw Color(0x...), fontFamily, left, non-directional APIs, or Spanish literals', () {
      final colorRe = RegExp(r'Color\s*\(\s*0x');
      final fontRe = RegExp(r'\bfontFamily\b');
      final leftRe = RegExp(r'\bleft\b', caseSensitive: false);
      final apiRe = RegExp(
        r'fromLTRB|topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight|EdgeInsets\.only|TextAlign\.left|TextAlign\.right|BorderRadius\.only|Positioned\s*\([^)]*(?:left|right)\s*:',
      );
      final spanishMicWords = Language.spanish.micWords.values.toList();

      for (final path in guardedFiles) {
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
        expect(
          leftRe.allMatches(content),
          isEmpty,
          reason: '$path contains left',
        );
        expect(
          apiRe.allMatches(content),
          isEmpty,
          reason: '$path contains non-directional layout API',
        );
        for (final word in spanishMicWords) {
          expect(
            content.contains(word),
            isFalse,
            reason: '$path contains hard-coded Spanish mic word',
          );
        }
      }

      final testContent = File('test/noche_mic_test.dart').readAsStringSync();
      for (final word in spanishMicWords) {
        expect(
          testContent.contains(word),
          isFalse,
          reason:
              'test/noche_mic_test.dart contains hard-coded Spanish mic word',
        );
      }
    });
  });

  group('NocheMic golden and phone dev page', () {
    testWidgets('6-state board golden matches Noche-Mic.dc.html', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(808, 568);
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(808, 568),
              devicePixelRatio: 1,
              disableAnimations: true,
            ),
            child: Material(
              color: NocheColors.ground,
              child: RepaintBoundary(
                key: key,
                child: NocheMicBoardShowcase(language: Language.spanish),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/noche_mic_states.png'),
      );
    });

    for (final size in const [Size(390, 844), Size(412, 915)]) {
      for (final dir in const [TextDirection.ltr, TextDirection.rtl]) {
        testWidgets(
          'NocheMicDevPage renders cleanly at ${size.width.toInt()}x${size.height.toInt()} ${dir.name} with >=48x48 targets',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: size,
                  devicePixelRatio: 1,
                  disableAnimations: true,
                ),
                child: Material(
                  color: NocheColors.ground,
                  child: NocheMicDevPage(textDirection: dir),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            // Walk all visible Pressable targets and scroll through the entire list.
            final scrollable = find.byType(Scrollable);
            var checkedTargets = 0;
            for (var step = 0; step < 6; step++) {
              final pressables = find.byType(Pressable);
              for (final element in pressables.evaluate()) {
                final box = element.renderObject! as RenderBox;
                expect(box.size.width, greaterThanOrEqualTo(NocheSize.touch));
                expect(box.size.height, greaterThanOrEqualTo(NocheSize.touch));
                checkedTargets++;
              }
              await tester.drag(scrollable, const Offset(0, -350));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            expect(checkedTargets, greaterThanOrEqualTo(6));
          },
        );
      }
    }
  });
}
