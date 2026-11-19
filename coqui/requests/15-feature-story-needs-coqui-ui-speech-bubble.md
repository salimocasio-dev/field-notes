# Request: the story's speech bubble

## What I need

A widget in `coqui_ui` for the speech bubble that stands over a lesson picture (index.html `#bub`): a white box with a 3 px
`#2A1810` border, 12 px corners, 5 / 11 / 6 px padding, text 800 weight 18 px on 1.2, centred, `#2A1810`, with a tail; the tail
points down from the middle of the bottom edge at a given distance from its left, or from the side (the bubble beside the frog).
It holds words, or a mic icon (28 px, coral `#D93025` and pulsing when listened to), three dots, or a green tick and words (a
speaking turn). Minimum 56 by 44 when it holds a turn's mic or tick.

## Why

Order 15: "captions and speech bubbles as Flutter text over [the picture] where the old page uses HTML text". Not in coqui_ui.

## What I am using meanwhile

`lib/src/screen/story_bubble.dart` (`StoryBubbleBody`, `StoryBubbleLayer`): the CSS of `#bub` as widgets, placed by
`lib/src/runner/bubble_place.dart` (juego.js `placeBub` as a function of numbers, tested against the old formulas run in node).

## Order and branch

Order 15, branch `lane/feature_story/15`. For the orchestrator to place in coqui_ui.
