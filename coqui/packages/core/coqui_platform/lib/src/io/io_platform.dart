import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/src/audio/graph_clip_player.dart';
import 'package:coqui_platform/src/audio/pcm_graph.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';
import 'package:coqui_platform/src/info/app_info.dart';
import 'package:coqui_platform/src/io/just_audio_sink.dart';
import 'package:coqui_platform/src/io/phone_clip_player.dart';
import 'package:coqui_platform/src/io/phone_speech.dart';
import 'package:coqui_platform/src/storage/spaces.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The phone builds (Android, iOS): the plugins. Nothing here is loaded on the web.

/// The [ClipPlayer] of a phone build: clips through just_audio, the made sounds rendered once by the
/// Web Audio formulas and played through it too. A clip's file is `base.resolve(clipInfo(id).url)`.
ClipPlayer createClipPlayer({
  required ClipLookup clipInfo,
  required Uri base,
}) => PhoneClipPlayer(
  effects: SoundCore(() => PcmGraph(JustAudioSink())),
  clipInfo: clipInfo,
  base: base,
);

PhoneSpeech? _speech;

/// The [SpeechListener] of a phone build: speech_to_text, with the web's turn timing.
SpeechListener createSpeechListener() => (_speech ??= PhoneSpeech()).listener();

class _Prefs implements StringBackend {
  _Prefs(this.p);
  final SharedPreferencesWithCache p;

  @override
  String? read(String key) => p.getString(key);

  @override
  Future<void> write(String key, String value) => p.setString(key, value);
}

/// shared_preferences, loaded once (reads are then synchronous).
Future<CoquiStorage> openStorage() async => CoquiStorage(
  _Prefs(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    ),
  ),
);

class _PhoneHaptics implements Haptics {
  @override
  void tick() => HapticFeedback.lightImpact();

  @override
  void unlock() {}
}

/// The platform's light haptic on a tap.
Haptics createHaptics() => _PhoneHaptics();

/// A phone build is an installed app.
AppInfo createAppInfo() => FixedAppInfo(
  isWeb: false,
  isIos: Platform.isIOS,
  isAndroid: Platform.isAndroid,
  installed: true,
);
