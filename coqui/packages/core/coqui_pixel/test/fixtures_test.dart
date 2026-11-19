// The fixture the chrome tests read holds the very bytes of the files the vm tests read (coqui/ref/pp/), so the two
// platforms compare against one reference. If this fails: `dart run tool/make_fixtures.dart` in this package.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'support/fixture_decode.dart';
import 'support/fixtures/ref_pp.dart';
import 'support/ref_data.dart';

void main() {
  test('every fixture file is the file in coqui/ref/pp/', () {
    expect(refPpFixture, isNotEmpty);
    for (final path in refPpFixture.keys) {
      final fromFile = refBytes(path);
      // refBytes on the vm reads the file; decode the fixture the way the browser's loader does
      final fromFixture = decodeFixture(path);
      expect(fromFixture, fromFile, reason: path);
    }
  });
}
