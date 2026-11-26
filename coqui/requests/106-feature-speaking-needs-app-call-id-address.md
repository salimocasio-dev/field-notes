# Request: Preserve CallRoute.callId in app URL addresses

## What I need

Update `coqui/app/lib/src/addresses.dart` so `CallRoute.callId` round-trips through `addressOf` and `routeOf`:

1. `addressOf(CallRoute(:final placeId, :final callId))`:
   - When `callId == null`: keep `'/llamada/$placeId'`.
   - When `callId != null`: encode `callId` (for example `'/llamada/$placeId?call=$callId'`).
2. `routeOf(Uri address)`:
   - For `'/llamada/<placeId>'`: read optional `q['call']` (validating identifier characters `[a-z0-9][a-z0-9_-]*`) and pass `CallRoute(id, callId: callId)`.

## Why

Story N4.6 ("Speak", issue #106) and #5 (`CallRoute(placeId, {callId})`) enable places with structured multi-call course data (`CallsCatalog.callsFor`) to launch individual short calls as well as the main call. `SpeakingModule.screenFor`, `CallScreen`, and `CallController` now resolve the exact `CallBrief` by `callId` (returning null instead of silently falling back to the main call when `callId` is unknown), but `coqui/app/lib/src/addresses.dart:43` currently drops `callId` during shell routing. Editing `coqui/app/` from `lane/feature_speaking/106` is disallowed by `check_boundaries.dart`.

## What I am using meanwhile

`SpeakingModule.screenFor`, `CallScreen`, `CallController`, and `HablarTab` preserve and resolve `CallRoute.callId` directly inside `feature_speaking` (verified by unit and widget tests). Smaller calls remain gated behind `SpeakingModule(shortCallsEnabled: false)` by default so tapping a smaller call can never accidentally open the place's main call while `addresses.dart` drops `callId`. Once `addresses.dart` preserves `callId`, pass `shortCallsEnabled: true` on `SpeakingModule` (or flip the default) to enable short calls everywhere with no screen rewrite.

## Order and branch

- Order: 106 (N4.6 Speak)
- Branch: `lane/feature_speaking/106`
