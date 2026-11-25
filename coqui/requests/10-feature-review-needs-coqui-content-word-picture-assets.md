## What I need

1. Dedicated individual single-word picture assets (drawn or pulled individually — never story-book screenshots from `historia/libros/img/` and never camera crops of story scenes from `historia/cuentos/cual-*.json`) stored under `word_assets/<slug>.png` for concrete, picturable vocabulary words only.
   Concrete examples across the 3 built places:
   - `casa`, `puerta`, `ventana`, `abuela`, `silla`, `vaso`, `jugo`, `agua`, `mamá`, `papá`, `abuelo`, `bebé`, `flor`, `sol`, `perro`, `gato`, `árbol`, `bola`, `pato`, `pez`, `pájaro`, `hombre`, `mujer`, `mesa`, `plato`, `taza`, `cuchara`, `tenedor`, `cuchillo`, `pan`, `arroz`, `pollo`, `huevo`, `leche`, `queso`, `fruta`, `guineo`, `manzana`, `china`, `café`, `azúcar`.
2. Explicitly mark abstract/unpicturable words as `picturable: false` (or omit picture assets for them) so they are never assigned picture assets or tested with pictures:
   - `sí`, `no`, `hola`, `adiós`, `gracias`, `bien`, `¿cómo estás?`, `también`, `todo`, `ya`, `listo`, `aquí`, `allá`, `él`, `ella`, `yo`, `tú`, `mi`, `tu`, `más`, `hay`, `no hay`, `quiero`, `quieres`, `¿qué quieres?`, `me gusta`, `no me gusta`, `buen provecho`, `un poco`, `mucho`, `cuidado`, `hasta mañana`, `tengo hambre`, `tengo sed`.
3. Add `oyes` hearing sentences in `repaso.json` for the 4 words that currently have `cual` only (`oyes == 0` in `repaso.json`): `tengo hambre`, `tengo sed`, `listo`, `ya`, so they can be scored via `¿Qué oyes?` without pictures.

## Why

Issue #10: Salim ruled that Repaso flashcards must not reuse story-book screenshots or story-scene crops (`ScenePictures`). Only dedicated single-word assets may be shown in `¿Cuál?`, and abstract/unpicturable words must never be tested with pictures.

## What I am using meanwhile

`WordPictureAsset` and `isDedicatedWordAssetPath` in `feature_review/lib/src/logic/word_picture.dart` with `wordAssets: const {}` by default (all words with `oyes` sentences fall back to `¿Qué oyes?`, and `¿Cuál?` only activates when a valid `word_assets/<slug>.png` pair is provided).

## Order and branch

- Issue #10 (`lane/feature_review/10`)
