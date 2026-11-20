# 27 feature_library needs coqui_scenes (or content): a cover picture for each routine

## What I need

A still picture for each routine (Haz esto: h-frente, h-balcon, h-sala, h-patio, h-camino, h-campo, h-lago, h-banco) that the shelf can show as its cover, 56 x 62 and 80 x 88 logical px (the book page's 196:216 aspect). Either of these would do:

- Content: a 196 x 216 PNG per routine beside the books' pictures, `historia/libros/img/h-<scene>-1.png` (the scene's set as the routine starts, captured the way the books' pictures are, no game marks), and its path named somewhere the catalog can give it (for example a `cover` key the catalog exposes, or a one-page book file with `"lee": false`). The shelf already shows a book's first page by address.
- Or `PictureSource`: a way to ask for a whole-scene still by scene id at a cover size, for example `PictureRef(scene: 'balcon', cam: [0, 0, 240, 216], name: 'cover')` answered by `ScenePictures` for converted and not-yet-converted scenes alike. Today a ref needs a sheet picture's name (`<word>.si`), and an old (not converted) scene only answers 196 x 104, so a routine's scene cannot be shown whole at cover size.

## Why

Order 27 (Biblioteca UX): "A cover picture for a story may come from what the app already has: the book's first-page picture where the book has pictures, or a still picture of the story's scene through the PictureSource contract. If neither is reachable from this package, request it and use the best plain tile you can design meanwhile." Routines have no book (page 10: all their lines are commands), and a routine's scene is not reachable as a whole picture through `PictureSource`.

## What I am using meanwhile

`ShelfCover` with no picture: the cover's warm grey (`CoquiColors.coverFill`) with a speaker icon (`CoquiIcons.volume`) in the middle, the same size as a cover. It shows on the 8 routine rows of a finished place and on the "Hear next" card when it names a routine.

## Order and branch

Order 27, branch `lane/feature_library/27`.
