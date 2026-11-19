# 21-feature-words-needs-coqui-testing-full-sample-course

## What I need

A sample course that holds every story of places 1 to 3 and every review set (`cual-*.json`) the old course has, or a `fakeServices(course: ...)` helper that gives the catalog over the whole of `historia/` (the files are small: 51 stories and 11 review sets are about 660 KB). Today `FakeCourseCatalog` reads the sample course of three stories and El frente's review set only.

## Why

Order 21: the dev entry runs "on `fakeServices()` ... in each reference state" and its pictures are compared with `ref/pantallas/`. In `curso`, `todo` and `nivel` most words come from other stories, so with the sample course nearly every word would fall under "More words" and only El frente's twelve words would have a picture: the grouping by place, the order inside a place and the picture-or-plain-tile choice could not be seen. The same holds for any feature that shows words, stories or pairs (feature_library, feature_review).

## What I am using meanwhile

`tool/make_dev_data.mjs` copies the course files of `historia/` into `tool/dev_data/course.g.dart` (one Dart string per file) and `tool/dev_services.dart` gives them to `FakeCourseCatalog(fetch: ...)`; the seeds of `ref/pantallas/seeds/` go the same way into `seeds.g.dart` and are loaded through `FakeProgressStore.import`. The widget tests use the sample course and, where they need another shape, a course made to measure through the same `fetch`.

## Order and branch

Order 21, `lane/feature_words/21`.
