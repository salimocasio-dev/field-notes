import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/src/fake_call.dart';
import 'package:coqui_testing/src/fake_clips.dart';
import 'package:coqui_testing/src/fake_course.dart';
import 'package:coqui_testing/src/fake_entitlements.dart';
import 'package:coqui_testing/src/fake_pictures.dart';
import 'package:coqui_testing/src/fake_platform.dart';
import 'package:coqui_testing/src/fake_progress.dart';
import 'package:coqui_testing/src/fake_speech.dart';
import 'package:coqui_ui/coqui_ui.dart';

/// [Services] wired from the fakes. Anything given is used as it is; the rest is a fresh fake:
/// one [FakeClock] shared by the progress store and the clip player, the sample course
/// ([FakeCourseCatalog], not loaded: call `course.load()`), a clip player that knows the sample's
/// twenty clips once the course is loaded, a scripted recogniser and call with nothing scripted,
/// Mulberry32 seed 1, [FakeEntitlements] (defaulting to [Plan.courseAndCalls]), and one
/// [FakeKeyValueStore] per storage space (the same one for the same space).
Services fakeServices({
  ProgressStore? progress,
  CourseCatalog? course,
  ClipPlayer? clips,
  SpeechListener? speech,
  CallSession? call,
  AppNavigator? nav,
  Clock? clock,
  Rng? rng,
  Haptics? haptics,
  AppInfo? info,
  PictureSource? pictures,
  KeyValueStore Function(String space)? storage,
  bool reduceMotion = false,
  Entitlements? entitlements,
  ProgressStoreCollection? progressStores,
  List<CourseCatalog> availableCourses = const [],
}) {
  final clk = clock ?? FakeClock();
  final cat = course ?? FakeCourseCatalog();
  final spaces = <String, FakeKeyValueStore>{};
  return Services(
    progress: progress ?? FakeProgressStore(clock: clk, language: cat.language),
    course: cat,
    clips:
        clips ??
        FakeClipPlayer(
          clock: clk is FakeClock ? clk : null,
          lengthOf: (id) {
            final c = cat.clip(id);
            return c == null ? null : c.endMs - c.startMs;
          },
        ),
    speech: speech ?? FakeSpeechListener(),
    call: call ?? FakeCallSession(),
    nav: nav ?? FakeNavigator(),
    clock: clk,
    rng: rng ?? FakeRng(),
    haptics: haptics ?? FakeHaptics(),
    info: info ?? FakeAppInfo(),
    pictures: pictures ?? FakePictureSource(),
    storage:
        storage ?? (space) => spaces.putIfAbsent(space, FakeKeyValueStore.new),
    reduceMotion: reduceMotion,
    entitlements: entitlements ?? FakeEntitlements(),
    progressStores: progressStores,
    availableCourses: availableCourses,
  );
}
