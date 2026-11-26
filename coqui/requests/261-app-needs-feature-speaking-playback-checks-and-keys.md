# Request: Speaking call & voice-test playback checks and stable keys in feature_speaking

## What I need

In `coqui/packages/features/feature_speaking/`:

### Already present on `main` (document as standing rule in `feature_speaking/AGENTS.md`)

Keep these existing keys stable as shell/integration test contracts:

- `Key('speak-next-call-card')` — `coqui/packages/features/feature_speaking/lib/src/hablar_tab.dart:357`
- `Key('speak-call-disc')` — `coqui/packages/features/feature_speaking/lib/src/hablar_tab.dart:523`

### New keys requested

- Clean root key on `CallScreen` (`Key('call-screen')`) rather than relying on the internal `ValueKey('call-$placeId-${callId ?? ''}')` composite key
- Call mic stage / start control (`Key('call-mic-stage')`) and end-screen back button (`Key('call-end-back')`)
- Voice test root (`Key('voice-test-screen')`) and mic button (`Key('voice-test-mic')`)
- Place stop chips in `HablarTab` (`Key('speak-place-<placeId>')`) and "Coming soon" card (`Key('speak-coming-soon')`).

### Already-merged feature test coverage on `main` (zero coverage loss)

The speaking call and voice-test assertions removed from `coqui/app/test/lessons_test.dart`, `tabs_test.dart`, and `previa_test.dart` are already covered inside `feature_speaking/test/`:

- `coqui/packages/features/feature_speaking/test/llamada_expected_test.dart` — scripted call flow & turn expectations
- `coqui/packages/features/feature_speaking/test/call_screen_test.dart:315-335` — `CallScreen` interaction & end-screen return
- `coqui/packages/features/feature_speaking/test/arabic_language_test.dart:268` — `mouth` answer recording & multi-language call flow
- `coqui/packages/features/feature_speaking/test/voice_test_test.dart:399-401` — `VoiceTestScreen` line recognition (`hola abuela` rendered in `CoquiColors.heard`).

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes `byTypeName('CallScreen')`, `byTypeName('CallMicStage')`, `byTypeName('VoiceTestScreen')`, `byTypeName('HablarTab')`, and quoted speaking copy (`'Back to Hablar'`, `'Call Danny'`, `'Coming soon · El colmado'`) from `coqui/app/test/`.

## What I am using meanwhile

`coqui/app/test/` verifies `ShellKeys.tab('speak')`, `Key('speak-next-call-card')`, `Key('speak-call-disc')`, `ShellKeys.route(const CallRoute('casa'))`, `ShellKeys.route(const VoiceTestRoute())`, and `VoiceTestData` / `voiceTestContent` unit checks in `parts_test.dart`.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
