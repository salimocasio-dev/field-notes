// Noche layout geometry checks for CallScreen across all 4 phone sizes
// (412x915, 390x844, 360x640, 844x390) in idle, Danny (theySpeak with flanking
// bars), and Your turn (listening with flanking bars) states.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_look.dart';
import 'package:feature_speaking/src/call_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/world.dart';

void main() {
  setUpAll(loadCoquiFonts);

  const phones = [Phone.android, Phone.iphone, Phone.small, Phone.side];

  for (final phone in phones) {
    testWidgets(
      'Noche call screen layout has zero overflows or overlaps in idle, Danny, and your turn: ${phone.name}',
      (tester) async {
        phone.use(tester);
        final w = await World.create(
          seed: 'todo',
          stub: const {'manual'},
          reduceMotion: true,
        );
        await tester.pumpWidget(
          w.app(CallScreen(services: w.services, placeId: 'casa')),
        );
        await tester.pump();

        void verifyGeometry(
          String stage, {
          required String line,
          required String label,
        }) {
          expect(
            tester.takeException(),
            isNull,
            reason: '$stage in ${phone.name}',
          );
          final screen = Rect.fromLTWH(0, 0, phone.width, phone.height);
          final closeRect = tester.getRect(find.byKey(const Key('call-close')));
          final timerRect = tester.getRect(find.textContaining(':'));
          final picRect = tester.getRect(find.byType(PictureFrame));
          final lineRect = tester.getRect(find.text(line));
          final micRect = tester.getRect(
            find.byKey(const Key('call-mic-stage')),
          );
          final discRect = tester.getRect(
            find.byKey(const ValueKey('noche_mic_disc')),
          );
          final labelRect = tester.getRect(find.text(label));
          final noteRect = tester.getRect(
            find.byKey(const ValueKey('call-note')),
          );
          final helpRect = tester.getRect(find.byType(NocheOutlineButton));

          expect(closeRect.width, closeTo(48, 0.01), reason: stage);
          expect(closeRect.height, closeTo(48, 0.01), reason: stage);
          expect(discRect.width, closeTo(NocheSize.mic, 0.01), reason: stage);
          expect(discRect.height, closeTo(NocheSize.mic, 0.01), reason: stage);
          expect(
            helpRect.width,
            closeTo(CallMetrics.helpWidth, 0.01),
            reason: stage,
          );
          expect(helpRect.height, closeTo(48, 0.01), reason: stage);

          final parts = <String, Rect>{
            'close': closeRect,
            'timer': timerRect,
            'picture': picRect,
            'line': lineRect,
            'mic': micRect,
            'label': labelRect,
            'note': noteRect,
            'help': helpRect,
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

          if (CallMetrics.landscape(Size(phone.width, phone.height))) {
            expect(picRect.left, 16, reason: '$stage landscape pic left');
            expect(micRect.left, greaterThan(picRect.right), reason: stage);
            expect(lineRect.left, greaterThan(picRect.right), reason: stage);
            expect(labelRect.left, greaterThan(micRect.right), reason: stage);
          } else {
            expect(
              picRect.bottom,
              lessThanOrEqualTo(lineRect.top),
              reason: stage,
            );
            expect(
              lineRect.bottom,
              lessThanOrEqualTo(micRect.top),
              reason: stage,
            );
            expect(
              micRect.bottom,
              lessThanOrEqualTo(labelRect.top),
              reason: stage,
            );
            expect(
              labelRect.bottom,
              lessThanOrEqualTo(noteRect.top),
              reason: stage,
            );
            expect(
              noteRect.bottom,
              lessThanOrEqualTo(helpRect.top),
              reason: stage,
            );
            expect(
              discRect.center.dx,
              closeTo(phone.width / 2, 1.0),
              reason: '$stage portrait disc centered',
            );
          }
        }

        verifyGeometry(
          'idle',
          line: 'La casa · about 5 min',
          label: 'Start call',
        );

        await tester.tap(find.byKey(const Key('call-mic-stage')));
        await tester.pump();
        w.call.go('connect');
        w.call.go('danny1');
        await w.elapse(tester, 500);
        verifyGeometry(
          'danny',
          line: '¡Hola! Soy Danny. ¿Cómo estás?',
          label: 'Danny',
        );

        w.call.go('you1');
        await w.elapse(tester, 300);
        w.call.go('talk1');
        await w.elapse(tester, 400);
        verifyGeometry(
          'you',
          line: '¡Hola! Soy Danny. ¿Cómo estás?',
          label: 'Your turn',
        );

        await w.close(tester);
      },
    );
  }
}
