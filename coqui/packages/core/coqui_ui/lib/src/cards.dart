/// Framed picture container still used by `feature_speaking` (`call_screen.dart`).
library;

import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// A picture in its frame: rounded corners ([radius] 8, or 12 for a large
/// picture) on the `#222` background that shows behind a picture. Whole-number
/// scaled pictures go inside it.
class PictureFrame extends StatelessWidget {
  const PictureFrame({
    super.key,
    required this.child,
    this.radius = CoquiMetrics.radiusPicture,
    this.background = CoquiColors.pictureBack,
  });

  final Widget child;
  final double radius;
  final Color background;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: ColoredBox(color: background, child: child),
  );
}
