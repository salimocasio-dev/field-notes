// Where a test puts its numbers for the order's report. On the vm, when the environment variable COQUI_REPORT_DIR is
// set: a file there. On every platform, when the test runs with `--dart-define=COQUI_SHOW=true`: the end of the test
// fails on purpose with the numbers as its message (a test that passes prints nothing).
import 'package:flutter_test/flutter_test.dart';

import 'report_web.dart' if (dart.library.io) 'report_vm.dart';

const bool _show = bool.fromEnvironment('COQUI_SHOW');

/// Puts [lines] where the order's report can read them (see above).
void report(String name, List<String> lines) {
  writeReport(name, lines);
  if (_show) fail('$name:\n${lines.join('\n')}');
}
