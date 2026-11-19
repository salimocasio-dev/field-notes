import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/coqui_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('off the web, the public file gives the phone build\'s implementations', () {
    final ClipPlayer p = createClipPlayer(
      clipInfo: (_) => null,
      base: Uri.parse('https://example.test/historia/'),
    );
    expect(p.muted, isFalse);
    final AppInfo i = createAppInfo();
    expect(i.isWeb, isFalse);
    expect(i.installed, isTrue);
    expect(i.build, coquiBuild);
    expect(createHaptics(), isA<Haptics>());
    expect(createSpeechListener(), isA<SpeechListener>());
  });
}
