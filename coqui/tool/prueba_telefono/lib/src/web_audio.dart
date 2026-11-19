// The browser's Web Audio through JS interop: the context, decoding, juego.js's trim rule, playing a clip
// from its start mark to its end mark, and the output meter (web/coqui_meter_worklet.js).
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'browser.dart';

/// juego.js line 100: threshold 0.012 on channel 0; start = first loud sample - 30 ms, end = last loud + 100 ms.
class Marks {
  Marks(
    this.t0,
    this.t1,
    this.firstLoud,
    this.lastLoud,
    this.duration,
    this.rate,
  );
  final double t0, t1, firstLoud, lastLoud, duration; // seconds
  final double rate;
  double get lead =>
      firstLoud - t0; // quiet before the first loud sample, inside the marks
  double get tail =>
      t1 - lastLoud; // quiet after the last loud sample, inside the marks
  double get len => t1 - t0;
}

Marks trim(web.AudioBuffer b) {
  final d = b.getChannelData(0).toDart;
  final sr = b.sampleRate.toDouble();
  const th = .012;
  var i = 0, j = d.length - 1;
  while (i < j && d[i].abs() < th) {
    i++;
  }
  while (j > i && d[j].abs() < th) {
    j--;
  }
  final t0 = (i / sr - .03) < 0 ? 0.0 : i / sr - .03;
  final dur = b.duration.toDouble();
  final t1 = (j / sr + .1) > dur ? dur : j / sr + .1;
  return Marks(t0, t1, i / sr, j / sr, dur, sr);
}

/// What a played clip did.
class WaPlay {
  WaPlay({
    required this.tCall,
    required this.ended,
    required this.endedBy,
    required this.ctxAdvance,
    required this.wallMs,
    required this.loudFrames,
    required this.state,
  });
  final double tCall; // context time when start() was called
  final bool ended; // the source's own "ended" event came before the limit
  final String endedBy; // "ended event" or "time limit" or an error
  final double
  ctxAdvance; // context seconds that passed from start() to the end
  final double wallMs;
  final int loudFrames; // loud frames the meter saw meanwhile (-1 = no meter)
  final String state; // context state at the end
}

class WebAudio {
  web.AudioContext? ctx;
  web.GainNode? master;
  web.AudioWorkletNode? meter;
  String error = '';
  String meterNote = 'meter: not loaded';
  final List<(int, int)> quietRuns = [];
  Completer<int>? _countWait;

  bool get ready => ctx != null;
  String get state => ctx?.state ?? 'none';
  double get rate => ctx?.sampleRate.toDouble() ?? 0;

  /// Inside a tap: create the context the first time, resume it every time. Synchronous on purpose.
  void unlock() {
    if (ctx == null) {
      try {
        final c = web.AudioContext();
        ctx = c;
        web.window.setProperty(
          '__coquiAC'.toJS,
          c,
        ); // for the safety net in coqui_meter.js
        final g = c.createGain();
        g.connect(c.destination);
        master = g;
        unawaited(_loadMeter());
      } catch (e) {
        error = 'AudioContext could not be made: ${errText(e)}';
        return;
      }
    }
    resume();
  }

  void resume() {
    final c = ctx;
    if (c == null) return;
    try {
      c.resume().toDart.catchError((Object e) {
        error = 'resume(): ${errText(e)}';
        return null;
      });
    } catch (e) {
      error = 'resume(): ${errText(e)}';
    }
  }

  String describe() {
    final c = ctx;
    if (c == null) {
      return 'Web Audio: no context yet${error.isEmpty ? '' : ' ($error)'}';
    }
    String lat(String k) {
      final o = c as JSObject;
      if (!o.has(k)) return 'n/a';
      final v = o.getProperty<JSAny?>(k.toJS);
      if (v == null || !v.isA<JSNumber>()) return 'n/a';
      return '${((v as JSNumber).toDartDouble * 1000).toStringAsFixed(1)} ms';
    }

    return 'Web Audio: ${c.sampleRate.round()} Hz, state ${c.state}, base latency ${lat('baseLatency')}, '
        'output latency ${lat('outputLatency')}; $meterNote';
  }

