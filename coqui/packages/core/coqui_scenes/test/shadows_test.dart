// The characters' shadows (page 12, section 5, "The frame", step 3), as frente-preview.html casts them: the frog's while he
// is seen (W.cq.vis), not in the window (W.tab) and MORE THAN HALF faded in (`q.al > .5`); abuela's, at the door or on the
// porch, while she has no `al` or more than half (`W.ab.al == null || W.ab.al > .5`). The sheet's `when` text says
// neither; the preview is what the readers saw.
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/frente/frente.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Frente scene;
  setUpAll(() async {
    scene =
        (await ScenePictures(bundle: testBundle()).frameOf('frente')).scene
            as Frente;
  });

  Map<String, dynamic> world({
    Object? frogAl = 1,
    int vis = 1,
    Object? tab,
    Map<String, dynamic>? ab,
  }) {
    final W = ScenePictures.pictureW(scene, const {});
    W['cq'] = <String, dynamic>{
      ...(W['cq'] as Map<String, dynamic>),
      'vis': vis,
      'al': frogAl,
    };
    W['tab'] = tab;
    W['ab'] = ab;
    return W;
  }

  Map<String, dynamic> abuela(String en, {Object? al = #none}) => {
    'en': en,
    'pose': 'idle',
    'bub': null,
    if (al != #none) 'al': al,
  };

  test('the frog casts one shadow while he is seen and more than half in', () {
    expect(scene.shadows(world()), hasLength(1));
    expect(scene.shadows(world(frogAl: .51)), hasLength(1));
    expect(scene.shadows(world(frogAl: 1)).single.r, .45);
  });

  test('the frog casts none at half or less, nor with no al (undefined > .5 is false)', () {
    for (final al in [.5, .49, .1, 0, -1, null]) {
      expect(scene.shadows(world(frogAl: al)), isEmpty, reason: 'al $al');
    }
  });

  test('the frog casts none when he is not seen or is in the window', () {
    expect(scene.shadows(world(vis: 0)), isEmpty);
    expect(scene.shadows(world(tab: 'seco')), isEmpty);
  });

  test('abuela casts her five shadows at the door or on the porch with no al or more than half', () {
    for (final en in ['puerta', 'paso']) {
      for (final al in [#none, null, 1, .6, .51]) {
        final casts = scene.shadows(world(vis: 0, ab: abuela(en, al: al)));
        expect(casts, hasLength(5), reason: '$en al $al');
        expect(casts.every((c) => c.r == .35), isTrue);
      }
    }
  });

  test(
    'abuela casts none at half or less, in the window, or with no one there',
    () {
      for (final al in [.5, .4, 0]) {
        expect(
          scene.shadows(world(vis: 0, ab: abuela('puerta', al: al))),
          isEmpty,
          reason: 'puerta al $al',
        );
      }
      expect(scene.shadows(world(vis: 0, ab: abuela('ventana'))), isEmpty);
      expect(scene.shadows(world(vis: 0)), isEmpty);
    },
  );

  test('each character is judged by his own al', () {
    // the frog fading out while abuela is whole: only hers
    var casts = scene.shadows(world(frogAl: .3, ab: abuela('puerta', al: 1)));
    expect(casts, hasLength(5));
    // abuela fading while the frog is whole: only his
    casts = scene.shadows(world(ab: abuela('puerta', al: .3)));
    expect(casts, hasLength(1));
    expect(casts.single.r, .45);
  });
}
