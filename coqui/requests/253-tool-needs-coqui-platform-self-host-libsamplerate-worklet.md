# Request: Self-host `libsamplerate.worklet.js` in `coqui_platform`

## What I need

1. In `coqui_platform` (`lane/coqui_platform/<n>`, touching only `coqui_platform/`):
   - Vendor `@alexanderolsen/libsamplerate-js@2.1.2`'s `dist/libsamplerate.worklet.js` (and `LICENSE`) under `coqui/packages/core/coqui_platform/assets/elevenlabs/`.
   - Declare `assets/elevenlabs/libsamplerate.worklet.js` in `coqui/packages/core/coqui_platform/pubspec.yaml`.
   - Pass `libsampleratePath` in `JsConvLibrary.startSession` (`coqui/packages/core/coqui_platform/lib/src/web/el_conv.dart`) pinned to `assets/packages/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js` (with package-root dev fallback `assets/assets/elevenlabs/libsamplerate.worklet.js`, mirroring `lib.iife.js`). Note that per CSP3, `AudioWorklet.addModule()` is governed by `script-src` (`script-src 'self' 'wasm-unsafe-eval' blob:` in `coqui/app/web/index.html`, whereas `worker-src 'self' blob:` restricts web workers), so `script-src 'self'` already permits loading a self-hosted `'self'` AudioWorklet without any CSP relaxation.
   - Remove the hardcoded `https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.2/dist/libsamplerate.worklet.js` fallback from `coqui/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js`.
2. Cross-lane handoff & issue tracking (do **not** edit `coqui/tool/` from `lane/coqui_platform/<n>`, which would violate boundary rule 5):
   - Track the live production bug (`type:bug` / linked GitHub issue in `lane:coqui_platform`) and the 3-step SHA-pin handoff as linked GitHub issues so the temporary jsdelivr allowance is retired promptly:
     1. Land a small `lane/tool` prep PR (or orchestrator-coordinated transition) that temporarily accepts both the current and new `lib.iife.js` SHA-256 hashes in `coqui/tool/test/check_sitio_test.dart`.
     2. Land the `lane/coqui_platform` PR self-hosting `libsamplerate.worklet.js` and removing the `cdn.jsdelivr.net` fallback from `lib.iife.js`.
     3. Land a follow-up `lane/tool` PR that narrows the pin to the single new SHA-256 and empties `TEMPORARY_ALLOWED_SCRIPT_URLS` in `coqui/tool/check_sitio.mjs`.

## Why

This is a **live user-facing runtime bug**, not only tooling debt: `#180`'s Content Security Policy (`script-src 'self' 'wasm-unsafe-eval' blob:` in `coqui/app/web/index.html`) already blocks `AudioWorklet.addModule()` from `cdn.jsdelivr.net` in production, so non-16 kHz microphones cannot load the resampler worklet during ElevenLabs calls today. Self-hosting the worklet in `coqui_platform` fixes calls on non-16 kHz devices and lets `#180`'s CSP and `check_sitio.mjs` agree on zero outside script/worklet hosts.

## What I am using meanwhile

A temporary exact-URL exception in `TEMPORARY_ALLOWED_SCRIPT_URLS` in `coqui/tool/check_sitio.mjs` allowing only `https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.2/dist/libsamplerate.worklet.js`, while leaving vendored `lib.iife.js` untouched and SHA-256 pinned in `coqui/tool/test/check_sitio_test.dart`.

## Order and branch

- Order/Issue: `#253`
- Branch: `lane/tool/253`
