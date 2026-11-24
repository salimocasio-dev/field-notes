# coqui_platform

Audio, speech recognition, the call connection, storage, haptics. The only package with plugins or browser code.

- Kind: Flutter package.
- Replaces: the sound code in juego.js, SpeechRecognition, the ElevenLabs client, localStorage, vibrate.
- One package is one lane. Branch: `lane/coqui_platform/<order number>`.
- Work orders: 18 and 19.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts, plugins.
- Coquí packages: `coqui_contracts`.
- Third party: `just_audio` ^0.10.6, `shared_preferences` ^2.5.6, `speech_to_text` ^7.5.0, `web` ^1.1.2.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK).
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/coqui_platform.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- After order 18 it gives `createClipPlayer`, `createSpeechListener`, `openStorage` (`CoquiStorage`: `progress` and `space(name)`), `createHaptics`, `createAppInfo`, and the build settings `coquiBuild`, `coquiCallsAllowed`, `iosAudioSessionType`. Order 19 added `createCallSession` (`CallStub`, `CallStubScript`, `elevenLabsClientUrl`); N2.5 takes the call agent id from `CallBrief.agentId`. All browser code stays behind a conditional import (`src/web/`); the plugins are in `src/io/`.
- Order 19b: `CallSession.start` throws only the contract's `CallStartError` (`CallStartFailure.microphone` when the client's error name and message match llamada.js's microphone test, `library` when the voice library did not load, `failed` otherwise, `unavailable` in a phone build or with calls off); its text stays `<name>: <message>`.
- Order 19b: the call suspends the shared sound context at start (llamada.js's `AC.suspend()`) and resumes it once when the call is over (its `Ended`, a failed start, or `end()`), so story audio works after a call without a reload; a phone build suspends nothing and resumes nothing.

## Order 18's own tools

- `node tool/juego_sonido.mjs`: juego.js's sound code run in node on a recording AudioContext; writes `test/fixtures/juego_sonido.json` (byte-identical on a re-run).
- `node tool/llamada_stub.mjs`: llamada.js run in node with `?callstub=1`; writes `assets/call_stub.json` (the stub's test lines), `test/fixtures/llamada_stub_trace.json` (what the old stub does in each llamada_check.py scenario) and `test/fixtures/llamada_stub_js.dart` (installStub's own source, the fake JS client of the Chrome tests). Byte-identical on a re-run.
- `flutter test --platform chrome`: the interop tests (`test/web_test.dart`; `flutter test` alone skips them).
- `flutter build web -t tool/dev_main.dart --no-web-resources-cdn`, then `node tool/dev_check.mjs`: the dev screen in headless Chromium, with the worktree's `historia/audio/` (gaps on the output bus, the made sounds, one recognition, storage, haptics, AppInfo, the call library's load, a stub call). `--el=<dir>` serves a local `lib.iife.js` of `@elevenlabs/client@1.25.0` (from the npm package) in place of the CDN, which is blocked from the build machine.

## Run and test it alone

```
cd coqui/packages/core/coqui_platform
flutter test
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 03-requirements, "Lessons":

- "I hear a robot voice and a script that repeats words. I told you a conversation." — rejected a script that plays lines and has him repeat words; rejected the phone's robot voice.

From 03-requirements, "The five plan decisions: all settled by him on Nov 13":

- 3. Saying a line back to Danny: approved. His objection to the earlier build was: "you had me repeating to no one, to myself, unheard by anyone or even the app. clicking 'i said it' which the app couldnt do anything with that information anyway." So: anything he says must be HEARD by the app or by Danny. Never a self-report button.

From 03-requirements, "What the app is":

- "Recorded listening for the bulk of the hours, live calls for speaking." (Live calls cost about $6.50/hour.)

From 03-requirements, "Audio and voice (Nov 13)":

- "Okay - we'll go recorded". The audio is made once and saved as files (on Azure). It is not generated on demand each time a line plays.

From 09-ui-plan, "What the doc says, in short":

- Speaking: a big mic in the bottom centre with clear states (idle, listening with a live wave, processing within 200 ms, system speaking in another colour); reply within about 0.6 to 1 s; pitch-contour feedback for intonation.
- Haptics: short crisp ticks on taps, a richer pattern on unlocking a place, never long buzzes. Synced with sound and visuals.
