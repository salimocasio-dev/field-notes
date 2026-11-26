# Request: Speaking call & voice-test playback checks and stable keys in feature_speaking

## What I need

In `coqui/packages/features/feature_speaking/`:

1. Expose stable widget keys on `CallScreen`, `VoiceTestScreen`, and `HablarTab` interactive controls:
   - Call mic stage / start control (e.g. `Key('call-mic-stage')`) and end-screen back button (`Key('call-end-back')`)
   - Voice test mic button (`Key('voice-test-mic')`) and line/progress indicators (`Key('voice-test-screen')`)
   - Place stop chips in `HablarTab` (e.g. `Key('speak-place-<placeId>')`) and "Coming soon" card (`Key('speak-coming-soon')`).
2. Own end-to-end call playback (`?callstub=1` mouth answer persistence and return to Speak tab), locked/coming-soon place card copy, and VoiceTestScreen line/speech-recognition checks previously in `coqui/app/test/lessons_test.dart`, `tabs_test.dart`, and `previa_test.dart` inside `feature_speaking/test/`.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes `byTypeName('CallScreen')`, `byTypeName('CallMicStage')`, `byTypeName('VoiceTestScreen')`, `byTypeName('HablarTab')`, and quoted speaking copy (`'Back to Hablar'`, `'Call Danny'`, `'Coming soon · El colmado'`) from `coqui/app/test/`.

## What I am using meanwhile

`coqui/app/test/` verifies `ShellKeys.tab('speak')`, `Key('speak-next-call-card')`, `Key('speak-call-disc')`, `ShellKeys.route(const CallRoute('casa'))`, `ValueKey('call-casa-')`, `ShellKeys.route(const VoiceTestRoute())`, and `VoiceTestData` / `voiceTestContent` unit checks in `parts_test.dart`.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
