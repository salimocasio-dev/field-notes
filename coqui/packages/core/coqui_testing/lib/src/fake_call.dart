import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';

/// A scripted call in the shape of today's `?callstub=1` (llamada.js, installStub).
///
/// [start] walks through the stub's steps with its timings: connect, Danny's first line, the learner's turn and
/// what was heard, Danny's second line (with the picture tool half a second later), the learner's second answer,
/// then, 1.5 s later, the learner's goodbye. When "(fin)" is sent, Danny says his goodbye 400 ms later.
/// [end] ends the call (Ended "user" 30 ms later). Options, as `?stub=`:
/// - `manual`: nothing moves by itself; step with [go] (names in [names]).
/// - `mic`: the microphone is refused ([start] throws, 400 ms); `fail`: the call does not start (600 ms).
///   Each throws a [CallStartError] (kinds microphone and failed). Two more for the other kinds (order 19b):
///   `library`: the voice library did not load (at once); `unavailable`, or [available] false: no calls here (at once).
/// - `nofin`: Danny does not answer "(fin)". `hasta`: the learner's goodbye is "Hasta mañana." instead of "Adiós.".
/// - `dannybye`: the learner says nothing more; Danny says goodbye on his own.
/// - `loop`: once a goodbye has been said Danny says "Hasta mañana." / "Adiós." every 3 s, whatever is sent.
///
/// What it does not do: no network, no microphone, no agent. `?clock=N` (the page's call clock) is not the
/// stub's and is not here. [inputVolume] and [outputVolume] are steady levels (0.14 while the learner talks,
/// 0.15 while Danny speaks), not the stub's wobble. Call [dispose] at the end of a test to cancel its timers.
class FakeCallSession implements CallSession {
  FakeCallSession({Set<String> stub = const {}, this.available = true})
    : options = {...stub};

  /// The `?stub=` options.
  final Set<String> options;

  @override
  bool available;

  /// What [start] was given (CallStub.opts).
  CallBrief? brief;
  Map<String, String>? variables;

  /// Every text sent, in order (CallStub.sent).
  final List<String> sent = [];

  /// Every mode, in order (CallStub.log).
  final List<String> log = [];

  /// Every volume set.
  final List<double> volumes = [];

  /// Whether the call has ended (CallStub.ended).
  bool ended = false;

  final StreamController<CallEvent> _events =
      StreamController<CallEvent>.broadcast();
  final List<Timer> _timers = [];
  Completer<void>? _started;
  String _inp = 'quiet';
  bool _say = false;
  int _nb = 0;

  @override
  Stream<CallEvent> get events => _events.stream;

  void _later(int ms, void Function() f) =>
      _timers.add(Timer(Duration(milliseconds: ms), f));
  void _mode(String m) {
    log.add(m);
    _events.add(Mode(m));
  }

  void _agent(String t) => _events.add(AgentLine(t));
  void _user(String t) => _events.add(Heard(t));

  // the goodbye loop: a line every 3 s
  void _loop() {
    if (ended) return;
    _say = true;
    _mode('speaking');
    _agent(_nb++ % 2 == 1 ? 'Adiós.' : 'Hasta mañana.');
    _later(1800, () {
      _say = false;
      _mode('listening');
      _later(1200, _loop);
    });
  }

