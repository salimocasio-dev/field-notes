import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:coqui_platform/src/audio/graph.dart';
import 'package:web/web.dart' as web;

/// The browser's Web Audio as an [AudioGraph]: every call goes straight through to the context and its
/// nodes, as juego.js makes it.
class WebAudioGraph implements AudioGraph {
  WebAudioGraph(this.ctx) : destination = WebNode(ctx.destination);

  /// juego.js: `new (window.AudioContext || window.webkitAudioContext)()`.
  factory WebAudioGraph.create() {
    final g = globalContext;
    if (g.has('AudioContext')) return WebAudioGraph(web.AudioContext());
    final old = g.getProperty<JSFunction>('webkitAudioContext'.toJS);
    return WebAudioGraph(old.callAsConstructor<web.AudioContext>());
  }

  /// An AudioContext, or an OfflineAudioContext (the tests render with one).
  final web.BaseAudioContext ctx;

  @override
  final WebNode destination;

  @override
  double get currentTime => ctx.currentTime.toDouble();

  @override
  double get sampleRate => ctx.sampleRate.toDouble();

  @override
  String get state => ctx.state;

  @override
  OscillatorH createOscillator() => _Osc(ctx.createOscillator());

  @override
  GainH createGain() => WebGain(ctx.createGain());

  @override
  BiquadH createBiquadFilter() => _Biquad(ctx.createBiquadFilter());

  @override
  BufferSourceH createBufferSource() => _Source(ctx.createBufferSource());

  @override
  AudioBufferH createBuffer(int channels, int length, double rate) =>
      WebBuffer(ctx.createBuffer(channels, length, rate));

  @override
  Future<AudioBufferH> decodeAudioData(Uint8List bytes) async {
    // decodeAudioData takes the ArrayBuffer away: give it a copy.
    final copy = Uint8List.fromList(bytes);
    final b = await ctx.decodeAudioData(copy.buffer.toJS).toDart;
    return WebBuffer(b);
  }

  @override
  Future<void> resume() async {
    final c = ctx;
    if (c.isA<web.OfflineAudioContext>()) return;
    await (c as web.AudioContext).resume().toDart;
  }
}

class WebNode implements AudioNodeH {
  WebNode(this.node);
  final web.AudioNode node;

  @override
  void connect(AudioNodeH to) => node.connect((to as WebNode).node);
}

class _Param implements ParamH {
  _Param(this.p);
  final web.AudioParam p;

  @override
  set value(double v) => p.value = v;

  @override
  void setValueAtTime(double v, double t) => p.setValueAtTime(v, t);

  @override
  void exponentialRampToValueAtTime(double v, double t) =>
      p.exponentialRampToValueAtTime(v, t);
}

class _Osc extends WebNode implements OscillatorH {
  _Osc(web.OscillatorNode super.node) : frequency = _Param(node.frequency);

  web.OscillatorNode get _o => node as web.OscillatorNode;

  @override
  final ParamH frequency;

  @override
  set type(String t) => _o.type = t;

  @override
  void start(double when) => _o.start(when);

  @override
  void stop(double when) => _o.stop(when);
}

class WebGain extends WebNode implements GainH {
  WebGain(web.GainNode super.node) : gain = _Param(node.gain);

  @override
  final ParamH gain;
}

class _Biquad extends WebNode implements BiquadH {
  _Biquad(web.BiquadFilterNode super.node) : frequency = _Param(node.frequency);

  @override
  final ParamH frequency;

  @override
  set type(String t) => (node as web.BiquadFilterNode).type = t;
}

class _Source extends WebNode implements BufferSourceH {
  _Source(web.AudioBufferSourceNode super.node);

  web.AudioBufferSourceNode get _s => node as web.AudioBufferSourceNode;

  @override
  set buffer(AudioBufferH b) => _s.buffer = (b as WebBuffer).b;

  @override
  set loop(bool v) => _s.loop = v;

  @override
  set onended(void Function()? f) =>
      _s.onended = f == null ? null : ((web.Event _) => f()).toJS;

  @override
  void start([double? when, double? offset, double? duration]) {
    if (when == null) {
      _s.start();
    } else if (offset == null) {
      _s.start(when);
    } else if (duration == null) {
      _s.start(when, offset);
    } else {
      _s.start(when, offset, duration);
    }
  }

  @override
  void stop([double? when]) => when == null ? _s.stop() : _s.stop(when);
}

class WebBuffer implements AudioBufferH {
  WebBuffer(this.b);
  final web.AudioBuffer b;

  @override
  double get duration => b.duration.toDouble();

  @override
  double get sampleRate => b.sampleRate.toDouble();

  @override
  int get length => b.length;

  @override
  Float32List channel(int c) =>
      Float32List.fromList(b.getChannelData(c).toDart);

  @override
  void fill(int c, Float32List data) => b.copyToChannel(data.toJS, c);
}

/// `fetch(url)` as bytes; an HTTP error is an error.
Future<Uint8List> webFetchBytes(Uri url) async {
  final r = await web.window.fetch(url.toString().toJS).toDart;
  if (!r.ok) throw StateError('HTTP ${r.status} for $url');
  final b = await r.arrayBuffer().toDart;
  return b.toDart.asUint8List();
}
