// The audio plugin under test (just_audio) and the watch on its <audio> element's clock (web/coqui_meter.js).
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:just_audio/just_audio.dart';

import 'browser.dart';
import 'web_audio.dart' show Marks;

String clipKey(Uri u) => u.pathSegments.isEmpty ? '' : u.pathSegments.last;

Duration secs(double s) => Duration(microseconds: (s * 1e6).round());

class PluginAudio {
  /// One player for the whole page, as an app would have: one <audio> element, unlocked by the first tap.
  /// handleAudioSessionActivation is off: on the web audio_session has nothing to activate.
  final AudioPlayer player = AudioPlayer(handleAudioSessionActivation: false);
  bool unlocked = false;
  String unlockNote = 'not yet';
  Future<void>? _unlocking;
  final List<String> errors = [];

  PluginAudio() {
    player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace _) => errors.add(errText(e)),
    );
  }

  /// Before any tap: load 40 ms of the quiet lead-in of a clip (every clip here has more than 150 ms of it),
  /// so the first tap can play it and unlock the element without a sound.
  Future<void> prepareUnlock(Uri url) async {
    try {
      await player
          .setAudioSource(
            ClippingAudioSource(
              child: AudioSource.uri(url),
              start: Duration.zero,
              end: const Duration(milliseconds: 40),
            ),
          )
          .timeout(const Duration(seconds: 15));
      unlockNote = 'ready';
    } catch (e) {
      unlockNote = 'could not load the unlock clip: ${errText(e)}';
    }
  }

  /// Inside a tap. Starts the silent play once; later taps do nothing.
  void unlock() {
    if (unlocked || _unlocking != null) return;
    final t = nowMs();
    _unlocking = () async {
      try {
        unawaited(
          player.play().catchError((Object e) => errors.add(errText(e))),
        );
        final ok = await within(
          player.processingStateStream.firstWhere(
            (s) => s == ProcessingState.completed,
          ),
          const Duration(seconds: 3),
        );
        await player.pause();
        unlocked = ok != null;
        unlockNote = ok != null
            ? 'unlocked by the first tap (${ms(nowMs() - t)} ms)'
            : 'the unlock play did not complete in 3 s (state ${player.processingState.name})';
      } catch (e) {
        unlockNote = 'unlock failed: ${errText(e)}';
      }
    }();
  }

  /// Wait for the unlock started by a tap (up to 4 s).
  Future<void> unlockDone() async {
    final u = _unlocking;
    if (u != null) await within(u, const Duration(seconds: 4));
  }

  Future<void> stopNow() async {
    try {
      await player.pause().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// Load [items] (url, marks) as the player's playlist, clipped to the marks.
  ///
  /// Not setAudioSources a second time: on the web (just_audio 0.10.6 with just_audio_web 0.4.16) that keeps
  /// playing the first playlist, because the web side caches the playlist's player by its id, which does not
  /// change. Editing the playlist works: add the new items after the old ones, then remove the old ones.
  Future<String?> load(List<(Uri, Marks)> items) async {
    final list = [
      for (final (u, m) in items)
        ClippingAudioSource(
          child: AudioSource.uri(u),
          start: secs(m.t0),
          end: secs(m.t1),
        ),
    ];
    try {
      await stopNow();
      final old = player.audioSources.length;
      if (old == 0) {
        await player
            .setAudioSources(list, preload: true)
            .timeout(const Duration(seconds: 15));
      } else {
        await player.addAudioSources(list).timeout(const Duration(seconds: 15));
        await player
            .removeAudioSourceRange(0, old)
            .timeout(const Duration(seconds: 15));
        if (player.currentIndex != 0) {
          await player
              .seek(Duration.zero, index: 0)
              .timeout(const Duration(seconds: 15));
        }
      }
      final first = clipKey(items.first.$1);
      final now = player.audioSources.isEmpty
          ? ''
          : clipKey(
              ((player.audioSources.first as ClippingAudioSource).child).uri,
            );
      if (player.audioSources.length != items.length || now != first) {
        return 'the playlist did not take the new clips (${player.audioSources.length} items, first "$now")';
      }
      return null;
    } catch (e) {
      return errText(e);
    }
  }

  /// Play what is loaded until the playlist completes or [limit] passes. Returns null or an error/timeout note.
  Future<String?> playToEnd(Duration limit) async {
    final errs0 = errors.length;
    unawaited(player.play().catchError((Object e) => errors.add(errText(e))));
    final ok = await within(
      player.processingStateStream.firstWhere(
        (s) => s == ProcessingState.completed,
      ),
      limit,
    );
    final state = player.processingState.name;
    await stopNow();
    if (ok == null) {
      final more = errors.length > errs0
          ? ' (${errors.sublist(errs0).join('; ')})'
          : '';
      return 'did not complete within ${limit.inMilliseconds} ms (state $state)$more';
    }
    return null;
  }
}

/// One sample of the <audio> element's clock.
class MediaSample {
  MediaSample(this.w, this.src, this.ct, this.paused, this.event);
  final double w; // ms since navigation start
  final String src;
  final double ct; // currentTime, s
  final bool paused;
  final String event;
}

void mediaWatchStart() {
  try {
    coquiMedia?.callMethod<JSAny?>('start'.toJS);
  } catch (_) {}
}

List<MediaSample> mediaWatchStop() {
  try {
    final s = coquiMedia?.callMethod<JSString>('stop'.toJS).toDart ?? '[]';
    final l = jsonDecode(s) as List;
    return [
      for (final m in l.cast<Map<String, dynamic>>())
        MediaSample(
          (m['w'] as num).toDouble(),
          m['src'] as String? ?? '',
          (m['ct'] as num?)?.toDouble() ?? 0,
          m['p'] as bool? ?? true,
          m['e'] as String? ?? '',
        ),
    ];
  } catch (_) {
    return const [];
  }
}

int mediaElements() {
  try {
    return coquiMedia?.callMethod<JSNumber>('count'.toJS).toDartInt ?? 0;
  } catch (_) {
    return 0;
  }
}

/// Where the clip [id] reached its end mark and where it started sounding from its start mark,
/// read from the element's clock.
///
/// Start: Chrome's element clock moves a little at play(), stalls while the audio output starts, then runs
/// steadily. The first movement is not sound, so the start is taken from the steady clock line: each sample
/// 150-450 ms after the first movement says "the start mark was at w - (ct - t0)"; the median of those is
/// used, and their spread is its error. A stall or stutter at the start therefore counts as silence.
/// End: the clock is steady by then; the crossing of the end mark is interpolated between the two samples
/// either side of it, and their distance is its error.
class ClipTimes {
  double? endAt, endErr, startAt, startErr, seekOff, firstMove;
  bool endExtrapolated = false;
  double maxCt = 0;
}

ClipTimes clipTimes(
  List<MediaSample> ss,
  String id,
  Marks m, {
  double after = -1,
}) {
  final r = ClipTimes();
  final mine = ss
      .where((s) => s.src.endsWith('/$id.mp3') && s.w >= after)
      .toList();
  if (mine.isEmpty) return r;
  var f = -1;
  for (var k = 1; k < mine.length; k++) {
    if (!mine[k].paused && mine[k].ct > mine[k - 1].ct + 1e-4) {
      f = k;
      break;
    }
  }
  if (f < 0) return r;
  final a0 = mine[f - 1], b0 = mine[f];
  r.firstMove = b0.w - (b0.ct - a0.ct) * 1000;
  r.seekOff = (a0.ct - m.t0) * 1000;
  List<double> est(double from, double to) => [
    for (final s in mine.skip(f))
      if (!s.paused && s.w >= from && s.w <= to && s.ct < m.t1)
        s.w - (s.ct - m.t0) * 1000,
  ];
  var e = est(r.firstMove! + 150, r.firstMove! + 450);
  if (e.length < 5) {
    e = est(r.firstMove! + 60, double.infinity).take(30).toList();
  }
  if (e.isEmpty) return r;
  e.sort();
  r.startAt = e[e.length ~/ 2];
  r.startErr = e.last - e.first;
  for (var k = f + 1; k < mine.length; k++) {
    final a = mine[k - 1], b = mine[k];
    if (b.ct > r.maxCt) r.maxCt = b.ct;
    if (a.ct < m.t1 && b.ct >= m.t1 && b.ct > a.ct) {
      r.endAt = a.w + (m.t1 - a.ct) / (b.ct - a.ct) * (b.w - a.w);
      r.endErr = b.w - a.w;
      break;
    }
  }
  if (r.endAt == null) {
    // it stopped before its end mark was seen (for instance at the file's end): from the last moving sample
    for (var k = mine.length - 1; k > f; k--) {
      final a = mine[k - 1], b = mine[k];
      if (b.ct > a.ct) {
        r.endAt = b.w + (m.t1 - b.ct) * 1000;
        r.endErr = b.w - a.w;
        r.endExtrapolated = true;
        break;
      }
    }
  }
  return r;
}
