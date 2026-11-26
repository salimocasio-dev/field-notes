# 254: `content` needs `coqui_ui` to decouple `historia/app.html` disk check

## What I need
Update `coqui/packages/core/coqui_ui/test/widgets_test.dart` (lines 71–81, test `'each label is copied from the line of the old page it names'`) so it no longer reads `File('../../../../historia/app.html').readAsLinesSync()` from disk during `flutter test`.

## Why
Issue #254 (`First-version pages: keep, move or remove`) removes the retired first-version public HTML pages and `?legacy=1` escape hatches. Deleting `historia/app.html` currently fails 1 test in `coqui_ui` (`PathNotFoundException: Cannot open file, path = '../../../../historia/app.html'`), blocking full removal of `historia/app.html`.

## What I am using meanwhile
Kept `historia/app.html` on disk temporarily while neutralizing its `?legacy=1` entry point on line 2 with an unconditional redirect to `../app/` (`<meta http-equiv="refresh" content="0; url=../app/"><script>location.replace("../app/");</script>`), preserving the exact line count so lines 7, 331, 365, and 374 remain unchanged and `coqui_ui` tests stay green until this decoupling lands.

## Order and branch
Issue `#254`, branch `content/254` (`lane:content`).
