import 'dart:io';

/// Appends [lines] to `$COQUI_REPORT_DIR/<name>.txt` when that variable is set.
void writeReport(String name, List<String> lines) {
  final dir = Platform.environment['COQUI_REPORT_DIR'];
  if (dir == null) return;
  File('$dir/$name.vm.txt')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${lines.join('\n')}\n');
}
