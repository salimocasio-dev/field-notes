# 25 · feature_profile needs coqui_ui: a card that follows another row has a line over it

## What I need

On `CoquiCard`, an optional top line: the 1 px `--line` (`#E3E1DA`) that app.html:21 gives a card that follows another
card of the same kind. The rule is `.row+.row{border-top:1px solid var(--line)}`, and the Yo tab's three switch cards
(`<div class="card row">`) are three `.row`s in a row: the second and the third have it, the first has not. It is a
`border-top` inside the card's own box (the card's ring is a `box-shadow`, outside it), so it makes the card 1 CSS px
taller and, with the 16 px corners, it is a crescent that is 1 px thick in the middle and thins out to nothing where the
corner curves away. Chrome draws the 1 px as the whole device pixels it floors to (2 at ratio 2.625, 3 at ratio 3), at
least one. A card with the note between (`notaHabla`'s `div`) has no line: `.row+.row` needs the two to be neighbours.

Something like `CoquiCard(topLine: true)`; its width taken as Chrome takes a 1 px border (the floor of
`devicePixelRatio`, at least 1 device pixel, over the ratio). Note that `CoquiLayout.border(context, 1)` gives 3 device
pixels at ratio 2.625 (it rounds), where Chrome's 1 px `border-top` is 2: the reference picture
`android-412x915/070-yo-a-medio-curso.png` has 2 device pixels of line at the top of the second and third cards, over the
ring's 3.

## Why

Order 25: Yo "to look and behave exactly as the old web app"; "Screens built ONLY from coqui_ui widgets and tokens (a
missing or mismatching widget: file a request and build a local stand-in)". The line is visible on every Yo picture of
the order (069 to 076, 080 to 082) as a slightly thicker top edge of the second and third cards.

## What I am using meanwhile

A stand-in in `feature_profile/lib/src/yo_screen.dart`: `_RowCard` (a `BlockWidget`, so the margins collapse as in a
`CollapsingColumn`) draws `CoquiCard(...).content` with 17 px of padding on top and paints the crescent over it
(`_TopLinePainter`: the card's rounded rectangle minus the same rectangle moved down by the line's width, whose top corners
are 16 wide and 16 minus the width high, as CSS makes the padding box's corners). On the reference pictures it is within
one device pixel.

## Order and branch

Order 25, branch `lane/feature_profile/25`.
