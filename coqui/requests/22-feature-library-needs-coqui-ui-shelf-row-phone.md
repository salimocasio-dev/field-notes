# feature_library needs coqui_ui: the shelf row as the old CSS draws it on a phone

## What I need

Three things in `ShelfRow` and `CoquiButton` (app.html:97-101, 22):

1. **A cover as tall as its picture.** `.cov{width:72px;min-height:72px}` and `.cov img{width:72px;height:auto}`: a book's first page is 196 x 216, so the cover is 72 x 79.4 and the picture is whole; `ShelfRow` makes the cover a fixed 72 x 72 square and clips the picture (the bottom 7 px of it are lost). A grey tile (no picture) stays 72 x 72.
2. **The phone rules.** `@media (max-width:420px){.bk .btn{padding:0 12px;gap:6px}}` and `@media (max-width:380px){.bk{gap:12px}.cov{width:64px;min-height:64px}.cov img{width:64px}.bk .btn{padding:0 10px}}`. Both reference phones (412 and 390 px wide) are under 420, so Listen and Read are 8 px narrower each than `CoquiButton(padX: 16)` draws them, and the icon-to-label gap is 6, not 8. `ShelfRow` has `coverSize` but nothing else of these rules, and the gap between the cover and the text is fixed at 16.
3. **`Read ✓`.** `CoquiButton` takes a `label` and an `icon` only. The shelf's Read button, once the book was read, is `Read` and a green semibold `✓` (`.okc`) after the label, with the button's gap between them. It needs a trailing part (a string with a colour, or a widget) and a `gap` (or the phone rule above applied by the button itself).

## Why

Order 22: "rebuilt in Flutter to look and behave exactly as the old web app (v=39)"; "built ONLY from coqui_ui widgets and tokens (a missing or mismatching widget: file a request and build a local stand-in)". The reference pictures `047-biblioteca-a-medio-curso.png` (the Listen button is 98.7 px wide, `CoquiButton` gives 110.7) and `052-biblioteca-queda-una-al-final.png` (`Read ✓`, the covers 72 x 79) show it.

## What I am using meanwhile

`feature_library/lib/src/shelf_row.dart`: `ShelfEntry` (the row, with the cover at its own height and the 380 px rule) and `ShelfButton` (the two buttons, with the 420 and 380 px rules and the trailing check). Both are built from `CoquiColors`, `CoquiMetrics`, `CoquiText` and `CoquiIcon`.

## Order and branch

Order 22, branch `lane/feature_library/22`.
