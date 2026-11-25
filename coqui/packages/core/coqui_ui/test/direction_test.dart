import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/gallery/lesson_direction.dart';

Widget _wrap(
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
  Size size = const Size(390, 844),
  EdgeInsets padding = EdgeInsets.zero,
  double dpr = 1.0,
}) => Directionality(
  textDirection: textDirection,
  child: MediaQuery(
    data: MediaQueryData(size: size, padding: padding, devicePixelRatio: dpr),
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Material(color: CoquiColors.lessonBg, child: child),
      ),
    ),
  ),
);

Future<Uint8List> _captureBytes(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final out = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final bytes = Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    image.dispose();
    return bytes;
  });
  return out!;
}

void main() {
  setUpAll(() async {
    final roboto = FontLoader('packages/coqui_ui/Roboto');
    for (final f in coquiFontFiles.values) {
      roboto.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await roboto.load();

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

  group('Static directional audit across all lib/src/*.dart', () {
    test('zero non-directional layout APIs in lib/src/*.dart', () {
      final nonDirectionalRe = RegExp(
        r'EdgeInsets\.fromLTRB|EdgeInsets\.only\(|'
        r'Alignment\.(topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight)|'
        r'TextAlign\.(left|right)|'
        r'\bPositioned\(|'
        r'\bAnimatedPositioned\(|'
        r'BorderRadius\.only\(',
      );
      final files =
          Directory('lib/src')
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      expect(files, isNotEmpty);
      for (final file in files) {
        final src = file.readAsStringSync();
        final matches = nonDirectionalRe.allMatches(src).toList();
        expect(
          matches.map((m) => m.group(0)).toList(),
          isEmpty,
          reason: '${file.path} contains non-directional layout API',
        );
      }
    });

    test('zero left/right layout APIs or raw hex colors in new files', () {
      const files = [
        'lib/src/speech_bubble.dart',
        'tool/gallery/lesson_direction.dart',
      ];
      final rawColorRe = RegExp(r'Color\s*\(\s*0x');
      final nonDirRe = RegExp(
        r'fromLTRB|topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight|'
        r'EdgeInsets\.only|TextAlign\.left|TextAlign\.right|BorderRadius\.only|'
        r'\bPositioned\(|\bAnimatedPositioned\(',
      );
      for (final path in files) {
        final src = File(path).readAsStringSync();
        expect(
          rawColorRe.allMatches(src),
          isEmpty,
          reason: '$path has raw Color(0x...)',
        );
        expect(
          nonDirRe.allMatches(src),
          isEmpty,
          reason: '$path has non-directional layout API',
        );
      }
    });
  });

  group('LanguageUi / LanguageDirectionUi', () {
    test('maps direction and locale for Spanish and Arabic', () {
      expect(LanguageDirection.ltr.textDirection, TextDirection.ltr);
      expect(LanguageDirection.rtl.textDirection, TextDirection.rtl);
      expect(Language.spanish.textDirection, TextDirection.ltr);
      expect(Language.spanish.locale, const Locale('es'));
      expect(lessonDirectionArabicLanguage.textDirection, TextDirection.rtl);
      expect(lessonDirectionArabicLanguage.locale, const Locale('ar'));
    });
  });

  group('LessonSpeechBubble', () {
    testWidgets('Spanish LTR vs Arabic RTL direction, locale, and font', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LessonSpeechBubble(
                text: '¡Hola! ¿Quieres bizcocho?',
                language: Language.spanish,
              ),
              LessonSpeechBubble(
                text: 'مرحباً! هل تريد كعكة؟',
                language: lessonDirectionArabicLanguage,
              ),
            ],
          ),
        ),
      );
      final esText = tester.widget<Text>(
        find.text('¡Hola! ¿Quieres bizcocho?'),
      );
      expect(esText.textDirection, TextDirection.ltr);
      expect(esText.locale, const Locale('es'));
      expect(esText.style!.fontFamily, 'packages/coqui_ui/Roboto');

      final arText = tester.widget<Text>(find.text('مرحباً! هل تريد كعكة؟'));
      expect(arText.textDirection, TextDirection.rtl);
      expect(arText.locale, const Locale('ar'));
      expect(
        arText.style!.fontFamily,
        'packages/coqui_ui/$nocheFontNotoSansArabic',
      );
    });

    testWidgets(
      'explicit lesson-language direction overrides opposite ambient Directionality',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            textDirection: TextDirection.ltr,
            LessonSpeechBubble(
              text: 'مرحباً',
              language: lessonDirectionArabicLanguage,
              tailSide: BubbleTailSide.start,
            ),
          ),
        );
        final dir = tester.widget<Directionality>(
          find.descendant(
            of: find.byType(LessonSpeechBubble),
            matching: find.byType(Directionality),
          ),
        );
        expect(dir.textDirection, TextDirection.rtl);
        final arText = tester.widget<Text>(find.text('مرحباً'));
        expect(arText.textDirection, TextDirection.rtl);

        // Tail on start in RTL is physically on the right edge (start > left).
        final bodyRect = tester.getRect(find.byType(Container).first);
        final tailRect = tester.getRect(
          find.descendant(
            of: find.byType(LessonSpeechBubble),
            matching: find.byType(CustomPaint),
          ),
        );
        expect(tailRect.center.dx, greaterThan(bodyRect.center.dx));

        // Now opposite: Spanish inside RTL shell.
        await tester.pumpWidget(
          _wrap(
            textDirection: TextDirection.rtl,
            LessonSpeechBubble(
              text: 'Hola',
              language: Language.spanish,
              tailSide: BubbleTailSide.start,
            ),
          ),
        );
        final esDir = tester.widget<Directionality>(
          find.descendant(
            of: find.byType(LessonSpeechBubble),
            matching: find.byType(Directionality),
          ),
        );
        expect(esDir.textDirection, TextDirection.ltr);
        final esBodyRect = tester.getRect(find.byType(Container).first);
        final esTailRect = tester.getRect(
          find.descendant(
            of: find.byType(LessonSpeechBubble),
            matching: find.byType(CustomPaint),
          ),
        );
        expect(esTailRect.center.dx, lessThan(esBodyRect.center.dx));
      },
    );

    testWidgets('supports bottom, start, end, none tails and light/dark', (
      tester,
    ) async {
      for (final side in BubbleTailSide.values) {
        for (final dark in [false, true]) {
          await tester.pumpWidget(
            _wrap(
              LessonSpeechBubble(
                text: 'Hola',
                language: Language.spanish,
                tailSide: side,
                dark: dark,
              ),
            ),
          );
          final paints = find.descendant(
            of: find.byType(LessonSpeechBubble),
            matching: find.byType(CustomPaint),
          );
          if (side == BubbleTailSide.none) {
            expect(paints, findsNothing);
          } else {
            expect(paints, findsOneWidget);
          }
          final container = tester.widget<Container>(
            find.descendant(
              of: find.byType(LessonSpeechBubble),
              matching: find.byType(Container),
            ),
          );
          final dec = container.decoration! as BoxDecoration;
          expect(dec.color, dark ? NocheColors.panel : CoquiColors.white);
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('Cyrillic Cyrl uses platform fallback and reports unbundled', (
      tester,
    ) async {
      NocheType.unbundledScripts.clear();
      final cyrlLang = Language(
        code: 'ru',
        englishName: 'Russian',
        nativeName: 'Русский',
        recognitionLocale: 'ru-RU',
        direction: LanguageDirection.ltr,
        script: 'Cyrl',
        partnerName: 'Ivan',
        callAgentId: 'test_cyrl',
        micWords: const {
          'ready': 'Говори',
          'listening': 'Слушаю',
          'thinking': 'Секунду',
          'theySpeak': 'Слушай',
          'right': 'Верно',
          'notYet': 'Ещё раз',
        },
        tabNames: const {
          'library': 'Библиотека',
          'words': 'Слова',
          'map': 'Карта',
          'speak': 'Говорить',
          'me': 'Я',
        },
      );
      await tester.pumpWidget(
        _wrap(LessonSpeechBubble(text: 'Привет', language: cyrlLang)),
      );
      final text = tester.widget<Text>(find.text('Привет'));
      expect(text.style!.fontFamily, isNull);
      expect(NocheType.unbundledScripts, contains('Cyrl'));
    });
  });

  group('Directional LTR vs RTL widget behavior', () {
    testWidgets('LessonProgressLine fills from start in LTR and RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LessonProgressLine(value: 0.25),
          textDirection: TextDirection.ltr,
        ),
      );
      final ltrBox = tester.getRect(
        find.descendant(
          of: find.byType(LessonProgressLine),
          matching: find.byType(ColoredBox),
        ),
      );
      final ltrTrack = tester.getRect(find.byType(LessonProgressLine));
      expect(ltrBox.left, closeTo(ltrTrack.left, 1));
      expect(ltrBox.width, closeTo(ltrTrack.width * 0.25, 1));

      await tester.pumpWidget(
        _wrap(
          const LessonProgressLine(value: 0.25),
          textDirection: TextDirection.rtl,
        ),
      );
      final rtlBox = tester.getRect(
        find.descendant(
          of: find.byType(LessonProgressLine),
          matching: find.byType(ColoredBox),
        ),
      );
      final rtlTrack = tester.getRect(find.byType(LessonProgressLine));
      expect(rtlBox.right, closeTo(rtlTrack.right, 1));
      expect(rtlBox.width, closeTo(rtlTrack.width * 0.25, 1));
    });

    testWidgets(
      'LessonFrame portrait/landscape, caption script, and 2-line Arabic non-clipping',
      (tester) async {
        const longArabic =
            'تقول جدة: مرحباً! هل تريد كعكة لذيذة اليوم في البيت الكبير مع الطائر؟';
        await tester.pumpWidget(
          _wrap(
            textDirection: TextDirection.rtl,
            LessonFrame(
              onClose: () {},
              onSound: () {},
              language: lessonDirectionArabicLanguage,
              caption: longArabic,
              picture: const SizedBox(width: 196, height: 104),
              bottom: [LessonStartButton(onPressed: () {})],
            ),
          ),
        );
        final closeCenter = tester.getCenter(find.byType(LessonCloseButton));
        final soundCenter = tester.getCenter(find.byType(LessonSoundButton));
        expect(closeCenter.dx, greaterThan(soundCenter.dx));

        final capText = tester.widget<Text>(find.text(longArabic));
        expect(capText.textDirection, TextDirection.rtl);
        expect(capText.locale, const Locale('ar'));
        expect(
          capText.style!.fontFamily,
          'packages/coqui_ui/$nocheFontNotoSansArabic',
        );
        // Verify OverflowBox maxHeight accommodates 2 lines of Arabic without clipping.
        final overflowBox = tester.widget<OverflowBox>(
          find.ancestor(
            of: find.text(longArabic),
            matching: find.byType(OverflowBox),
          ),
        );
        final lineH = capText.style!.fontSize! * capText.style!.height!;
        expect(overflowBox.maxHeight, greaterThanOrEqualTo(lineH * 2));
        expect(tester.takeException(), isNull);

        // Landscape mode: picture on end (right) in RTL, controls column on start (left).
        await tester.pumpWidget(
          _wrap(
            textDirection: TextDirection.rtl,
            size: const Size(844, 390),
            LessonFrame(
              onClose: () {},
              onSound: () {},
              language: lessonDirectionArabicLanguage,
              caption: 'انظر إلى بيت جدة.',
              picture: const SizedBox(
                key: ValueKey('pic'),
                width: 196,
                height: 104,
              ),
              bottom: [LessonStartButton(onPressed: () {})],
            ),
          ),
        );
        final picCenter = tester.getCenter(find.byKey(const ValueKey('pic')));
        final lsCloseCenter = tester.getCenter(find.byType(LessonCloseButton));
        expect(picCenter.dx, greaterThan(lsCloseCenter.dx));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('PictureChoice badges sit on end edge in LTR and RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.ltr,
          const Center(
            child: PictureChoice(
              check: true,
              child: SizedBox(width: 120, height: 100),
            ),
          ),
        ),
      );
      final ltrBox = tester.getRect(find.byType(PictureChoice));
      final ltrBadge = tester.getRect(find.byType(CheckBadge));
      expect(
        ltrBadge.right,
        closeTo(ltrBox.right - CoquiMetrics.badgeInset, 1),
      );

      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.rtl,
          const Center(
            child: PictureChoice(
              check: true,
              child: SizedBox(width: 120, height: 100),
            ),
          ),
        ),
      );
      final rtlBox = tester.getRect(find.byType(PictureChoice));
      final rtlBadge = tester.getRect(find.byType(CheckBadge));
      expect(rtlBadge.left, closeTo(rtlBox.left + CoquiMetrics.badgeInset, 1));
    });

    testWidgets('CoquiSheet title/close mirror in RTL', (tester) async {
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.rtl,
          CoquiSheet(
            title: 'البيت',
            onClose: () {},
            child: const SizedBox(height: 100),
          ),
        ),
      );
      final titleRect = tester.getRect(find.text('البيت'));
      final closeRect = tester.getRect(find.byType(CoquiCloseButton));
      expect(titleRect.right, greaterThan(closeRect.right));
    });

    testWidgets('CoquiSwitch knob slides start->end in LTR and RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.ltr,
          CoquiSwitch(value: false, onChanged: (_) {}),
        ),
      );
      final ltrOffX = tester
          .getCenter(
            find.descendant(
              of: find.byType(AnimatedPositionedDirectional),
              matching: find.byType(Container),
            ),
          )
          .dx;
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.ltr,
          CoquiSwitch(value: true, onChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      final ltrOnX = tester
          .getCenter(
            find.descendant(
              of: find.byType(AnimatedPositionedDirectional),
              matching: find.byType(Container),
            ),
          )
          .dx;
      expect(ltrOnX, greaterThan(ltrOffX));

      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.rtl,
          CoquiSwitch(key: UniqueKey(), value: false, onChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      final rtlOffX = tester
          .getCenter(
            find.descendant(
              of: find.byType(AnimatedPositionedDirectional),
              matching: find.byType(Container),
            ),
          )
          .dx;
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.rtl,
          CoquiSwitch(value: true, onChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      final rtlOnX = tester
          .getCenter(
            find.descendant(
              of: find.byType(AnimatedPositionedDirectional),
              matching: find.byType(Container),
            ),
          )
          .dx;
      expect(rtlOnX, lessThan(rtlOffX));
    });

    testWidgets(
      'WordTile speaker, badges, TouchSign, Arabic script/direction mirror in RTL',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            textDirection: TextDirection.rtl,
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WordTile(
                    word: 'بيت',
                    language: lessonDirectionArabicLanguage,
                    onTap: () {},
                    onSpeaker: () {},
                    check: true,
                    number: 1,
                  ),
                  const SizedBox(height: 16),
                  WordTile(
                    word: 'باب',
                    language: lessonDirectionArabicLanguage,
                    onTap: () {},
                    sign: true,
                    still: true,
                  ),
                ],
              ),
            ),
          ),
        );
        final tiles = find.byType(WordTile);
        final firstRect = tester.getRect(tiles.at(0));
        final speakerRect = tester.getRect(
          find.bySemanticsLabel('Hear the word'),
        );
        expect(speakerRect.center.dx, lessThan(firstRect.center.dx));

        final badgeRect = tester.getRect(find.byType(CheckBadge));
        expect(badgeRect.left, lessThan(firstRect.left));

        final numRect = tester.getRect(find.byType(NumberBadge));
        expect(numRect.center.dx, lessThan(firstRect.center.dx));

        final secondRect = tester.getRect(tiles.at(1));
        final signRect = tester.getRect(find.byType(TouchSign));
        expect(signRect.center.dx, lessThan(secondRect.center.dx));

        final text = tester.widget<Text>(find.text('بيت'));
        expect(text.textDirection, TextDirection.rtl);
        expect(text.locale, const Locale('ar'));
        expect(
          text.style!.fontFamily,
          'packages/coqui_ui/$nocheFontNotoSansArabic',
        );
      },
    );

    testWidgets('TileTray(line: true) starts from start edge in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.rtl,
          TileTray(
            line: true,
            children: [
              WordTile(word: 'بيت', language: lessonDirectionArabicLanguage),
            ],
          ),
        ),
      );
      final trayRect = tester.getRect(find.byType(TileTray));
      final tileRect = tester.getRect(find.byType(WordTile));
      expect(tileRect.right, closeTo(trayRect.right, 1));
    });

    testWidgets('StreakChip(reserve: true) aligns to end in LTR and RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.ltr,
          const Center(child: StreakChip(count: 4, reserve: true)),
        ),
      );
      final ltrBox = tester.getRect(find.byType(StreakChip));
      final ltrPill = tester.getRect(find.text('4 in a row'));
      expect(ltrPill.right, greaterThan(ltrBox.center.dx));

      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.rtl,
          const Center(child: StreakChip(count: 4, reserve: true)),
        ),
      );
      final rtlBox = tester.getRect(find.byType(StreakChip));
      final rtlPill = tester.getRect(find.text('4 in a row'));
      expect(rtlPill.left, lessThan(rtlBox.center.dx));
    });

    testWidgets('CoquiTabBar places raised disc over raisedId in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.rtl,
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: CoquiTabBar(selectedId: CoquiTabs.mapId, onTap: (_) {}),
          ),
        ),
      );
      final mapLabelCenter = tester.getCenter(find.text(CoquiLabels.map));
      final barRect = tester.getRect(find.byType(CoquiTabBar));
      expect(mapLabelCenter.dx, closeTo(barRect.center.dx, 2));

      // Non-middle raisedId mirrors cleanly with AlignmentDirectional in RTL.
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.rtl,
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: CoquiTabBar(
              selectedId: CoquiTabs.libraryId,
              raisedId: CoquiTabs.libraryId,
              onTap: (_) {},
            ),
          ),
        ),
      );
      final libLabelCenter = tester.getCenter(find.text(CoquiLabels.library));
      expect(libLabelCenter.dx, greaterThan(barRect.center.dx));
    });

    testWidgets('LessonBackButton/LessonNextButton mirror icons in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.ltr,
          Row(
            children: [
              LessonBackButton(onPressed: () {}),
              LessonNextButton(onPressed: () {}),
            ],
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(LessonBackButton),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(LessonNextButton),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );

      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.rtl,
          Row(
            children: [
              LessonBackButton(onPressed: () {}),
              LessonNextButton(onPressed: () {}),
            ],
          ),
        ),
      );
      final flipsInBack = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(LessonBackButton),
          matching: find.byType(Transform),
        ),
      );
      expect(flipsInBack.any((t) => t.transform.storage[0] == -1.0), isTrue);
      final flipsInNext = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(LessonNextButton),
          matching: find.byType(Transform),
        ),
      );
      expect(flipsInNext.any((t) => t.transform.storage[0] == -1.0), isTrue);
    });

    testWidgets('NocheMic sets explicit RTL textDirection inside LTR shell', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          textDirection: TextDirection.ltr,
          Center(
            child: NocheMic(
              state: NocheMicState.ready,
              language: lessonDirectionArabicLanguage,
              onPressed: () {},
            ),
          ),
        ),
      );
      final statusText = tester.widget<Text>(
        find.text(lessonDirectionArabicLanguage.micWords['ready']!),
      );
      expect(statusText.textDirection, TextDirection.rtl);
      expect(statusText.locale, const Locale('ar'));
    });
  });

  group('PixelView unmirrored in RTL', () {
    testWidgets(
      'asymmetric pixel buffer renders identically in LTR and RTL and tap returns physical (x, y)',
      (tester) async {
        const w = 16;
        const h = 8;
        final pixels = Uint32List(w * h);
        const red = 0xFF0000FF; // 0xAABBGGRR -> R=255, G=0, B=0
        const blue = 0xFFFF0000; // 0xAABBGGRR -> R=0, G=0, B=255
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            pixels[y * w + x] = x < w ~/ 2 ? red : blue;
          }
        }

        Future<Uint8List> render(TextDirection dir) async {
          final key = GlobalKey();
          await tester.pumpWidget(
            _wrap(
              textDirection: dir,
              size: const Size(160, 80),
              Center(
                child: RepaintBoundary(
                  key: key,
                  child: PixelView(pixels: pixels, width: w, height: h),
                ),
              ),
            ),
          );
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
          return _captureBytes(tester, key);
        }

        final ltrBytes = await render(TextDirection.ltr);
        final rtlBytes = await render(TextDirection.rtl);
        expect(rtlBytes, equals(ltrBytes));
        // Physical left pixel (0,0) is red; physical right pixel (159,0) is blue (scaled 10x).
        expect(rtlBytes[0], 255); // R
        expect(rtlBytes[2], 0); // B
        const rightByte = (160 - 1) * 4;
        expect(rtlBytes[rightByte], 0); // R
        expect(rtlBytes[rightByte + 2], 255); // B

        // Tap physical left & right inside RTL and verify coordinates.
        final tapped = <(int, int)>[];
        await tester.pumpWidget(
          _wrap(
            textDirection: TextDirection.rtl,
            size: const Size(160, 80),
            Center(
              child: PixelView(
                pixels: pixels,
                width: w,
                height: h,
                onTapPixel: (x, y) => tapped.add((x, y)),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        final rect = tester.getRect(find.byType(PixelView));
        await tester.tapAt(Offset(rect.left + 2, rect.top + 2));
        await tester.tapAt(Offset(rect.right - 2, rect.top + 2));
        expect(tapped.length, 2);
        expect(tapped[0].$1, lessThan(4));
        expect(tapped[1].$1, greaterThan(w - 5));
      },
    );
  });

  group('LessonDirectionGalleryPage', () {
    for (final size in [const Size(390, 844), const Size(412, 915)]) {
      testWidgets(
        'renders Spanish (LTR) and Arabic (RTL) without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);

          // Spanish (LTR)
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: coquiTheme(),
              home: Scaffold(
                body: LessonDirectionGalleryPage(language: Language.spanish),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.text('Mira la casa de abuela.'), findsOneWidget);
          expect(
            find.text('Abuela dice: ¡Hola! ¿Quieres bizcocho?'),
            findsOneWidget,
          );
          expect(find.byType(PixelView), findsOneWidget);
          final esCloseX = tester.getCenter(find.byType(LessonCloseButton)).dx;
          final esSoundX = tester.getCenter(find.byType(LessonSoundButton)).dx;
          expect(esCloseX, lessThan(esSoundX));

          // Arabic (RTL)
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: coquiTheme(),
              home: Scaffold(
                body: LessonDirectionGalleryPage(
                  language: lessonDirectionArabicLanguage,
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.text('انظر إلى بيت جدة.'), findsOneWidget);
          expect(find.text('تقول جدة: مرحباً! هل تريد كعكة؟'), findsOneWidget);
          expect(find.byType(PixelView), findsOneWidget);
          final arCloseX = tester.getCenter(find.byType(LessonCloseButton)).dx;
          final arSoundX = tester.getCenter(find.byType(LessonSoundButton)).dx;
          expect(arCloseX, greaterThan(arSoundX));
        },
      );
    }
  });
}
