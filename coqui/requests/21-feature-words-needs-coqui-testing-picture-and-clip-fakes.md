# 21-feature-words-needs-coqui-testing-picture-and-clip-fakes

## What I need

Two changes to the fakes of coqui_testing:

1. `FakePictureSource.of` draws a grey box that is always 196 x 104 (times `scale`). The real source gives a widget that sizes itself by the width it is offered, at a whole number of device pixels per picture pixel (page 12, section 3; `WordCard.picture`). A fake with the same geometry (`pixelViewScale` of the width offered, 196 : `height`) would let a screen's layout be compared with its reference.
2. `FakeClipPlayer.play` returns at once, so a screen can never show "a line is playing". A mode where a clip plays for its own length (or until `stop`), as the real one does.

## Why

Order 21: the word sheet's big picture is 373 px wide in the reference at 412 px (196 x 5 device pixels at ratio 2.625) and the "Heard in" line that plays shows a stop square (`039-palabra-linea-sonando.png`). With the fakes as they are, the sheet is 94 px shorter and the playing state cannot be seen.

## What I am using meanwhile

`DevPictures` and `DevClips` in `feature_words/tool/dev_services.dart`, for the dev entry and the screenshots. The widget tests use `FakePictureSource` as it is, and a `GateClips` (a `FakeClipPlayer` whose clips end when the test says) in `test/support.dart`.

## Order and branch

Order 21, `lane/feature_words/21`.
