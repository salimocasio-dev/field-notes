# 23 feature_review needs coqui_ui: the Repaso end list

## What I need

The words of a Repaso's end screen (cual.html:40-44, cual.js `cualGrupo`, `cualGrid`): under a heading (18/24 semibold) and a grey
line (14/20, none in a practice session) a grid of pictures, each in a 1.5 px `--line` frame with its word under it
(16/24, 8 px apart, wrapping inside a cell as wide as its picture); 16 px between cells and rows; three or two to a row
(`endGridFor`); the whole in one block as wide as the grid, centred, scrolling above the 56 px button with a 16 px fade at both
ends, 96 px from the bottom, padding 16/16/24.

## Why

Order 23. The gallery of coqui_ui has `_LessonEnd` (`tool/gallery/screens.dart`) as a sample, but it is not a widget and its
grid is fixed at 3 columns; the scale and the number of columns are the page's own arithmetic (`cualGrid`: 2 columns at a whole
scale of 2 on the iPhone reference, 3 at 1 on the Android one).

## What I am using meanwhile

`ReviewEndScreen` and `endGridFor` in `packages/features/feature_review/lib/src/ui/` (`review_screen.dart`, `block_layout.dart`),
checked against the old `cualGrid` run in Node for 16 phone sizes (`test/layout_test.dart`).

## Order and branch

Order 23, branch `lane/feature_review/23`.
