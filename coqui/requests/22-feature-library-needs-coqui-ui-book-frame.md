# feature_library needs coqui_ui: the frame of the book

## What I need

A frame for the book, next to `LessonFrame`, with slots for what the book puts on its screen (app.html:103-128, 164-170):

- the top bar (close X, the page line, the page count, "Aa"): 56 px (+ safe area), `LessonFrame`'s top bar is private; its `progress` is centred in its slot while `.lbbar{flex:1;max-width:480px}` stands at the left with the count and "Aa" right after it;
- the picture area: flexible, 8 px above, 16 at the sides, and `8 + --finx` below (`--finx` is 72 px, 0 on the last page), so that the picture stands in the same place on every page and the last page's "Fin" has room;
- the text area: its height is as tall as the book's tallest page (never under three single lines, never over half the screen), at most 55% of the room, and it scrolls;
- the foot: 8 px above, 16 at the sides and below, an optional line in it ("Fin": 32 px high with 16 px above and below), then a row of 56 px buttons, 16 apart;
- a layer over the whole frame (the word card's scrim);
- on a phone on its side (`@media (orientation:landscape) and (max-height:500px)`, `CoquiLayout.compact`): the picture at the left, the top bar, the lines and the foot in a column at the right, at least 280 px wide or 44%.

`LessonFrame` puts one picture in the middle of the room above a 112 px foot reserve and a caption under it; the book's body is not that. Also: `Pressable` is not exported, so a screen of a feature that wants the `:active` look of `.lbl` (the book's lines) has to write its own.

And two pieces the book uses that coqui_ui has no widget for: the book line (`.lbl`: the whole line is a button, the line as recorded, a 20 px speaker icon, the playing line lit with a 4 px green bar at its left; the words that have a picture underlined 5 px under the baseline, dotted and faint, or solid green and 3 px for a moment after a tap) and the word card that pops over the page (`#lbcard .cd`: a white card with the word's picture in a `PictureFrame` and the word at 24/32).

## Why

Order 22: "The reader exactly as the old one"; "built ONLY from coqui_ui widgets and tokens (a missing or mismatching widget: file a request and build a local stand-in inside your package meanwhile; list each)".

## What I am using meanwhile

`feature_library/lib/src/reader.dart` (the frame and its layout, with `LessonIconButton`, `LessonProgressLine`, `LessonTextSizeButton`, `LessonButton`, `PictureFrame`, `PixelView` and the tokens from coqui_ui), `book_line.dart` (the line and its underlines), `word_popup.dart` (the card) and `press.dart` (the pressed state).

## Order and branch

Order 22, branch `lane/feature_library/22`.
