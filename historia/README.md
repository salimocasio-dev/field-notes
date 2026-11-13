# historia/: the story game

- `index.html` loads `engine.js` (drawing library), `juego.js` (the game engine, shared by every story) and `escenas/*.js` (one file per scene).
- `cuentos/<id>.json` is one story as data. Open it with `index.html?cuento=<id>`. The default is `la-lluvia`.
- `audio/` holds the recorded lines. They are made by `.github/workflows/voz.yml` + `tools/voz.py`, which run by themselves when a file in `cuentos/` is pushed.
- `tools/juega.py` plays a story by machine. Read its first lines for how.
- When a script changes, raise the `?v=N` on the script tags in `index.html`, or phones keep the old one.

The full reference (story file format, what a scene must provide, how to test and publish) is in the Claude Project "Coqui - Language Learning App", page `07-handoff-build-a1`.
