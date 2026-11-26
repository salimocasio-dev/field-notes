// Static and widget Noche migration checks for feature_review.
import 'dart:io';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/repaso_course.dart';

void main() {
  final libDir = Directory(
    '${repoRoot.path}/coqui/packages/features/feature_review/lib',
  );
  final uiDir = Directory('${libDir.path}/src/ui');

  List<File> dartFiles(Directory dir) =>
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  String stripComments(String src) => src
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//.*$', multiLine: true), '');

  test('lib/ has zero raw hex Color literals, fontFamily, or flutter/material.dart', () {
    final hexColorRe = RegExp(r'Color\s*\(\s*0x');
    final fontRe = RegExp(r'\bfontFamily\b');
    for (final f in dartFiles(libDir)) {
      final src = stripComments(f.readAsStringSync());
      expect(hexColorRe.allMatches(src), isEmpty, reason: f.path);
      expect(fontRe.allMatches(src), isEmpty, reason: f.path);
      expect(
        src,
        isNot(contains('package:flutter/material.dart')),
        reason: f.path,
      );
    }
  });

  test('lib/src/ui/ has zero CoquiColors, CoquiText, or CoquiIcon(s)', () {
    for (final f in dartFiles(uiDir)) {
      final src = stripComments(f.readAsStringSync());
      expect(src, isNot(contains('CoquiColors')), reason: f.path);
      expect(src, isNot(contains('CoquiText')), reason: f.path);
      expect(src, isNot(contains('CoquiIcon')), reason: f.path);
    }
  });

  test('lib/ has zero legacy lesson/game widgets', () {
    const legacy = [
      'LessonFrame',
      'LessonProgressDashes',
      'LessonButton',
      'LessonStartButton',
      'PictureChoice',
      'WordTile',
      'SpeakerTile',
      'TileTray',
      'WrongBadge',
      'RepasoMic',
    ];
    for (final f in dartFiles(libDir)) {
      final src = stripComments(f.readAsStringSync());
      for (final symbol in legacy) {
        expect(
          RegExp('\\b$symbol\\b').hasMatch(src),
          isFalse,
          reason: '${f.path} still references $symbol',
        );
      }
    }
  });

  testWidgets(
    'ChoiceRing.wrong and ChoiceRing.selected are visually distinct on pictures and tiles (white outline + badge vs plain white outline, never red)',
    (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: NocheColors.lessonGround,
            body: Column(
              children: [
                NochePictureChoice(
                  key: ValueKey('pic-wrong'),
                  ring: ChoiceRing.wrong,
                  inside: true,
                  child: SizedBox(width: 80, height: 60),
                ),
                NochePictureChoice(
                  key: ValueKey('pic-selected'),
                  ring: ChoiceRing.selected,
                  inside: true,
                  child: SizedBox(width: 80, height: 60),
                ),
                NocheWordTile(
                  key: ValueKey('tile-wrong'),
                  word: 'casa',
                  ring: ChoiceRing.wrong,
                ),
                NocheWordTile(
                  key: ValueKey('tile-selected'),
                  word: 'puerta',
                  ring: ChoiceRing.selected,
                ),
              ],
            ),
          ),
        ),
      );

      // Wrong picture & wrong tile ALWAYS show the white-outlined NocheWrongBadge
      // even when cross is not explicitly passed, while selected shows none.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pic-wrong')),
          matching: find.byType(NocheWrongBadge),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pic-selected')),
          matching: find.byType(NocheWrongBadge),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tile-wrong')),
          matching: find.byType(NocheWrongBadge),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tile-selected')),
          matching: find.byType(NocheWrongBadge),
        ),
        findsNothing,
      );

      // Ring colour on wrong is white outline (NocheColors.text), never red.
      final picBorder =
          (t
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byKey(const ValueKey('pic-wrong')),
                          matching: find.byWidgetPredicate(
                            (w) =>
                                w is DecoratedBox &&
                                w.decoration is BoxDecoration &&
                                (w.decoration as BoxDecoration).shape ==
                                    BoxShape.rectangle &&
                                (w.decoration as BoxDecoration).border != null,
                          ),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .border!
              .top;
      expect(picBorder.color, NocheColors.text);
      expect(picBorder.color, isNot(CoquiColors.lessonBad));
    },
  );

  testWidgets(
    'NocheReviewDashes distinguishes current item (listening ring) from missed item (white outline)',
    (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: NocheColors.lessonGround,
            body: NocheReviewDashes(
              segments: 3,
              marks: [DashMark.wrong, DashMark.none, DashMark.right],
              current: 1,
            ),
          ),
        ),
      );
      final containers = t
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(NocheReviewDashes),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .toList();
      expect(containers, hasLength(3));
      final wrongDec = containers[0].decoration! as BoxDecoration;
      final currentDec = containers[1].decoration! as BoxDecoration;
      final rightDec = containers[2].decoration! as BoxDecoration;
      expect(wrongDec.color, NocheColors.lessonGround);
      expect(wrongDec.border?.top.color, NocheColors.text);
      expect(wrongDec.boxShadow, isNull);
      expect(currentDec.color, NocheColors.lessonLine);
      expect(currentDec.border, isNull);
      expect(currentDec.boxShadow?.single.color, NocheColors.listening);
      expect(rightDec.color, NocheColors.right);
    },
  );
}
