import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

import 'compare.dart';
import 'fixtures/ref_dash.dart';

/// One of the cases of `tool/make_dash_ref.mjs`: a title and the canvas calls, which Chrome and `Ctx` both run.
class DashCase {
  DashCase(this.n, this.json);

  final int n;
  final Map<String, dynamic> json;

  String get title => json['title'] as String;
  List<dynamic> get ops => json['ops'] as List<dynamic>;
}

Uint8List _file(String name) {
  final pieces = refDashFixture[name];
  if (pieces == null) throw StateError('$name is not in the dash reference');
  return base64Decode(pieces.join());
}

/// The cases, in the order the tiles are numbered.
List<DashCase> loadDashCases() {
  final doc =
      jsonDecode(utf8.decode(_file('cases.json'))) as Map<String, dynamic>;
  final cases = doc['cases'] as List<dynamic>;
  return [
    for (var i = 0; i < cases.length; i++)
      DashCase(i + 1, cases[i] as Map<String, dynamic>),
  ];
}

/// The tile Chrome drew.
Uint32List dashReference(DashCase c) =>
    readU32(_file('tiles/${c.n.toString().padLeft(2, '0')}.bin'));

/// `"#RRGGBB"` as 0xFFBBGGRR.
int _colour(String h) =>
    0xFF000000 |
    (int.parse(h.substring(5, 7), radix: 16) << 16) |
    (int.parse(h.substring(3, 5), radix: 16) << 8) |
    int.parse(h.substring(1, 3), radix: 16);

/// The tile `Ctx` draws: the background the case starts on, then the case's calls in order.
Uint32List dashReplay(DashCase c) {
  final doc =
      jsonDecode(utf8.decode(_file('cases.json'))) as Map<String, dynamic>;
  final px = Uint32List(64 * 64);
  final g = Ctx(px, 64, 64);
  g.fillStyle = _colour(doc['background'] as String);
  g.fillRect(0, 0, 64, 64);
  for (final raw in c.ops) {
    final op = raw as List<dynamic>;
    switch (op[0] as String) {
      case 'strokeStyle':
        g.strokeStyle = _colour(op[1] as String);
      case 'fillStyle':
        g.fillStyle = _colour(op[1] as String);
      case 'lineWidth':
        g.lineWidth = (op[1] as num).toDouble();
      case 'setLineDash':
        if (op[1] != null) {
          g.setLineDash([for (final v in op[1] as List<dynamic>) v as num]);
        }
      case 'save':
        g.save();
      case 'restore':
        g.restore();
      case 'beginPath':
        g.beginPath();
      case 'moveTo':
        g.moveTo(op[1] as num, op[2] as num);
      case 'lineTo':
        g.lineTo(op[1] as num, op[2] as num);
      case 'rect':
        g.rect(op[1] as num, op[2] as num, op[3] as num, op[4] as num);
      case 'arc':
        g.arc(
          op[1] as num,
          op[2] as num,
          op[3] as num,
          op[4] as num,
          op[5] as num,
        );
      case 'stroke':
        g.stroke();
      default:
        throw StateError('no canvas call ${op[0]}');
    }
  }
  return px;
}