  Future<void> _loadMeter() async {
    final c = ctx;
    if (c == null) return;
    try {
      final o = c as JSObject;
      if (!o.has('audioWorklet')) {
        meterNote = 'meter: no AudioWorklet in this browser';
        return;
      }
      final ok = await within(
        c.audioWorklet
            .addModule('coqui_meter_worklet.js')
            .toDart
            .then((_) => true),
        const Duration(seconds: 8),
      );
      if (ok == null) {
        meterNote = 'meter: the worklet did not load within 8 s';
        return;
      }
      final n = web.AudioWorkletNode(
        c,
        'coqui-meter',
        web.AudioWorkletNodeOptions(
          numberOfInputs: 1,
          numberOfOutputs: 1,
          outputChannelCount: [1.toJS].toJS,
        ),
      );
      n.port.onmessage = ((web.MessageEvent e) {
        final m = e.data.dartify();
        if (m is! Map) return;
        if (m['q0'] != null) {
          quietRuns.add(((m['q0'] as num).toInt(), (m['q1'] as num).toInt()));
        } else if (m['count'] != null) {
          final w = _countWait;
          _countWait = null;
          if (w != null && !w.isCompleted) {
            w.complete((m['count'] as num).toInt());
          }
        }
      }).toJS;
      master!.connect(n);
      n.connect(
        c.destination,
      ); // its output is silence; the link keeps it running
      meter = n;
      meterNote = 'meter: on';
    } catch (e) {
      meterNote = 'meter: failed (${errText(e)})';
    }
  }

  /// Wait (up to [limit]) for the meter to be on.
  Future<bool> meterReady({Duration limit = const Duration(seconds: 8)}) async {
    final end = nowMs() + limit.inMilliseconds;
    while (meter == null && meterNote == 'meter: not loaded' && nowMs() < end) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return meter != null;
  }

  void meterReset() {
    quietRuns.clear();
    meter?.port.postMessage('reset'.toJS);
  }

  /// The meter's count of loud frames so far, or -1 when there is no meter or it does not answer in 1 s.
  Future<int> loudCount() async {
    final m = meter;
    if (m == null) return -1;
    final w = _countWait = Completer<int>();
    m.port.postMessage('count'.toJS);
    return await within(w.future, const Duration(seconds: 1)) ?? -1;
  }

  Future<web.AudioBuffer> decode(Uint8List bytes) {
    final c = ctx;
    if (c == null) throw StateError('no audio context');
    final copy = Uint8List.fromList(
      bytes,
    ); // decodeAudioData takes the buffer away
    return c.decodeAudioData(copy.buffer.toJS).toDart;
  }

  /// Play [b] from [m.t0] to [m.t1] through the master bus. [limit]: stop and give up after this long.
  Future<WaPlay> play(web.AudioBuffer b, Marks m, {Duration? limit}) async {
    final c = ctx!;
    final before = meter == null ? -1 : await loudCount();
    final done = Completer<String>();
    final s = c.createBufferSource();
    s.buffer = b;
    s.connect(master!);
    s.onended = ((web.Event _) {
      if (!done.isCompleted) done.complete('ended event');
    }).toJS;
    final w0 = nowMs();
    final t0 = c.currentTime.toDouble();
    try {
      s.start(0, m.t0, m.len);
    } catch (e) {
      if (!done.isCompleted) done.complete('start() threw ${errText(e)}');
    }
    Timer? lim;
    if (limit != null) {
      lim = Timer(limit, () {
        try {
          s.stop();
        } catch (_) {}
        if (!done.isCompleted) done.complete('time limit');
      });
    }
    final why = await done.future;
    lim?.cancel();
    final adv = c.currentTime.toDouble() - t0;
    final wall = nowMs() - w0;
    final after = before < 0 ? -1 : await loudCount();
    return WaPlay(
      tCall: t0,
      ended: why == 'ended event',
      endedBy: why,
      ctxAdvance: adv,
      wallMs: wall,
      loudFrames: before < 0 || after < 0 ? -1 : after - before,
      state: c.state,
    );
  }

  /// For test 1: start [b] now (marks [m]); [onEnded] runs from the source's own "ended" event.
  /// Returns the context time at the start() call.
  double startNow(web.AudioBuffer b, Marks m, void Function() onEnded) {
    final c = ctx!;
    final s = c.createBufferSource();
    s.buffer = b;
    s.connect(master!);
    s.onended = ((web.Event _) => onEnded()).toJS;
    final t = c.currentTime.toDouble();
    s.start(0, m.t0, m.len);
    return t;
  }
}

/// Decode with an OfflineAudioContext (no user gesture needed), for the marks before the first tap.
Future<web.AudioBuffer> decodeOffline(Uint8List bytes, {int rate = 48000}) {
  final oc = web.OfflineAudioContext(1.toJS, 1, rate);
  final copy = Uint8List.fromList(bytes);
  return oc.decodeAudioData(copy.buffer.toJS).toDart;
}

/// fetch() a file as bytes.
Future<Uint8List> fetchBytes(String url) async {
  final r = await web.window.fetch(url.toJS).toDart;
  if (!r.ok) throw StateError('HTTP ${r.status} for $url');
  final b = await r.arrayBuffer().toDart;
  return b.toDart.asUint8List();
}
