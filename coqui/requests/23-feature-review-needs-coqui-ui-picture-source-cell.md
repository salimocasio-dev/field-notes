# 23 feature_review needs coqui_ui: a picture of a window that is not 196 wide (the level check's cells)

## What I need

`PictureSource.of` for a camera window of any size shown in a box of any size: the level check draws each of its four pictures
as the window `[x, y, w, h]` (nivel.js `nivelPanel`: `h = cam[3]`, `w = h * 96 / 106`, `x` kept inside the 240 px scene) scaled
into a cell of 96 x 106 art pixels (`CW`, `CH`), at the whole-number scale the block of four allows (`fit`). Contracts, section 3, says
`of` gives "the 196-wide window at cam, cropped to height", and section 5 says a level-check picture is "a whole-number crop:
zoom 1 is 196 x 104, zoom 2 a 98 x 52 region doubled; the sheet gives each picture its centre and zoom". The old code's windows
(for example 45.28 x 50 art pixels, scaled 2.1 times into a cell 96 wide) are neither.

Also: what `scale` means (device pixels to a picture pixel, or logical pixels: `FakePictureSource` multiplies logical pixels by it).

## Why

Order 23: "the level check: ... three or four pictures per item". I cannot tell which crop and scale the real source will draw.

## What I am using meanwhile

`PictureRef(scene, set, cam: [x, y, w, h])` with the old code's numbers exactly (the differential test compares them with
nivel.js), shown by `pictures.of(ref, height: h.round())` inside a box of the cell's size, so the fake fills the cell. I pass no
`scale`; the review block's boxes are `196 * kd / dpr` wide, so a source that snaps to whole device pixels from its width gets kd.

## Order and branch

Order 23, branch `lane/feature_review/23`.
