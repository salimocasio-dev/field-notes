# 23 feature_review needs coqui_ui: PictureChoice that takes the touch when the finger goes down

## What I need

`PictureChoice` with an `onPointerDown` (or `onTap` that fires on the pointer going down, not on its release), and the
accessibility label ("Picture 1", "Picture 2" ...: cual.js `aria-label="Picture "+(k+1)`) on the choice whatever the callback is.
Today `onTap` goes through `Pressable`, which fires on the tap's release and gives the label only when `onTap` is set.

## Why

cual.js `mkOpts`: `d.addEventListener("pointerdown", ...)`. The touch time is measured at that instant
(`ms = performance.now() - tEnd`) and is written to the learner's record (`progress.answer(..., ms:)`; a right answer
slower than 2 s does not stretch the schedule). A release-time tap would add the length of the press to every answer.

## What I am using meanwhile

`OptionTouch` in `packages/features/feature_review/lib/src/ui/lesson_parts.dart`: a `Listener(onPointerDown)` and a `Semantics`
around a `PictureChoice` that has no `onTap`.

## Order and branch

Order 23, branch `lane/feature_review/23`.
