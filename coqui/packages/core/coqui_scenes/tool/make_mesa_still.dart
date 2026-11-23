// La mesa's stored still of El colmado's stall (cual-mesa's cocina.no, the sheet's `pictures["cocina.no"].port`): the
// picture docs/proyecto/pixel/frutas-set.html?surtido=frutas draws, as coqui/tool/ref/pp/make.js baked it once
// (coqui/ref/pp/mesa/frutas-surtido-frutas/pix.bin), written into the scene's own code as its colours and their runs, so
// that the scene draws it at once, on every platform. It goes when El colmado's `frutas` is ported (order 52): its set
// at that state then draws the picture.
//
//   dart run tool/make_mesa_still.dart          (in this package) writes lib/src/mesa/mesa_frutas_still.dart
//   dart run tool/make_mesa_still.dart --check  fails when the file is not what the reference picture gives
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main(List<String> args) {
  final src = File('../../../ref/pp/mesa/frutas-surtido-frutas/pix.bin');
  if (!src.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/core/coqui_scenes: ${src.path} is not there.',
    );
    exit(2);
  }
  final bytes = src.readAsBytesSync();
  final px = Uint32List.view(Uint8List.fromList(bytes).buffer);
  if (px.length != 240 * 216) {
    stderr.writeln('${src.path} is not 240 x 216 pixels');
    exit(2);
  }
  // the colours in the order they first come, and the runs: a colour's index (2 bytes, little endian) and the run's
  // length (1 to 3 bytes, 7 bits each, the last without its high bit)
  final palette = <int>[], index = <int, int>{}, runs = BytesBuilder();
  var i = 0;
  while (i < px.length) {
    final c = px[i];
    var n = 1;
    while (i + n < px.length && px[i + n] == c) {
      n++;
    }
    final k = index.putIfAbsent(c, () {
      palette.add(c);
      return palette.length - 1;
    });
    runs.add([k & 255, k >> 8]);
    var v = n;
    while (v >= 128) {
      runs.addByte(128 | (v & 127));
      v >>= 7;
    }
    runs.addByte(v);
    i += n;
  }
  final b64 = base64Encode(runs.takeBytes());
  final colours = [
    for (var j = 0; j < palette.length; j += 8)
      [
        for (final c in palette.skip(j).take(8))
          c.toRadixString(16).toUpperCase().padLeft(8, '0'),
      ].join(' '),
  ];
  final made = [
    '// Made by tool/make_mesa_still.dart from coqui/ref/pp/mesa/frutas-surtido-frutas/pix.bin. Do not edit.',
    '// ignore_for_file: lines_longer_than_80_chars',
    '',
    '/// The still of El colmado\'s stall (docs/proyecto/pixel/frutas-set.html?surtido=frutas, 240 x 216, baked once by',
    '/// coqui/tool/ref/pp/make.js): its colours (`AABBGGRR` in hexadecimal), in the order they first come, a blank line,',
    '/// then its runs, row by row from the top left: base64 of a colour\'s index (2 bytes, little endian) and the run\'s',
    '/// length (7 bits a byte, low first, the last byte without its high bit), run after run.',
    "const String mesaFrutasStill = r'''",
    ...colours,
    '',
    for (var j = 0; j < b64.length; j += 116)
      b64.substring(j, j + 116 > b64.length ? b64.length : j + 116),
    "''';",
    '',
  ].join('\n');
  final file = File('lib/src/mesa/mesa_frutas_still.dart');
  if (args.contains('--check')) {
    final same = file.existsSync() && file.readAsStringSync() == made;
    stdout.writeln(
      same ? 'the still of El colmado\'s stall is current' : 'the still of El colmado\'s stall is NOT current: run tool/make_mesa_still.dart',
    );
    if (!same) exit(1);
    return;
  }
  file.writeAsStringSync(made);
  stdout.writeln(
    'wrote ${file.path}: ${palette.length} colours, ${b64.length} characters of runs',
  );
}
