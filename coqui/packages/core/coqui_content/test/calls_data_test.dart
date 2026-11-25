// Verifies the 31 reviewed calls in `data/llamadas.json` through `ContentCatalog` (VM only).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:coqui_content/coqui_content.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

import 'support.dart';

final Directory _repoRoot = () {
  var dir = Directory.current.absolute;
  while (true) {
    final historia = Directory('${dir.path}/historia');
    final data = File(
      '${dir.path}/coqui/packages/core/coqui_content/data/llamadas.json',
    );
    if (historia.existsSync() && data.existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('no repository root above ${Directory.current.path}');
    }
    dir = parent;
  }
}();

final File _llamadasFile = File(
  '${_repoRoot.path}/coqui/packages/core/coqui_content/data/llamadas.json',
);

Future<String> _fetchWithReviewedCalls(String path) {
  if (path == 'datos/llamadas.json') return _llamadasFile.readAsString();
  return File('${_repoRoot.path}/historia/$path').readAsString();
}

const _expectedCalls =
    <String, List<({String id, String jobEn, int minutes, bool isMain})>>{
      'casa': [
        (
          id: 'casa_main',
          jobEn: 'Greet {partner}, introduce yourself, and accept a drink.',
          minutes: 5,
          isMain: true,
        ),
        (
          id: 'casa_agua',
          jobEn: 'Ask for a drink and say thanks.',
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'casa_saludo',
          jobEn: 'Greet {partner} and say how you are doing.',
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'casa_despedida',
          jobEn: 'Wrap up a quick visit and say goodbye.',
          minutes: 2,
          isMain: false,
        ),
      ],
      'parque': [
        (
          id: 'parque_main',
          jobEn: 'Describe the park, its colours, and what the dog does.',
          minutes: 5,
          isMain: true,
        ),
        (
          id: 'parque_colores',
          jobEn: 'Name the colours of things around the park.',
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'parque_perro',
          jobEn: 'Say what the dog is doing right now.',
          minutes: 2,
          isMain: false,
        ),
      ],
      'cocina': [
        (
          id: 'cocina_main',
          jobEn: 'Say you are hungry, what you want, and what you like.',
          minutes: 5,
          isMain: true,
        ),
        (
          id: 'cocina_tomar',
          jobEn: 'Say what you want to drink.',
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'cocina_comer',
          jobEn: 'Say which foods you like and do not like.',
          minutes: 2,
          isMain: false,
        ),
      ],
      'colmado': [
        (
          id: 'colmado_main',
          jobEn: 'Ask for three things, ask the price, and pay.',
          minutes: 5,
          isMain: true,
        ),
        (
          id: 'colmado_precio',
          jobEn: 'Ask how much two items cost together.',
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'colmado_pagar',
          jobEn: 'Pick one item and pay at the counter.',
          minutes: 2,
          isMain: false,
        ),
      ],
      'calle': [
        (
          id: 'calle_main',
          jobEn: 'Ask for directions and say where you are going.',
          minutes: 5,
          isMain: true,
        ),
        (
          id: 'calle_lados',
          jobEn: 'Follow simple left, right, and near directions.',
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'calle_destino',
          jobEn: 'Tell {partner} where you are heading.',
          minutes: 2,
          isMain: false,
        ),
      ],
      'plaza': [
        (
          id: 'plaza_main',
          jobEn: 'Share your name, hometown, and work, and ask back.',
          minutes: 5,
          isMain: true,
        ),
        (
          id: 'plaza_hora',
          jobEn: 'Ask for and tell the time.',
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'plaza_origen',
          jobEn: 'Say where you are from and what you do.',
          minutes: 2,
          isMain: false,
        ),
      ],
      'playa': [
        (
          id: 'playa_main',
          jobEn: 'Talk about the weather, clothes, and what you can do.',
          minutes: 5,
          isMain: true,
        ),
        (
          id: 'playa_clima',
          jobEn: "Talk about today's weather at the beach.",
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'playa_nadar',
          jobEn: 'Say what you can and cannot do in the water.',
          minutes: 2,
          isMain: false,
        ),
      ],
      'fonda': [
        (
          id: 'fonda_main',
          jobEn: 'Get a table, order lunch, and ask for the bill.',
          minutes: 5,
          isMain: true,
        ),
        (
          id: 'fonda_mesa',
          jobEn: 'Ask for a table and order a drink.',
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'fonda_cuenta',
          jobEn: 'Say how the food was and ask for the bill.',
          minutes: 2,
          isMain: false,
        ),
      ],
      'casa2': [
        (
          id: 'casa2_main',
          jobEn: 'Walk through your daily routine and times.',
          minutes: 5,
          isMain: true,
        ),
        (
          id: 'casa2_manana',
          jobEn: 'Say what you do in the morning and when.',
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'casa2_noche',
          jobEn: 'Say how you spend your evening and go to bed.',
          minutes: 2,
          isMain: false,
        ),
      ],
      'fuerte': [
        (
          id: 'fuerte_main',
          jobEn: 'Invite {partner} out, share plans, and say how you feel.',
          minutes: 6,
          isMain: true,
        ),
        (
          id: 'fuerte_invitar',
          jobEn: 'Invite someone along and pick a time.',
          minutes: 2,
          isMain: false,
        ),
        (
          id: 'fuerte_sentir',
          jobEn: 'Say how you are feeling today.',
          minutes: 2,
          isMain: false,
        ),
      ],
    };

