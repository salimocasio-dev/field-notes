# 13 · feature_map needs coqui_ui: the title of the Today card's review entry

## What I need

The title that app.html's `plan()` writes for the review entry of the Today card, `¿Cuál?` (the same string
for "N words coming back" and for the fallback "All your words"), from somewhere feature_map may read it
without writing Spanish in its own code: a member of `coqui_ui` (as `CoquiTabs` holds the tab labels), or the
course catalog. Which of the two is the orchestrator's decision; this request names coqui_ui because it is the
package feature_map may read that holds v=39's hard-coded labels.

## Why

Order 13: "the Today card with the green play button ... 'Listen' rows, the review row and whatever else v=39's
sheet and card hold call the routes page 12 gives", and "No Spanish text and no clip id in code: titles and
names come from the catalog". The review title is not in the catalog (the catalog has a story called ¿Cuál? in
El parque, which is another thing), so this item is stopped.

## What I am using meanwhile

The review entry is built (its subtitle "N word(s) coming back · M min", its minutes, `nav.go(ReviewRoute())`),
but `MapScreen` shows it only when it is given a `reviewTitle`. `MapModule` gives none, so the shipped map's
Today card goes straight to the stories. The dev entry and the tests give the old string `¿Cuál?` from
`tool/map_fixture.dart` (`fixtureReviewTitle`), so the screenshots and the tests show the card as v=39 does.
When the title has a source, `MapModule.tab` passes it to `MapScreen(reviewTitle: ...)`: one line.

## Order and branch

Order 13, branch `lane/feature_map/13`.
