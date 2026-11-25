@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:coqui_platform/src/io/phone_speech.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class _FakeSpeechPlugin implements SpeechPlugin {
  bool permission = true;
  bool initResult = true;
  SpeechErrorListener? onError;
  SpeechStatusListener? onStatus;
  final List<SpeechListenOptions?> listenCalls = [];
  bool throwOnDevice = false;
  bool throwAlways = false;
  String? errorOnDeviceMsg;
  bool emitDoneAfterOnDeviceError = false;

  @override
  Future<bool> get hasPermission async => permission;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
  }) async {
    this.onError = onError;
    this.onStatus = onStatus;
    return initResult;
  }

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    SpeechListenOptions? listenOptions,
  }) async {
    listenCalls.add(listenOptions);
    if (throwAlways) {
      throw ListenFailedException('failed');
    }
    if (throwOnDevice && listenOptions?.onDevice == true) {
      throw ListenFailedException('on device failed');
    }
    if (errorOnDeviceMsg != null && listenOptions?.onDevice == true) {
      scheduleMicrotask(() {
        onError?.call(SpeechRecognitionError(errorOnDeviceMsg!, true));
        if (emitDoneAfterOnDeviceError) {
          onStatus?.call(SpeechToText.doneStatus);
        }
      });
      return;
    }
    scheduleMicrotask(() {
      onResult?.call(
        SpeechRecognitionResult([
          SpeechRecognitionWords('hola', null, 1.0),
        ], ResultType.finalResult.value),
      );
      onStatus?.call(SpeechToText.doneStatus);
    });
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

void main() {
  group('PhoneSpeech onDevice & DNS probe (S10 / N7)', () {
    test('source file does not hardcode www.google.com DNS probe', () {
      final source = File('lib/src/io/phone_speech.dart').readAsStringSync();
      expect(source, isNot(contains('www.google.com')));
    });

    test(
      'online() returns true with 0 DNS lookups when on-device is supported',
      () async {
        final lookups = <String>[];
        final phone = PhoneSpeech(
          lookupHost: (host) async {
            lookups.add(host);
            return false;
          },
          plugin: _FakeSpeechPlugin(),
        );
        expect(await phone.online(), isTrue);
        expect(lookups, isEmpty);
      },
    );

    test(
      'online() skips DNS lookup by default even when on-device is unsupported',
      () async {
        final lookups = <String>[];
        final phone = PhoneSpeech(
          onDeviceSupported: ({localeId}) async => false,
          lookupHost: (host) async {
            lookups.add(host);
            return false;
          },
          plugin: _FakeSpeechPlugin(),
        );
        expect(await phone.online(), isTrue);
        expect(lookups, isEmpty);
      },
    );

    test('online() uses explicit networkProbeHost only when on-device is unsupported', () async {
      final lookups = <String>[];
      final phone = PhoneSpeech(
        networkProbeHost: 'speech.example.test',
        onDeviceSupported: ({localeId}) async => false,
        lookupHost: (host) async {
          lookups.add(host);
          return false;
        },
        plugin: _FakeSpeechPlugin(),
      );
      expect(await phone.online(), isFalse);
      expect(lookups, ['speech.example.test']);
    });

    test('listen prefers onDevice: true when supported', () async {
      final plugin = _FakeSpeechPlugin();
      final phone = PhoneSpeech(plugin: plugin);
      final listener = phone.listener();
      expect(await listener.available(), isTrue);

      final turn = listener.listen(
        locale: 'es-US',
        limit: const Duration(seconds: 6),
      );
      final res = await turn.result;
      expect(res.alternatives, ['hola']);
      expect(res.error, isNull);
      expect(plugin.listenCalls, hasLength(1));
      expect(plugin.listenCalls.single!.onDevice, isTrue);
    });

    test('falls back to onDevice: false when ListenFailedException is thrown and remembers locale', () async {
      final plugin = _FakeSpeechPlugin()..throwOnDevice = true;
      final phone = PhoneSpeech(plugin: plugin);
      final listener = phone.listener();

      final res1 = await listener
          .listen(locale: 'es-US', limit: const Duration(seconds: 6))
          .result;
      expect(res1.alternatives, ['hola']);
      expect(res1.error, isNull);
      expect(plugin.listenCalls.map((o) => o!.onDevice), [true, false]);

      // Subsequent turn for the same locale skips onDevice: true immediately.
      final res2 = await listener
          .listen(locale: 'es-US', limit: const Duration(seconds: 6))
          .result;
      expect(res2.alternatives, ['hola']);
      expect(plugin.listenCalls.map((o) => o!.onDevice), [true, false, false]);
    });

    test('falls back to onDevice: false on onDevice error callback without marking speech unavailable', () async {
      final plugin = _FakeSpeechPlugin()
        ..errorOnDeviceMsg = 'error_language_unavailable';
      final phone = PhoneSpeech(plugin: plugin);
      final listener = phone.listener();

      final res = await listener
          .listen(locale: 'es-PR', limit: const Duration(seconds: 6))
          .result;
      expect(res.alternatives, ['hola']);
      expect(res.error, isNull);
      expect(plugin.listenCalls.map((o) => o!.onDevice), [true, false]);
      expect(await listener.available(), isTrue);
    });

    test('doneStatus right after onDevice error callback does not finish before fallback completes', () async {
      final plugin = _FakeSpeechPlugin()
        ..errorOnDeviceMsg = 'error_language_unavailable'
        ..emitDoneAfterOnDeviceError = true;
      final phone = PhoneSpeech(plugin: plugin);
      final listener = phone.listener();

      final res = await listener
          .listen(locale: 'es-MX', limit: const Duration(seconds: 6))
          .result;
      expect(res.alternatives, ['hola']);
      expect(res.error, isNull);
      expect(plugin.listenCalls.map((o) => o!.onDevice), [true, false]);
    });
  });
}
