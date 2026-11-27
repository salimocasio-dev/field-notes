# feature_story

The story game: the step runner, the play screen, Listen mode, speaking turns.

- Kind: Flutter package.
- Replaces: `juego.js`, `index.html`.
- One package is one lane. Branch: `lane/feature_story/<order number>`.
- The runbook is `../../../AGENTS.md`. Read it first.
- This file holds standing rules only. What a ticket did goes in its PR body and its issue.

## May depend on

- The plan's row: contracts, ui, pixel, scenes.
- Coquí packages: `coqui_contracts`, `coqui_pixel`, `coqui_scenes`, `coqui_ui`.
- Third party: `material_ui` ^1.11.1 (and `collection`, allowed anywhere).
- Dev only: `flutter_lints`, `flutter_test` (from the SDK), and `coqui_testing` (the fakes).
- `coqui_testing` goes under `dev_dependencies` only. Tests and `tool/` import it. Nothing under `lib/` does.
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/feature_story.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- It exports:
  - `StoryModule({scenes, txt, showPerf})`: a `FeatureModule` with no tab that answers `StoryRoute` (played or, with `listen`, told straight through).
    - `scenes` defaults to `registryScenes` (`loadScene` from `coqui_scenes`). Scenes that throw `UnimplementedError('not converted yet')` render `StoryNotReady` inside the lesson frame (centred "This story is not in the new app yet." and a "Back to the map" button, plus the close X). Any other load failure shows the lesson frame with its X and reports the error.
    - `txt` (`TxtMode`: `con`, `tras`, `no`) controls when captions appear (matching `?txt=` / `juego.js` `TXT`).
    - `showPerf` (`StoryScreen.showPerf`, off by default) shows a small bake-time chip under the top bar for `?perf=1`.
  - `TxtMode` (exported with `show`) for the shell's `?txt=` flag.
  - `play` (exported with `show`) for `coqui_story_checks` (where all per-scene play-every-path and sheet-rules checks live).
- Package layout under `lib/src/`:
  - `runner/` (pure Dart): `StoryRunner` (port of `historia/juego.js` and `SceneHost`), `StoryTimers`, `StoryView`, `bubble_place.dart`.
  - `play/` (pure Dart): `play(story, plan, draws, seed, {letters, ...})` trace runner.
  - `screen/` (Flutter): `StoryScreen` and its widgets.
- Screen wording lives in `lib/src/wording.dart` (`StoryWording`), and screen-local motion waits and hero tags live in `lib/src/motion.dart` (`StoryMotion`, the only file under `lib/` allowed to call `NocheMotion.ms`).
- The scene picture window is wrapped in `NocheWindow` with `StoryMotion.storyWindowTag(storyId)` (the story id) as its hero tag so the picture travels cleanly across map, place, and story lesson screens without changing its whole-number pixel scale.

## Stable widget keys

Keep these widget keys stable as the shell and integration test contract:

- `Key('story-start-disc')`
- `Key('story-close-button')`
- `Key('story-end-primary')`
- `Key('story-end-replay')`
- `Key('story-end-map')`
- `Key('story-unconverted')`
- `Key('story-unconverted-back')`

When the end screen's primary action itself returns to the map (listen mode or no next story/review), `Key('story-end-map')` wraps `Key('story-end-primary')` on that orange button instead of rendering a separate outline Map button.

## Runner, player, and testing rules

- **Virtual time and lifecycle:** Time is `StoryTimers` (`setTimeout`/`setInterval` on a host-driven clock). The runner never reads a real clock and never sleeps. When the app lifecycle leaves `resumed`, the screen calls `StoryRunner.holdClock` so virtual time pauses; on return, `resumeClock` subtracts elapsed wall time so there is no burst of due timers (`test/lifecycle_test.dart`).
- **Renderer separation:** The runner knows nothing of Flutter widgets. UI state flows through `StoryView` (caption, bubble, dashes, mic state, end buttons), and frames through `StoryRenderer` (`FrameRenderer` on `drawFrame` for the screen, `HeadlessRenderer` for the no-screen player).
- **Differential parity:** `play(...)` returns traces matching `coqui/ref/trazas/<story>/<plan>.json`. Any change to the runner that moves a time, sound, clip, step, or draw fails `test/differential_test.dart`. When a story file or `juego.js` changes intentionally, regenerate traces with `coqui/tool/ref/trazas/juega.mjs` and act fixtures with `tool/ref/record_acts.mjs`.
- **Scene-level story checks live in `coqui_story_checks`:** Per-scene play-every-path and sheet-rules checks belong in `coqui/packages/coqui_story_checks/`, not here. `play(letters:)` accepts an explicit per-decision plan (`r`/`w`) for those checks.
- **Unconverted-scene tests:** `test/not_converted_test.dart` and `test/screen_test.dart` use the never-converted test scene `prueba` (`test/support/test_scene.dart`) so scene ports never have to modify `feature_story` tests.
- **Speech event order:** `speech.events` records speaking turns and answers in time order (stable sort by `t`, turn before answer on ties; `test/speech_order_test.dart`).
- **Decision round replay:** When waiting at a decision, lines said since the round's `dots` step (`StoryRunner.ronda`) replay in order when more than one; a single-line round repeats its `line` (`test/round_repeat_test.dart`). Asks and eliges are unchanged.
- **Position remapping:** A set step's positions (`x`/`y` maps and `respEn`) pass through the scene's `remap` (`remapPositions`).
- **End screen "Next story":** Unlike `juego.js`, the runner shows "Next story" only when `course.meta(next) != null` so staged stories remain invisible to the app (`test/differential_test.dart`).
- **Touch pass-through:** Overlays that take no touch in the old page (`#bub`, `#fin`, `#mic[data-s=ok]`, and the `?perf=1` chip) pass pointer events through to the picture underneath (`test/touch_through_test.dart`).

