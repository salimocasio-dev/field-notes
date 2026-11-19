// Where each part of the voice test stands, against where habla-prueba.html puts it on the page itself
// (test/fixtures/prueba_layout.json, made by `node tool/prueba_layout.mjs`: getBoundingClientRect of each part at 412x915, 390x844,
// 360x640 and 844x390, before the mic and once the first line has been heard). A part whose width is its text's is held to its
// height and its centre: the old page draws text with Inter, this build with Roboto.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_speaking/src/voice_test_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/voice_fixture.dart';
import 'support/world.dart';

final Map<String, dynamic> expected = jsonDecode(
  File('test/fixtures/prueba_layout.json').readAsStringSync(),
) as Map<String, dynamic>;

List<double> old(Map<String, dynamic> part, String k) => [
  for (final v in part[k] as List) (v as num).toDouble(),
];

void main() {
  setUpAll(loadCoquiFonts);

  for (final e in (expected['sizes'] as Map<String, dynamic>).entries) {
    final size = e.value as Map<String, dynamic>;
    final phone = Phone(
      e.key,
      (size['width'] as num).toDouble(),
      (size['height'] as num).toDouble(),
      (size['ratio'] as num).toDouble(),
    );

    testWidgets(
      'the layout is the old page\'s, before the mic and with a line heard: ${e.key}',
      (tester) async {
        phone.use(tester);
        final w = await World.create(
          seed: null,
          speech: FakeSpeechListener.stub('hola abuela|none|no/nó'),
          reduceMotion: true,
        );
        await tester.pumpWidget(
          w.app(VoiceTestScreen(services: w.services, content: voiceFixture)),
        );
        await tester.pump();
        await tester.pump();

        Rect dash(int k) => tester.getRect(
          find
              .byWidgetPredicate(
                (x) => x is AnimatedContainer && x.constraints?.maxHeight == 6,
              )
              .at(k),
        );
        Rect disc() => tester.getRect(
          find.byWidgetPredicate((x) => x.runtimeType.toString() == '_Disc'),
        );

        void near(
          String when,
          String k,
          Rect r,
          Map<String, dynamic> parts, {
          bool sides = true,
          bool centre = false,
        }) {
          final o = old(parts, k);
          final why =
              '$when $k in ${e.key}: old $o, here ${[r.top, r.bottom, r.left, r.right]}';
          expect(r.top, closeTo(o[0], .6), reason: why);
          expect(r.bottom, closeTo(o[1], .6), reason: why);
          if (sides) {
            expect(r.left, closeTo(o[2], .6), reason: why);
            expect(r.right, closeTo(o[3], .6), reason: why);
          }
          if (centre) {
            expect(
              (r.left + r.right) / 2,
              closeTo((o[2] + o[3]) / 2, .6),
              reason: why,
            );
          }
        }

        void compare(String when, Map<String, dynamic> parts, bool done) {
          // the bar: from the first dash to the last, as tall as a dash
          final first = dash(0);
          final last = dash(11);
          near(
            when,
            '#bar',
            Rect.fromLTRB(first.left, first.top, last.right, first.bottom),
            parts,
          );
          near(
            when,
            '#ins',
            tester.getRect(find.text('Tap the mic and say each Spanish line.')),
            parts,
            sides: false,
            centre: true,
          );
          near(
            when,
            '#n',
            tester.getRect(find.textContaining(' / 12')),
            parts,
            sides: false,
            centre: true,
          );
          near(
            when,
            '#line',
            tester.getRect(find.text(done ? 'Hola, abuela' : 'Hola, abuela')),
            parts,
            sides: false,
            centre: true,
          );
          near(
            when,
            '#heard',
            tester.getRect(
              find
                  .ancestor(
                    of: find.byType(Row),
                    matching: find.byType(Visibility),
                  )
                  .first,
            ),
            parts,
            sides: false,
          );
          near(when, done ? '#next' : '#mic', disc(), parts);
        }

        compare('ready', size['ready'] as Map<String, dynamic>, false);
        await tester.tap(
          find.byWidgetPredicate(
            (x) => x is Semantics && x.properties.label == 'Micrófono',
          ),
        );
        await w.elapse(tester, 700);
        compare('done', size['done'] as Map<String, dynamic>, true);
        await w.close(tester);
      },
    );
  }
}
