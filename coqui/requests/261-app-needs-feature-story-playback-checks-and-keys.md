# Request: Story playback checks (`?txt=`, unconverted scenes, silent preview, end screen) and stable keys in feature_story

## What I need

In `coqui/packages/features/feature_story/`:

### Already present on `main` (document as standing rule in `feature_story/AGENTS.md`)

Keep this existing key stable as a shell/integration test contract:

- `Key('story-start-disc')` — `coqui/packages/features/feature_story/lib/src/screen/story_screen.dart:392`

### New keys requested

- Close button (`Key('story-close-button')`)
- End-screen primary/secondary actions (`Key('story-end-primary')`, `Key('story-end-replay')`, `Key('story-end-map')`)
- Unconverted-scene fallback view and return button (`Key('story-unconverted')`, `Key('story-unconverted-back')`).

### Already-merged feature test coverage on `main` (zero coverage loss)

The story playback behaviors removed from `coqui/app/test/story_test.dart` and `coqui/app/test/previa_test.dart` are already covered inside `feature_story/test/`:

- `coqui/packages/features/feature_story/test/screen_test.dart:54-59,187` — story playback, end-screen actions, and progression
- `coqui/packages/features/feature_story/test/lines_test.dart:104-185` — `TxtMode.con` / `TxtMode.tras` / `TxtMode.no` caption timing
- `coqui/packages/features/feature_story/test/not_converted_test.dart:14` — unconverted-scene fallback screen and return-to-map behavior.

Follow-up (optional): add a unit test in `feature_story/test/` explicitly asserting silent playback when a story has an unrecorded clip (matching the preview overlay story behavior).

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes story-internal playback loops, type-name probes (`byTypeName('StoryScreen')`, `StoryHeader`, `StoryCloseButton`), and quoted story copy (`'Play again'`, `'Next story'`, `'This story is not in the new app yet.'`, `'Back to the map'`) from `coqui/app/test/`.

## What I am using meanwhile

`coqui/app/test/` verifies `StoryRoute` mounting, tab-bar hiding, RTL directionality, `coquiModules` forwarding `switches.txt`/`switches.perf`, `storyScenes` throwing `UnimplementedError` for unknown scenes, and a single key-driven real-catalog smoke test (`real_catalog_smoke_test.dart`) using `ShellKeys.route(...)`, `Key('story-start-disc')`, `PixelView`, and `handlePopRoute()`.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
