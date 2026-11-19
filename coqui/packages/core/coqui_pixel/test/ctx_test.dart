// The canvas sheet: the 40 cases of coqui/ref/ctx/ (one 64 x 64 tile each, drawn by the browser's canvas), replayed on
// Ctx from the calls cases.json records. The kinds the order wants exact (fillRect, plain and flipped drawImage, a clip
// rectangle) must match pixel for pixel; every other case may differ by more than 24 in some channel in no more than
// 3% of the tile's pixels. A case recorded with smoothing on is replayed with smoothing on (its first call says so).
// On the vm the reference is read from the files, in a browser from the fixture made from them.
import 'package:test/test.dart';

import 'support/ctx_replay.dart';

void main() {
  final sheet = CtxSheet.load();

  test('the sheet has 40 cases', () {
    expect(sheet.cases.length, 40);
  });

  for (final c in sheet.cases) {
    final diff = diffTile(sheet.replay(c), sheet.reference(c));
    final label =
        'case ${c.n.toString().padLeft(2)} ${c.kind}'
        '${c.smoothing ? ' (smoothing on)' : ''}: '
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
      if (c.exactKind) {
        expect(diff.any, 0, reason: 'must be exact; first: $first');
      } else {
        expect(
          diff.far,
          lessThanOrEqualTo(diff.total * 3 ~/ 100),
          reason: 'more than 3%; first: $first',
        );
      }
    });
  }
}
