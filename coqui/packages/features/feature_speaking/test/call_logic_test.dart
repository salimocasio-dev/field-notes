import 'package:feature_speaking/src/call_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/call_rig.dart';

void main() {
  testWidgets('natural call: smoke', (tester) async {
    final rig = await CallRig.create();
    final c = rig.controller..open();
    final seq = <CallState>[c.state];
    c.addListener(() {
      if (seq.last != c.state) seq.add(c.state);
    });
    c.start();
    await rig.until(tester, () => c.state == CallState.done, maxMs: 40000);
    // ignore: avoid_print
    print(
      '$seq why=${c.why} sent=${rig.call.sent} ${c.summaryLine} ${c.timerText} said=${c.said} answers=${rig.progress.answers}',
    );
    expect(c.state, CallState.done);
    rig.dispose();
  });
}
