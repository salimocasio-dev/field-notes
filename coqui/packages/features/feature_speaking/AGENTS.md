# feature_speaking

Hablar: the call with Danny, the voice test.

- Kind: Flutter package.
- Replaces: llamada.js, habla-prueba.html, the Hablar tab.
- One package is one lane. Branch: `lane/feature_speaking/<order number>`.
- Work orders: 24.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts, ui.
- Coquí packages: `coqui_contracts`, `coqui_ui`.
- Third party: `material_ui` ^1.11.1.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK), and `coqui_testing` (the fakes).
- `coqui_testing` goes under `dev_dependencies` only. Tests and `tool/` import it. Nothing under `lib/` does.
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/feature_speaking.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- The file exports `SpeakingModule`, a `FeatureModule` (boundary rule 4), and, with `show`, the four types the shell builds `SpeakingModule(voiceTest:)` from: `VoiceTestContent`, `VoiceLine`, `VoiceTarget`, `VoiceTestLabels`. Since order 24 it is the real one: the tab `speak` (Hablar), `CallRoute` (the call with Danny) and `VoiceTestRoute`. The dev entry is `tool/dev_main.dart`: `flutter run -d chrome -t tool/dev_main.dart`; its address parameters are listed at the head of `test/support/dev_app.dart`; `web/` is there for it.
- Two things v=39 does not settle are given to the module by whoever builds it (`voiceTest`, `voiceTestEntry`; see `coqui/requests/24-feature-speaking-needs-coqui-contracts-voice-test-lines.md`). The line on a call card when `call.available` is false is decided: "Calls with Danny open later." (`CallTexts.callsLater`); the module's `callsLater` overrides it. The voice test is reached only by its route. The Hablar tab asks `call.available` once for the open cards, and keeps an answer of false for as long as the tab lives: each read starts another try at loading the call library, and the tab is built again at every change of the progress. A tab made again asks again; the call screen's own start button loads the library again at each tap.
- `tool/shots.mjs` takes each reference state on both phones and pairs it with its reference picture; `tool/llamada_expected.mjs` runs the old call code to give the expected values of `test/llamada_expected_test.dart`, and `tool/llamada_layout.mjs` the old page's boxes for `test/call_layout_test.dart` (both re-run with `--check`); `tool/make_seeds.dart` and `tool/make_fixtures.dart` make `test/support/speaking_seeds.dart` and `test/support/fixtures/course_fixture.dart`.

## Run and test it alone

```
cd coqui/packages/features/feature_speaking
flutter test
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

A dev entry that starts the feature on the fakes comes with order 02. It lives in `tool/dev_main.dart`, not in `lib/` (`lib/` may not import `coqui_testing`): `flutter run -d chrome -t tool/dev_main.dart` in `coqui/packages/features/feature_speaking`. Page 12, section 7 says `lib/dev_main.dart`; the orchestrator changed that on Nov 19, 2026.

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 03-requirements, "What the app is":

- "Recorded listening for the bulk of the hours, live calls for speaking." (Live calls cost about $6.50/hour.)

From 03-requirements, "Lessons":

- Danny (the voice): slow and deliberate, plain, A1/A2 vocabulary, not flamboyant, does not talk back a lot after each answer, NO pet names ("mi amor", "nene").

From 03-requirements, "The five plan decisions: all settled by him on Nov 13":

- 3. Saying a line back to Danny: approved. His objection to the earlier build was: "you had me repeating to no one, to myself, unheard by anyone or even the app. clicking 'i said it' which the app couldnt do anything with that information anyway." So: anything he says must be HEARD by the app or by Danny. Never a self-report button.

From 03-requirements, "Speaking inside the stories (Nov 16)":

- Asked when the research says to add speaking: per word, 2 to 3 days after he first hears it. His conclusion: "So basically the design is fine. You speak to Danny after finishing a story. Except right now we should probably put some speaking prompts in the next stories that use the previously learned vocabulary".
- So: the next stories carry speaking prompts with words learned in earlier scenes, heard by the app. (Danny's call opens after all of a place's stories, not after each one.)

From 09-ui-plan, "What the doc says, in short":

- Speaking: a big mic in the bottom centre with clear states (idle, listening with a live wave, processing within 200 ms, system speaking in another colour); reply within about 0.6 to 1 s; pitch-contour feedback for intonation.

From 09-ui-plan, "Call screen (v=35, Nov 16)":

- Built from historia/notas/llamada-decisiones-1.md (code: historia/llamada.js). Only La casa has a call.
- Hablar: one "Call Danny" card for each place, in place order. La casa's opens once all 11 of its stories are played (stories the level check skipped count). Open: "Call Danny", "La casa · about 5 min", a green 48 px call disc. Locked: grey, "Opens when you finish <place>".
- The call is a full-screen lesson screen on calm dark grey #1B1B1F, the tab bar hidden. Top bar: the close X (48 px) at the left, the timer (mm:ss, 12 px) at the right.
- Middle: the picture Danny shows (starts as the house; whole-number scaled, 16 px margins), under it Danny's last line (18 px, white, two lines at most), under that what the app heard the learner say (16 px, #9AD5A8).
- Bottom third: the mic disc (72 px) with its state label, and an outline "Help" button (48 px, sends "(ayuda)").
- Mic states: Start call (green disc, phone icon); Calling… (the disc pulses); Danny (blue #3B5BDB rings spreading from the disc); Your turn (a green ring whose thickness follows the microphone level); One moment (three pulsing dots, once he has spoken and been quiet for 0.6 s, until Danny speaks). Every change shows within 200 ms of its cause.
- The end: the X, the 7-minute limit, or Danny ending it. A summary on the same layout as a lesson end: "Call done", "N min · M words said", the words as small chips, a blue "Back to Hablar" button. Everything stops (session, timers, sound lock) on every way out, and the tab bar comes back.
- Errors are one plain line and the X: "The microphone is off. Allow it in your browser to call." / "The call did not start. Check your connection and try again."
- Landscape (844x390): the picture at the left, the lines and the mic at the right. Small phone (360x640): the picture scales down by whole numbers.
- Checked with the stub (?callstub=1, page 05): states, sizes, colours and layout at 390x844, 360x640 and 844x390.
