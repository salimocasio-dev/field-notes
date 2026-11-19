// The contact sheets of `gate_a_frames_test.dart` again, from the pictures already on disk (no story is played):
//
//   cd coqui/app && flutter test tool/gate_a_sheets_test.dart --dart-define=OUT=<dir>
//
// Each folder of <dir> that holds pictures `NN-<kind>.png` gets its `sheet-NN.png` made again.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'gate_a_sheets.dart';

const String _out = String.fromEnvironment('OUT');

void main() {
  testWidgets('contact sheets of every play folder in OUT', (tester) async {
    if (_out.isEmpty) fail('give the folder: --dart-define=OUT=<dir>');
    final plays = [
      for (final d in Directory(_out).listSync().whereType<Directory>())
        if (d.listSync().any(
          (f) => RegExp(r'/\d+-[a-z]+\.png$').hasMatch(f.path),
        ))
          d,
    ]..sort((a, b) => a.path.compareTo(b.path));
    expect(plays, isNotEmpty, reason: 'no play folder with pictures in $_out');
    for (final d in plays) {
      final n = await tester.runAsync(() => makeSheets(d));
      expect(n, greaterThan(0), reason: d.path);
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
