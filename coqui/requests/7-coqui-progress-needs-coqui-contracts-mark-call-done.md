# Request: Expose markCallDone on CallProgressStore and CallProgress

## What I need

In `coqui_contracts` (`lib/src/progress.dart`), add the write counterpart to `bool callDone(String callId)`:

1. Add `void markCallDone(String callId);` to `CallProgressStore` (matching `PalabrasStore.markCallDone(String callId)`).
2. Add `void markCallDone(String callId)` to `extension CallProgress on ProgressStore`, delegating to `(this as CallProgressStore).markCallDone(callId)` when implemented and acting as a no-op otherwise.

(And in `coqui_testing`, implement `CallProgressStore` — both `callDone` and `markCallDone` — on `FakeProgressStore` alongside request 25.)

## Why

Issue #7 implements `CallProgressStore` (`callDone(String callId)`) and persists completed calls in `PalabrasStore` via `markCallDone(String callId)` under per-language `db.llamadas`. Downstream feature packages such as `feature_speaking` (`CallController`) only depend on `coqui_contracts`, not `coqui_progress`, so they need `markCallDone(String callId)` on `CallProgressStore` / `CallProgress` to record finished calls through `ProgressStore`.

## What I am using meanwhile

- `PalabrasStore` implements `CallProgressStore` (`@override bool callDone(String callId)`) and directly exposes `void markCallDone(String callId)` as a public method without modifying `coqui_contracts`. Once `markCallDone` lands on `CallProgressStore`, `PalabrasStore` already matches the exact signature.

## Order and branch

- Order: 7 (Remember finished calls in progress)
- Branch: `lane/coqui_progress/7`
