/// What the play screen shows for a story whose scene is not converted yet: one line and one button, in the middle of the
/// lesson frame, and nothing else but its X.
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The line the screen shows when the story's scene is not converted yet.
const String storyNotReadyLine = 'This story is not in the new app yet.';

/// The line the screen shows when the story needs a newer app (unsupported
/// `minApp` or an act the scene does not have).
const String storyNeedsUpdateLine = 'Update the app to play this story';

/// The button under [storyNotReadyLine] / [storyNeedsUpdateLine]: it does what
/// the X does.
const String storyNotReadyLabel = 'Back to the map';

/// The lesson frame with its X, [line] and a [storyNotReadyLabel] button (blue:
/// the main action, as the end of a story's "Map") centred in it. No dashes, no
/// sound button, no picture. [onClose] is what the X does, and the button too.
class StoryNotReady extends StatelessWidget {
  const StoryNotReady({
    super.key,
    required this.onClose,
    this.line = storyNotReadyLine,
  });

  final VoidCallback onClose;
  final String line;

  @override
  Widget build(BuildContext context) => LessonFrame(
    onClose: onClose,
    showSound: false,
    overlay: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CoquiMetrics.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              line,
              textAlign: TextAlign.center,
              style: CoquiText.lessonCaption,
            ),
            const SizedBox(height: CoquiMetrics.s24),
            LessonButton(
              label: storyNotReadyLabel,
              kind: LessonButtonKind.blue,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    ),
  );
}
