/// The end of a story: its title under the last picture and the Noche action buttons.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:material_ui/material_ui.dart';

/// The story's title at the end, start-aligned under the last picture in the
/// course's language and script font. Takes no touch (`#fin{pointer-events:none}`).
class StoryEndTitle extends StatelessWidget {
  const StoryEndTitle({super.key, required this.title, this.language});

  final String title;
  final Language? language;

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();
    final lang = language ?? Language.spanish;
    final titleStyle = NocheType.forScript(
      NocheType.lessonLine,
      lang.script,
    ).copyWith(color: NocheColors.text);

    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        child: Text(
          title,
          textAlign: TextAlign.start,
          textDirection: lang.textDirection,
          locale: lang.locale,
          style: titleStyle,
        ),
      ),
    );
  }
}

/// The Noche buttons of the end screen, from [StoryFoot]: "Play again" (outline)
/// with the outline "Map" beside it when a next story waits, then the ONE orange
/// primary action ("Next story" or "Map", mutually exclusive).
List<Widget> storyEndButtons({
  required StoryFoot foot,
  required VoidCallback onAgain,
  required VoidCallback onNext,
  required VoidCallback onMap,
}) {
  final showOutlineMap = foot.map || (foot.next && foot.home);
  return [
    if (foot.again && showOutlineMap)
      Row(
        children: [
          Expanded(
            child: NocheOutlineButton(label: 'Play again', onPressed: onAgain),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: NocheOutlineButton(label: 'Map', onPressed: onMap),
          ),
        ],
      )
    else if (foot.again)
      NocheOutlineButton(label: 'Play again', onPressed: onAgain)
    else if (showOutlineMap)
      NocheOutlineButton(label: 'Map', onPressed: onMap),
    if (foot.next)
      NochePrimaryButton(label: 'Next story', onPressed: onNext)
    else if (foot.home)
      NochePrimaryButton(label: 'Map', onPressed: onMap),
  ];
}
