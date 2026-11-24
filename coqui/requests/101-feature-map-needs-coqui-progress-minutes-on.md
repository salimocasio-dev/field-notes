# Request: ProgressStore.minutesOn(day) for Up next card minutes today

## What I need

`int minutesOn(DateTime day)` (or `double minutesOn(DateTime day)`) on `ProgressStore` in `coqui_contracts` / `coqui_progress` (story N2.4, issue #87).

## Why

Story N4.1 ("Map (home)", issue #101) shows `"<N> of <M> min today"` at the end of the bottom row inside the Up next card using `minutesOn(today)` and the minutes-a-day setting (`progress.setting('min')`). N2.4 (#87) is not merged yet.

## What I am using meanwhile

Leaving the `"<N> of <M> min today"` half of the bottom row out without inventing a number, as instructed for N4.1.

## Order and branch

- Order: 101 (N4.1 Map home)
- Branch: `lane/feature_map/101`
