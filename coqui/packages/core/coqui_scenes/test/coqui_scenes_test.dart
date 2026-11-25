import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the registry starts with the 12 published scenes and matches convertedScenes', () {
    expect(sceneRegistry.keys.take(12).toList(), [
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
      'comer',
    ]);
    expect(sceneRegistry.keys.toSet(), convertedScenes);
    expect(sceneRegistry.length, sceneRegistry.keys.toSet().length);
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
