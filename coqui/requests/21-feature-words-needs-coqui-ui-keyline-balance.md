# 21-feature-words-needs-coqui-ui-keyline-balance

## What I need

`KeyLine` (and any grey line that v=39 sets with `text-wrap: balance`) should balance its lines: when the text has to wrap, the lines come out of even length, as the browser's `balance` does (the narrowest width that keeps the number of lines). Flutter has no such property; a `LayoutBuilder` with a `TextPainter` and a search for that width does it.

## Why

Order 21: the key line under the first place title in Palabras, "Ear: you know it when you hear it. Mouth: you can say it." (`.keyl{margin:-8px 0 16px;text-wrap:balance}`, app.html:91). In `iphone-390x844/030-palabras-a-medio-curso.png` it wraps as "Ear: you know it when you / hear it. Mouth: you can say it."; a plain `Text` would break it after "Mouth: you can say" and leave "it." alone on the second line. (On the dev entry, in Roboto, it still fits on one line at 390 px; on a 360 px phone it wraps.)

## What I am using meanwhile

`BalancedKeyLine` and `BalancedText` in `feature_words/lib/src/balanced_key_line.dart`: a `BlockWidget` with the margins of `KeyLine` (-8 above, 16 below) around a text that is laid out at the narrowest width that gives the same number of lines. Four widget tests.

## Order and branch

Order 21, `lane/feature_words/21`.
