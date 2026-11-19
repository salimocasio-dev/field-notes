import 'dart:typed_data';

/// A reference `.bin` file read as pixels (`Uint32Array`, little endian, `0xAABBGGRR`).
Uint32List readU32(Uint8List bytes) {
  final d = ByteData.sublistView(bytes), n = bytes.length ~/ 4;
  final out = Uint32List(n);
  for (var i = 0; i < n; i++) {
    out[i] = d.getUint32(i * 4, Endian.little);
  }
  return out;
}

/// How a picture differs from its reference: how many elements, of how many, and the first few.
class Diff {
  Diff(this.count, this.total, this.first);

  final int count, total;

  /// The first differing elements: index, the reference's value, the Dart value.
  final List<({int index, num ref, num dart})> first;

  double get percent => total == 0 ? 0 : count * 100 / total;

  /// `12 of 51840 (0.023%)`
  String get text => '$count of $total (${percent.toStringAsFixed(3)}%)';
}

/// The elements of [dart] that are not equal to the same element of [ref] (`!=` on the numbers read out).
Diff diffExact(List<num> dart, List<num> ref, {int keep = 20}) {
  if (dart.length != ref.length) {
    throw ArgumentError('${dart.length} elements against ${ref.length}');
  }
  var count = 0;
  final first = <({int index, num ref, num dart})>[];
  for (var i = 0; i < ref.length; i++) {
    if (dart[i] != ref[i]) {
      count++;
      if (first.length < keep) {
        first.add((index: i, ref: ref[i], dart: dart[i]));
      }
    }
  }
  return Diff(count, ref.length, first);
}
