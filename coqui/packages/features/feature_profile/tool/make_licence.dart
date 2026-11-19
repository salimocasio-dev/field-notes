// Embeds the Pixel Plays licence text into this package, so the About sheet shows it on every platform.
//
//   dart run tool/make_licence.dart          (in this package) writes lib/src/licence_text.dart
//   dart run tool/make_licence.dart --check  says whether that file is the one the licence file gives
//
// The text is read from coqui/packages/core/coqui_pixel/LICENSE-pixel-plays.txt and never retyped.
import 'dart:io';

const source = '../../core/coqui_pixel/LICENSE-pixel-plays.txt';
const target = 'lib/src/licence_text.dart';

String render(String text) {
  if (text.contains("'''")) {
    throw StateError("the licence text holds ''' and cannot be embedded raw");
  }
  final body = text.endsWith('\n') ? text : '$text\n';
  return [
    '// Made by tool/make_licence.dart from coqui_pixel/LICENSE-pixel-plays.txt. Do not edit.',
    '',
    '/// The Pixel Plays licence (MIT), exactly as the file in coqui_pixel has it.',
    "const String pixelPlaysLicence = r'''",
    body.trimRight(),
    "''';",
    '',
  ].join('\n');
}

void main(List<String> args) {
  final src = File(source);
  if (!src.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/features/feature_profile: $source is not there.',
    );
    exit(2);
  }
  final made = render(src.readAsStringSync());
  final out = File(target);
  if (args.contains('--check')) {
    final same = out.existsSync() && out.readAsStringSync() == made;
    stdout.writeln(
      same
          ? '$target is the licence file, embedded.'
          : '$target is NOT what the licence file gives: run `dart run tool/make_licence.dart`.',
    );
    exit(same ? 0 : 1);
  }
  out.writeAsStringSync(made);
  stdout.writeln('wrote $target');
}
