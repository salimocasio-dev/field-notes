# Request: Self-host `libsamplerate.worklet.js` in `coqui_platform`

## What I need

1. In `coqui_platform` (`lane/coqui_platform/<n>`, touching only `coqui_platform/`):
   - Vendor `@alexanderolsen/libsamplerate-js@2.1.2`'s `dist/libsamplerate.worklet.js` (and `LICENSE`) under `coqui/packages/core/coqui_platform/assets/elevenlabs/`.
   - Declare `assets/elevenlabs/libsamplerate.worklet.js` in `coqui/packages/core/coqui_platform/pubspec.yaml`.
   - Pass `libsampleratePath` in `JsConvLibrary.startSession` (`coqui/packages/core/coqui_platform/lib/src/web/el_conv.dart`) pinned to `assets/packages/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js` (with package-root dev fallback `assets/assets/elevenlabs/libsamplerate.worklet.js`, mirroring `lib.iife.js`). Note that `coqui/app/web/index.html`'s `worker-src 'self' blob:` already permits same-origin `'self'` worklets, so no CSP change is needed.
   - Remove the hardcoded `https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.2/dist/libsamplerate.worklet.js` fallback from `coqui/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js`.
2. Cross-lane handoff (do **not** edit `coqui/tool/` from `lane/coqui_platform/<n>`, which would violate boundary rule 5):
   - Because `coqui/tool/test/check_sitio_test.dart` pins `lib.iife.js`'s SHA-256 (`ec975ddc738967e53b0e37346eef5488217ff4d50968030bd1c26f9fd63a9c3c`), first land a small `lane/tool` prep PR (or orchestrator-coordinated transition) that temporarily accepts both the current and new `lib.iife.js` SHA-256 hashes, then land the `lane/coqui_platform` PR, then land a follow-up `lane/tool` PR that narrows the pin to the single new SHA-256 and empties `TEMPORARY_ALLOWED_SCRIPT_URLS` in `coqui/tool/check_sitio.mjs`.

## Why

This is a **live user-facing runtime bug**, not only tooling debt: `#180`'s Content Security Policy (`script-src 'self' 'wasm-unsafe-eval' blob:`, `worker-src 'self' blob:`) in `coqui/app/web/index.html` already blocks `cdn.jsdelivr.net` in production, so non-16 kHz microphones cannot load the resampler worklet during ElevenLabs calls today. Self-hosting the worklet in `coqui_platform` fixes calls on non-16 kHz devices and lets `#180`'s CSP and `check_sitio.mjs` agree on zero outside script/worklet hosts.

## What I am using meanwhile

A temporary exact-URL exception in `TEMPORARY_ALLOWED_SCRIPT_URLS` in `coqui/tool/check_sitio.mjs` allowing only `https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.2/dist/libsamplerate.worklet.js`, while leaving vendored `lib.iife.js` untouched and SHA-256 pinned in `coqui/tool/test/check_sitio_test.dart`.

## Order and branch

- Order/Issue: `#253`
- Branch: `lane/tool/253`
