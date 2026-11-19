# 21-feature-words-needs-coqui-ui-text-field

## What I need

A text field as v=39 draws it: `CoquiTextField` (or a `coquiInputDecoration()`) with the look of the `input` of "Add a word or a goal" (app.html, `palabras`): full width, 48 px high at least, white fill, a 1.5 px `--line2` ring, 12 px corners, 12 px side padding, the 16 px body text, the browser's grey placeholder (`#757575`), no focus ring, no label. The `input` carries an `aria-label` equal to its placeholder.

## Why

Order 21: "Add a word or a goal" (the order's row; page 10, "The tab"). coqui_ui has no text field; `coquiTheme()` says a text field "starts from the old look" but gives it none (Material's own underline or filled box).

## What I am using meanwhile

`AddBox` in `feature_words/lib/src/add_box.dart`: a Material `TextField` with an `InputDecoration` set to those values (the style needs a `textBaseline` because `CoquiText` styles inherit nothing).

## Order and branch

Order 21, `lane/feature_words/21`.
