// The scene's own names are kept as in the old code (page 12, section 4).
// ignore_for_file: non_constant_identifier_names

// A stand-in scene that replays what the OLD scene did in one recorded run (written by tool/ref/record_acts.mjs). It is
// how the story runner is checked against coqui/ref/trazas/ with no scene of its own: every call the story makes on the
// scene (an act, the stake, a poke) takes the time the old call took, makes the sounds it made, draws the random numbers
// it drew, starts the camera moves it started, and leaves the story variables and the world flags as the old call left
// them. What the runner does is the runner's own.
import 'package:coqui_contracts/coqui_contracts.dart' show Rng;
import 'package:coqui_pixel/coqui_pixel.dart';

/// One call of the old scene, as recorded.
class RecordedCall {
  RecordedCall(Map<String, dynamic> j)
    : name = j['name'] as String,
      t0 = (j['t0'] as num).toInt(),
      t1 = (j['t1'] as num).toInt(),
      ev0 = j['ev0'] as int,
      v = (j['v'] as Map?)?.cast<String, dynamic>() ?? const {},
      w = (j['w'] as Map?)?.cast<String, dynamic>() ?? const {};

  final String name;
  final int t0, t1;

  /// The index of the first event after the call began.
  final int ev0;
  final Map<String, dynamic> v, w;

  /// What the old scene did because of this call, in order: `{t, k: sfx|tone|rand|cam, a}`. A scene's event belongs to
  /// the latest call the story made that began before it, so what a call left running (`suelto`) is part of it.
  final List<Map<String, dynamic>> events = [];
}

/// The views a story and a recorded run name: each its own view of zoom 1 (the old scenes' views were not whole
/// numbers; here two names are never the same view, as in the old scenes).
Map<String, List<num>> replayViews(
  Map<String, dynamic> story,
  Map<String, dynamic> run,
) {
  final names = <String>{'wide'};
  void walk(Object? x) {
    if (x is Map) {
      final c = x['cam'];
      if (c is String) names.add(c);
      x.values.forEach(walk);
    } else if (x is List) {
      x.forEach(walk);
    }
  }

  walk(story);
  for (final e in (run['events'] as List).cast<Map<String, dynamic>>()) {
    if (e['k'] == 'cam') names.add((e['a'] as List)[0] as String);
  }
  final out = <String, List<num>>{};
  var i = 0;
  for (final n in names) {
    out[n] = [i++, 0, 196, 216];
  }
  return out;
}

