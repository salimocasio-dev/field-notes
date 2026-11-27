# Request: Retire `libsamplerate.worklet.js` CDN exception and complete Step 2 pin handoff

## What I need

Step 1 (`#290`, branch `lane/coqui_platform/290`) is complete:
- Vendored `@alexanderolsen/libsamplerate-js@2.1.2` `dist/libsamplerate.worklet.js` to `coqui/packages/core/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js` (SHA-256 `ca6e162f194d3ee5a2d2cd3c3b49641d31e56845aeae507feca1cdf8aa8116cb`, 2,016,428 bytes, zero external URLs, zero `sourceMappingURL`).
- Added the `@alexanderolsen/libsamplerate-js@2.1.2` MIT + libsamplerate 2-clause BSD license alongside the `@elevenlabs/client@1.25.0` MIT license in `coqui/packages/core/coqui_platform/assets/elevenlabs/LICENSE`.
- Declared `assets/elevenlabs/libsamplerate.worklet.js` in `coqui/packages/core/coqui_platform/pubspec.yaml`.
- Updated `JsConvLibrary` in `coqui/packages/core/coqui_platform/lib/src/web/el_conv.dart` to pass `libsampleratePath` (`assets/packages/coqui_platform/assets/elevenlabs/libsamplerate.worklet.js`, or `assets/assets/elevenlabs/libsamplerate.worklet.js` when loaded via the package-root asset fallback) in `startSession`.
- Kept `coqui/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js` byte-for-byte unchanged (SHA-256 `ec975ddc738967e53b0e37346eef5488217ff4d50968030bd1c26f9fd63a9c3c`).

Remaining Step 2 handoff across `lane:tool` and `lane:coqui_platform`:
1. **`lane:tool`**: Add the SHA-256 pin for `libsamplerate.worklet.js` (`ca6e162f194d3ee5a2d2cd3c3b49641d31e56845aeae507feca1cdf8aa8116cb`) and temporarily accept both the old and new `lib.iife.js` SHA-256 hashes in `coqui/tool/test/check_sitio_test.dart`.
2. **`lane:coqui_platform`**: Remove the `https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.2/dist/libsamplerate.worklet.js` fallback in `coqui/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js`. Note the upstream `@elevenlabs/client@1.25.0` quirk verified during `#290`: `setupWebSocketIO` forwards `libsampleratePath: options.libsampleratePath` to `MediaDeviceInput.create(...)` (non-16 kHz mics) but omits forwarding it to `MediaDeviceOutput.create(...)` even though `MediaDeviceOutput.create` accepts `libsampleratePath`, so that follow-up should also forward `libsampleratePath` to `MediaDeviceOutput.create` (or upgrade `@elevenlabs/client`).
3. **`lane:tool`**: Narrow the `lib.iife.js` SHA-256 pin to the single new hash and empty `TEMPORARY_ALLOWED_SCRIPT_URLS` in `coqui/tool/check_sitio.mjs`.

## Why

`coqui/tool/` is outside `lane:coqui_platform` (boundary rule 5), and `lib.iife.js` is currently SHA-256 pinned in `coqui/tool/test/check_sitio_test.dart`. Retiring the temporary `cdn.jsdelivr.net` exception in `TEMPORARY_ALLOWED_SCRIPT_URLS` (`coqui/tool/check_sitio.mjs`) requires coordinating the `lib.iife.js` pin transition with `lane:tool`.

## What I am using meanwhile

Self-hosted `libsamplerate.worklet.js` passed explicitly via `libsampleratePath` in `JsConvLibrary.startSession`, while leaving `lib.iife.js` byte-for-byte unchanged at its pinned SHA-256 (`ec975ddc738967e53b0e37346eef5488217ff4d50968030bd1c26f9fd63a9c3c`) until Step 2 updates the tool pins.

## Order and branch

- Order/Issue: `#290`
- Branch: `lane/coqui_platform/290`
