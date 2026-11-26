# 254: `content` needs tooling decoupled from `historia/*.html` harnesses

## What I need
Move the headless tooling/reference harnesses out of the five legacy `historia/*.html` pages (`historia/app.html`, `historia/index.html`, `historia/cual.html`, `historia/nivel.html`, `historia/habla-prueba.html`) and update their local tool consumers — specifically `historia/tools/gen_libros.py` (lines 60 & 255), `coqui/tool/ref/escenas/` (`make.mjs`, `check.mjs`), `coqui/tool/ref/pantallas/` (`capturar.mjs`, `lib/seeds.mjs`, `lib/drive.mjs`, `lib/g-hablar.mjs`), `coqui/tool/ref/trazas/juega.mjs`, `coqui/tool/export_datos.mjs`, `coqui/packages/features/feature_speaking/tool/prueba_layout.mjs`, and `docs/proyecto/pixel/*-sheet-make.js` — so all five `historia/*.html` files can be fully deleted in a follow-up cleanup.

## Why
Issue #254 (`First-version pages: keep, move or remove`) retires the first-version public HTML pages and `?legacy=1` escape hatches. Deleting these five HTML pages directly breaks local book generation (`gen_libros.py`), reference capture scripts (`coqui/tool/ref/{escenas,pantallas,trazas}/`), voice-test export/layout tools (`export_datos.mjs`, `prueba_layout.mjs`), and pixel sheet generators with HTTP 404 or missing source files.

## What I am using meanwhile
Kept all five `historia/*.html` files on disk temporarily as loopback-only webdriver tooling harnesses with zero `?legacy=1` escape hatches: public visitors (and any non-loopback host, non-webdriver browser, or `<noscript>` client) are unconditionally redirected to `../app/` (calling `if(window.stop)window.stop();` before `location.replace("../app/");` to halt legacy script execution without aborting the redirect), while local headless tools on `127.0.0.1` / `localhost` / `[::1]` with `navigator.webdriver === true` continue to load cleanly (`historia/habla-prueba.html` keeps its single inline `<script>` tag intact for `coqui/tool/export_datos.mjs`).

## Order and branch
Issue `#254`, branch `content/254` (`lane:content`).
