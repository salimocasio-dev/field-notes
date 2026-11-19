# 11 · Pixel engine: the map and the scene sets (for the Flutter build)

Written Nov 19 2026 from the Nov 14 chat. Read with 00, 03, 08 and 09. Where this page and 08 differ about the map or scene pictures, this page wins.

## What happened

- Salim saw "Pixel Plays" on Instagram: github.com/amirmushichge/pixel-plays, by Amir Mushich, MIT licence. It's a tiny software rasteriser that draws isometric pixel dioramas in real time, with a depth buffer, Bayer dither, hue-shifted colour ramps, hard shadows and wind.
- Claude rebuilt the home map on it. Preview (owner-only, Salim can open it): https://claude.ai/artifact/388thwCa6svydp1svGBqGg
- Salim asked how the story scenes would look. Claude rendered the El frente set in the engine and placed the existing abuela and coquí sprites on top. That is the direction: **sets in the engine, characters stay the current sprites.**
- Nothing was pushed to field-notes (push was blocked in that chat). The working code is in this project under `claude/pixel/`:
    - `pp-engine.js`: the engine, changed so canvas size and scale come from `PP_SCENE`.
    - `mapa.js`: the map, plus the shared building helpers (block, onWall, windowOn, gable, flatRoof, bush, palm, shadowBox, person) and the frog.
    - `mapa.html`: the map page shell (demo progress via `?hecho=N`).
    - `frente-set.html`: the El frente set. Render it with `?s=26&ox=-30&oy=40` (these are the chosen values; the defaults in the file are older).
- Salim is converting the app to Flutter. This is the time to put the engine in.

## Decisions (made; don't reopen them)

1. **Port the engine to Dart and render at runtime.** The map needs live state: locked places grey, flags on finished places, the frog hopping, sea and wind moving. The scenes need state too (door, shutters, lamp, rain). The JS files are the reference.
2. **Parity is tested, not eyeballed.** Render the same scene in the JS reference (headless Chrome) and in Dart, and diff the buffers. The hash uses `sin(x*127.1 + y*311.7) * 43758.5453`, so tiny float differences can flip a pixel. Allow up to 0.5% of pixels to differ; anything more is a porting bug.
3. **Buffer, then integer scale.** Draw into a fixed `Uint32List` buffer, make a `ui.Image` (`decodeImageFromPixels`), and paint it scaled by a whole number with `FilterQuality.none`. Never a fractional scale. Pick the scale as `floor(availableWidth * devicePixelRatio / bufferWidth)` device pixels per buffer pixel, as `mapa.html` does.
4. **Keep the look exactly.** The look is: 30° orthographic camera, Bayer dither on big flat surfaces, flat bands on figures, 5-step ramps that push shadows violet and lights warm yellow, hard shadows to screen right (`shadowX .9, shadowY -.1`), depth-buffer edges, and wind stepped at 8 fps in whole pixels. When the OS asks for reduced motion (`MediaQuery.disableAnimations`), everything stands still.
5. **The UI stays hybrid (page 09).** Only the map and the scene pictures are pixel art. The top chip, the Today button, the place sheet and the tab bar are normal Flutter widgets.
6. **Map settings.** Buffer 256 × 480, `S = 8`, `originY = 36`. Keep the layout constants exactly as in `mapa.js`: `PADS`, `DIO`, `ROAD`, the road rule in `legs()` (sideways at the lower stop, then straight up), and `islandSd()`. The ten places are the ten `PLACES` builders, in the same order as `CURSO.lugares`.
7. **Map states come from the real progress store, not `?hecho`.** Use the same open, done and current rules the current app's map uses.
    - Locked: the place's pixels and its tree leaves go through `greyOf()`.
    - Open: white number plate.
    - Done: yellow plate, plus a red flag waving beside the stop.
    - Current: the frog stands there, with the bouncing arrow over him.
    - The fort's flag is red once place 10 opens, grey before.
8. **Map interaction.**
    - A tap goes to the nearest stop or place within 22 buffer pixels.
    - On an open place, the frog hops there along the roads: hops of about 2.2 units, 0.2 s each, squash on landing, the short hop sound. Then the place sheet opens.
    - On a locked place, the sheet opens saying it's locked.
    - The map opens scrolled to the frog.
9. **Scene settings.** Buffer 240 × 216, the same size as today's scenes. `S = 26`, `originX = -30`, `originY = 40` for El frente. Other scenes may move the origin to frame their set, but keep `S = 26`, so a door is about abuela's height (door 2.55 units tall).
10. **Characters stay sprites.** Abuela, the coquí and everyone else keep the current sprite code, drawn 1:1 on top of the engine's picture. Never scale a sprite. Each character has a spot in world coordinates. Project it to place the sprite: abuela's anchor is (30, 49) in her 48 × 51 sprite; the coquí's is (width/2, height−2). The engine casts each character's shadow at its spot (see the end of `frente-set.html`).
11. **One set per scene, with its states as parameters.** Each scene's states (door shut, half or open; shutters; lamp; storm cloud; rain) are inputs to its set builder. Cache one baked buffer per state the stories actually use. Moving things (rain, clouds, the butterflies) stay as today's per-frame overlays.
12. **Touch areas come from the 3D objects.** Project each touchable object's 8 box corners and take the screen bounding box. Keep the existing touch keys, so the story files don't change.
13. **Fill gaps at large scale.** The building helpers step at `ST = 0.36 / S`. At `S = 26` a fixed step left holes in walls.
14. **Keep greenery off touch targets.** El frente's palm was taken out because it covered the door.
15. **Licence.** Keep the MIT notice at the top of the Dart engine file, and credit Amir Mushich / Pixel Plays in the app's About screen. Don't ship Pixel Plays' music; it isn't covered by the MIT licence.

## Build order

1. Port `pp-engine.js` to Dart (`lib/pixel/engine.dart`), with the parity test from decision 2.
2. Port the map from `mapa.js` and `mapa.html`. Golden tests for three states: nothing done, 3 places done, all done. Measure on a phone: bake under 500 ms (move it to an isolate if not) and a frame under 8 ms.
3. Port El frente from `frente-set.html`, with every state its stories use. Then show Salim El frente running in the app before doing any other scene.
4. Then the other scenes, one at a time. Each one is converted from its current `historia/escenas/*.js` `bg()` drawing: same objects, same states, same touch keys, now built from the 3D helpers. The scenes are balcon, banco, camino, campo, estufa, lago, mesa, nevera, patio and sala.
5. For each scene, render every state to images and check them against El frente's look before calling it done. Then run the stories' play-through checks (page 00: "Before anything with pictures or lines goes to Salim").

## Known gaps

- The sprites have a dark outline and face the viewer, while the sets are at an angle. Salim saw this and chose to go ahead. Don't restyle the sprites unless he asks.
- The map's ten dioramas are small (about 50 buffer pixels each). That's fine for the map. It isn't the look for scenes; scenes use `S = 26`.
