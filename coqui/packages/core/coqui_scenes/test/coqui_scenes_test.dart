import 'package:coqui_scenes/src/registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
