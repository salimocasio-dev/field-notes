// The fixture the chrome tests read holds the very bytes of the files the vm tests read (coqui/ref/pp/), so the two
// platforms compare against one reference. If this fails: `dart run tool/make_fixtures.dart` in this package.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'dart:convert';
import 'dart:io';

import 'support/fixture_decode.dart';
import 'support/fixtures/ref_ctx.dart';
import 'support/fixtures/ref_kit.dart';
import 'support/fixtures/balcon_sheet.dart';
import 'support/fixtures/frente_sheet.dart';
import 'support/fixtures/ref_pp.dart';
import 'support/fixtures/ref_sprites.dart';
import 'support/ref_data.dart';
import 'support/ref_files.dart';
import 'support/sheet_text.dart';

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
    expect(refKitFixture, isNotEmpty);
    for (final entry in {
      ...refSpritesFixture,
      ...refCtxFixture,
      ...refKitFixture,
    }.entries) {
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
      expect(refKitFixture.keys.toSet(), {
        for (final f in Directory('../../../ref/sprites/kit').listSync())
          if (f is File) 'sprites/kit/${f.uri.pathSegments.last}',
      });
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

  test(
    'the Nov 14 one-state El frente is whole (it is in no folder any more)',
    () {
      expect(decodeFrenteNov14('pix.bin').length, 240 * 216 * 4);
      expect(decodeFrenteNov14('zb.bin').length, 240 * 216 * 4);
      expect(decodeFrenteNov14('kinds.bin').length, 240 * 216);
      expect(decodeFrenteNov14('state.json').length, 1130);
    },
  );

  test('the sheet fixture is the text of El frente\'s sheet', () {
    expect(frenteSheetJson, frenteSheetText());
  });

  test('the sheet fixture is the text of El balcón\'s sheet', () {
    expect(balconSheetJson, balconSheetText());
  });
}
