# Request: Self-host `libsamplerate.worklet.js` in `coqui_platform`

## What I need

1. Vendor `@alexanderolsen/libsamplerate-js@2.1.2`'s `dist/libsamplerate.worklet.js` (along with its `LICENSE`) into `coqui/packages/core/coqui_platform/assets/elevenlabs/`.
2. Declare the vendored worklet asset in `coqui/packages/core/coqui_platform/pubspec.yaml`.
3. Pass `libsampleratePath` in `JsConvLibrary.startSession` (`coqui/packages/core/coqui_platform/lib/src/web/el_conv.dart`) pointing to the bundled asset (`assets/packages/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js` or the app asset path used on web).
4. Eliminate the hardcoded `https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.2/dist/libsamplerate.worklet.js` fallback URL from the vendored ElevenLabs SDK (`coqui/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js`), and update the pinned SHA-256 in `coqui/tool/test/check_sitio_test.dart` in the same PR.
5. Remove the temporary exact-URL entry from `TEMPORARY_ALLOWED_SCRIPT_URLS` in `coqui/tool/check_sitio.mjs` in the same PR.

## Why

GitHub issue `#253` enforces that built web JS/HTML allows zero permanent outside script/worklet hosts, matching `#180`'s Content Security Policy (`script-src 'self' 'wasm-unsafe-eval' blob:`, `worker-src 'self' blob:`) in `coqui/app/web/index.html`. Currently, vendored `@elevenlabs/client@1.25.0` (`coqui/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js`) falls back to `https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.2/dist/libsamplerate.worklet.js` for non-16 kHz microphones, which `#180`'s CSP blocks at runtime. Self-hosting the worklet in `coqui_platform` lets non-16 kHz microphones work under `#180`'s CSP and allows `check_sitio.mjs` and `#180`'s CSP to agree on zero outside script/worklet hosts.

## What I am using meanwhile

A temporary exact-URL exception in `TEMPORARY_ALLOWED_SCRIPT_URLS` in `coqui/tool/check_sitio.mjs` allowing only `https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.2/dist/libsamplerate.worklet.js` while leaving vendored `lib.iife.js` untouched and SHA-256 pinned in `coqui/tool/test/check_sitio_test.dart`.

## Order and branch

- Order/Issue: `#253`
- Branch: `lane/tool/253`
