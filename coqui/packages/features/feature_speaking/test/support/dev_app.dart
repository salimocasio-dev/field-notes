// The dev entry's root widget (tool/dev_main.dart runs it), here so that the tests can run it too.
//
// What the address says (all optional):
//   ?screen=hablar|call|voice     what opens first (default hablar); from Hablar, a tap on a call card opens the
//                                 call as the shell would, and its X or "Back to Hablar" comes back
//   &seed=vacio|curso|casi|todo|nivel   the stored progress of a reference picture of v=39
//                                 (coqui/ref/pantallas/seeds); default todo
//   &stub=manual,nofin,mic,fail,hasta,dannybye,loop,library   the scripted call's options, as the old page's ?stub=
//                                 (`library`: the voice library did not load)
//   &steps=connect@0,danny1@100,...   with stub=manual: the scripted call's steps and when (ms after the call
//                                 starts); `jump60000` moves the clock on 60 s; `say:Hola.` the learner says it
//   &later=1                      the call cannot be placed on this build (call.available is false)
//   &entry=1                      the Hablar tab has an entry to the voice test
//   &mic=stub:a|b|...  or  &mic=off   the voice test's scripted recogniser, as habla-prueba.html's ?mic=;
//                                 &micwait=ms holds each result back that much more, &speechwait=ms the end of speech
//   &reduce=1                     reduceMotion: nothing animates (as the reference pictures were taken)
//   &bar=0                        no tab bar under the Hablar tab
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/module.dart';
import 'package:material_ui/material_ui.dart';

import 'call_rig.dart';
import 'scripted_call.dart';
import 'speaking_seeds.dart';
import 'voice_fixture.dart';

/// The title of the stand-in entry to the voice test.
const devVoiceTestEntry = 'Voice test';

/// A clock that starts at the moment of the reference pictures (19 Nov 2026, 12:00 in Puerto Rico) and moves with
/// the real time, plus whatever a script has jumped.
class DevClock implements Clock {
  DevClock()
    : _base = DateTime.utc(2026, 11, 19, 16).millisecondsSinceEpoch,
      _watch = Stopwatch()..start();

  final int _base;
  final Stopwatch _watch;
  int skew = 0;

  @override
  int nowMs() => _base + _watch.elapsedMilliseconds + skew;
}

/// The scripted call of coqui_testing, with a few things the dev entry adds: its steps given as a list and started
/// when the call starts (`steps=connect@0,danny1@100`), `jump<ms>` that moves the clock on, `say:<text>` that has
/// the learner say a line (the stub's own `CallStub.o.onMessage`), and the option `library` (the voice library
/// did not load).
class DevCall extends ScriptedCall {
  DevCall({
    super.stub,
    super.available,
    required this.clock,
    this.steps = const [],
  }) : super(
         startError: stub.contains('library')
             ? Exception('LibraryError: The voice library did not load.')
             : null,
       );

  final DevClock clock;

  /// [name, ms after start]
  final List<(String, int)> steps;
  final List<Timer> _scripted = [];

  @override
  Future<void> start(CallBrief brief, Map<String, String> variables) {
    final f = super.start(brief, variables);
    for (final (name, ms) in steps) {
      _scripted.add(
        Timer(Duration(milliseconds: ms), () {
          final jump = RegExp(r'^jump(\d+)$').firstMatch(name);
          if (jump != null) {
            clock.skew += int.parse(jump.group(1)!);
          } else if (name.startsWith('say:')) {
            emit(Heard(name.substring(4)));
          } else {
            go(name);
          }
        }),
      );
    }
    return f;
  }

  @override
  void dispose() {
    for (final t in _scripted) {
      t.cancel();
    }
    _scripted.clear();
    super.dispose();
  }
}

/// The scripted recogniser of coqui_testing, with `micwait` ms more before each result (so a picture can be taken
/// of "Un momento…", which lasts 120 ms on the fake).
class DevSpeech implements SpeechListener {
  DevSpeech(this.fake, this.extraMs, [this.speechEndMs = 0]);
  final FakeSpeechListener fake;
  final int extraMs;

  /// ms more before the end of speech is reported.
  final int speechEndMs;

