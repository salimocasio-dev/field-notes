# Request: Story playback checks (`?txt=`, unconverted scenes, silent preview, end screen) and stable keys in feature_story

## What I need

In `coqui/packages/features/feature_story/`:

1. Expose stable widget keys on `StoryScreen`'s shell-visible controls and states:
   - Close button (`Key('story-close-button')`)
   - End-screen primary/secondary actions (e.g. `Key('story-end-primary')`, `Key('story-end-replay')`, `Key('story-end-map')`)
   - Unconverted-scene fallback view and return button (e.g. `Key('story-unconverted')`, `Key('story-unconverted-back')`)
   - Keep `Key('story-start-disc')` as a stable contract key.
2. Own the detailed story playback assertions previously in `coqui/app/test/story_test.dart` and `coqui/app/test/previa_test.dart` inside `feature_story/test/`:
   - `?txt=con|tras|no` caption timing checks
   - Unconverted-scene fallback wording and back-to-map behaviour across course stories/routines
   - Second-play completion and end-screen "Play again" / "Next story" / "Map" flows
   - Silent playback of stories containing unrecorded clips (preview overlay stories).

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes story-internal playback loops, type-name probes (`byTypeName('StoryScreen')`, `StoryHeader`, `StoryCloseButton`), and quoted story copy (`'Play again'`, `'Next story'`, `'This story is not in the new app yet.'`, `'Back to the map'`) from `coqui/app/test/`.

## What I am using meanwhile

`coqui/app/test/` verifies `StoryRoute` mounting, tab-bar hiding, RTL directionality, `coquiModules` forwarding `switches.txt`/`switches.perf`, `storyScenes` throwing `UnimplementedError` for unknown scenes, and a single key-driven real-catalog smoke test (`real_catalog_smoke_test.dart`) using `ShellKeys.route(...)`, `Key('story-start-disc')`, `PixelView`, and `handlePopRoute()`.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
