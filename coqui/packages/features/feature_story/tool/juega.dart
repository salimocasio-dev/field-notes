// A story played with no screen, by rule, on the story runner. See `lib/src/play/play.dart`.
//
//   dart run tool/juega.dart <story> <plan> <seed> [--out FILE] [--root DIR]      (in this package)
//
// <plan> is right, wrong or alternate. It prints the trace (the shape of `coqui/ref/trazas/<story>/<plan>.json`) or
// writes it to FILE. The scene is the stand-in scene until El frente's real one is in the registry: the run is the
// runner's, not the scene's acts' (see test/differential_test.dart).
import 'dart:io';

import 'package:feature_story/src/play/play.dart';
import 'package:feature_story/src/play/trace_json.dart';

import 'disk_course.dart';
import 'frente_order.dart';
import 'sha256.dart';
import 'stand_in_scene.dart';
import 'tool_progress.dart';

Future<void> main(List<String> args) async {
  final pos = <String>[];
  String? out, rootArg;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out') {
      out = args[++i];
    } else if (args[i] == '--root') {
      rootArg = args[++i];
    } else {
      pos.add(args[i]);
    }
  }
  if (pos.length != 3) {
    stderr.writeln(
      'usage: dart run tool/juega.dart <story> <plan> <seed> [--out FILE] [--root DIR]',
    );
    exit(64);
  }
  final root = findRoot(rootArg == null ? null : Directory(rootArg));
  final course = DiskCourse(root);
  await course.load();
  final trace = await playFromDisk(course, pos[0], pos[1], int.parse(pos[2]));
  final text = traceToText(trace);
  if (out != null) {
    File(out).writeAsStringSync(text);
  } else {
    stdout.write(text);
  }
}

/// Plays one story of the course on disk, as the tool and the differential check do.
Future<Map<String, dynamic>> playFromDisk(
  DiskCourse course,
  String story,
  String plan,
  int seed,
) async {
  final file = await course.story(story);
  return play(
    story: file,
    plan: plan,
    seed: seed,
    sceneFor: (rng) =>
        StandInScene(sceneId: file['scene'] as String, cam: camsOf(file)),
    course: course,
    progress: ToolProgress(),
    storySha256: sha256Hex(course.storyBytes(story)),
    thingOrder: file['scene'] == 'frente' ? frenteThingOrder : null,
  );
}

/// A view for every name a story's `cam` steps use, each its own (the stand-in scene has no places of its own): a name
/// is a view of zoom 1 at its own x. Two names are never the same view, as in the old scenes.
Map<String, List<num>> camsOf(Map<String, dynamic> story) {
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
  final out = <String, List<num>>{};
  var i = 0;
  for (final n in names) {
    out[n] = [i++, 0, 196, 216];
  }
  return out;
}
