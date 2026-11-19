# 24 · feature_speaking needs coqui_ui: `PictureSource.of` fills the box it is given, at a whole-number scale

## What I need

`PictureSource.of(ref)` (page 12, section 3), with no `scale`, returns a widget that fills the tight box its parent gives it and draws the picture at the largest whole number of device pixels per picture pixel that box allows (as `pixelViewScale` does), not smoothed. The fake of coqui_testing does fill a tight box (its grey `SizedBox` takes the parent's tight constraints).

## Why

Order 24: the call's picture is "whole-number scaled" by llamada.js's own formula (`fit()`: `s = max(1, min(floor(aw*dpr/196), floor(ah*dpr/104)))`, laid out at `196*s/dpr` by `104*s/dpr` CSS px). The screen computes that size and gives it as a tight box. It does not pass `scale`, because page 12 does not say whether `scale` counts device pixels or logical ones (the fake counts logical ones: `196 * scale`).

## What I am using meanwhile

A `SizedBox` of the computed size around `pictures.of(PictureRef.of(pair, pair.yes))`, with no `scale`. On the fake that is a grey box of exactly that size. If the real source does not fill its box, only that one call in `CallScreen._picture` changes.

## Order and branch

Order 24, branch `lane/feature_speaking/24`.
