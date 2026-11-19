import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';

ReviewPair _pair(String word, {String scene = 'frente'}) => ReviewPair(
  word: word,
  say: 'esta_$word',
  scene: scene,
  yes: PictureSpec(cam: [52, 8, 180, 96]),
  no: PictureSpec(scene: 'sala', set: {'gente': 1}, cam: [44, 120, 180, 96]),
);

void main() {
  group('PictureRef.of', () {
    test(
      'a picture of a pair side takes the side\'s scene, else the pair\'s',
      () {
        final pair = ReviewPair(
          word: 'casa',
          say: 'esta_casa',
          scene: 'frente',
          yes: PictureSpec(cam: [52, 8, 180, 96]),
          no: PictureSpec(
            scene: 'sala',
            set: {'gente': 1},
            cam: [44, 120, 180, 96],
          ),
        );
        final yes = PictureRef.of(pair, pair.yes);
        expect(yes.scene, 'frente');
        expect(yes.cam, [52, 8, 180, 96]);
        final no = PictureRef.of(pair, pair.no);
        expect(no.scene, 'sala');
        expect(no.set, {'gente': 1});
      },
    );

    test('it names the picture "<word>.si" or "<word>.no"', () {
      final pair = _pair('abuela');
      expect(PictureRef.of(pair, pair.yes).name, 'abuela.si');
      expect(PictureRef.of(pair, pair.no).name, 'abuela.no');
    });

    test(
      'a copy of a side is told apart by its value; a stranger has no name',
      () {
        final pair = _pair('cierra');
        expect(
          PictureRef.of(pair, PictureSpec(cam: [52, 8, 180, 96])).name,
          'cierra.si',
        );
        expect(
          PictureRef.of(
            pair,
            PictureSpec(
              scene: 'sala',
              set: {'gente': 1},
              cam: [44, 120, 180, 96],
            ),
          ).name,
          'cierra.no',
        );
        expect(
          PictureRef.of(pair, PictureSpec(cam: [1, 2, 3, 4])).name,
          isNull,
        );
      },
    );
  });

  group('PictureRef equality', () {
    PictureRef ref({
      String scene = 'frente',
      Map<String, dynamic> set = const {},
      List<num> cam = const [52, 8, 180, 96],
      String? name,
    }) => PictureRef(scene: scene, set: set, cam: cam, name: name);

    test('the same scene, set, cam and name are equal, with the same hash', () {
      final a = ref(
        set: {
          'a': 1,
          'b': [1, 2],
        },
        name: 'x.si',
      );
      final b = ref(
        set: {
          'b': [1, 2],
          'a': 1.0,
        },
        cam: [52.0, 8, 180, 96.0],
        name: 'x.si',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a, b}.length, 1);
    });

    test('the name is part of it: abuela.si and cierra.no may share scene, state and view', () {
      final a = ref(name: 'abuela.si');
      final b = ref(name: 'cierra.no');
      expect(a, isNot(b));
      expect(ref(), isNot(ref(name: 'abuela.si')));
      expect({a, b}.length, 2);
    });

    test('the scene, the set and the cam are part of it', () {
      expect(ref(), isNot(ref(scene: 'sala')));
      expect(ref(), isNot(ref(set: {'gente': 1})));
      expect(ref(), isNot(ref(cam: [52, 8, 180, 97])));
      expect(ref(), isNot(ref(cam: [52, 8, 180])));
    });
  });

  group('PictureRef.ofLevel (nivel.js: nivelPanel)', () {
    final pairs = {
      for (final w in ['abuela', 'mamá', 'cierra']) w: _pair(w),
    };
    // nivel.js: {w:"abuela", s:1, p:[["abuela","si",166],["mamá","si"],["cierra","no",10],["cierra","no",238]]}
    final item = LevelItem(
      word: 'abuela',
      step: 1,
      pictures: [
        ['abuela', 'si', 166],
        ['mamá', 'si'],
        ['cierra', 'no', 10],
        ['cierra', 'no', 238],
      ],
    );
    // CW 96 x CH 106: a square-ish crop as wide as the camera is tall times 96 / 106.
    const w = 96 * 96 / 106;

    test('a crop centred on the given x, with the pair\'s scene and view', () {
      final r = PictureRef.ofLevel(item, 0, pairs: pairs);
      expect(r.scene, 'frente');
      expect(r.set, isEmpty);
      expect(r.cam[0], closeTo(166 - w / 2, 1e-9));
      expect(r.cam[1], 8);
      expect(r.cam[2], closeTo(w, 1e-9));
      expect(r.cam[3], 96);
      expect(r.name, 'nivel.abuela.0');
    });

    test('with no x it is centred on the middle of the pair\'s camera', () {
      final r = PictureRef.ofLevel(item, 1, pairs: pairs);
      expect(r.cam[0], closeTo(52 + 90 - w / 2, 1e-9));
      expect(r.name, 'nivel.abuela.1');
    });

    test('a "no" picture takes the pair\'s no side, scene and set', () {
      final r = PictureRef.ofLevel(item, 2, pairs: pairs);
      expect(r.scene, 'sala');
      expect(r.set, {'gente': 1});
      expect(r.cam[1], 120);
      expect(r.name, 'nivel.abuela.2');
    });

    test('the crop stays inside the scene: 0 at the left, sceneWidth - width at the right', () {
      expect(PictureRef.ofLevel(item, 2, pairs: pairs).cam[0], 0);
      expect(
        PictureRef.ofLevel(item, 3, pairs: pairs).cam[0],
        closeTo(240 - w, 1e-9),
      );
      expect(
        PictureRef.ofLevel(item, 3, pairs: pairs, sceneWidth: 300).cam[0],
        closeTo(238 - w / 2, 1e-9),
      );
    });

    test('each picture of an item has its own name', () {
      final names = {
        for (var i = 0; i < 4; i++)
          PictureRef.ofLevel(item, i, pairs: pairs).name,
      };
      expect(names, {
        'nivel.abuela.0',
        'nivel.abuela.1',
        'nivel.abuela.2',
        'nivel.abuela.3',
      });
      // And two of them, 2 and 3, share scene, set and view but not the crop: they are not equal.
      expect(
        PictureRef.ofLevel(item, 2, pairs: pairs),
        isNot(PictureRef.ofLevel(item, 3, pairs: pairs)),
      );
    });

    test(
      'a picture that is not there, or a pair that is missing, is an error',
      () {
        expect(
          () => PictureRef.ofLevel(item, 4, pairs: pairs),
          throwsArgumentError,
        );
        expect(
          () => PictureRef.ofLevel(item, -1, pairs: pairs),
          throwsArgumentError,
        );
        expect(
          () => PictureRef.ofLevel(item, 0, pairs: {'mamá': _pair('mamá')}),
          throwsArgumentError,
        );
      },
    );
  });
}
