// Ctx.setLineDash (patio.js line 142 needs it) against the browser: the cases of tool/make_dash_ref.mjs, drawn by
// headless Chrome into 64 x 64 tiles and replayed on Ctx. The rule is order 11's for a stroke: no more than 3% of the
// tile's pixels differ by more than 24 in a channel. On the vm and in a browser the reference is the same fixture.
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/ctx_replay.dart' show diffTile, tolerance;
import 'support/dash_replay.dart';

void main() {
  final cases = loadDashCases();

  test('the reference holds the cases', () => expect(cases.length, 12));

  for (final c in cases) {
    final diff = diffTile(dashReplay(c), dashReference(c));
    final label =
        'case ${c.n.toString().padLeft(2)}: ${c.title}: '
        '${diff.far} of ${diff.total} pixels differ by more than $tolerance '
        '(${diff.farPercent.toStringAsFixed(2)}%), ${diff.any} differ at all';
    test(label, () {
      final first = diff.first
          .take(20)
          .map(
            (d) =>
                '#${d.index} ref ${d.ref.toRadixString(16)} '
                'dart ${d.dart.toRadixString(16)}',
          )
          .join(', ');
      expect(
        diff.far,
        lessThanOrEqualTo(diff.total * 3 ~/ 100),
        reason: 'more than 3%; first: $first',
      );
    });
  }

  group('setLineDash', () {
    Uint32List tile() => Uint32List(16 * 4);

    // a horizontal line along y = 2 (a row of pixels), the dash list as given; the columns that are painted
    String row(List<num>? dash, {bool restoreFirst = false}) {
      final px = tile();
      final g = Ctx(px, 16, 4)
        ..strokeStyle = 0xFFFFFFFF
        ..lineWidth = 1;
      if (restoreFirst) g.save();
      if (dash != null) g.setLineDash(dash);
      if (restoreFirst) g.restore();
      g
        ..beginPath()
        ..moveTo(0, 2)
        ..lineTo(16, 2)
        ..stroke();
      return [for (var x = 0; x < 16; x++) px[2 * 16 + x] != 0 ? '#' : '.']
          .join();
    }

    test('[2, 3]: two on, three off, from the start', () {
      expect(row([2, 3]), '##...##...##...#');
    });
    test('an odd list is used twice: [3] is [3, 3]', () {
      expect(row([3]), '###...###...###.');
    });
    test('[2, 3, 1] is [2, 3, 1, 2, 3, 1]', () {
      expect(row([2, 3, 1]), '##...#..###.##..');
    });
    test('a negative or infinite or NaN length changes nothing', () {
      expect(row([2, 3]), '##...##...##...#');
      final px = tile();
      Ctx(px, 16, 4)
        ..strokeStyle = 0xFFFFFFFF
        ..setLineDash([2, 3])
        ..setLineDash([-1, 2])
        ..setLineDash([double.infinity, 1])
        ..setLineDash([double.nan])
        ..beginPath()
        ..moveTo(0, 2)
        ..lineTo(16, 2)
        ..stroke();
      expect(
        [for (var x = 0; x < 16; x++) px[2 * 16 + x] != 0 ? '#' : '.'].join(),
        '##...##...##...#',
      );
    });
    test('an empty list, or only zeros, is a solid line', () {
      expect(row([]), '#' * 16);
      expect(row([0, 0]), '#' * 16);
    });
    test('save keeps the list and restore brings it back', () {
      final px = tile();
      Ctx(px, 16, 4)
        ..strokeStyle = 0xFFFFFFFF
        ..setLineDash([2, 3])
        ..save()
        ..setLineDash([1, 1])
        ..restore()
        ..beginPath()
        ..moveTo(0, 2)
        ..lineTo(16, 2)
        ..stroke();
      expect(
        [for (var x = 0; x < 16; x++) px[2 * 16 + x] != 0 ? '#' : '.'].join(),
        '##...##...##...#',
      );
      expect(row([2, 2], restoreFirst: true), '#' * 16);
    });
    test('each sub-path starts a new round of the list', () {
      final px = Uint32List(16 * 4);
      Ctx(px, 16, 4)
        ..strokeStyle = 0xFFFFFFFF
        ..setLineDash([2, 3])
        ..beginPath()
        ..moveTo(0, 1)
        ..lineTo(7, 1)
        ..moveTo(4, 3)
        ..lineTo(11, 3)
        ..stroke();
      String line(int y) =>
          [for (var x = 0; x < 16; x++) px[y * 16 + x] != 0 ? '#' : '.'].join();
      expect(line(1), '##...##.........');
      expect(line(3), '....##...##.....');
    });
  });
}
