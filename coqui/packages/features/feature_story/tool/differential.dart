// The runner against the old page's recorded runs (coqui/ref/trazas/), on a stand-in scene that replays what the old scene
// did (tool/replay_scene.dart, from test/fixtures/acts/, made by tool/ref/record_acts.mjs).
//
//   dart run tool/differential.dart [--only STORY] [--plan right|wrong|alternate]     (in this package)
//
// Prints one line per run that differs (the first difference, with both values) and a count. The whole trace is
// compared: every field, `t` included, but for the touches' `x` and `y`, which are places on the old screen's boxes
// (the runs touch by thing id; the point only places the stars).
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart' show Rng;
import 'package:coqui_pixel/coqui_pixel.dart' show Scene;
import 'package:feature_story/src/play/play.dart';
import 'package:feature_story/src/play/trace_json.dart';
import 'package:feature_story/src/runner/story_view.dart' show StoryView;

import 'disk_course.dart';
import 'replay_scene.dart';
import 'sha256.dart';
import 'tool_progress.dart';

/// A trace as the comparison reads it: the touches without their places on the old screen.
Map<String, dynamic> forComparison(Map<String, dynamic> t) {
  final c = Map<String, dynamic>.of(t);
  c['touches'] = [
    for (final x in (t['touches'] as List? ?? const []))
      {
        for (final e in (x as Map).entries)
          if (e.key != 'x' && e.key != 'y') e.key: e.value,
      },
  ];
  return c;
}

/// A trace as the comparison of a different scene reads it: without any time (`t`, `virtualMs`, `minutes`, the time to answer
/// `ms`), without the touches' places, and without the frog's `hop` sounds. A scene's own geometry (where its frog stands and
/// which views it has) changes how long its acts take and how many hops one has; everything else must be the old run's.
Map<String, dynamic> forTimeless(Map<String, dynamic> t) {
  Object? strip(Object? v, String key) {
    if (v is Map) {
      return {
        for (final e in v.entries)
          if (!const {
            't',
            'virtualMs',
            'minutes',
            'x',
            'y',
            'ms',
          }.contains(e.key))
            e.key: strip(e.value, e.key as String),
      };
    }
    if (v is List) {
      final l = [for (final e in v) strip(e, key)];
      return key == 'sounds' ? l.where((e) => e != 'hop').toList() : l;
    }
    return v;
  }

  return Map<String, dynamic>.from(strip(t, '') as Map);
}

/// One recorded run of the old page played by the runner on a scene of the caller's. Returns the first difference, or null
/// when the two traces are equal.
Future<String?> compareWithScene(
  DiskCourse course,
  String story,
  String plan,
  Directory trazas,
  Scene Function(Rng rng) sceneFor, {
  List<String> Function(Map<String, dynamic> W, int now)? thingOrder,
  ({int x, int y, num scale}) Function(Scene scene)? startFrog,
  bool Function(Scene scene)? frogShadow,
}) async {
  final committed = jsonDecode(
    File('${trazas.path}/$story/$plan.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final file = await course.story(story);
  final trace = await play(
    story: file,
    plan: plan,
    seed: committed['seed'] as int,
    sceneFor: sceneFor,
    course: course,
    progress: ToolProgress(),
    storySha256: sha256Hex(course.storyBytes(story)),
    thingOrder: thingOrder,
    startFrog: startFrog,
    frogShadow: frogShadow,
  );
  final errs = trace['errors'];
  if (errs is List && errs.isNotEmpty) {
    return 'the run failed: ${(errs.first as String).split('\n').take(4).join(' | ')}';
  }
  lastCompared = (committed: committed, trace: trace);
  return firstDifference(forComparison(committed), forComparison(trace));
}

/// The two traces [compareWithScene] compared last (the recorded one and the one played), to look at a difference.
({Map<String, dynamic> committed, Map<String, dynamic> trace})? lastCompared;

/// One recorded run of the old page played by the runner on the replay scene. Returns the first difference, or null when
/// the two traces are equal (the committed one is [committed]). [view] is the screen's state the run was played on: the
/// caller reads the end screen's buttons from it (the recorded runs do not hold them, so the comparison does not either).
Future<String?> compareRun(
  DiskCourse course,
  String story,
  String plan,
  Directory actsDir,
  Directory trazas, {
  StoryView? view,
}) async {
  final committed = jsonDecode(
    File('${trazas.path}/$story/$plan.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final run = jsonDecode(
    File('${actsDir.path}/$story/$plan.acts.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final file = await course.story(story);
  final wrongs = [
    for (final t in (committed['touches'] as List).cast<Map<String, dynamic>>())
      if (t['why'] == 'wrong-poke')
        (t: (t['t'] as num).toInt(), what: t['what'] as String),
  ];
  late ReplayScene scene;
  final trace = await play(
    story: file,
    plan: plan,
    seed: committed['seed'] as int,
    sceneFor: (rng) => scene = ReplayScene(
      sceneId: file['scene'] as String,
      story: file,
      run: run,
      rng: rng,
    ),
    course: course,
    progress: ToolProgress(),
    storySha256: sha256Hex(course.storyBytes(story)),
    view: view,
    // the old learner's wrong touch of an ask: the first thing of the scene's list; here, the thing it touched
    thingOrder: (W, now) {
      for (final w in wrongs) {
        if (w.t >= now) return [w.what];
      }
      return const [];
    },
  );
  if (scene.divergences.isNotEmpty) {
    return 'the replay: ${scene.divergences.first}';
  }
  final errs = trace['errors'];
  if (errs is List && errs.isNotEmpty) {
    return 'the run failed: ${(errs.first as String).split('\n').take(4).join(' | ')}';
  }
  return firstDifference(forComparison(committed), forComparison(trace));
}

Future<void> main(List<String> args) async {
  String? only, onlyPlan;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--only') only = args[++i];
    if (args[i] == '--plan') onlyPlan = args[++i];
  }
  final root = findRoot();
  final course = DiskCourse(root);
  await course.load();
  final trazas = Directory('${root.path}/coqui/ref/trazas');
  final actsDir = Directory('${Directory.current.path}/test/fixtures/acts');
  final runs =
      (jsonDecode(File('${trazas.path}/runs.json').readAsStringSync())['runs']
              as List)
          .cast<Map<String, dynamic>>();
  var same = 0, differ = 0;
  for (final r in runs) {
    if (only != null && r['story'] != only) continue;
    if (onlyPlan != null && r['plan'] != onlyPlan) continue;
    String? d;
    try {
      d = await compareRun(
        course,
        r['story'] as String,
        r['plan'] as String,
        actsDir,
        trazas,
      );
    } catch (e, s) {
      d = 'threw $e\n$s';
    }
    if (d == null) {
      same++;
    } else {
      differ++;
      stdout.writeln('${r['story']} ${r['plan']}: $d');
    }
  }
  stdout.writeln('$same runs equal, $differ differ');
}