  late final Map<String, void Function()> _steps = {
    'connect': () {
      _events.add(const Connected());
      final s = _started;
      if (s != null && !s.isCompleted) s.complete();
    },
    'danny1': () {
      _say = true;
      _mode('speaking');
      _agent('¡Hola! Soy Danny. ¿Cómo estás?');
    },
    'you1': _you,
    'talk1': () => _inp = 'talk',
    'quiet1': () => _inp = 'quiet',
    'heard1': () => _user('Hola. Bien, gracias.'),
    'danny2': () {
      _inp = 'quiet';
      _say = true;
      _mode('speaking');
      _agent('Eso. Mira. ¿Quieres jugo?');
      _later(
        500,
        () => _events.add(const Tool('show_picture', {'picture': 'jugo'})),
      );
    },
    'you2': _you,
    'talk2': () => _inp = 'talk',
    'quiet2': () => _inp = 'quiet',
    'heard2': () => _user('Sí, quiero jugo.'),
    'you3': _you,
    'talk3': () => _inp = 'talk',
    'quiet3': () => _inp = 'quiet',
    'heard3': () {
      _user(options.contains('hasta') ? 'Hasta mañana.' : 'Adiós.');
      if (options.contains('loop')) _later(300, _loop);
    },
    'danny3': () {
      _inp = 'quiet';
      _say = true;
      _mode('speaking');
      _agent('Sí. Hasta mañana.');
      _later(1800, () {
        _say = false;
        _mode('listening');
        if (options.contains('loop')) _later(1200, _loop);
      });
    },
    'end': () {
      ended = true;
      _events.add(const Ended('agent'));
    },
  };

  void _you() {
    _say = false;
    _inp = 'quiet';
    _mode('listening');
  }

  /// The step names, in the stub's order (CallStub.names).
  List<String> get names => _steps.keys.toList();

  /// Runs one step (CallStub.go). After the end only "connect" runs.
  void go(String name) {
    if (ended && name != 'connect') return;
    _steps[name]!();
  }

  static const _seq = [
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

  @override
  Future<void> start(CallBrief brief, Map<String, String> variables) {
    this.brief = brief;
    this.variables = variables;
    final done = _started = Completer<void>();
    if (!available || options.contains('unavailable')) {
      return Future.error(
        const CallStartError(
          CallStartFailure.unavailable,
          'Calls are off on this build.',
        ),
      );
    }
    if (options.contains('library')) {
      return Future.error(
        const CallStartError(
          CallStartFailure.library,
          'The voice library did not load.',
        ),
      );
    }
    if (options.contains('mic')) {
      _later(
        400,
        () => done.completeError(
          const CallStartError(
            CallStartFailure.microphone,
            'Permission denied',
            name: 'NotAllowedError',
          ),
        ),
      );
      return done.future;
    }
    if (options.contains('fail')) {
      _later(
        600,
        () => done.completeError(
          const CallStartError(
            CallStartFailure.failed,
            'The call did not start.',
          ),
        ),
      );
      return done.future;
    }
    // the test steps it: go('connect'), ...
    if (options.contains('manual')) return done.future;
    var i = 0;
    void next() {
      if (ended) return;
      if (i < _seq.length) {
        final (n, d) = _seq[i++];
        _steps[n]!();
        _later(d, next);
        return;
      }
      // then, a moment later, the learner says goodbye (or, with dannybye, Danny does)
      _later(1500, () {
        if (options.contains('dannybye')) {
          _steps['danny3']!();
          return;
        }
        _steps['you3']!();
        _later(500, () {
          _steps['talk3']!();
          _later(1200, () {
            _steps['quiet3']!();
            _later(900, _steps['heard3']!);
          });
        });
      });
    }

    next();
    return done.future;
  }

  @override
  void send(String text) {
    sent.add(text);
    if (text == '(fin)' &&
        !options.contains('nofin') &&
        !options.contains('loop')) {
      _later(400, () {
        _say = true;
        _mode('speaking');
        _agent('Eso. Hasta mañana.');
        _later(2000, () {
          _say = false;
          _mode('listening');
        });
      });
    }
  }

  @override
  void setVolume(double v) => volumes.add(v);

  @override
  double inputVolume() => _inp == 'talk' ? .14 : .004;

  @override
  double outputVolume() => _say ? .15 : 0;

  @override
  Future<void> end() async {
    if (ended) return;
    ended = true;
    _later(30, () => _events.add(const Ended('user')));
  }

  /// Cancels every timer still waiting.
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }
}
