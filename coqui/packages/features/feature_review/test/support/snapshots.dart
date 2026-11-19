// What the Dart lessons look like at an instant, in the shape old_harness.mjs / runs.mjs writes for the old page.
import 'package:coqui_ui/coqui_ui.dart' show PictureRef;
import 'package:feature_review/src/logic/level_check.dart';
import 'package:feature_review/src/logic/review_session.dart';

List<String> _classes(OptionRing r, {bool check = false}) =>
    [if (check) 'chk', if (r != OptionRing.none) r.name]..sort();

Map<String, Object?> reviewSnapshot(ReviewSession s) {
  final asking = s.running && s.index < s.queue.length;
  final q = asking ? s.queue[s.index] : null;
  return {
    'scr': s.screen.name,
    'i': s.running ? s.index : null,
    'ask': (s.running && q != null)
        ? '${q.pair.word}${q.again ? '*' : ''}'
        : null,
    'pan': s.panels == null
        ? null
        : [
            for (final p in s.panels!)
              {
                'right': p.right,
                'sign': p.sign ? 1 : 0,
                'dim': p.dim || p.pre,
                'pre': p.pre,
              },
          ],
    'ring': [
      for (var k = 0; k < 2; k++) _classes(s.rings[k], check: s.checks[k]),
    ],
    'cap': s.caption,
    'bar': s.barLit,
  };
}

Map<String, Object?> levelSnapshot(LevelCheckSession s) => {
  'scr': s.screen.name,
  'i': s.running ? s.index : null,
  'pan': s.panels == null
      ? null
      : [
          for (final p in s.panels!) {'right': p.right, 'cam': p.ref.cam},
        ],
  'ring': [for (var k = 0; k < 4; k++) _classes(s.rings[k])],
  'cap': s.caption,
  'bar': s.barLit,
  'dots': s.barSegments,
};

bool sameRef(PictureRef a, PictureRef b) =>
    a.scene == b.scene &&
    identical(a.set, b.set) &&
    a.cam.length == b.cam.length &&
    [for (var i = 0; i < a.cam.length; i++) a.cam[i] == b.cam[i]]
        .every((x) => x);
