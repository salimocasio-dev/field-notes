import 'package:app/src/content.dart';
import 'package:app/src/web/browser_io.dart';
import 'package:flutter_test/flutter_test.dart';

const _envAppBase = String.fromEnvironment('COQUI_APP_BASE');

void main() {
  test('defaultAppBaseUrl is byte-identical to the live site app URL', () {
    expect(
      defaultAppBaseUrl,
      'https://salimocasio-dev.github.io/field-notes/app/',
    );
  });

  test('appBaseUri uses default or COQUI_APP_BASE dart-define', () {
    if (_envAppBase.isEmpty) {
      expect(
        appBaseUri(),
        Uri.parse('https://salimocasio-dev.github.io/field-notes/app/'),
      );
      expect(
        contentBaseOf(appBaseUri()).toString(),
        'https://salimocasio-dev.github.io/field-notes/historia/',
      );
    } else {
      expect(appBaseUri(), parseAppBaseUri(_envAppBase));
    }
  });

  test('parseAppBaseUri resolves custom base URLs cleanly', () {
    final withTrailingSlash = parseAppBaseUri(
      'https://cdn.example.com/coqui/app/',
    );
    expect(withTrailingSlash.toString(), 'https://cdn.example.com/coqui/app/');
    expect(
      contentBaseOf(withTrailingSlash).toString(),
      'https://cdn.example.com/coqui/historia/',
    );

    final withoutTrailingSlash = parseAppBaseUri(
      'https://cdn.example.com/coqui/app',
    );
    expect(
      withoutTrailingSlash.toString(),
      'https://cdn.example.com/coqui/app/',
    );
    expect(
      contentBaseOf(withoutTrailingSlash).toString(),
      'https://cdn.example.com/coqui/historia/',
    );

    final originOnly = parseAppBaseUri('https://cdn.example.com');
    expect(originOnly.toString(), 'https://cdn.example.com/');
    expect(
      contentBaseOf(originOnly).toString(),
      'https://cdn.example.com/historia/',
    );

    final localHttp = parseAppBaseUri('http://127.0.0.1:8123/field-notes/app/');
    expect(localHttp.toString(), 'http://127.0.0.1:8123/field-notes/app/');
    expect(
      contentBaseOf(localHttp).toString(),
      'http://127.0.0.1:8123/field-notes/historia/',
    );

    final whitespacePadded = parseAppBaseUri(
      '  https://cdn.example.com/coqui/app  ',
    );
    expect(whitespacePadded.toString(), 'https://cdn.example.com/coqui/app/');
    expect(
      contentBaseOf(whitespacePadded).toString(),
      'https://cdn.example.com/coqui/historia/',
    );
  });

  test('parseAppBaseUri falls back to defaultAppBaseUrl when empty', () {
    expect(parseAppBaseUri(''), Uri.parse(defaultAppBaseUrl));
    expect(parseAppBaseUri('   '), Uri.parse(defaultAppBaseUrl));
  });

  test('parseAppBaseUri throws FormatException for invalid URLs', () {
    expect(() => parseAppBaseUri('field-notes/app/'), throwsFormatException);
    expect(
      () => parseAppBaseUri('ftp://example.com/app/'),
      throwsFormatException,
    );
    expect(() => parseAppBaseUri('https://'), throwsFormatException);
  });
}