  @override
  Future<bool> available() => fake.available();

  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) {
    final t = fake.listen(
      locale: locale,
      limit: limit,
      maxAlternatives: maxAlternatives,
    );
    return extraMs == 0 && speechEndMs == 0
        ? t
        : _Slow(t, extraMs, speechEndMs);
  }
}

class _Slow implements SpeechTurn {
  _Slow(this.inner, this.ms, this.endMs);
  final SpeechTurn inner;
  final int ms;
  final int endMs;

  @override
  Future<SpeechResult> get result async {
    final r = await inner.result;
    await Future<void>.delayed(Duration(milliseconds: ms));
    return r;
  }

  @override
  Future<void> get speechEnd async {
    await inner.speechEnd;
    await Future<void>.delayed(Duration(milliseconds: endMs));
  }

  @override
  void cancel() => inner.cancel();
}

/// `steps=connect@0,danny1@100`
List<(String, int)> parseSteps(String? s) => [
  if (s != null && s.isNotEmpty)
    for (final p in s.split(','))
      if (p.contains('@'))
        (p.split('@')[0], int.parse(p.split('@')[1]))
      else
        (p, 0),
];

/// The routes the dev entry stands on: what the shell's navigator would do.
class DevNavigator implements AppNavigator {
  DevNavigator(this.onGo, this.onBack);
  final void Function(AppRoute) onGo;
  final VoidCallback onBack;
  final List<AppRoute> routes = [];

  @override
  void go(AppRoute route) {
    routes.add(route);
    onGo(route);
  }

  @override
  void back() => onBack();
}

Widget devApp([Map<String, String> query = const {}]) =>
    SpeakingDevApp(query: query);

class SpeakingDevApp extends StatefulWidget {
  const SpeakingDevApp({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  State<SpeakingDevApp> createState() => _SpeakingDevAppState();
}

class _SpeakingDevAppState extends State<SpeakingDevApp> {
  late final DevClock clock;
  late final FixtureCourse course;
  late final DevCall call;
  late final Services services;
  late final SpeakingModule module;
  AppRoute? route;
  late final Future<void> loading;

  Map<String, String> get q => widget.query;

  @override
  void initState() {
    super.initState();
    clock = DevClock();
    course = FixtureCourse();
    final stub = (q['stub'] ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toSet();
    call = DevCall(
      stub: stub,
      available: q['later'] != '1',
      clock: clock,
      steps: parseSteps(q['steps']),
    );
    final mic = q['mic'] ?? '';
    final speech = DevSpeech(
      mic == 'off'
          ? FakeSpeechListener(isAvailable: false)
          : FakeSpeechListener.stub(
              mic.startsWith('stub:') ? mic.substring(5) : voiceStubOfPictures,
            ),
      int.tryParse(q['micwait'] ?? '') ?? 0,
      int.tryParse(q['speechwait'] ?? '') ?? 0,
    );
    final seed = speakingSeeds[q['seed'] ?? 'todo'] ?? speakingSeeds['todo']!;
    services = fakeServices(
      progress: FakeProgressStore(clock: clock, json: seed),
      course: course,
      call: call,
      speech: speech,
      clock: clock,
      nav: DevNavigator(
        (r) => setState(() => route = r),
        () => setState(() => route = null),
      ),
      reduceMotion: q['reduce'] == '1',
    );
    module = SpeakingModule(
      voiceTest: voiceFixture,
      voiceTestEntry: q['entry'] == '1' ? devVoiceTestEntry : null,
    );
    switch (q['screen']) {
      case 'call':
        route = CallRoute(course.places.first.id);
      case 'voice':
        route = const VoiceTestRoute();
    }
    loading = course.load();
  }

  @override
  void dispose() {
    call.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Coqui speaking',
    theme: coquiTheme(),
    home: Scaffold(
      body: FutureBuilder<void>(
        future: loading,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          final r = route;
          final screen = r == null ? null : module.screenFor(r, services);
          if (screen != null) return screen;
          return Stack(
            fit: StackFit.expand,
            children: [
              module.tab(services)!.builder(context),
              if (q['bar'] != '0')
                Align(
                  alignment: Alignment.bottomCenter,
                  child: CoquiTabBar(
                    selectedId: CoquiTabs.speakId,
                    onTap: (_) {},
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
