# Request: Playback speed parameter on ClipPlayer

## What I need

Support optional playback rate (`double rate = 1.0`) on `ClipPlayer.play` (or an optional `VariableSpeedClipPlayer` interface in `coqui_contracts`, implemented by `coqui_platform`'s audio player and `FakeClipPlayer` in `coqui_testing`), so callers can play recorded lines at `0.75×`, `0.9×`, or `1.0×`.

## Why

Story N5.1 ("The reader page", issue #112) adds the reader footer speed button (`0.75×`, `0.9×`, `1×`, default `0.9×`) matching `Noche-Lector.dc.html`. Right now `ClipPlayer.play(String clipId, {Duration? limit})` in `coqui/packages/core/coqui_contracts/lib/src/audio.dart` has no playback speed parameter.

## What I am using meanwhile

`TextReader` persists the learner's selected speed (`0.75`, `0.9`, `1.0`) in `ReaderSettings` under the `'leer'` storage space, cycles it on tap, and calls `ClipPlayer.play(clipId)` at the default rate until `coqui_contracts` exposes playback rate.

## Order and branch

Order #112 (N5.1), branch `lane/feature_library/112`.