## Run and test it alone

```
cd coqui/packages/features/feature_story
flutter test
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

The dev entry lives in `tool/dev_main.dart`, not in `lib/` (`lib/` may not import `coqui_testing`): `flutter run -d chrome -t tool/dev_main.dart` in `coqui/packages/features/feature_story`.

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 03-requirements, "Lessons":

- "the pictures are an aid to the listening. Not the game. It's listening and speaking" — said about an early build that was tap-only, with an "I said it" honor button. The app must actually hear him by voice. (Nov 13, his correction: he did not reject games or touch. He rejected tapping that was all there was and taught nothing, and speaking that nobody heard.)
- "I hear a robot voice and a script that repeats words. I told you a conversation." — rejected a script that plays lines and has him repeat words; rejected the phone's robot voice.
- English only so a stuck learner can navigate; never a mostly-English lesson.

From 03-requirements, "The five plan decisions: all settled by him on Nov 13":

- 1. Touch as the answer in listening: approved. "this is fine." "I didnt reject games. you didnt give me a game before, you gave me tap this thing and learn nothing." The earlier build failed "because that's ALL you did. you made me garbage. I support stuff that works." So: games are NOT ruled out. His test is whether it works and teaches.
- 3. Saying a line back to Danny: approved. His objection to the earlier build was: "you had me repeating to no one, to myself, unheard by anyone or even the app. clicking 'i said it' which the app couldnt do anything with that information anyway." So: anything he says must be HEARD by the app or by Danny. Never a self-report button.

From 03-requirements, "How a story must sound and play (Nov 13, his verdict on the first version of story 1)":

- The first version spoke in bare labels with long pauses and asked for the same touches twice ("La casa. Es la casa. Toca la casa. Sí. La casa."). His verdict: "What you gave me is beyond boring".
- His direction: "Here's how it needs to go. Something like (in Spanish): Is this Abuelas house. Look at Abuelas house. Can you touch the house? Big indicator to touch. Good job. This is the door of the house. It's closed. Where is the door? Big indicator to touch (when I touch the door it reads as wrong btw). Abuela opened the door. Hola Abuela! Abuela says hola como estas".
- So: the voice talks TO the learner in whole, natural sentences and asks real questions. Not labels. Praise is short ("¡Muy bien!"), then on. The sign for what to touch is BIG. A right touch never reads as wrong. The story moves; no repeating an ask to pad it.

From 03-requirements, "A real game with stakes (Nov 13)":

- "I want to explore the idea of making the game a real game with stakes. Responses and taps move the story forward in meaningful ways."
- "We are just on MVP so it doesn't need to be fully now, bit I want what we create to be easily scaleable."
- "Try again story 1 and 2 and 3. Reread the research. Have someone review"
- So: something can be lost in a story; what he touches and answers changes what happens; what is built for stories 1 to 3 carries over to every later story. The plan's line "No points, timers, lives or win screens" was Claude's, from a report. It no longer stands as written.

From 03-requirements, "Speaking inside the stories (Nov 16)":

- Asked when the research says to add speaking: per word, 2 to 3 days after he first hears it. His conclusion: "So basically the design is fine. You speak to Danny after finishing a story. Except right now we should probably put some speaking prompts in the next stories that use the previously learned vocabulary".
- So: the next stories carry speaking prompts with words learned in earlier scenes, heard by the app. (Danny's call opens after all of a place's stories, not after each one.)

From 03-requirements, "His instructions to the build chat (Nov 13)":

- "Why are the captions English. Everything should be in spanish." (The code was all Spanish; most likely his phone translated the page. Pages are now marked do-not-translate.) Then: "It's good. Continue". So: nothing on screen in a lesson may turn into English, by any route.

From 09-ui-plan, "What the doc says, in short":

- Lessons go full screen; the tab bar hides and comes back on exit. Learning screens are calm (white, off-white or dark grey); colour only for meaning (green right, red/orange wrong, blue/purple system and active tab).
- Speaking: a big mic in the bottom centre with clear states (idle, listening with a live wave, processing within 200 ms, system speaking in another colour); reply within about 0.6 to 1 s; pitch-contour feedback for intonation.

From 09-ui-plan, "What is built (v=34, Nov 14)":

- Lessons (story, ¿Cuál?, level check) are full screen on calm dark grey, the tab bar hidden: a top bar with a close X (works mid-play and returns to where the lesson began), a thin progress bar and the sound button; pictures whole-number scaled; the start disc in the bottom third; at a story's end its last picture stays, with the title and buttons under it.
