import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:coqui_platform/src/call/conv.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The old stub's lines and errors (assets/call_stub.json, made from llamada.js by
/// tool/llamada_stub.mjs). Test text, kept as data.
class CallStubScript {
  CallStubScript(this.json);

  /// The asset, as the app has it (`packages/coqui_platform/...`) or as this package's own tests have it.
  static Future<CallStubScript> load() async {
    String text;
    try {
      text = await rootBundle.loadString(
        'packages/coqui_platform/assets/call_stub.json',
      );
    } catch (_) {
      text = await rootBundle.loadString('assets/call_stub.json');
    }
    return CallStubScript(jsonDecode(text) as Map<String, dynamic>);
  }

  final Map<String, dynamic> json;

  String line(String k) => (json['lines'] as Map)[k] as String;
  Map<String, dynamic> get picture =>
      Map<String, dynamic>.from(json['picture'] as Map);
  Map<String, dynamic> get connect =>
      Map<String, dynamic>.from(json['connect'] as Map);
  ConvStartError error(String k) {
    final e = json[k] as Map;
    return ConvStartError(e['name'] as String, e['message'] as String);
  }
}

/// llamada.js, installStub, ported: a fake Conversation that walks through the modes, sends two of
/// Danny's lines (the second asks for a picture) and the learner's lines, then, a moment later, the
/// learner's "Adiós.", and answers "(fin)" with a goodbye. The same steps, the same pacing.
///
/// [options], as the old page's `?stub=`: `manual` (nothing moves; step with [go]), `mic` (the microphone
/// is refused), `fail` (the call does not start), `nofin` (no answer to "(fin)"), `hasta` (the learner's
/// goodbye is "Hasta mañana."), `dannybye` (Danny says goodbye on his own), `loop` (once a goodbye is said,
/// Danny says goodbye every 3 s for ever). [clock] is `?clock=N` (only [sentAt] uses it here: the page's call
/// clock is the page's).
///
/// What it keeps, as window.CallStub: [sent], [sentAt], [opts], [ended], [names], [log].
class CallStub implements ConvLibrary {
  CallStub(
    this.script, {
    Set<String> options = const {},
    this.clock = 1,
    double Function()? random,
  }) : options = {...options},
       _random = random ?? math.Random().nextDouble;

  final CallStubScript script;
  final Set<String> options;
  final int clock;
  final double Function() _random;

  final List<String> sent = [];
  final List<int> sentAt = [];
  ConvOptions? opts;
  bool ended = false;
  List<String> names = [];

  /// Every mode, in order.
  final List<String> log = [];
  void Function(String name)? _go;
  final List<Timer> _timers = [];
  final Stopwatch _sw = Stopwatch()..start();

  @override
  bool? get loaded => true;

  @override
  Future<bool> load() async => true;

  /// CallStub.go(name): one step, by hand (with `manual`). After the end only "connect" runs.
  void go(String name) => _go?.call(name);

  /// Cancels every timer still waiting.
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _later(int ms, void Function() f) =>
      _timers.add(Timer(Duration(milliseconds: ms), f));

  double get _now => _sw.elapsedMicroseconds / 1000;

