import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/coqui_platform.dart';
import 'package:coqui_platform/src/info/app_info.dart';
import 'package:coqui_platform/src/storage/spaces.dart';
import 'package:flutter_test/flutter_test.dart';

class _Map implements StringBackend {
  _Map(this.m);
  final Map<String, String> m;

  @override
  String? read(String key) => m[key];

  @override
  Future<void> write(String key, String value) async => m[key] = value;

  @override
  Future<void> delete(String key) async => m.remove(key);
}

const _ua = {
  'android chrome': 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
  'iphone safari': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
  'iphone chrome': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/131.0.6778.73 Mobile/15E148 Safari/604.1',
  'ipad desktop mode': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15',
  'desktop chrome': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
};

void main() {
  group('storage spaces', () {
    // What the old app leaves in localStorage.
    final old = {
      'coqui.palabras.v1': '{"palabras":{},"v":1}',
      'coqui.juego.ult': '{"la-lluvia:3":"b"}',
      'coqui.juego.mem': '{"nombre":"Ana"}',
      'coqui.leer.tam': '2',
      'coqui.hablaprueba': '{}',
    };

    test(
      'the progress space has no prefix: the store\'s own key is the old key',
      () async {
        final m = Map.of(old);
        final s = CoquiStorage(_Map(m));
        expect(s.progress.read('coqui.palabras.v1'), old['coqui.palabras.v1']);
        await s.progress.write('coqui.palabras.v1', '{"v":2}');
        expect(m['coqui.palabras.v1'], '{"v":2}');
      },
    );
    test(
      'a space is the prefix coqui.<name>.: the old keys are simply there',
      () async {
        final m = Map.of(old);
        final s = CoquiStorage(_Map(m));
        expect(s.space('juego').read('ult'), old['coqui.juego.ult']);
        expect(s.space('juego').read('mem'), old['coqui.juego.mem']);
        expect(s.space('leer').read('tam'), '2');
        await s.space('leer').write('tam', '3');
        expect(m['coqui.leer.tam'], '3');
        await s.space('library').write('x', 'y');
        expect(m['coqui.library.x'], 'y');
      },
    );
    test(
      'nothing is deleted: every old key is still there after use',
      () async {
        final m = Map.of(old);
        final s = CoquiStorage(_Map(m));
        await s.space('juego').write('ult', '{}');
        for (final k in old.keys) {
          expect(m.containsKey(k), isTrue, reason: k);
        }
      },
    );
    test('spaces do not see each other\'s keys', () async {
      final s = CoquiStorage(_Map({}));
      await s.space('a').write('k', '1');
      expect(s.space('b').read('k'), isNull);
      expect(s.progress.read('k'), isNull);
      expect(identical(s.space('a'), s.space('a')), isTrue);
    });
    test('a space name is letters, digits, _ or -', () {
      final s = CoquiStorage(_Map({}));
      expect(() => s.space(''), throwsArgumentError);
      expect(() => s.space('a.b'), throwsArgumentError);
    });
    test(
      'delete removes only the targeted key in that space or progress',
      () async {
        final m = Map.of(old);
        final s = CoquiStorage(_Map(m));
        await s.space('leer').write('extra', '1');
        await s.space('juego').write('extra', '2');
        await s.space('leer').delete('extra');
        expect(s.space('leer').read('extra'), isNull);
        expect(m.containsKey('coqui.leer.extra'), isFalse);
        expect(s.space('juego').read('extra'), '2');
        expect(s.space('leer').read('tam'), '2');

        await s.space('leer').delete('missing');
        expect(s.space('leer').read('tam'), '2');

        await s.progress.delete('coqui.palabras.v1');
        expect(s.progress.read('coqui.palabras.v1'), isNull);
        expect(m.containsKey('coqui.palabras.v1'), isFalse);
        expect(m['coqui.juego.ult'], old['coqui.juego.ult']);
      },
    );
    test(
      'SpaceStore implements DeletableKeyValueStore via KeyValueStoreDelete',
      () async {
        final m = Map.of(old);
        final s = CoquiStorage(_Map(m));
        expect(s.space('leer'), isA<DeletableKeyValueStore>());
        expect(s.progress, isA<DeletableKeyValueStore>());

        await s.space('leer').write('extra', '1');
        await s.space('juego').write('extra', '2');

        await (s.space('leer') as KeyValueStore).delete('extra');
        expect(s.space('leer').read('extra'), isNull);
        expect(m.containsKey('coqui.leer.extra'), isFalse);
        expect(s.space('juego').read('extra'), '2');
        expect(s.space('leer').read('tam'), '2');

        await (s.progress as KeyValueStore).delete('coqui.palabras.v1');
        expect(s.progress.read('coqui.palabras.v1'), isNull);
        expect(m.containsKey('coqui.palabras.v1'), isFalse);
        expect(m['coqui.juego.ult'], old['coqui.juego.ult']);
      },
    );
  });

  group('AppInfo on the web, from the user agent', () {
    FixedAppInfo info(
      String ua, {
      String platform = '',
      int touch = 0,
      bool standalone = false,
    }) => FixedAppInfo.web(
      BrowserFacts(
        userAgent: ua,
        platform: platform,
        maxTouchPoints: touch,
        standalone: standalone,
      ),
    );

    test('Android Chrome', () {
      final i = info(
        _ua['android chrome']!,
        platform: 'Linux armv81',
        touch: 5,
      );
      expect(
        [i.isWeb, i.isAndroid, i.isIos, i.installed],
        [true, true, false, false],
      );
    });
    test('iPhone Safari, and Chrome on an iPhone', () {
      for (final k in ['iphone safari', 'iphone chrome']) {
        final i = info(_ua[k]!, platform: 'iPhone', touch: 5);
        expect([i.isIos, i.isAndroid], [true, false], reason: k);
      }
    });
    test('an iPad that says it is a Mac', () {
      expect(
        info(_ua['ipad desktop mode']!, platform: 'MacIntel', touch: 5).isIos,
        isTrue,
      );
      expect(
        info(_ua['ipad desktop mode']!, platform: 'MacIntel').isIos,
        isFalse,
      );
    });
    test('desktop Chrome', () {
      final i = info(_ua['desktop chrome']!, platform: 'Linux x86_64');
      expect([i.isIos, i.isAndroid], [false, false]);
    });
    test('opened from the home screen', () {
      expect(info(_ua['iphone safari']!, standalone: true).installed, isTrue);
    });
    test('the build and calls come from the build\'s settings', () {
      final i = info(_ua['desktop chrome']!);
      expect(i.build, 'dev'); // no --dart-define=COQUI_BUILD in a test
      expect(i.callsAllowed, isTrue); // COQUI_CALLS defaults to true
      expect(coquiBuild, 'dev');
      expect(iosAudioSessionType, isNull); // set after order 00's iPhone result
    });
  });

  group('haptics on the web', () {
    test('a tick is navigator.vibrate(8)', () {
      final got = <int>[];
      WebHaptics(isIos: false, vibrate: got.add).tick();
      expect(got, [8]);
    });
    test(
      'nothing on an iPhone, nothing without vibrate, and nothing for unlock',
      () {
        final got = <int>[];
        WebHaptics(isIos: true, vibrate: got.add)
          ..tick()
          ..unlock();
        WebHaptics(isIos: false, vibrate: null).tick();
        WebHaptics(isIos: false, vibrate: got.add).unlock();
        expect(got, isEmpty);
      },
    );
    test('a vibrate that throws is ignored (app.html wraps it in try)', () {
      WebHaptics(isIos: false, vibrate: (_) => throw StateError('x')).tick();
    });
  });
}
