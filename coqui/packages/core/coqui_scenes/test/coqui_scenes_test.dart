import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the registry holds the eleven scene ids, in order', () {
    expect(sceneRegistry.keys.toList(), [
      'frente',
      'balcon',
      'sala',
      'patio',
      'camino',
      'campo',
      'lago',
      'banco',
      'mesa',
      'estufa',
      'nevera',
    ]);
  });

  for (final entry in sceneRegistry.entries) {
    if (convertedScenes.contains(entry.key)) {
      test('${entry.key} is converted: made from its sheet', () async {
        final scene = await loadScene(entry.key, bundle: testBundle());
        expect(scene, isA<SetScene>());
        expect(scene.id, entry.key);
      });
      continue;
    }
    test('the stub of ${entry.key} throws "not converted yet"', () {
      expect(
        entry.value,
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            'not converted yet',
          ),
        ),
      );
    });
  }
}
