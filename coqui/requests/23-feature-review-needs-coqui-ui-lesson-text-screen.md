# 23 feature_review needs coqui_ui: the text of a lesson's start and end screen

## What I need

A widget for `#fin` of cual.html / nivel.html (cual.html:34-37): the title (24/32 semibold white) and the lines under it
(16/24 `--ink2`, 8 px apart), left aligned, each as wide as the column up to 480 px, the column centred. Portrait: its
top is at 35% of the screen's height (`padding-top: calc(35dvh - 56px - env(safe-area-inset-top))`, never negative),
16 px at the sides, 160 px under; on its side (`@media (orientation:landscape) and (max-height:600px)`) it is the top
of the column beside the picture, `padding: 8px 0 152px`, no background. It is the `overlay` of `LessonFrame`. Repaso's start
and end, the level check's start and result, and a story's end screen all use it.

## Why

Order 23: "Screens built ONLY from coqui_ui widgets and tokens". `LessonFrame.overlay` takes a widget but there is none for
this text, and the story's end screen (order 15) needs the same one.

## What I am using meanwhile

`LessonTextScreen` in `packages/features/feature_review/lib/src/ui/lesson_parts.dart`, made of `CoquiText.lessonH1`,
`CoquiText.lessonBody` and `CoquiMetrics.lessonTopBar`.

## Order and branch

Order 23, branch `lane/feature_review/23`.