  @override
  Future<Conv> startSession(ConvOptions o) {
    opts = o;
    final res = Completer<Conv>();
    if (options.contains('mic')) {
      _later(400, () => res.completeError(script.error('micError')));
      return res.future;
    }
    if (options.contains('fail')) {
      _later(600, () => res.completeError(script.error('failError')));
      return res.future;
    }
    double t0 = 0;
    var inp = 'quiet';
    var say = false;
    void mode(String m) {
      log.add(m);
      o.onModeChange({'mode': m});
    }

    void msg(String who, String t) => o.onMessage(
      who == 'user'
          ? {'role': 'user', 'source': 'user', 'message': t}
          : {'role': 'agent', 'source': 'ai', 'message': t},
    );
    var nb = 0;
    // the goodbye loop: a line every 3 s
    void loop() {
      if (ended) return;
      say = true;
      mode('speaking');
      msg('agent', script.line(nb++ % 2 == 1 ? 'loopOdd' : 'loopEven'));
      _later(1800, () {
        say = false;
        mode('listening');
        _later(1200, loop);
      });
    }

    late final _StubConv c;
    c = _StubConv(
      send: (t) {
        sent.add(t);
        sentAt.add(t0 != 0 ? ((_now - t0) / 1000 * clock + .5).floor() : 0);
        if (t == '(fin)' &&
            !options.contains('nofin') &&
            !options.contains('loop')) {
          _later(400, () {
            say = true;
            mode('speaking');
            msg('agent', script.line('finReply'));
            _later(2000, () {
              say = false;
              mode('listening');
            });
          });
        }
      },
      end: () {
        if (ended) return;
        ended = true;
        _later(30, () => o.onDisconnect({'reason': 'user'}));
      },
      input: () => inp == 'talk'
          ? .10 + .08 * math.sin(_now / 90).abs() + _random() * .04
          : .004,
      output: () => say ? .10 + .10 * math.sin(_now / 130).abs() : 0,
    );
    void you() {
      say = false;
      inp = 'quiet';
      mode('listening');
    }

    final steps = <String, void Function()>{
      'connect': () {
        t0 = _now == 0 ? 1e-9 : _now;
        o.onConnect(script.connect);
        if (!res.isCompleted) res.complete(c);
      },
      'danny1': () {
        say = true;
        mode('speaking');
        msg('agent', script.line('danny1'));
      },
      'you1': you,
      'talk1': () => inp = 'talk',
      'quiet1': () => inp = 'quiet',
      'heard1': () => msg('user', script.line('heard1')),
      'danny2': () {
        inp = 'quiet';
        say = true;
        mode('speaking');
        msg('agent', script.line('danny2'));
        _later(500, () {
          try {
            o.clientTools['show_picture']!(script.picture);
          } catch (_) {}
        });
      },
      'you2': you,
      'talk2': () => inp = 'talk',
      'quiet2': () => inp = 'quiet',
      'heard2': () => msg('user', script.line('heard2')),
      'you3': you,
      'talk3': () => inp = 'talk',
      'quiet3': () => inp = 'quiet',
      'heard3': () {
        msg(
          'user',
          script.line(options.contains('hasta') ? 'heard3Hasta' : 'heard3'),
        );
        if (options.contains('loop')) _later(300, loop);
      },
      'danny3': () {
        inp = 'quiet';
        say = true;
        mode('speaking');
        msg('agent', script.line('danny3'));
        _later(1800, () {
          say = false;
          mode('listening');
          if (options.contains('loop')) _later(1200, loop);
        });
      },
      'end': () {
        ended = true;
        o.onDisconnect({'reason': 'agent'});
      },
    };
    names = steps.keys.toList();
    _go = (n) {
      if (ended && n != 'connect') return;
      steps[n]!();
    };
    if (options.contains('manual')) return res.future;
    const seq = [
      ('connect', 1200),
      ('danny1', 2800),
      ('you1', 700),
      ('talk1', 1500),
      ('quiet1', 900),
      ('heard1', 1100),
      ('danny2', 3000),
      ('you2', 700),
      ('talk2', 1500),
      ('quiet2', 900),
      ('heard2', 0),
    ];
    var i = 0;
    void next() {
      if (ended) return;
      if (i < seq.length) {
        final (n, d) = seq[i++];
        steps[n]!();
        _later(d, next);
        return;
      }
      // then, a moment later, the learner says goodbye (or, with dannybye, Danny does)
      _later(1500, () {
        if (options.contains('dannybye')) {
          steps['danny3']!();
          return;
        }
        steps['you3']!();
        _later(500, () {
          steps['talk3']!();
          _later(1200, () {
            steps['quiet3']!();
            _later(900, () => steps['heard3']!());
          });
        });
      });
    }

    next();
    return res.future;
  }
}

class _StubConv implements Conv {
  _StubConv({
    required this.send,
    required this.end,
    required this.input,
    required this.output,
  });
  final void Function(String) send;
  final void Function() end;
  final double Function() input, output;

  @override
  void sendUserMessage(String text) => send(text);

  @override
  void endSession() => end();

  @override
  double getInputVolume() => input();

  @override
  double getOutputVolume() => output();

  /// The old stub has no setVolume.
  @override
  void setVolume(double v) {}
}
