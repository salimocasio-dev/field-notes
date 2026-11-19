import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

import 'compare.dart';
import 'ref_files.dart';

/// The size of a tile of the canvas sheet.
const tileSize = 64;

/// One of the 40 cases of `coqui/ref/ctx/cases.json`.
class CtxCase {
  CtxCase(this.json);

  final Map<String, dynamic> json;

  int get n => json['n'] as int;
  String get kind => json['kind'] as String;
  String get title => json['title'] as String;
  String get file => json['file'] as String;
  List<dynamic> get ops => json['ops'] as List<dynamic>;

  /// `imageSmoothingEnabled`: every case begins by setting it.
  bool get smoothing => (ops.first as List<dynamic>)[1] as bool;

  /// The kinds the order wants exact: fillRect (whole and half), plain and flipped drawImage, a clip rectangle.
  bool get exactKind =>
      kind.startsWith('fillRect') ||
      kind == 'drawImage-plain' ||
      kind == 'drawImage-flip' ||
      kind == 'clip-rect';
}

/// The sheet: its cases and the sprites they draw.
class CtxSheet {
  CtxSheet._(this.cases, this.sources);

  final List<CtxCase> cases;
  final Map<String, Sprite> sources;

  factory CtxSheet.load() {
    final doc =
        jsonDecode(refFileText('ctx/cases.json')) as Map<String, dynamic>;
    final sources = <String, Sprite>{};
    (doc['sources'] as Map<String, dynamic>).forEach((id, v) {
      final s = v as Map<String, dynamic>;
      final bytes = refFile('ctx/${s['file']}');
      sources[id] = Sprite(s['w'] as int, s['h'] as int, readU32(bytes));
    });
    return CtxSheet._([
      for (final c in doc['cases'] as List<dynamic>)
        CtxCase(c as Map<String, dynamic>),
    ], sources);
  }

  /// The tile the browser drew.
  Uint32List reference(CtxCase c) => readU32(refFile('ctx/${c.file}'));

  /// The tile `Ctx` draws: a new 64 × 64 `Ctx`, the case's calls in order.
  Uint32List replay(CtxCase c) {
    final px = Uint32List(tileSize * tileSize);
    final ctx = Ctx(px, tileSize, tileSize);
    int colour(List<dynamic> rgba) =>
        (((rgba[3] as int) << 24) |
            ((rgba[2] as int) << 16) |
            ((rgba[1] as int) << 8) |
            (rgba[0] as int)) &
        0xFFFFFFFF;
    for (final raw in c.ops) {
      final op = raw as List<dynamic>;
      double d(int i) => (op[i] as num).toDouble();
      switch (op[0] as String) {
        case 'imageSmoothingEnabled':
          ctx.smoothing = op[1] as bool;
        case 'fillStyle':
          ctx.fillStyle = colour(op[2] as List<dynamic>);
        case 'strokeStyle':
          ctx.strokeStyle = colour(op[2] as List<dynamic>);
        case 'globalAlpha':
          ctx.globalAlpha = d(1);
        case 'lineWidth':
          ctx.lineWidth = d(1);
        case 'save':
          ctx.save();
        case 'restore':
          ctx.restore();
        case 'translate':
          ctx.translate(d(1), d(2));
        case 'scale':
          ctx.scale(d(1), d(2));
        case 'rotate':
          ctx.rotate(d(1));
        case 'fillRect':
          ctx.fillRect(op[1] as num, op[2] as num, op[3] as num, op[4] as num);
        case 'clearRect':
          ctx.clearRect(op[1] as num, op[2] as num, op[3] as num, op[4] as num);
        case 'drawImage':
          final s = sources[op[1] as String]!;
          if (op.length == 4) {
            ctx.drawImage(s, op[2] as num, op[3] as num);
          } else {
            ctx.drawImage(
              s,
              op[2] as num,
              op[3] as num,
              op[4] as num,
              op[5] as num,
            );
          }
        case 'drawImageRect':
          ctx.drawImageRect(
            sources[op[1] as String]!,
            op[2] as num,
            op[3] as num,
            op[4] as num,
            op[5] as num,
            op[6] as num,
            op[7] as num,
            op[8] as num,
            op[9] as num,
          );
        case 'beginPath':
          ctx.beginPath();
        case 'rect':
          ctx.rect(op[1] as num, op[2] as num, op[3] as num, op[4] as num);
        case 'arc':
          ctx.arc(
            op[1] as num,
            op[2] as num,
            op[3] as num,
            op[4] as num,
            op[5] as num,
          );
        case 'ellipse':
          ctx.ellipse(
            op[1] as num,
            op[2] as num,
            op[3] as num,
            op[4] as num,
            op[5] as num,
            op[6] as num,
            op[7] as num,
          );
        case 'moveTo':
          ctx.moveTo(op[1] as num, op[2] as num);
        case 'lineTo':
          ctx.lineTo(op[1] as num, op[2] as num);
        case 'fill':
          ctx.fill();
        case 'stroke':
          ctx.stroke();
        case 'clip':
          ctx.clip();
        default:
          throw StateError('no canvas call ${op[0]}');
      }
    }
    return px;
  }
}

/// How a tile differs from the browser's: `any` pixels that differ at all, `far` pixels that differ by more than
/// [tolerance] in some channel, over `total` pixels.
class TileDiff {
  TileDiff(this.any, this.far, this.total, this.first);

  final int any, far, total;

  /// The first pixels that differ by more than the tolerance: index, the browser's colour, Dart's.
  final List<({int index, int ref, int dart})> first;

  double get farPercent => far * 100 / total;
}

const tolerance = 24;

TileDiff diffTile(Uint32List dart, Uint32List ref) {
  var any = 0, far = 0;
  final first = <({int index, int ref, int dart})>[];
  for (var i = 0; i < ref.length; i++) {
    if (dart[i] == ref[i]) continue;
    any++;
    var worst = 0;
    for (var s = 0; s < 32; s += 8) {
      final d = (((dart[i] >> s) & 255) - ((ref[i] >> s) & 255)).abs();
      if (d > worst) worst = d;
    }
    if (worst > tolerance) {
      far++;
      if (first.length < 20) {
        first.add((index: i, ref: ref[i], dart: dart[i]));
      }
    }
  }
  return TileDiff(any, far, ref.length, first);
}
