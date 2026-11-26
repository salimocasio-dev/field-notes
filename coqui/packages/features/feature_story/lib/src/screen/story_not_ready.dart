/// What the play screen shows for a story whose scene is not converted yet or
/// that requires a newer app: one line and one primary button, centred on
/// `lessonGround`, with only the close X in the header.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/screen/story_header.dart';
import 'package:material_ui/material_ui.dart';

/// The line the screen shows when the story's scene is not converted yet.
const String storyNotReadyLine = 'This story is not in the new app yet.';

/// The line the screen shows when the story needs a newer app (unsupported
/// `minApp` or an act the scene does not have).
const String storyNeedsUpdateLine = 'Update the app to play this story';

/// The button under [storyNotReadyLine] / [storyNeedsUpdateLine]: it does what
/// the X does.
const String storyNotReadyLabel = 'Back to the map';

/// Full-screen Noche `lessonGround` frame with the 64-high close header, [line],
/// and a [NochePrimaryButton] labelled [storyNotReadyLabel]. No dashes, no TXT
/// pill, no picture. [onClose] is what the X does, and the button too.
class StoryNotReady extends StatelessWidget {
  const StoryNotReady({
    super.key,
    required this.onClose,
    this.line = storyNotReadyLine,
    this.language,
  });

  final VoidCallback onClose;
  final String line;
  final Language? language;

  @override
  Widget build(BuildContext context) {
    final lang = language ?? Language.spanish;
    return ColoredBox(
      color: NocheColors.lessonGround,
      child: SafeArea(
        child: Column(
          children: [
            StoryHeader(
              onClose: onClose,
              language: lang,
              showProgress: false,
              showTxt: false,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          line,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          style: NocheType.bodyLarge.copyWith(
                            color: NocheColors.text,
                          ),
                        ),
                        const SizedBox(height: 24),
                        NochePrimaryButton(
                          label: storyNotReadyLabel,
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
