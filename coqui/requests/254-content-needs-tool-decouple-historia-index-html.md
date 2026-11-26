# 254: `content` needs tooling decoupled from `historia/index.html`

## What I need
Move the headless story-playback harness out of `historia/index.html` and update the local tooling scripts that open `http://127.0.0.1:<port>/historia/index.html` and wait for `window.Story && Story.ready` — specifically `historia/tools/gen_libros.py` (lines 60 & 255), `coqui/tool/ref/trazas/juega.mjs`, `coqui/tool/ref/escenas/make.mjs`, and `docs/proyecto/pixel/*-sheet-make.js` — so `historia/index.html` can be fully deleted in a follow-up cleanup.

## Why
Issue #254 (`First-version pages: keep, move or remove`) removes the retired first-version public HTML pages and `?legacy=1` escape hatches. Deleting `historia/index.html` directly breaks `historia/tools/gen_libros.py` book regeneration and reference capture scripts with HTTP 404.

## What I am using meanwhile
Kept `historia/index.html` on disk temporarily as a loopback-only webdriver tooling harness: replaced line 2 so public visitors (and any non-loopback or non-webdriver browser, plus `<noscript>`) are unconditionally redirected to `../app/` with zero `?legacy=1` escape hatch, while local headless tools on `127.0.0.1` / `localhost` / `[::1]` with `navigator.webdriver === true` continue to load `window.Story && Story.ready`.

## Order and branch
Issue `#254`, branch `content/254` (`lane:content`).
