// The fixture the chrome tests read holds the very bytes of the files the vm tests read (coqui/ref/pp/), so the two
// platforms compare against one reference. If this fails: `dart run tool/make_fixtures.dart` in this package.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'dart:convert';
import 'dart:io';

import 'support/fixture_decode.dart';
import 'support/fixtures/ref_ctx.dart';
import 'support/fixtures/ref_pp.dart';
import 'support/fixtures/ref_sprites.dart';
import 'support/ref_data.dart';
import 'support/ref_files.dart';

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

  test('every sprite and canvas fixture file is the file in coqui/ref/', () {
    expect(refSpritesFixture, isNotEmpty);
    expect(refCtxFixture, isNotEmpty);
    for (final entry in {...refSpritesFixture, ...refCtxFixture}.entries) {
      final fromFile = File('../../../ref/${entry.key}').readAsBytesSync();
      expect(base64Decode(entry.value.join()), fromFile, reason: entry.key);
      expect(refFile(entry.key), fromFile, reason: entry.key);
    }
  });

  test(
    'the fixtures hold every sprite file and every tile of the canvas sheet',
    () {
      final onDisk = {
        for (final f in Directory('../../../ref/sprites/engine').listSync())
          if (f is File) 'sprites/engine/${f.uri.pathSegments.last}',
      };
      expect(refSpritesFixture.keys.toSet(), onDisk);
      expect(
        refCtxFixture.keys.where((k) => k.startsWith('ctx/tiles/')).length,
        40,
      );
      expect(
        refCtxFixture.keys.where((k) => k.startsWith('ctx/sources/')).length,
        10,
      );
      expect(refCtxFixture.containsKey('ctx/cases.json'), isTrue);
    },
  );
}
