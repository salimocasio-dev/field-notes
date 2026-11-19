# What I need

`PictureRef` (coqui_ui, page 12 section 3) to say which picture of the scene's sheet it is: a field such as
`final String? picture;` holding the sheet's picture name, `<word>.<side>` (`abuela.si`, `cierra.no`), filled by
`PictureRef.of(pair, side)` (the side is `si` when `side` is `pair.yes`, `no` when it is `pair.no`), and by whatever
makes a level picture's reference (a level item names its pair and side: nivel.js `NV.p`, `[word, side, x]`).

# Why

Order 14: "`of(ref, ...)` draws the scene in the state the ref's `set` gives and returns a widget showing the review crop
the sheet gives for that picture (centre and zoom 1 or 2)". The sheet keys its review and level pictures by
`<word>.<side>` (`pictures`, `level`), and a `PictureRef` holds only the scene, the state and the old view rectangle.
In cual-frente two sides have the same scene, state and view but different crops: `abuela.si` (the door, zoom 1) and
`cierra.no` (the door, close, zoom 2), both `{door: 1, ab: {en: puerta, pose: idle, bub: null, al: 1}}` at
`[135, 46, 94, 50]`. From a plain reference the source cannot tell which picture to draw.

# What I am using meanwhile

`ScenePictures` (coqui_scenes) is given the review pairs (`ScenePictures(pairs: course.pairs)`) and finds a plain
reference's picture by its scene, state and view. When two pictures of the sheet share them and the sheet crops them
differently (only `abuela.si` / `cierra.no` today) it draws nothing and says so (a clear failure, not a wrong picture).
`ScenePictures.ofPicture(ref, name)` takes the name itself; the tests and the dev page use it.

# Order and branch

Order 14, `lane/coqui_scenes/14`.
