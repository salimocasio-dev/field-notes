# feature_story

The story game: the step runner, the play screen, Listen mode, speaking turns.

- Kind: Flutter package.
- Replaces: juego.js, index.html.
- One package is one lane. Branch: `lane/feature_story/<order number>`.
- Work orders: 15.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts, ui, pixel, scenes.
- Coquí packages: `coqui_contracts`, `coqui_pixel`, `coqui_scenes`, `coqui_ui`.
- Third party: `material_ui` ^1.11.1.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK), and `coqui_testing` (the fakes).
- `coqui_testing` goes under `dev_dependencies` only. Tests and `tool/` import it. Nothing under `lib/` does.
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/feature_story.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Since order 02 the file exports a placeholder module (its screen says the feature's name), until this feature's order builds the real one. The dev entry is `tool/dev_main.dart`: `flutter run -d chrome -t tool/dev_main.dart`; `web/` is there for it.
- Later it holds one thing: its module, a `FeatureModule` (boundary rule 4). It also implements `SceneHost` for play.

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

A dev entry that starts the feature on the fakes comes with order 02. It lives in `tool/dev_main.dart`, not in `lib/` (`lib/` may not import `coqui_testing`): `flutter run -d chrome -t tool/dev_main.dart` in `coqui/packages/features/feature_story`. Page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026.

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