void main() {
  test('serves the 31 reviewed calls (10 main + 21 smaller) across all 10 places from data/llamadas.json', () async {
    final catalog = ContentCatalog(_fetchWithReviewedCalls);
    await catalog.load();
    expect(catalog, isA<CallsCatalog>());
    final CourseCatalog course = catalog;

    final rawData =
        jsonDecode(_llamadasFile.readAsStringSync()) as Map<String, dynamic>;
    final legacyData = jsonDecode(
      File('${_repoRoot.path}/historia/datos/llamadas.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final legacyCasa = legacyData['casa'] as Map<String, dynamic>;

    final placeIds = [for (final p in course.places) p.id];
    expect(placeIds, _expectedCalls.keys.toList());
    expect(rawData.keys.toList(), placeIds);

    final seenIds = <String>{};
    var totalCalls = 0;
    var mainCount = 0;
    var smallerCount = 0;

    for (final place in course.places) {
      final expectedList = _expectedCalls[place.id]!;
      final rawList = rawData[place.id] as List<dynamic>;
      final calls = course.callsFor(place.id);
      final mainCall = course.callFor(place.id);

      expect(calls, hasLength(expectedList.length), reason: place.id);
      expect(mainCall, isNotNull, reason: place.id);
      expect(mainCall, same(calls.first), reason: place.id);

      for (var i = 0; i < expectedList.length; i++) {
        final exp = expectedList[i];
        final c = calls[i];
        final rawEntry = rawList[i] as Map<String, dynamic>;

        expect(seenIds.add(c.id), isTrue, reason: 'duplicate id ${c.id}');
        expect(c.id, exp.id, reason: c.id);
        expect(c.placeId, place.id, reason: c.id);
        expect(c.title.trim(), isNotEmpty, reason: c.id);
        expect(c.jobEn, exp.jobEn, reason: c.id);
        expect(c.minutes, exp.minutes, reason: c.id);
        expect(c.job.trim(), isNotEmpty, reason: c.id);
        expect(c.isMain, exp.isMain, reason: c.id);
        expect(c.photo, isNull, reason: c.id);
        expect(c.agentId, Language.spanish.callAgentId, reason: c.id);

        final lowerTitle = c.title.toLowerCase();
        expect(lowerTitle, isNot(contains('call danny')), reason: c.id);
        expect(lowerTitle, isNot(contains('llamar a danny')), reason: c.id);
        for (final field in [c.title, c.jobEn, c.job, c.opening]) {
          final lower = field.toLowerCase();
          expect(lower, isNot(contains('mi amor')), reason: c.id);
          expect(lower, isNot(contains('nene')), reason: c.id);
        }

        if (c.id == 'casa_main') {
          expect(c.job, legacyCasa['job']);
          expect(c.opening, legacyCasa['opening']);
        } else {
          expect(c.opening, isEmpty, reason: c.id);
        }

        expect(c.toJson(), sameJson(rawEntry), reason: c.id);
        final roundTripped = CallBrief.fromJson(c.placeId, c.toJson());
        expect(roundTripped.id, c.id, reason: c.id);
        expect(roundTripped.placeId, c.placeId, reason: c.id);
        expect(roundTripped.title, c.title, reason: c.id);
        expect(roundTripped.jobEn, c.jobEn, reason: c.id);
        expect(roundTripped.minutes, c.minutes, reason: c.id);
        expect(roundTripped.job, c.job, reason: c.id);
        expect(roundTripped.opening, c.opening, reason: c.id);
        expect(roundTripped.photo, c.photo, reason: c.id);
        expect(roundTripped.isMain, c.isMain, reason: c.id);
        expect(roundTripped.agentId, c.agentId, reason: c.id);

        totalCalls++;
        if (c.isMain) {
          mainCount++;
        } else {
          smallerCount++;
        }
      }
    }

    expect(totalCalls, 31);
    expect(mainCount, 10);
    expect(smallerCount, 21);
    expect(seenIds, hasLength(31));
  });
}
