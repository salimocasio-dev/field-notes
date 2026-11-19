// The Dart fixture (test/fixtures/progress_fixture.dart, made by tool/make_fixture.mjs) must equal
// the recordings it was made from. Chrome cannot read files, so this runs on the VM only.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'fixtures/progress_fixture.dart';
import 'support/diff.dart';

/// coqui/ref/progress, from the package folder where `dart test` runs.
final Directory _ref = Directory('../../../ref/progress');

void main() {
  test('the recordings are where the test looks for them', () {
    expect(
      _ref.existsSync(),
      isTrue,
      reason:
          'run `dart test` in coqui/packages/core/coqui_progress; looked for ${_ref.absolute.path}',
    );
  });

  test('index.json is the same', () {
    final file = File('${_ref.path}/index.json');
    expect(
      firstDifference(
        jsonDecode(fixtureIndex),
        jsonDecode(file.readAsStringSync()),
      ),
      isNull,
    );
  });

  for (final zone in fixtureZones) {
    group(zone, () {
      final files =
          Directory('${_ref.path}/$zone')
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      final keys = [
        for (final k in fixtureSequences.keys)
          if (k.startsWith('$zone/')) k,
      ];

      test('the same ${files.length} sequences', () {
        expect(keys, [
          for (final f in files)
            '$zone/${f.uri.pathSegments.last.replaceAll('.json', '')}',
        ]);
      });

      for (final file in files) {
        final name = file.uri.pathSegments.last.replaceAll('.json', '');
        test('$name is the same', () {
          final key = '$zone/$name';
          final fromFile =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          final fromFixture =
              jsonDecode(fixtureSequences[key]!) as Map<String, dynamic>;
          // The fixture holds each store as its own text; put the objects back.
          (fromFixture['initial'] as Map)['store'] = jsonDecode(
            (fromFixture['initial'] as Map)['store'] as String,
          );
          for (final s
              in (fromFixture['steps'] as List).cast<Map<String, dynamic>>()) {
            s['store'] = jsonDecode(s['store'] as String);
          }
          expect(firstDifference(fromFixture, fromFile), isNull);
        });
      }
    });
  }
}
