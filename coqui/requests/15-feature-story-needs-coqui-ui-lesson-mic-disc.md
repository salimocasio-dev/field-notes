# Request: the lesson's mic disc

## What I need

A widget in `coqui_ui`, for a lesson screen's bottom zone, with the states of index.html's `#mic` (docs/hablar/01-decisiones.md,
step 3 to 7; page 09, "Mic states"):

- `LessonMicButton(state, onPressed, reduceMotion)`, `state` one of `dead`, `ready`, `listening`, `processing`, `ok`.
- 72 px, the start disc's place (16 px under it, so 40 px above the edge). dead: grey `#2B2B33`, mic `#A7A7B0`. ready: green
  `#17803F`, white mic. listening: coral `#FF5A5F`, dark mic `#2B0A0C`, a steady coral ring 5 px off with the frame's colour between,
  a second at 8 px, and two rings that spread to 1.8 times its size (1.2 s, a timer, not the voice level); the disc pulses to 1.06.
  processing: grey with three white 8 px dots pulsing (0.9 s). ok: no fill, a 3 px `#3DDC84` outline and tick. With reduced
  motion the rings and dots are still (a static ring at 1.5 times, no second ring).
- Only `ready` takes a tap. Semantics label "Micrófono" (the old page's `aria-label`), enabled only when ready.
- The mic icon is `CoquiIcons.lessonMic`, the tick `CoquiIcons.badgeCheck`: both exist.

## Why

Order 15: "the mic button and each of its states ... Built from coqui_ui widgets; a missing or mismatching widget is a request plus a
local stand-in." Page 12 section 3 lists no widget for it.

## What I am using meanwhile

`lib/src/screen/story_mic.dart` (`StoryMicButton`, `StoryMicState`): a local copy of index.html's CSS for `#mic`, drawn with
`CoquiIcon`, `CoquiColors` and `CoquiShadows`. Widget tests cover each state.

## Order and branch

Order 15, branch `lane/feature_story/15`. For the orchestrator to place in coqui_ui (order 20's lane).
