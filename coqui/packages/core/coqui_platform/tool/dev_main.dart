// coqui_platform's dev screen (order 18). Web only.
//
//   flutter build web -t tool/dev_main.dart --no-web-resources-cdn     (in this package)
//   node tool/dev_check.mjs                                              (serves it with historia/audio/, runs it)
//
// One button, "Run" (or ?auto=1). It plays ten recorded lines back to back through the package's
// ClipPlayer, with juego.js's own pauses between them, and measures each gap on the output bus: a meter
// (an AudioWorklet on the master gain, as order 00's) sees every sample sent to the speaker and reports
// each quiet run. A gap is that quiet run less the quiet inside the two clips' marks (after the last loud
// sample of one, before the first loud sample of the next): the time from one clip's end mark to the
// next clip's start mark, as heard. Then: every SFX name once, the thunder, the rain; one recognition; the
// storage spaces; a tick; the AppInfo values. Everything shown is also in window.__coquiDev (JSON).
//
// The clips' files are `audio/<id>.mp3?v=<ready.json's v>` from the page's base (or ?base=<url>), with
// their marks from audio/marcas.json, as coqui_content makes ClipInfo.
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_platform/coqui_platform.dart';
import 'package:coqui_platform/src/audio/graph_clip_player.dart';
import 'package:coqui_platform/src/audio/sound_core.dart';
import 'package:coqui_platform/src/web/web_audio_graph.dart';
import 'package:coqui_platform/src/web/web_platform.dart' show webSoundCore;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Ten lines story 1 (La lluvia) opens with, in its order (order 00's test 1).
const lines = [
  'esta_casa',
  'mira_casa',
  'puedes_casa',
  'muy_bien',
  'esta_puerta',
  'cerrada',
  'donde_puerta',
  'mira_ventana',
  'tambien_cerrada',
  'toca_ventana',
];

/// The pause after each line but the last, in ms: juego.js's own values. say(id) waits 420 after a
/// line; say(id, 300), say(id, 250), say("ahora_tu", 200) and say(line, 0) are its other calls; 700
/// between the answer bubbles' voices (voces); then again from the start.
const pauses = [420, 300, 250, 200, 0, 700, 420, 300, 250];

/// The trim threshold (juego.js line 100): a sample at or above it is sound.
const loud = .012;

const meterJs =
    '''
class CoquiMeter extends AudioWorkletProcessor {
  constructor() {
    super();
    this.th = $loud;
    this.minQuiet = Math.round(sampleRate * 0.05);
    this.lastLoud = -1;
    this.loud = 0;
    this.port.onmessage = (e) => {
      if (e.data === "reset") { this.lastLoud = -1; this.loud = 0; }
      if (e.data === "count") this.port.postMessage({ count: this.loud });
    };
  }
  process(inputs) {
    const ch = inputs[0] && inputs[0][0];
    if (ch) {
      for (let i = 0; i < ch.length; i++) {
        const v = ch[i];
        if (v >= this.th || v <= -this.th) {
          const f = currentFrame + i;
          if (this.lastLoud >= 0 && f - this.lastLoud > this.minQuiet) this.port.postMessage({ q0: this.lastLoud, q1: f });
          this.lastLoud = f;
          this.loud++;
        }
      }
    }
    return true;
  }
}
registerProcessor("coqui-meter", CoquiMeter);
''';

void main() => runApp(const DevScreen());

class DevScreen extends StatefulWidget {
  const DevScreen({super.key});

  @override
  State<DevScreen> createState() => _DevScreenState();
}

class _DevScreenState extends State<DevScreen> {
  final List<String> out = ['Tap Run.'];
  final Map<String, Object?> report = {};
  bool running = false;
  late final Uri base;
  Map<String, ClipInfo> clips = {};
  late final ClipPlayer player;

  @override
  void initState() {
    super.initState();
    final page = Uri.parse(web.document.baseURI);
    final q = Uri.parse(web.window.location.href).queryParameters;
    base = q['base'] != null ? page.resolve(q['base']!) : page;
    player = createClipPlayer(clipInfo: (id) => clips[id], base: base);
    if (q['auto'] == '1') unawaited(run());
  }

  void say(String s) => setState(() => out.add(s));

  Future<void> run() async {
    if (running) return;
    running = true;
    unawaited(player.unlock()); // inside the tap
    setState(out.clear);
    try {
      await _run();
    } catch (e) {
      say('stopped: $e');
      report['error'] = '$e';
    }
    globalContext.setProperty('__coquiDev'.toJS, jsonEncode(report).toJS);
    globalContext.setProperty('__coquiDevDone'.toJS, true.toJS);
    running = false;
  }

  Future<void> _run() async {
    await _info();
    await _clips();
    await _lines();
    await _sounds();
    await _speech();
    await _callLibrary();
    await _stubCall();
  }

  /// Order 19: the voice library, loaded as the old page loads it, never a call. `?el=<url>` imports that
  /// module in place of the pinned client (dev_check serves a local copy of the same version).
  Future<void> _callLibrary() async {
    final q = Uri.parse(web.window.location.href).queryParameters;
    final url = q['el'] == null
        ? elevenLabsClientUrl
        : Uri.parse(web.document.baseURI).resolve(q['el']!).toString();
    final call = createCallSession(appInfo: createAppInfo(), libraryUrl: url);
    final sw = Stopwatch()..start();
    var avail = call.available; // reading it starts the load (precarga)
    while (sw.elapsedMilliseconds < 20000 &&
        !globalContext.has('ELConv') &&
        !globalContext.has('ELConvError')) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    avail = call.available;
    final type = globalContext.has('ELConv')
        ? (globalContext.getProperty<JSObject>('ELConv'.toJS))
              .getProperty<JSAny?>('startSession'.toJS)
              .typeofEquals('function')
        : false;
    final err = globalContext.has('ELConvError')
        ? globalContext.getProperty<JSString>('ELConvError'.toJS).toDart
        : null;
    report['callLibrary'] = {
      'url': url,
      'pinned': url == elevenLabsClientUrl,
      'startSessionIsFunction': type,
      'error': err,
      'available': avail,
      'ms': sw.elapsedMilliseconds,
    };
    say(
      'call library: $url ${type ? 'loaded, ELConv.startSession is a function' : 'not loaded${err == null ? '' : ': $err'}'}; '
      'available $avail (${sw.elapsedMilliseconds} ms); no call placed',
    );
  }

  /// Order 19: the old page's ?callstub=1 through the package's CallSession, as the call screen gets it.
  Future<void> _stubCall() async {
    final stub = CallStub(await CallStubScript.load());
    final call = createCallSession(appInfo: createAppInfo(), stub: stub);
    final ev = <String>[];
    var speaking = 0;
    final done = Completer<void>();
    call.events.listen((e) {
      final t = switch (e) {
        Connected() => 'Connected',
        AgentLine(:final text) => 'AgentLine $text',
        Heard(:final text) => 'Heard $text',
        Mode(:final mode) => 'Mode $mode',
        Tool(:final name, :final args) => 'Tool $name ${jsonEncode(args)}',
        CallError(:final message) => 'CallError $message',
        Ended(:final reason) => 'Ended $reason',
      };
      ev.add(t);
      say('stub call: $t');
      if (e is Heard && e.text == stub.script.line('heard3')) {
        call.send('(fin)');
      }
      if (e is Mode && e.mode == 'speaking') speaking++;
      if (e is Mode && e.mode == 'listening' && speaking == 3) {
        Timer(const Duration(milliseconds: 400), call.end);
      }
      if (e is Ended && !done.isCompleted) done.complete();
    });
    // order 19b: the sound context, before, during and after the call
    String ctx() => webSoundCore.context?.state ?? 'none';
    final states = <String>[ctx()];
    final sw = Stopwatch()..start();
    await call.start(
      CallBrief(
        placeId: 'casa',
        minutes: 5,
        job: 'job',
        opening: 'opening',
        photo: 'casa',
      ),
      const {'place': 'place', 'words_open': '', 'words_heard': ''},
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    states.add(ctx());
    await done.future.timeout(const Duration(seconds: 40), onTimeout: () {});
    await Future<void>.delayed(const Duration(milliseconds: 300));
    states.add(ctx());
    say(
      'stub call: the sound context before, during, after: ${states.join(', ')}',
    );
    report['stubCall'] = {
      'events': ev,
      'sent': stub.sent,
      'ended': stub.ended,
      'ms': sw.elapsedMilliseconds,
      'contextStates': states,
    };
    stub.dispose();
  }

  Future<void> _info() async {
    final i = createAppInfo();
    report['appInfo'] = {
      'build': i.build,
      'isWeb': i.isWeb,
      'isIos': i.isIos,
      'isAndroid': i.isAndroid,
      'installed': i.installed,
      'callsAllowed': i.callsAllowed,
    };
    say('AppInfo: ${jsonEncode(report['appInfo'])}');
    final s = await openStorage();
    await s.space('dev').write('marca', 'order 18');
    final old = {
      'progress: coqui.palabras.v1': s.progress.read('coqui.palabras.v1'),
      'juego: ult (coqui.juego.ult)': s.space('juego').read('ult'),
      'juego: mem (coqui.juego.mem)': s.space('juego').read('mem'),
      'leer: tam (coqui.leer.tam)': s.space('leer').read('tam'),
      'dev: marca (coqui.dev.marca)': s.space('dev').read('marca'),
      'localStorage coqui.dev.marca': web.window.localStorage.getItem(
        'coqui.dev.marca',
      ),
    };
    report['storage'] = old;
    for (final e in old.entries) {
      final v = e.value;
      say(
        'storage ${e.key}: ${v == null ? 'none' : '${v.length} chars${v.length < 40 ? ' "$v"' : ''}'}',
      );
    }
    var tick = 'ok';
    try {
      createHaptics().tick();
    } catch (e) {
      tick = '$e';
    }
    report['haptics'] = tick;
    say('haptics: tick() $tick');
  }

  Future<void> _clips() async {
    final ready =
        jsonDecode(await _text(base.resolve('audio/ready.json'))) as Map;
    final marks =
        jsonDecode(await _text(base.resolve('audio/marcas.json'))) as Map;
    final v = ready['v'];
    clips = {
      for (final id in lines)
        id: ClipInfo(
          id: id,
          who: '',
          text: '',
          startMs: (marks[id] as List)[0] as int,
          endMs: (marks[id] as List)[1] as int,
          url: 'audio/$id.mp3?v=$v',
        ),
    };
    final sw = Stopwatch()..start();
    final missing = await player.preload(lines);
    say(
      'preload: ${lines.length - missing.length} of ${lines.length} fetched and decoded in ${sw.elapsedMilliseconds} ms; not ready: ${missing.isEmpty ? '[]' : missing}',
    );
    if (missing.isNotEmpty) throw StateError('not loaded: $missing');
  }

  Future<void> _lines() async {
    final g = webSoundCore.context! as WebAudioGraph;
    final meter = await _meter(g);
    final quiet = meter.$1;
    say(
      'context ${g.state}, ${g.sampleRate.round()} Hz; meter ${meter.$2 ?? 'on'}',
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final starts = <double>[];
    final ended = <bool>[];
    for (var k = 0; k < lines.length; k++) {
      starts.add(g.currentTime);
      ended.add(await player.play(lines[k]));
      if (k < pauses.length) {
        // say(id, gap): playClip(id).then(ok => ok ? sleep(gap) : 0)
        await Future<void>.delayed(Duration(milliseconds: pauses[k]));
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final sr = g.sampleRate;
    final rows = <Map<String, Object?>>[];
    for (var k = 0; k + 1 < lines.length; k++) {
      final a = webSoundCore.clips[lines[k]]!,
          b = webSoundCore.clips[lines[k + 1]]!;
      final tail = a.t1 - _lastLoud(a.buf.channel(0), a.t0, a.t1, sr);
      final lead = _firstLoud(b.buf.channel(0), b.t0, b.t1, sr) - b.t0;
      final x = (starts[k + 1] * sr).round();
      (int, int)? run;
      for (final r in quiet) {
        if (r.$1 < x && r.$2 > x) run = r;
      }
      final gap = run == null
          ? null
          : ((run.$2 - run.$1) / sr - tail - lead) * 1000;
      final clock = (starts[k + 1] - starts[k] - (a.t1 - a.t0)) * 1000;
      rows.add({
        'after': lines[k],
        'asked': pauses[k],
        'gap': gap == null ? null : double.parse(gap.toStringAsFixed(1)),
        'off': gap == null
            ? null
            : double.parse((gap - pauses[k]).toStringAsFixed(1)),
        'clock': double.parse(clock.toStringAsFixed(1)),
      });
      say(
        'gap after ${lines[k]}: asked ${pauses[k]} ms, measured ${gap?.toStringAsFixed(1) ?? 'none'} ms on the bus '
        '(context clock ${clock.toStringAsFixed(1)})',
      );
    }
    final worst = rows
        .map((r) => (r['off'] as double?)?.abs() ?? double.infinity)
        .reduce((a, b) => a > b ? a : b);
    report['lines'] = {
      'ended': ended,
      'gaps': rows,
      'worstOffMs': worst.isFinite ? worst : null,
    };
    say(
      'lines: ${ended.where((e) => e).length} of ${lines.length} played to their end mark; '
      'worst gap ${worst.isFinite ? '${worst.toStringAsFixed(1)} ms' : 'not measured'} off what was asked '
      '(limit 60)',
    );
  }

  Future<void> _sounds() async {
    // The made sounds through the same code, on the same context, with the meter where the speaker is:
    // tones go straight to the speaker (juego.js connects them to A.destination), past the master gain.
    final g = webSoundCore.context! as WebAudioGraph;
    final ctx = g.ctx as web.AudioContext;
    final speaker = ctx.createGain()..connect(ctx.destination);
    final n = _node;
    if (n != null) speaker.connect(n);
    final p = GraphClipPlayer(
      core: SoundCore(() => WebAudioGraph(ctx, output: speaker)),
      clipInfo: (_) => null,
      base: base,
      fetch: webFetchBytes,
    );
    void t(
      double f0,
      double at,
      double dur,
      String w,
      double v, [
      double? f1,
    ]) => p.tone(f0, at: at, dur: dur, wave: w, vol: v, toHz: f1);
    // juego.js's SFX table, as the scene host calls the player
    final sfx = <String, void Function()>{
      'right': () {
        t(784, 0, .1, 'triangle', .14);
        t(1047, .09, .1, 'triangle', .14);
        t(1319, .18, .26, 'triangle', .14);
      },
      'toc': () {
        t(950, 0, .07, 'sine', .22, 480);
        t(950, .17, .07, 'sine', .22, 480);
      },
      'blip': () => t(520, 0, .06, 'sine', .07, 640),
      'creak': () {
        t(210, 0, .5, 'sawtooth', .025, 120);
        t(330, .05, .4, 'sawtooth', .012, 170);
      },
      'hop': () => t(320, 0, .07, 'square', .025, 520),
      'coqui': () {
        t(1500, 0, .11, 'sine', .09);
        t(2300, .17, .2, 'sine', .09, 2750);
      },
      'win': () {
        const fs = [523.0, 659.0, 784.0, 1047.0];
        for (var i = 0; i < fs.length; i++) {
          t(fs[i], i * .11, .2, 'square', .04);
        }
      },
      'luz': () {
        t(1320, 0, .09, 'sine', .1);
        t(1760, .08, .22, 'sine', .1);
      },
      'drop': () => t(1400, 0, .05, 'sine', .06, 700),
      'trueno': () => p.noiseBurst(),
      'lluvia': () => p.loop('rain', true),
      'calla': () => p.loop('rain', false),
      'suave': () => t(330, 0, .16, 'sine', .05, 290),
      'pio': () {
        t(2600, 0, .06, 'sine', .07, 3400);
        t(2900, .09, .08, 'sine', .07, 3800);
      },
      'slam': () {
        t(140, 0, .12, 'square', .05, 70);
        t(90, .02, .18, 'sine', .12, 50);
      },
      'bonk': () {
        t(600, 0, .06, 'square', .05, 200);
        t(300, .06, .2, 'triangle', .08, 120);
      },
      'munch': () {
        for (final at in [0.0, .16, .32]) {
          t(260, at, .06, 'square', .03, 180);
        }
      },
      'swoop': () => t(1800, 0, .35, 'sine', .04, 600),
    };
    final got = <String, String>{};
    for (final e in sfx.entries) {
      final before = await _count();
      String r;
      try {
        e.value();
        await Future<void>.delayed(
          Duration(milliseconds: e.key == 'trueno' ? 1700 : 600),
        );
        final after = await _count();
        r = before < 0 || after < 0
            ? 'fired, no error'
            : 'fired, no error, ${after - before} loud frames at the speaker';
      } catch (x) {
        r = 'error: $x';
      }
      got[e.key] = r;
      say('SFX.${e.key}: $r');
    }
    report['sfx'] = got;
  }

  Future<void> _speech() async {
    final l = createSpeechListener();
    final avail = await l.available();
    final sw = Stopwatch()..start();
    final turn = l.listen(locale: 'es-US', limit: const Duration(seconds: 6));
    var speechEnd = -1;
    unawaited(turn.speechEnd.then((_) => speechEnd = sw.elapsedMilliseconds));
    final r = await turn.result.timeout(
      const Duration(seconds: 12),
      onTimeout: () => SpeechResult(error: 'HUNG: no result in 12 s'),
    );
    final ms = sw.elapsedMilliseconds;
    report['speech'] = {
      'available': avail,
      'error': r.error,
      'alternatives': r.alternatives,
      'msToSound': r.msToSound,
      'endedAfterMs': ms,
      'speechEndAfterMs': speechEnd,
      'limitMs': 6000 + 2500,
    };
    say(
      'speech: available() $avail; listen(es-US, 6 s) ended after $ms ms with '
      '${r.error != null ? 'error "${r.error}"' : 'alternatives ${r.alternatives}'} '
      '(its limit: 6000 + 2500 ms)',
    );
  }

  web.AudioWorkletNode? _node;
  Completer<int>? _countWait;

  /// The meter's count of loud frames so far; -1 without a meter.
  Future<int> _count() async {
    final n = _node;
    if (n == null) return -1;
    final w = _countWait = Completer<int>();
    n.port.postMessage('count'.toJS);
    return w.future.timeout(const Duration(seconds: 1), onTimeout: () => -1);
  }

  /// The meter on the master gain: the quiet runs it reports, and why it is off (null when on).
  Future<(List<(int, int)>, String?)> _meter(WebAudioGraph g) async {
    final runs = <(int, int)>[];
    try {
      final master = webSoundCore.out() as WebGain;
      final blob = web.Blob(
        [meterJs.toJS].toJS,
        web.BlobPropertyBag(type: 'application/javascript'),
      );
      final url = web.URL.createObjectURL(blob);
      final ctx = g.ctx as web.AudioContext;
      await ctx.audioWorklet.addModule(url).toDart;
      final n = web.AudioWorkletNode(
        ctx,
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
          runs.add(((m['q0'] as num).toInt(), (m['q1'] as num).toInt()));
        } else if (m['count'] != null) {
          final w = _countWait;
          _countWait = null;
          if (w != null && !w.isCompleted) {
            w.complete((m['count'] as num).toInt());
          }
        }
      }).toJS;
      master.node.connect(n);
      n.connect(
        ctx.destination,
      ); // its output is silence; the link keeps it running
      _node = n;
      return (runs, null);
    } catch (e) {
      return (runs, 'off: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      color: const Color(0xFFF4F1EA),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: run,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: const Color(0xFF2E6B4F),
              child: Text(
                running ? 'Running...' : 'Run',
                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                for (final l in out)
                  Text(
                    l,
                    style: const TextStyle(
                      color: Color(0xFF1B1B1F),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<String> _text(Uri u) async {
  final r = await web.window.fetch(u.toString().toJS).toDart;
  if (!r.ok) throw StateError('HTTP ${r.status} for $u');
  return (await r.text().toDart).toDart;
}

/// The time of the first sample at or above the threshold inside the marks, in s.
double _firstLoud(List<double> d, double t0, double t1, double sr) {
  final a = (t0 * sr).floor(), b = (t1 * sr).ceil().clamp(0, d.length - 1);
  for (var i = a; i <= b; i++) {
    if (d[i].abs() >= loud) return i / sr;
  }
  return t0;
}

/// The time of the last sample at or above the threshold inside the marks, in s.
double _lastLoud(List<double> d, double t0, double t1, double sr) {
  final a = (t0 * sr).floor(), b = (t1 * sr).ceil().clamp(0, d.length - 1);
  for (var i = b; i >= a; i--) {
    if (d[i].abs() >= loud) return i / sr;
  }
  return t1;
}
