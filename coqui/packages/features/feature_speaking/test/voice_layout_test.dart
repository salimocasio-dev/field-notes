// Noche layout geometry checks for VoiceTestScreen across all 4 phone sizes
// (412x915, 390x844, 360x640, 844x390) in ready, listening (with bars), and
// done states.
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_look.dart';
import 'package:feature_speaking/src/voice_test_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/voice_fixture.dart';
import 'support/world.dart';

void main() {
  setUpAll(loadCoquiFonts);

  const phones = [Phone.android, Phone.iphone, Phone.small, Phone.side];

  for (final phone in phones) {
    testWidgets(
      'Noche voice test layout has zero overflows or overlaps in ready, listen, and done: ${phone.name}',
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

        void verifyGeometry(String stage, {required bool showNext}) {
          expect(
            tester.takeException(),
            isNull,
            reason: '$stage in ${phone.name}',
          );
          final screen = Rect.fromLTWH(0, 0, phone.width, phone.height);
          final firstDash = tester.getRect(
            find.byKey(const ValueKey('noche_dash_0')),
          );
          final lastDash = tester.getRect(
            find.byKey(const ValueKey('noche_dash_11')),
          );
          final dashesRect = Rect.fromLTRB(
            firstDash.left,
            firstDash.top,
            lastDash.right,
            lastDash.bottom,
          );
          final insRect = tester.getRect(
            find.text('Tap the mic and say each Spanish line.'),
          );
          final countRect = tester.getRect(find.textContaining(' / 12'));
          final lineRect = tester.getRect(find.text('Hola, abuela'));
          final micRect = tester.getRect(
            find.byKey(const Key('voice-test-mic')),
          );
          final discRect = tester.getRect(
            find.byKey(const ValueKey('noche_mic_disc')),
          );
          final nextRect = tester.getRect(
            find.byKey(const Key('voice-test-next')),
          );

          expect(firstDash.height, 8, reason: '$stage NocheDashes height');
          expect(
            discRect.size,
            const Size(NocheSize.mic, NocheSize.mic),
            reason: '$stage NocheMic disc size',
          );
          expect(
            nextRect.height,
            NocheSize.primaryHeight,
            reason: '$stage Next primary button height',
          );

          final parts = <String, Rect>{
            'dashes': dashesRect,
            'ins': insRect,
            'count': countRect,
            'line': lineRect,
            'mic': micRect,
            if (showNext) 'next': nextRect,
          };
          for (final entry in parts.entries) {
            expect(
              screen.contains(entry.value.topLeft) &&
                  screen.contains(
                    entry.value.bottomRight - const Offset(0.01, 0.01),
                  ),
              isTrue,
              reason: '$stage ${entry.key} ${entry.value} outside $screen',
            );
          }

          final names = parts.keys.toList();
          for (var i = 0; i < names.length; i++) {
            for (var j = i + 1; j < names.length; j++) {
              final overlap = parts[names[i]]!.intersect(parts[names[j]]!);
              expect(
                overlap.width > 1 && overlap.height > 1,
                isFalse,
                reason:
                    '$stage ${names[i]} and ${names[j]} overlap in ${phone.name}',
              );
            }
          }

          expect(dashesRect.bottom, lessThanOrEqualTo(insRect.top));
          expect(insRect.bottom, lessThanOrEqualTo(countRect.top));
          expect(countRect.bottom, lessThanOrEqualTo(lineRect.top));
          expect(lineRect.bottom, lessThanOrEqualTo(micRect.top));

          if (CallMetrics.landscape(Size(phone.width, phone.height))) {
            expect(micRect.right, lessThanOrEqualTo(nextRect.left));
          } else {
            expect(micRect.bottom, lessThanOrEqualTo(nextRect.top));
            expect(
              discRect.center.dx,
              closeTo(phone.width / 2, 1.0),
              reason: '$stage portrait mic centered',
            );
          }
        }

        verifyGeometry('ready', showNext: false);

        await tester.tap(find.byKey(const Key('voice-test-mic')));
        await w.elapse(tester, 100);
        verifyGeometry('listen', showNext: false);

        await w.elapse(tester, 700);
        verifyGeometry('done', showNext: true);

        await w.close(tester);
      },
    );
  }
}
