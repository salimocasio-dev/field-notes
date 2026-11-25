/// Pre-flight checks run before a story starts: every act the story names must
/// exist on its scene, and the app build must satisfy the course/story `minApp`.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_story/src/runner/js.dart';
import 'package:feature_story/src/runner/story_runner.dart';

/// Every act name referenced in [story]'s `beats` and `final` step trees.
///
/// Walks `story['beats']` and `story['final']` recursively following the same
/// step kinds and nested step lists that [StoryRunner] executes:
/// - `act`: `step['act']`
/// - `if`: `then`, `else`
/// - `ask`: `lead`, `after`, `then`
/// - `elige`: `lead`, and each branch named in `options`
/// - `decide`: `step['do']`, `lead`, `wrong`, `right`, and each branch in
///   `gratis`
///
/// Returns unique names in first-encounter order.
List<String> storyNamedActs(Map<String, dynamic> story) {
  final seen = <String>{};
  final acts = <String>[];

  void record(Object? name) {
    if (!jsTruthy(name)) return;
    final key = name is String ? name : jsString(name);
    if (seen.add(key)) acts.add(key);
  }

  void walkSteps(Object? list) {
    if (list is! List) return;
    for (final st in list) {
      if (st is! Map) continue;
      switch (stepKind(st)) {
        case 'act':
          record(st['act']);
        case 'if':
          walkSteps(st['then']);
          walkSteps(st['else']);
        case 'ask':
          walkSteps(st['lead']);
          walkSteps(st['after']);
          walkSteps(st['then']);
        case 'elige':
          walkSteps(st['lead']);
          final ops = st['options'];
          if (ops is List) {
            for (final o in ops) {
              if (o is String) walkSteps(st[o]);
            }
          }
        case 'decide':
          if (jsTruthy(st['do'])) record(st['do']);
          walkSteps(st['lead']);
          walkSteps(st['wrong']);
          walkSteps(st['right']);
          final gratis = st['gratis'];
          if (gratis is Map) {
            for (final branch in gratis.values) {
              walkSteps(branch);
            }
          }
      }
    }
  }

  walkSteps(story['beats']);
  walkSteps(story['final']);
  return acts;
}

/// Every act named in [story] that [scene] does not provide (`scene.acts[name]
/// == null`).
///
/// Uses `scene.acts[name] == null` (the exact lookup [StoryRunner] performs) so
/// real scenes and lenient stand-in scenes agree with the runner.
List<String> missingSceneActs(Map<String, dynamic> story, Scene scene) => [
  for (final name in storyNamedActs(story))
    if (scene.acts[name] == null) name,
];

/// Whether playing [storyId] requires a newer app build: either [info] does not
/// satisfy `course.minAppFor(storyId)`, or (when [story] and [scene] are given)
/// [story] names an act that [scene] does not have.
bool storyNeedsAppUpdate({
  required CourseCatalog course,
  required String storyId,
  required AppInfo info,
  Map<String, dynamic>? story,
  Scene? scene,
}) {
  if (!info.supportsMinApp(course.minAppFor(storyId))) return true;
  if (story != null && scene != null) {
    return missingSceneActs(story, scene).isNotEmpty;
  }
  return false;
}
