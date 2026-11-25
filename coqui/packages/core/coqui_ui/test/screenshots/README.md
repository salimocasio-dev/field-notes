# Noche & Lesson Direction dev-page Chrome captures

Captured from `flutter build web -t tool/dev_main.dart --no-web-resources-cdn` on Flutter 3.50.0. Each image is the viewport of the live, scrollable `?section=noche-ltr`, `?section=noche-rtl`, `?section=lesson-direction-es`, or `?section=lesson-direction-ar` dev page, with no changes to the app for capture.

The page ran in Chrome in measured 390 × 844 and 412 × 915 CSS-pixel frames at device pixel ratio 1. Images were cropped to those exact frame rectangles from the browser screenshot.

The `test/goldens/noche_phone_*` images separately test these same phone layouts in Flutter. The tall `noche_dev_*` goldens show all component states.

- `lesson_direction_390x844_es.png` (3x DPR), `lesson_direction_412x915_es.png` (2.625x DPR): `?section=lesson-direction-es` (Spanish LTR `LessonFrame`, `LessonSpeechBubble`, unmirrored `PixelView`).
- `lesson_direction_390x844_ar.png` (3x DPR), `lesson_direction_412x915_ar.png` (2.625x DPR): `?section=lesson-direction-ar` (Arabic RTL `LessonFrame`, `LessonSpeechBubble`, unmirrored `PixelView`).
