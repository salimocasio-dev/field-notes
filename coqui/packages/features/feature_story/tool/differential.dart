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

import 'package:feature_story/src/play/play.dart';
import 'package:feature_story/src/play/trace_json.dart';

import 'disk_course.dart';
import 'replay_scene.dart';
import 'sha256.dart';
import 'tool_progress.dart';

/// A trace as the comparison reads it: the touches without their places on the old screen.
Map<String, dynamic> forComparison(Map<String, dynamic> t) {
  final c = Map<String, dynamic>.of(t);
  c['touches'] = [
    for (final x in (t['touches'] as List? ?? const []))
      {for (final e in (x as Map).entries) if (e.key != 'x' && e.key != 'y') e.key: e.value},
  ];
  return c;
}

/// One recorded run of the old page played by the runner on the replay scene. Returns the first difference, or null when
/// the two traces are equal (the committed one is [committed]).
Future<String?> compareRun(
  DiskCourse course,
  String story,
  String plan,
  Directory actsDir,
  Directory trazas,
) async {
  final committed = jsonDecode(File('${trazas.path}/$story/$plan.json').readAsStringSync()) as Map<String, dynamic>;
  final run = jsonDecode(File('${actsDir.path}/$story/$plan.acts.json').readAsStringSync()) as Map<String, dynamic>;
  final file = await course.story(story);
  final wrongs = [
    for (final t in (committed['touches'] as List).cast<Map<String, dynamic>>())
      if (t['why'] == 'wrong-poke') (t: (t['t'] as num).toInt(), what: t['what'] as String),
  ];
  late ReplayScene scene;
  final trace = await play(
    story: file,
    plan: plan,
    seed: committed['seed'] as int,
    sceneFor: (rng) => scene = ReplayScene(sceneId: file['scene'] as String, story: file, run: run, rng: rng),
    course: course,
    progress: ToolProgress(),
    storySha256: sha256Hex(course.storyBytes(story)),
    // the old learner's wrong touch of an ask: the first thing of the scene's list; here, the thing it touched
    thingOrder: (W, now) {
      for (final w in wrongs) {
        if (w.t >= now) return [w.what];
      }
      return const [];
    },
  );
  if (scene.divergences.isNotEmpty) return 'the replay: ${scene.divergences.first}';
  final errs = trace['errors'];
  if (errs is List && errs.isNotEmpty) return 'the run failed: ${(errs.first as String).split('\n').take(4).join(' | ')}';
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
  final runs = (jsonDecode(File('${trazas.path}/runs.json').readAsStringSync())['runs'] as List).cast<Map<String, dynamic>>();
  var same = 0, differ = 0;
  for (final r in runs) {
    if (only != null && r['story'] != only) continue;
    if (onlyPlan != null && r['plan'] != onlyPlan) continue;
    String? d;
    try {
      d = await compareRun(course, r['story'] as String, r['plan'] as String, actsDir, trazas);
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
