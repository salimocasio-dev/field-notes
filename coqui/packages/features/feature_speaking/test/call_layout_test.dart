// Where each part of the call screen stands, against where llamada.js puts it on the page itself (test/fixtures/llamada_layout.json,
// made by `node tool/llamada_layout.mjs`: getBoundingClientRect of each part of #llam at 412x915, 390x844, 360x640 and 844x390, before
// the call and with Danny speaking). A part whose width is its text's (the timer, the state label) is held to its height and its
// centre or edge: the old page draws text with Inter, this build with Roboto.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_look.dart';
import 'package:feature_speaking/src/call_mic.dart';
import 'package:feature_speaking/src/call_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/world.dart';

final Map<String, dynamic> expected = jsonDecode(
  File('test/fixtures/llamada_layout.json').readAsStringSync(),
) as Map<String, dynamic>;

/// [top, bottom, left, right] as the old page gave them.
List<double> old(Map<String, dynamic> part, String k) => [
  for (final v in part[k] as List) (v as num).toDouble(),
];

Finder textStyled(TextStyle style, [String? data]) => find.byWidgetPredicate(
  (w) => w is Text && w.style == style && (data == null || w.data == data),
);

void main() {
  setUpAll(loadCoquiFonts);

  final sizes = (expected['sizes'] as Map<String, dynamic>).entries.toList();

  for (final e in sizes) {
    final size = e.value as Map<String, dynamic>;
    final phone = Phone(
      e.key,
      (size['width'] as num).toDouble(),
      (size['height'] as num).toDouble(),
      (size['ratio'] as num).toDouble(),
    );

    testWidgets(
      'the layout is the old page\'s, before the call and with Danny speaking: ${e.key}',
      (tester) async {
        phone.use(tester);
        final w = await World.create(
          seed: 'todo',
          stub: {'manual'},
          reduceMotion: true,
        );
        await tester.pumpWidget(
          w.app(CallScreen(services: w.services, placeId: 'casa')),
        );
        await tester.pump();

        void compare(
          String when,
          Map<String, dynamic> parts,
          String line,
          String label,
        ) {
          void rect(
            String k,
            Rect r, {
            bool top = true,
            bool bottom = true,
            bool left = true,
            bool right = true,
          }) {
            final o = old(parts, k);
            final why =
                '$when $k in ${e.key}: old $o, here ${[r.top, r.bottom, r.left, r.right]}';
            if (top) expect(r.top, closeTo(o[0], .6), reason: why);
            if (bottom) expect(r.bottom, closeTo(o[1], .6), reason: why);
            if (left) expect(r.left, closeTo(o[2], .6), reason: why);
            if (right) expect(r.right, closeTo(o[3], .6), reason: why);
          }

          rect('.lx', tester.getRect(find.byType(LessonCloseButton)));
          rect('canvas', tester.getRect(find.byType(PictureFrame)));
          rect('.lmic', tester.getRect(find.byType(CallMicStage)));
          rect(
            '.ldisc',
            tester.getRect(
              find
                  .descendant(
                    of: find.byType(CallMicStage),
                    matching: find.byType(AnimatedContainer),
                  )
                  .last,
            ),
          );
          rect('.lhelp', tester.getRect(find.byType(LessonButton)));
          rect('.ld', tester.getRect(find.text(line)));
          rect('.lh', tester.getRect(textStyled(CallText.heard)));
          // the timer: its height and its right edge; the label: its height and its centre; the note: its height and its centre
          rect('.lt', tester.getRect(textStyled(CallText.timer)), left: false);
          rect(
            '.ll',
            tester.getRect(find.text(label)),
            left: false,
            right: false,
          );
          // centred under the disc in a portrait screen, starting where the old page starts it on its side
          final lbl = tester.getRect(find.text(label));
          final o = old(parts, '.ll');
          if (phone.width > phone.height) {
            expect(
              lbl.left,
              closeTo(o[2], .6),
              reason: '$when label left in ${e.key}',
            );
          } else {
            expect(
              lbl.center.dx,
              closeTo((o[2] + o[3]) / 2, .6),
              reason: '$when label centre in ${e.key}',
            );
          }
          rect(
            '.lo',
            tester.getRect(find.byKey(const ValueKey('call-note'))),
            left: false,
            right: false,
          );
        }

        compare(
          'idle',
          size['idle'] as Map<String, dynamic>,
          'La casa · about 5 min',
          'Start call',
        );
        await tester.tap(find.byType(CallMicStage));
        await tester.pump();
        w.call.go('connect');
        w.call.go('danny1');
        await w.elapse(tester, 500);
        compare(
          'live',
          size['live'] as Map<String, dynamic>,
          '¡Hola! Soy Danny. ¿Cómo estás?',
          'Danny',
        );
        await w.close(tester);
      },
    );
  }
}
