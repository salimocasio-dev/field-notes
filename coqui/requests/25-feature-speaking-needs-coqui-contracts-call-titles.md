# Request: Call titles, multiple calls per place, and entitlements hook

## What I need

1. In `coqui_contracts` (`lib/src/course.dart`):
   - Add `id` (`String`), `title` (`String`, beginner-readable Puerto Rican Spanish), `jobEn` (`String`, one-line plain English job), and `isMain` (`bool`) to `CallBrief`.
   - Make `photo` (`String?`) nullable on `CallBrief` so a call with no drawn pixel-art asset yet renders no picture instead of a story screenshot.
   - Add `List<CallBrief> callsFor(String placeId)` to `CourseCatalog` (keeping `CallBrief? callFor(String placeId)` returning the main call for backward compatibility).
2. In `coqui_contracts` (`lib/src/routes.dart`):
   - Allow `CallRoute(this.placeId, {this.callId})` so Hablar can launch either a place's main call or one of its smaller calls.
3. In `coqui_contracts` (`lib/src/progress.dart` and `lib/src/platform.dart`):
   - Add `bool callDone(String callId)` (or `Set<String> get completedCalls`) to `ProgressStore` so Hablar can mark completed calls on the map journey and retire the first-time "Practice · no fail" hint after the first completed call.
   - Add an `Entitlements` interface on `Services` (e.g., `bool get liveCalls`) for the top subscription tier gate.
4. In `coqui_content`:
   - Move the 31 reviewed calls (10 main job calls + 21 smaller calls with Puerto Rican Spanish titles and one-line English jobs) into course data.

## Why

The Calls (Hablar) build brief (sections 4, 7, 8, and 10, settled Nov 22, 2026) requires:
- Every call to have a short beginner-readable Spanish title and a plain English job line underneath instead of "Call Danny".
- Each of the 10 places to have its main job call plus 2–3 smaller calls, each with its own title.
- No picture shown until an original pixel-art asset is drawn for that call.
- A clear Entitlements hook for the top subscription tier.

## What I am using meanwhile

- Local reviewed catalog in `feature_speaking/lib/src/call_catalog.dart` mapping all 10 place IDs (`casa`, `parque`, `cocina`, `colmado`, `calle`, `plaza`, `playa`, `fonda`, `casa2`, `fuerte`) to their main + 2–3 smaller `HablarCallSpec` entries (all 31 calls checked by independent Clarity/UX and Puerto Rican Spanish reviewers, with `pixelAsset: null` until drawn).
- Local `CallEntitlement` hook in `feature_speaking/lib/src/entitlements_hook.dart` passed optionally into `SpeakingModule` (defaulting to unlocked on dev/fake builds).
- Local `completedCallIds` optional set passed into `HablarTab` / `hablarSnapshot` until `ProgressStore` tracks completed calls.

## Order and branch

- Order: 25 (Hablar redesign & call titles)
- Branch: `lane/feature_speaking/25`

## Status

- Done in N2.1 (`#84`/`#123`): `Entitlements`, `AllowAllEntitlements`, `CallBrief.agentId`.
- Done in `#5` (`story/5`): `CallBrief` (`id`, `title`, `jobEn`, `isMain`, nullable `photo`), `CallsCatalog` + `CourseCalls.callsFor(placeId)`, `CallRoute(placeId, {callId})`, `CallProgressStore` + `CallProgress.callDone(callId)`.
- Remaining in other lanes:
  - `coqui_ui`: wire `Entitlements entitlements = const AllowAllEntitlements()` into `Services` (see `5-coqui-contracts-needs-coqui-ui-services-entitlements.md`).
  - `coqui_content` (`#6`): implement `CallsCatalog` and move the 31 reviewed calls into course data.
  - `coqui_progress` (`#7`): implement `CallProgressStore` (`callDone(callId)`).
  - `coqui_testing`: implement `CallsCatalog` on `FakeCourseCatalog` (multiple calls per place, optional `photo: null`) and `CallProgressStore` on `FakeProgressStore` (seeding / querying `callDone(callId)`).
