import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
