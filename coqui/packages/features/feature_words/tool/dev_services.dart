// The services of the dev entry: the fakes of coqui_testing, set up to look like the reference states.
//
// What differs from `fakeServices()` as it comes, and why:
// - the clock stands at 19 Nov 2026, 12:00 in Puerto Rico (`window.__PAL_NOW` of coqui/ref/pantallas), the moment
//   the old pictures were taken at, so that "Comes back in 1 day" and the due words are the same;
// - the course is the sample course's catalog fed with every course file the old app reads (tool/dev_data/): the
//   sample course holds three stories, so most words of a reference state would fall under "More words";
// - a clip plays for its own length (the fake plays at once, and a line would never show as playing);
// - a picture is a grey box of the size the real picture source gives (the width it is offered, at a whole number
//   of device pixels per picture pixel), where the fake's is always 196 x 104.
import 'dart:async';

import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'dev_data/course.g.dart';
import 'dev_data/seeds.g.dart';

/// `window.__PAL_NOW` of coqui/ref/pantallas/README.md: 2026-11-19T16:00:00Z.
const devNowMs = 1795104000000;

/// The names of the stored-progress states the dev entry starts in (`?state=<name>`).
List<String> get devStates => devSeeds.keys.toList();

/// Services on the fakes, with the stored progress of [state] (a name of [devStates]; null or unknown: nothing
/// stored yet) loaded through the store's `import`.
Services devServices({String? state}) {
  final clock = FakeClock(devNowMs);
  final progress = FakeProgressStore(clock: clock);
  final seed = devSeeds[state];
  if (seed != null) progress.import(seed);
  final course = FakeCourseCatalog(
    fetch: (path) async =>
        devCourseFiles[path] ?? (throw StateError('no file "$path"')),
  );
  return fakeServices(
    clock: clock,
    progress: progress,
    course: course,
    clips: DevClips(
      lengthOf: (id) {
        final c = course.clip(id);
        return c == null ? null : c.endMs - c.startMs;
      },
    ),
    pictures: DevPictures(),
  );
}

/// A clip player whose clips take their own time: [play] ends after the clip's length (3 s for a clip with no
/// marks), or at [stop] (false: cut off).
class DevClips extends FakeClipPlayer {
  DevClips({super.lengthOf});

  Completer<bool>? _running;
  Timer? _timer;

  @override
  Future<bool> play(String clipId, {Duration? limit}) {
    played.add(clipId);
    _finish(false);
    final c = Completer<bool>();
    _running = c;
    final len = lengthOf?.call(clipId) ?? 3000;
    _timer = Timer(Duration(milliseconds: len), () => _finish(true));
    return c.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    _finish(false);
  }

  void _finish(bool toTheEnd) {
    _timer?.cancel();
    final c = _running;
    _running = null;
    if (c != null && !c.isCompleted) c.complete(toTheEnd);
  }
}

/// Grey boxes with the geometry of the real picture source: 196 : [height] picture pixels, as many device pixels
/// to a picture pixel as the width offered holds (PixelView's rule), or `scale` when given.
class DevPictures implements PictureSource {
  @override
  Widget of(
    PictureRef ref, {
    int height = 104,
    int? scale,
    bool animated = false,
  }) => LayoutBuilder(
    builder: (context, c) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final k =
          scale ??
          pixelViewScale(
            availableWidth: c.hasBoundedWidth ? c.maxWidth : 196,
            devicePixelRatio: dpr,
            width: 196,
          );
      return SizedBox(
        width: 196 * k / dpr,
        height: height * k / dpr,
        child: ColoredBox(
          color: const Color(0xFF9E9E9E),
          child: Center(
            child: Text(
              '${ref.scene} ${ref.cam.join(',')}',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: Color(0xFF212121),
                fontSize: 10,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  Future<void> warm(Iterable<PictureRef> refs) async {}
}
