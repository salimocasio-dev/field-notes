import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:material_ui/material_ui.dart';

/// A scene in a given state, seen through a camera: a review pair's side, a
/// word's picture. scene: the scene id; set: the keys a pair file's `set` writes
/// into the scene's world; cam: the view, as the pair file gives it.
class PictureRef {
  const PictureRef({
    required this.scene,
    this.set = const {},
    required this.cam,
  });

  /// One side of a review pair, drawn by [PictureSpec.scene] or else the pair's own scene.
  factory PictureRef.of(ReviewPair pair, PictureSpec side) =>
      PictureRef(scene: side.scene ?? pair.scene, set: side.set, cam: side.cam);

  final String scene;
  final Map<String, dynamic> set;
  final List<num> cam;

  @override
  String toString() => 'PictureRef($scene, $set, $cam)';
}

/// Where features get pictures of scenes. They never import a scene.
abstract interface class PictureSource {
  /// A scene in a given state, the 196-wide window at cam (section 5, "The camera"), cropped to height.
  Widget of(
    PictureRef ref, {
    int height = 104,
    int? scale,
    bool animated = false,
  });
  Future<void> warm(Iterable<PictureRef> refs); // bake ahead
}

/// Everything a feature is given. The shell builds one from the real packages;
/// tests and dev entries build one from the fakes in coqui_testing.
class Services {
  const Services({
    required this.progress,
    required this.course,
    required this.clips,
    required this.speech,
    required this.call,
    required this.nav,
    required this.clock,
    required this.rng,
    required this.haptics,
    required this.info,
    required this.pictures,
    required this.storage,
    this.reduceMotion = false,
  });

  final ProgressStore progress;
  final CourseCatalog course;
  final ClipPlayer clips;
  final SpeechListener speech;
  final CallSession call;
  final AppNavigator nav;
  final Clock clock;
  final Rng rng;
  final Haptics haptics;
  final AppInfo info;
  final PictureSource pictures;
  final KeyValueStore Function(String space) storage;
  final bool reduceMotion;
}

/// A feature's tab in the tab bar.
class FeatureTab {
  const FeatureTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

/// What a feature exports: its one module. The shell holds the only list of modules.
abstract interface class FeatureModule {
  String get id;
  FeatureTab? tab(Services s);
  Widget? screenFor(AppRoute route, Services s); // null: not mine
}
