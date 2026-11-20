# 27: feature_words needs coqui_ui: the new Palabras parts in the shared look

## What I need

Order 27 changed the Palabras card and added three small controls. They are built inside feature_words from coqui_ui's tokens and widgets; if the orchestrator wants them shared (Biblioteca or Repaso may want the same), these would move to coqui_ui:

- `WordTile` (`feature_words/lib/src/word_tile.dart`): the word card with a top area of one height for every card of a grid (the picture at a whole scale, as wide as the card, one scale larger when the largest that fits leaves it under 3/4 of the card's width, its sides cut), the word, and the two meters in one row (`SkillDot`: a 16 px speaker or microphone icon and `SmallDots`, four 8 px dots 3 px apart). coqui_ui's `WordCard` has the picture "contain" only and the meters as two labelled rows, and its grid (`WordGrid`, `IntrinsicHeight`) cannot hold a child that measures its own width.
- `TodayTag`: a 12 px white-on-blue tag in a card's top left corner.
- `SkillKey`: the key of the two icons ("Ear: you know it when you hear it." / "Mouth: you can say it.").
- `FindButton` and `FindBox` (`find_box.dart`): a 48 px square toggle in the pills' look with a magnifying-glass icon (coqui_ui's `CoquiIcons` has none: the path is in `find_box.dart`), and a text field in the look of v=39's `input` with a clear button. coqui_ui has no text field (the AddBox stand-in already says so).
- `Pressable` exported, so a feature's own tappable card gets the shared hand cursor and pressed state (the card uses a plain `GestureDetector` meanwhile).
- `SegmentedPills` with an optional trailing widget, or a text-size limit: its labels overflow their 48 px pills at large text sizes; Palabras clamps its pills' text at 1.3 times.

## Why

Order 27: "use its components and text styles" (coqui_ui AGENTS.md); these parts are new design, not in coqui_ui yet.

## What I am using meanwhile

The local copies named above, in `feature_words/lib/src/`.

## Order and branch

Order 27, branch `lane/feature_words/27`.
