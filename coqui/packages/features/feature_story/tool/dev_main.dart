// The dev entry: feature_story alone, on the fakes, on a scene of our own (the real El frente is the scenes package's).
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_story/feature_story.dart';
import 'package:material_ui/material_ui.dart';

import 'dev_scene.dart';

/// Real time for the dev entry (the fakes' clock stands still).
class DevClock implements Clock {
  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

/// A clip player for the dev entry: a line takes as long as its marks say, and makes no sound.
class DevClips extends FakeClipPlayer {
  DevClips(CourseCatalog course)
    : super(
        lengthOf: (id) {
          final c = course.clip(id);
          return c == null ? null : c.endMs - c.startMs;
        },
      );

  @override
  Future<bool> play(String clipId, {Duration? limit}) async {
    final len = lengthOf!(clipId);
    final ok = await super.play(clipId, limit: limit);
    if (len != null) {
      final cap = limit?.inMilliseconds;
      await Future<void>.delayed(
        Duration(milliseconds: cap != null && cap < len ? cap : len),
      );
    }
    return ok;
  }
}

/// The dev entry's root widget: the module on the fakes, playing story [id] of the sample course.
Widget devApp({String id = 'la-lluvia', bool listen = false}) {
  final course = FakeCourseCatalog();
  final services = fakeServices(
    course: course,
    clock: DevClock(),
    clips: DevClips(course),
  );
  final stories = <Map<String, dynamic>>[];
  return FutureBuilder<void>(
    future: () async {
      await course.load();
      for (final s in ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro']) {
        stories.add(await course.story(s));
      }
    }(),
    builder: (context, snap) => snap.connectionState != ConnectionState.done
        ? const SizedBox.shrink()
        : FeatureDevApp(
            module: StoryModule(scenes: devScenes(stories)),
            services: services,
            route: StoryRoute(id, listen: listen),
          ),
  );
}

void main() => runApp(devApp());
