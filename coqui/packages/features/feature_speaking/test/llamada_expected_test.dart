// The words recorded as mouth answers, against what llamada.js itself records for the same scripts
// (test/fixtures/llamada_expected.json, made by `node tool/llamada_expected.mjs` from the old page run with its own stub:
// every call of PAL.responde, what the page says it heard, what it sent, the variables it gave the call).
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/call_rig.dart';

final Map<String, dynamic> expected = jsonDecode(
  File('test/fixtures/llamada_expected.json').readAsStringSync(),
) as Map<String, dynamic>;

void main() {
  final scripts = (expected['scripts'] as List).cast<Map<String, dynamic>>();

  test('the expected file has the nine scripts of the old page', () {
    expect(scripts.length, 9);
    expect(
      scripts.fold<int>(0, (n, s) => n + (s['answers'] as List).length),
      24,
    );
  });

  testWidgets(
    'the variables: the same six as llamada.js gives, with the same words in the same order',
    (tester) async {
      final v = expected['variables'] as Map<String, dynamic>;
      final rig = await CallRig.create(stub: {'manual'});
      rig.controller.open();
      rig.controller.start();
      await tester.pump();
      final mine = rig.call.variables!;
      expect(mine.keys.toList(), (v['keys'] as List).cast<String>());
      expect(mine['place'], v['place']);
      expect(mine['job'], v['job']);
      expect(mine['minutes'], v['minutes']);
      expect(mine['opening'], v['opening']);
      expect(mine['words_open'], (v['words_open'] as List).join(', '));
      expect(mine['words_heard'], v['words_heard']);
      rig.dispose();
    },
  );

  for (final s in scripts) {
    testWidgets(
      "what the call records for '${s['name']}' is what llamada.js records",
      (tester) async {
        final rig = await CallRig.create(stub: {'manual'});
        final c = rig.controller..open();
        c.start();
        await tester.pump();
        rig.call.go('connect');
        await rig.elapse(tester, 150);
        for (final step in (s['steps'] as List).cast<Map<String, dynamic>>()) {
          if (step.containsKey('go')) {
            rig.call.go(step['go'] as String);
            await rig.elapse(tester, 150);
          } else if (step.containsKey('say')) {
            rig.call.emit(Heard(step['say'] as String));
            await rig.elapse(tester, 80);
          } else if (step.containsKey('agent')) {
            rig.call.emit(AgentLine(step['agent'] as String));
            await rig.elapse(tester, 80);
          } else if (step.containsKey('wait')) {
            await rig.elapse(tester, step['wait'] as int);
          }
        }
        // what PAL.responde was called with: word, skill, right, and whether ms was a number
        final mine = [
          for (final a in rig.progress.answers)
            [a[0], a[1], a[2], a[3] == null ? 'null' : 'int'],
        ];
        expect(mine, s['answers']);
        expect(c.said, (s['said'] as List).cast<String>());
        expect(rig.call.sent, (s['sent'] as List).cast<String>());
        rig.dispose();
      },
    );
  }
}
