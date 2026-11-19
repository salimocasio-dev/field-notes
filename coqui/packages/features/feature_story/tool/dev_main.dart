// The dev entry: feature_story alone, on the fakes, on a scene of our own (the real El frente is the scenes package's).
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_story/feature_story.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/screen/story_screen.dart';
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

/// The sample course with four clips of El bizcocho marked "tu_turno", as `historia/tools/habla_motor_check.py` marks them in a
/// scratch copy, so that the mic can be seen (`?mic=stub:...`).
class MarkedCourse extends FakeCourseCatalog {
  final Map<String, Future<Map<String, dynamic>>> _marked = {};

  @override
  Future<Map<String, dynamic>> story(String id) => _marked[id] ??= () async {
    final f = Map<String, dynamic>.of(await super.story(id));
    if (id == 'el-bizcocho') {
      final c = Map<String, dynamic>.of(
        (f['clips'] as Map).cast<String, dynamic>(),
      );
      for (final k in ['cq_si', 'cq_no', 'cq_si_gracias', 'cq_no_gracias']) {
        c[k] = {
          ...(c[k] as Map).cast<String, dynamic>(),
          'tu_turno': [
            {
              'palabra': k.contains('si') ? 'sí' : 'no',
              'formas': k.contains('si') ? ['sí', 'si'] : ['no'],
            },
          ],
        };
      }
      f['clips'] = c;
    }
    return f;
  }();
}

/// The dev entry's root widget: the module on the fakes, playing story [id] of the sample course. The old page's switches:
/// [listen] is `?oir=1`, [txt] `?txt=`, [micStub] `?mic=stub:` (every word is open for speaking then).
Widget devApp({
  String id = 'la-lluvia',
  bool listen = false,
  TxtMode txt = TxtMode.con,
  List<String>? micStub,
}) {
  final course = micStub != null ? MarkedCourse() : FakeCourseCatalog();
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
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const SizedBox.shrink();
      }
      final scenes = devScenes(stories);
      if (txt == TxtMode.con && micStub == null) {
        return FeatureDevApp(
          module: StoryModule(scenes: scenes),
          services: services,
          route: StoryRoute(id, listen: listen),
        );
      }
      // the old page's switches are options of the screen: the module has none
      return MaterialApp(
        home: Scaffold(
          body: StoryScreen(
            services: services,
            route: StoryRoute(id, listen: listen),
            scenes: scenes,
            txt: txt,
            options: StoryOptions(micStub: micStub, allOpen: micStub != null),
          ),
        ),
      );
    },
  );
}

void main() {
  final q = Uri.base.queryParameters;
  final mic = q['mic'];
  runApp(
    devApp(
      id: q['cuento'] ?? 'la-lluvia',
      listen: q['oir'] == '1',
      txt: switch (q['txt']) {
        'tras' => TxtMode.tras,
        'no' => TxtMode.no,
        _ => TxtMode.con,
      },
      micStub: mic != null && mic.startsWith('stub:')
          ? mic.substring(5).split('|')
          : null,
    ),
  );
}
