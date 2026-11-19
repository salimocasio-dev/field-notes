// The dev entry: feature_review alone, on the fakes.
//
//   flutter run -d chrome -t tool/dev_main.dart
//   flutter run -d chrome -t tool/dev_main.dart --web-launch-url "/?screen=review&seed=curso"
//
// Address parameters:
//   screen=review|level   which lesson (default review)
//   seed=<name>           the progress state, from coqui/ref/pantallas/seeds (curso, uno, todo, vacio, nivel,
//                         nivel1, casi, segunda); default curso (review), vacio (level)
//   state=<name>          a reference state (tool/dev_states.dart: reviewStates, levelStates): the lesson is played on
//                         a virtual clock to the instant that reference picture was taken, and held there. Without
//                         it the lesson runs on real time and you play it.
//   n=<count>  solo=<w,w>  todo=1   the old page's own switches (cual.js: ?n= ?solo= ?todo=; nivel.js: ?todo=)
//   rng=<seed>            the random source's seed (default 1, as the reference pictures were taken)
//   clip=<ms>             how long a recorded line lasts, on real time (default 1200)
//   txt=con|tras|no       when the words show (juego.js: ?txt=; default con)
//
// The old pictures were taken with the progress clock fixed at 19 Nov 2026 16:00 UTC; so is the store's here.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/level_check.dart';
import 'package:feature_review/src/logic/review_session.dart';
import 'package:feature_review/src/ui/level_check_screen.dart';
import 'package:feature_review/src/ui/review_screen.dart';
import 'package:material_ui/material_ui.dart';

import 'dev_data.g.dart';
import 'dev_states.dart';
import 'support/scripted_clips.dart' show ScriptedClips, clipLength;
import 'support/timed_clips.dart';
import 'support/virtual_time.dart';

/// 19 Nov 2026 16:00 UTC: the clock of the reference pictures (ref/pantallas/README.md).
const int devNow = 1795104000000;

/// The real clock, for the dev entry when it runs on real time.
class _WallClock implements Clock {
  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

Future<Services> devServices(
  Map<String, String> q, {
  VirtualTime? vt,
  required String defaultSeed,
}) async {
  final course = FakeCourseCatalog(
    fetch: (path) async =>
        devCourseFiles[path] ?? (throw StateError('no file $path')),
  );
  await course.load();
  final seed = q['seed'] ?? defaultSeed;
  final json = devSeeds[seed];
  if (json == null) throw StateError('no seed "$seed"');
  final store = FakeProgressStore(clock: FakeClock(devNow), json: json);
  final ClipPlayer clips = vt == null
      ? TimedClips(
          lengthOf: q['clip'] == null
              ? (id) => 600 + clipLength(id) ~/ 2
              : (_) => int.parse(q['clip']!),
        )
      : ScriptedClips(vt);
  return fakeServices(
    progress: store,
    course: course,
    clips: clips,
    clock: vt ?? _WallClock(),
    rng: FakeRng(int.tryParse(q['rng'] ?? '') ?? 1),
  );
}

CaptionMode captionsOf(String? txt) => switch (txt) {
  'tras' => CaptionMode.after,
  'no' => CaptionMode.never,
  _ => CaptionMode.during,
};

class DevApp extends StatefulWidget {
  const DevApp({super.key, required this.query});
  final Map<String, String> query;

  @override
  State<DevApp> createState() => _DevAppState();
}

class _DevAppState extends State<DevApp> {
  Services? _services;
  VirtualTime? _vt;
  final GlobalKey<ReviewScreenState> _review = GlobalKey();
  final GlobalKey<LevelCheckScreenState> _level = GlobalKey();
  Object? _error;

  Map<String, String> get q => widget.query;
  bool get _isLevel => q['screen'] == 'level';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final vt = q['state'] == null ? null : VirtualTime();
      final s = await devServices(
        q,
        vt: vt,
        defaultSeed: _isLevel ? 'vacio' : 'curso',
      );
      setState(() {
        _vt = vt;
        _services = s;
      });
      if (vt != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _playState(vt));
      }
    } catch (e) {
      setState(() => _error = e);
    }
  }

  Future<void> _playState(VirtualTime vt) async {
    final state = q['state']!;
    if (_isLevel) {
      final st = _level.currentState!;
      await playLevelState(st.session, vt, state, () async {
        await st.pressStart();
      });
    } else {
      final st = _review.currentState!;
      await playReviewState(st.session, vt, state, () async {
        await st.pressStart();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _services;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coqui review dev',
      theme: coquiTheme(),
      home: Scaffold(
        backgroundColor: CoquiColors.lessonBg,
        body: _error != null
            ? Center(child: Text('$_error'))
            : s == null
            ? const SizedBox.shrink()
            : _isLevel
            ? LevelCheckScreen(
                key: _level,
                services: s,
                options: LevelOptions(all: q['todo'] != null),
                captions: captionsOf(q['txt']),
                wait: _vt?.wait,
              )
            : ReviewScreen(
                key: _review,
                services: s,
                options: ReviewOptions(
                  cap: int.tryParse(q['n'] ?? '') ?? reviewCap,
                  only: q['solo']?.split(','),
                  all: q['todo'] != null,
                ),
                captions: captionsOf(q['txt']),
                wait: _vt?.wait,
              ),
      ),
    );
  }
}

void main() => runApp(DevApp(query: Uri.base.queryParameters));