class ReplayScene extends Escena {
  ReplayScene({
    required this.sceneId,
    required Map<String, dynamic> story,
    required this.run,
    required this.rng,
  }) : _cam = replayViews(story, run) {
    final events = (run['events'] as List).cast<Map<String, dynamic>>();
    final tops = <RecordedCall>[];
    for (final c in (run['calls'] as List).cast<Map<String, dynamic>>()) {
      if (c['top'] != true) continue;
      final rc = RecordedCall(c);
      tops.add(rc);
      (rc.name == 'stake'
              ? _stakes
              : rc.name == 'poke'
              ? _pokes
              : _acts)
          .add(rc);
    }
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      if (e['sc'] != true) continue;
      RecordedCall? owner;
      for (final c in tops) {
        if (c.ev0 <= i) owner = c;
      }
      owner?.events.add(e);
    }
  }

  final String sceneId;

  /// The recorded run (the fixture's JSON).
  final Map<String, dynamic> run;
  final Rng rng;
  final Map<String, List<num>> _cam;
  final List<RecordedCall> _acts = [], _stakes = [], _pokes = [];
  int _nAct = 0, _nStake = 0, _nPoke = 0;

  /// What the replay was asked for that the recording does not have (a divergence from the old run).
  final List<String> divergences = [];

  @override
  String get id => sceneId;

  @override
  Map<String, List<num>> get CAM => _cam;

  @override
  List<Thing> get cosas => const [];

  @override
  Map<String, List<num>> get lugar => const {};

  @override
  Map<String, dynamic> fresh(Map<String, dynamic> story) {
    final start = (run['start'] as Map)['W'] as Map;
    return {for (final e in start.entries) e.key as String: e.value};
  }

  @override
  String setKey(Map<String, dynamic> W) => 'k';

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) {}

  @override
  List<num> remap(List<num> xy) => xy;

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {}

  @override
  String estado(Map<String, dynamic> W) =>
      ((run['end'] as Map)['estado'] as String?) ?? '';

  /// Any act the story names answers with the next recorded one (the names must agree).
  @override
  Map<String, Act> get acts => _Replays(this);

  Future<void> _replay(String act, Map<String, dynamic> o) async {
    if (_nAct >= _acts.length) {
      divergences.add('act $act asked for after the recording ended');
      return;
    }
    final rc = _acts[_nAct++];
    if (rc.name != 'act:$act') {
      divergences.add(
        'act call ${_nAct - 1}: the story asked for $act, the old run called ${rc.name}',
      );
    }
    await _play(rc);
  }

  Future<void> _play(RecordedCall rc) async {
    final t0 = rc.t0;
    for (final e in rc.events) {
      final dt = (e['t'] as num).toInt() - t0;
      if (dt <= 0) {
        _emit(e);
      } else {
        host.sleep(dt).then((_) => _emit(e));
      }
    }
    final dur = rc.t1 - t0;
    if (dur > 0) await host.wait(dur);
    // what the call left changed
    rc.v.forEach((k, v) => host.V[k] = v);
    rc.w.forEach((k, v) => host.W[k] = v);
  }

  void _emit(Map<String, dynamic> e) {
    final a = (e['a'] as List?) ?? const [];
    switch (e['k']) {
      case 'rand':
        rng.next();
      case 'tone':
        num? n(int i) => i < a.length ? a[i] as num? : null;
        host.tone(
          n(0)!,
          n(1)!,
          n(2)!,
          a.length > 3 ? a[3] as String? : null,
          n(4),
          n(5),
        );
      case 'cam':
        host
            .camGo(a[0] as String, (a[1] as num?)?.toInt())
            .then((_) {}, onError: (Object _) {});
      case 'sfx':
        _sfx(a[0] as String, a.length > 1 ? a[1] as num? : null);
    }
  }

  void _sfx(String name, num? arg) {
    final s = host.SFX;
    switch (name) {
      case 'right':
        s.right();
      case 'toc':
        s.toc();
      case 'blip':
        s.blip();
      case 'creak':
        s.creak();
      case 'hop':
        s.hop();
      case 'coqui':
        s.coqui();
      case 'win':
        s.win();
      case 'luz':
        s.luz();
      case 'drop':
        s.drop();
      case 'trueno':
        s.trueno(arg);
      case 'lluvia':
        s.lluvia();
      case 'calla':
        s.calla();
      case 'suave':
        s.suave();
      case 'pio':
        s.pio();
      case 'slam':
        s.slam();
      case 'bonk':
        s.bonk();
      case 'munch':
        s.munch();
      case 'swoop':
        s.swoop();
      default:
        divergences.add('a sound the replay does not know: $name');
    }
  }

  @override
  Future<void> stake(int lost, int max, String en) async {
    if (_nStake >= _stakes.length) {
      divergences.add('stake asked for after the recording ended');
      return;
    }
    await _play(_stakes[_nStake++]);
  }

  @override
  dynamic poke(String what) {
    if (_nPoke >= _pokes.length) {
      divergences.add('poke asked for after the recording ended');
      return null;
    }
    final rc = _pokes[_nPoke++];
    for (final e in rc.events) {
      _emit(e);
    }
    rc.v.forEach((k, v) => host.V[k] = v);
    return null;
  }
}

class _Replays implements Map<String, Act> {
  _Replays(this.scene);

  final ReplayScene scene;

  @override
  Act? operator [](Object? key) =>
      key is String ? (o) => scene._replay(key, o) : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'the replay scene has no ${invocation.memberName}',
  );
}
