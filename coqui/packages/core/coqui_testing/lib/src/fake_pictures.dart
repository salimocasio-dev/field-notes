import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A saved picture for a ref, or null to show the grey box. Order 06's frames from `coqui/ref/` plug in here.
typedef FakeFrame = Widget? Function(
  PictureRef ref, {
  required int height,
  int? scale,
});

/// Pictures of scenes, for tests and dev entries, without any scene.
///
/// What it does: [of] shows a grey box the size the real one would be (196 wide, [of]'s height, times `scale`,
/// 1 when none), labelled with the scene and the camera; or, when [frames] gives one, that saved frame instead.
/// Callers do not change when the frames come. It records every ref shown and warmed.
///
/// What it does not do: no drawing of a scene, no state (`set`) shown, no animation.
class FakePictureSource implements PictureSource {
  FakePictureSource({this.frames});

  /// Saved frames, when there are any.
  final FakeFrame? frames;

  /// Every ref [of] was asked for, in order.
  final List<PictureRef> shown = [];

  /// Every ref [warm] was given, in order.
  final List<PictureRef> warmed = [];

  @override
  Widget of(
    PictureRef ref, {
    int height = 104,
    int? scale,
    bool animated = false,
  }) {
    shown.add(ref);
    final saved = frames?.call(ref, height: height, scale: scale);
    if (saved != null) return saved;
    final k = scale ?? 1;
    return SizedBox(
      width: 196.0 * k,
      height: height.toDouble() * k,
      child: ColoredBox(
        color: const Color(0xFF9E9E9E),
        child: Center(
          child: Text(
            '${ref.scene} ${ref.cam.join(',')}',
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Color(0xFF212121), fontSize: 10),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> warm(Iterable<PictureRef> refs) async => warmed.addAll(refs);
}
