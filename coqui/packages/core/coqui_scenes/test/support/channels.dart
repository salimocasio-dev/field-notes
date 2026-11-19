import 'dart:typed_data';

/// How two pictures (`0xAABBGGRR`) differ: the pixels where some channel differs by more than [limit].
({int count, int total, double percent, List<String> first}) channelDiff(
  Uint32List a,
  Uint32List b, {
  int limit = 24,
  int width = 0,
}) {
  if (a.length != b.length) {
    throw ArgumentError('${a.length} pixels against ${b.length}');
  }
  var n = 0;
  final first = <String>[];
  for (var i = 0; i < a.length; i++) {
    final p = a[i], q = b[i];
    if (p == q) continue;
    var far = false;
    for (var s = 0; s < 32; s += 8) {
      if ((((p >> s) & 255) - ((q >> s) & 255)).abs() > limit) far = true;
    }
    if (!far) continue;
    n++;
    if (first.length < 8) {
      final at = width > 0 ? '(${i % width},${i ~/ width})' : '$i';
      first.add('$at ${p.toRadixString(16)} ${q.toRadixString(16)}');
    }
  }
  return (count: n, total: a.length, percent: n * 100 / a.length, first: first);
}

/// A region [x, y, w, h] of a [pw]-wide picture, each pixel [zoom] × [zoom].
Uint32List cropZoom(Uint32List pic, int pw, List<num> r, int zoom) {
  final x0 = r[0].toInt(),
      y0 = r[1].toInt(),
      w = r[2].toInt(),
      h = r[3].toInt();
  final out = Uint32List(w * zoom * h * zoom);
  for (var j = 0; j < h * zoom; j++) {
    for (var i = 0; i < w * zoom; i++) {
      out[j * w * zoom + i] = pic[(y0 + j ~/ zoom) * pw + x0 + i ~/ zoom];
    }
  }
  return out;
}
