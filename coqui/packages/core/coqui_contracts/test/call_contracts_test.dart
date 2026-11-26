import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:test/test.dart';

import 'fixtures/old_code.dart';

class _LegacyCatalog implements CourseCatalog {
  _LegacyCatalog(this._calls);

  final Map<String, CallBrief> _calls;

  @override
  CallBrief? callFor(String placeId) => _calls[placeId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MultiCallCatalog extends _LegacyCatalog implements CallsCatalog {
  _MultiCallCatalog(super.calls, this._multiCalls);

  final Map<String, List<CallBrief>> _multiCalls;

  @override
  List<CallBrief> callsFor(String placeId) =>
      _multiCalls[placeId] ?? const <CallBrief>[];
}

class _LegacyProgressStore implements ProgressStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CallAwareProgressStore extends _LegacyProgressStore
    implements CallProgressStore {
  _CallAwareProgressStore(this._completed);

  final Set<String> _completed;

  @override
  bool callDone(String callId) => _completed.contains(callId);

  @override
  void markCallDone(String callId) => _completed.add(callId);
}

void main() {
  group('CallBrief', () {
    test('backward-compatible constructor sets expected defaults', () {
      final brief = CallBrief(
        placeId: 'casa',
        minutes: 5,
        job: 'Pide un café con leche.',
        opening: '¡Hola! ¿Qué deseas?',
      );

      expect(brief.id, 'casa');
      expect(brief.placeId, 'casa');
      expect(brief.title, '');
      expect(brief.jobEn, '');
      expect(brief.minutes, 5);
      expect(brief.job, 'Pide un café con leche.');
      expect(brief.opening, '¡Hola! ¿Qué deseas?');
      expect(brief.photo, isNull);
      expect(brief.isMain, isTrue);
      expect(brief.agentId, spanishCallAgentId);
    });

    test('full constructor keeps explicit values including null and non-null photo', () {
      final noPhoto = CallBrief(
        id: 'casa_agua',
        placeId: 'casa',
        title: 'Agua fría',
        jobEn: 'Ask for cold water',
        minutes: 3,
        job: 'Pide un vaso de agua fría.',
        opening: '¿Tienes sed?',
        photo: null,
        isMain: false,
        agentId: 'agent_custom_1',
      );

      expect(noPhoto.id, 'casa_agua');
      expect(noPhoto.placeId, 'casa');
      expect(noPhoto.title, 'Agua fría');
      expect(noPhoto.jobEn, 'Ask for cold water');
      expect(noPhoto.minutes, 3);
      expect(noPhoto.job, 'Pide un vaso de agua fría.');
      expect(noPhoto.opening, '¿Tienes sed?');
      expect(noPhoto.photo, isNull);
      expect(noPhoto.isMain, isFalse);
      expect(noPhoto.agentId, 'agent_custom_1');

      final withPhoto = CallBrief(
        id: 'casa_main',
        placeId: 'casa',
        title: 'Desayuno en casa',
        jobEn: 'Order breakfast at home',
        minutes: 5,
        job: 'Pide café y tostadas.',
        opening: '¡Buenos días!',
        photo: 'pixel/casa_main.png',
        isMain: true,
        agentId: 'agent_custom_2',
      );

      expect(withPhoto.id, 'casa_main');
      expect(withPhoto.photo, 'pixel/casa_main.png');
      expect(withPhoto.isMain, isTrue);
      expect(withPhoto.agentId, 'agent_custom_2');
    });

    test('round-trips legacy LLAMADAS JSON with unchanged keys', () {
      final ll = jsonDecode(llamadasJson) as Map<String, dynamic>;
      for (final entry in ll.entries) {
        final raw = entry.value as Map<String, dynamic>;
        final brief = CallBrief.fromJson(entry.key, raw);

        expect(brief.id, entry.key);
        expect(brief.placeId, entry.key);
        expect(brief.title, '');
        expect(brief.jobEn, '');
        expect(brief.isMain, isTrue);
        expect(brief.agentId, spanishCallAgentId);
        expect(brief.photo, raw['foto']);
        expect(brief.toJson(), raw);
      }
    });

    test(
      'round-trips new main call JSON with null photo and smaller call JSON',
      () {
        final mainJson = <String, dynamic>{
          'title': 'Buenos días en casa',
          'jobEn': 'Say hello and ask for coffee',
          'minutos': 5,
          'job': 'Saluda y pide un café.',
          'opening': '¡Buenos días!',
        };
        final mainCall = CallBrief.fromJson('casa', mainJson);
        expect(mainCall.id, 'casa');
        expect(mainCall.title, 'Buenos días en casa');
        expect(mainCall.jobEn, 'Say hello and ask for coffee');
        expect(mainCall.photo, isNull);
        expect(mainCall.isMain, isTrue);
        expect(mainCall.agentId, spanishCallAgentId);
        expect(mainCall.toJson(), mainJson);
        expect(mainCall.toJson().containsKey('foto'), isFalse);
        expect(mainCall.toJson().containsKey('id'), isFalse);
        expect(mainCall.toJson().containsKey('isMain'), isFalse);

        final smallerJson = <String, dynamic>{
          'id': 'casa_agua',
          'title': 'Un vaso de agua',
          'jobEn': 'Ask for a glass of water',
          'minutos': 2,
          'job': 'Pide un vaso de agua.',
          'opening': '¿Qué necesitas?',
          'isMain': false,
          'agentId': 'agent_small_99',
        };
        final smallerCall = CallBrief.fromJson('casa', smallerJson);
        expect(smallerCall.id, 'casa_agua');
        expect(smallerCall.placeId, 'casa');
        expect(smallerCall.title, 'Un vaso de agua');
        expect(smallerCall.jobEn, 'Ask for a glass of water');
        expect(smallerCall.minutes, 2);
        expect(smallerCall.photo, isNull);
        expect(smallerCall.isMain, isFalse);
        expect(smallerCall.agentId, 'agent_small_99');
        expect(smallerCall.toJson(), smallerJson);
      },
    );

    test('handles missing foto key and explicit null foto cleanly', () {
      final missingFoto = CallBrief.fromJson('plaza', {
        'minutos': 4,
        'job': 'Pregunta la hora.',
        'opening': 'Hola.',
      });
      expect(missingFoto.photo, isNull);
      expect(missingFoto.toJson().containsKey('foto'), isFalse);

      final nullFoto = CallBrief.fromJson('plaza', {
        'minutos': 4,
        'job': 'Pregunta la hora.',
        'opening': 'Hola.',
        'foto': null,
      });
      expect(nullFoto.photo, isNull);
      expect(nullFoto.toJson().containsKey('foto'), isFalse);
    });
  });

  group('CourseCalls.callsFor', () {
    final mainCall = CallBrief(
      id: 'casa',
      placeId: 'casa',
      title: 'En la casa',
      jobEn: 'Ask for breakfast',
      minutes: 5,
      job: 'Pide desayuno.',
      opening: '¡Buenos días!',
    );
    final smallCall1 = CallBrief(
      id: 'casa_agua',
      placeId: 'casa',
      title: 'Agua',
      jobEn: 'Ask for water',
      minutes: 2,
      job: 'Pide agua.',
      opening: '¿Agua?',
      isMain: false,
    );
    final smallCall2 = CallBrief(
      id: 'casa_llaves',
      placeId: 'casa',
      title: 'Las llaves',
      jobEn: 'Ask where the keys are',
      minutes: 2,
      job: 'Pregunta por las llaves.',
      opening: '¿Buscas algo?',
      isMain: false,
    );

    test(
      'falls back to [callFor(placeId)] or [] when catalog omits CallsCatalog',
      () {
        final CourseCatalog course = _LegacyCatalog({'casa': mainCall});

        expect(course.callsFor('casa'), [mainCall]);
        expect(course.callsFor('unknown'), isEmpty);
      },
    );

    test('returns all calls in order when catalog implements CallsCatalog', () {
      final CourseCatalog course = _MultiCallCatalog(
        {'casa': mainCall},
        {
          'casa': [mainCall, smallCall1, smallCall2],
        },
      );

      expect(course.callsFor('casa'), [mainCall, smallCall1, smallCall2]);
      expect(course.callsFor('unknown'), isEmpty);
      expect(course.callFor('casa'), mainCall);
    });
  });

  group('CallRoute', () {
    test('defaults callId to null and formats toString cleanly', () {
      const route = CallRoute('casa');
      const explicitNull = CallRoute('casa', callId: null);

      expect(route.placeId, 'casa');
      expect(route.callId, isNull);
      expect('$route', 'CallRoute(casa)');
      expect(route, explicitNull);
      expect(route.hashCode, explicitNull.hashCode);
    });

    test(
      'supports non-null callId with value equality, hashCode, and toString',
      () {
        const a = CallRoute('casa', callId: 'casa_agua');
        const b = CallRoute('casa', callId: 'casa_agua');
        const mainOnly = CallRoute('casa');
        const diffCall = CallRoute('casa', callId: 'casa_llaves');
        const diffPlace = CallRoute('plaza', callId: 'casa_agua');

        expect(a.placeId, 'casa');
        expect(a.callId, 'casa_agua');
        expect('$a', 'CallRoute(casa, callId: casa_agua)');

        expect(a, b);
        expect(a.hashCode, b.hashCode);
        expect(a, isNot(mainOnly));
        expect(a, isNot(diffCall));
        expect(a, isNot(diffPlace));
      },
    );
  });

  group('CallProgress', () {
    test(
      'callDone returns false and markCallDone is a no-op on legacy store',
      () {
        final ProgressStore store = _LegacyProgressStore();
        expect(store.callDone('casa'), isFalse);
        expect(store.callDone('casa_agua'), isFalse);
        expect(() => store.markCallDone('casa'), returnsNormally);
        expect(store.callDone('casa'), isFalse);
      },
    );

    test('delegates callDone and markCallDone to CallProgressStore', () {
      final ProgressStore store = _CallAwareProgressStore({
        'casa',
        'casa_agua',
      });
      expect(store.callDone('casa'), isTrue);
      expect(store.callDone('casa_agua'), isTrue);
      expect(store.callDone('casa_llaves'), isFalse);

      store.markCallDone('casa_llaves');
      expect(store.callDone('casa_llaves'), isTrue);
    });
  });
}
